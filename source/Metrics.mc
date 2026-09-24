import Toybox.Activity;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
using Toybox.SensorHistory;
using Toybox.Weather;

//! Everything the tiles can show, refreshed once per second by compute().
//! Values that Activity.Info hands over directly are copied; everything else is
//! accumulated or differentiated here.
class Metrics {

    // Straight from Activity.Info
    public var power as Numeric? = null;
    public var hr as Numeric? = null;
    public var cadence as Numeric? = null;
    public var speed as Numeric? = null;
    public var distance as Numeric? = null;
    public var altitude as Numeric? = null;
    public var ascent as Numeric? = null;
    public var descent as Numeric? = null;
    public var avgPower as Numeric? = null;
    public var maxPower as Numeric? = null;
    public var avgHr as Numeric? = null;
    public var maxHr as Numeric? = null;
    public var avgCadence as Numeric? = null;
    public var maxCadence as Numeric? = null;
    public var avgSpeed as Numeric? = null;
    public var maxSpeed as Numeric? = null;
    public var calories as Numeric? = null;
    public var trainingEffect as Numeric? = null;
    public var pressure as Numeric? = null;
    public var seaPressure as Numeric? = null;
    public var timerMs as Number = 0;
    public var elapsedMs as Number = 0;
    public var gpsQuality as Number? = null;

    // Navigation - only meaningful while a course is loaded
    public var distToDest as Numeric? = null;
    public var distToNext as Numeric? = null;
    public var altAtDest as Numeric? = null;
    public var altAtNext as Numeric? = null;
    public var nextPointName as String? = null;
    public var destName as String? = null;
    public var offCourse as Numeric? = null;
    public var bearing as Numeric? = null;
    public var heading as Numeric? = null;
    public var track as Numeric? = null;
    public var bearingFromStart as Numeric? = null;

    // Drivetrain
    public var frontGear as Number? = null;
    public var rearGear as Number? = null;
    public var frontTeeth as Number? = null;
    public var rearTeeth as Number? = null;

    // Derived
    public var grade as Numeric? = 0.0;
    public var vam as Numeric? = null;
    public var normalizedPower as Numeric? = null;
    public var work as Number = 0;
    public var timeInZoneMs as Number = 0;

    // Device and environment
    public var temperature as Numeric? = null;
    public var battery as Numeric? = null;
    public var batteryHours as Numeric? = null;
    public var weather as Weather.CurrentConditions? = null;

    // Laps
    public var lap as Lap;
    public var lastLap as Lap? = null;
    public var lapNumber as Number = 1;

    // Rolling power window, one slot per second
    hidden var mPower as Array<Numeric?>;
    hidden var mPowerSlot as Number = 0;

    // Rolling altitude window, for VAM
    hidden var mAltitude as Array<Numeric?>;
    hidden var mAltitudeSlot as Number = 0;

    // Normalized power: mean of the 30 s rolling average to the fourth power.
    // Scaled down by 100 W so the running total stays inside a Float.
    hidden var mNpSum as Numeric = 0.0;
    hidden var mNpCount as Number = 0;
    hidden var mSamples as Number = 0;

    hidden var mZone as Number? = null;

    // Grade is differentiated over distance, not time, so it survives stops.
    hidden var mRefAltitude as Numeric? = null;
    hidden var mRefDistance as Numeric? = null;

    // Polls too expensive to run every second
    hidden var mTempTick as Number = 0;
    hidden var mStatsTick as Number = 0;
    hidden var mWeatherTick as Number = 0;

    function initialize() {
        mPower = new [Config.PWR_WINDOW];
        mAltitude = new [Config.VAM_WINDOW];
        lap = new Lap();
    }

    function update(info as Activity.Info) as Void {
        power = info.currentPower;
        hr = info.currentHeartRate;
        cadence = info.currentCadence;
        speed = info.currentSpeed;
        distance = info.elapsedDistance;
        altitude = info.altitude;
        ascent = info.totalAscent;
        descent = info.totalDescent;

        avgPower = info.averagePower;
        maxPower = info.maxPower;
        avgHr = info.averageHeartRate;
        maxHr = info.maxHeartRate;
        avgCadence = info.averageCadence;
        maxCadence = info.maxCadence;
        avgSpeed = info.averageSpeed;
        maxSpeed = info.maxSpeed;
        calories = info.calories;
        trainingEffect = info.trainingEffect;
        pressure = info.ambientPressure;
        seaPressure = info.meanSeaLevelPressure;
        gpsQuality = info.currentLocationAccuracy;

        distToDest = info.distanceToDestination;
        distToNext = info.distanceToNextPoint;
        altAtDest = info.elevationAtDestination;
        altAtNext = info.elevationAtNextPoint;
        nextPointName = info.nameOfNextPoint;
        destName = info.nameOfDestination;
        offCourse = info.offCourseDistance;
        bearing = info.bearing;
        heading = info.currentHeading;
        track = info.track;
        bearingFromStart = info.bearingFromStart;

        frontGear = info.frontDerailleurIndex;
        rearGear = info.rearDerailleurIndex;
        frontTeeth = info.frontDerailleurSize;
        rearTeeth = info.rearDerailleurSize;

        timerMs = (info.timerTime != null) ? info.timerTime as Number : 0;
        elapsedMs = (info.elapsedTime != null) ? info.elapsedTime as Number : 0;

        var running = (info.timerState == Activity.TIMER_STATE_ON);

        pushPower();
        pushAltitude();
        updateNormalizedPower(running);
        updateWork(running);
        updateTimeInZone(running);
        updateLap(running);
        updateGrade();
        updateTemperature();
        updateSystemStats();
        updateWeather();

        mSamples++;
    }

    function onLap(info as Activity.Info?) as Void {
        var now = (info != null && info.timerTime != null) ? info.timerTime as Number : timerMs;
        lastLap = lap;
        lap = new Lap();
        lap.begin(now, distance, toInt(ascent), toInt(descent));
        lapNumber++;
    }

    function onReset() as Void {
        lastLap = null;
        lap = new Lap();
        lapNumber = 1;
        grade = 0.0;
        vam = null;
        normalizedPower = null;
        work = 0;
        timeInZoneMs = 0;
        mNpSum = 0.0;
        mNpCount = 0;
        mSamples = 0;
        mZone = null;
        mRefAltitude = null;
        mRefDistance = null;
    }

    //! Rolling average of the last n seconds of power, null if nothing recorded.
    function rollingPower(seconds as Number) as Numeric? {
        var size = mPower.size();
        var span = (seconds < size) ? seconds : size;
        var sum = 0;
        var count = 0;
        for (var i = 1; i <= span; i++) {
            var v = mPower[(mPowerSlot - i + size) % size];
            if (v != null) {
                sum += v.toNumber();
                count++;
            }
        }
        return (count > 0) ? sum / count : null;
    }

    function stoppedMs() as Number {
        var stopped = elapsedMs - timerMs;
        return (stopped > 0) ? stopped : 0;
    }

    hidden function toInt(v as Numeric?) as Number? {
        return (v != null) ? v.toNumber() : null;
    }

    hidden function pushPower() as Void {
        mPower[mPowerSlot] = power;
        mPowerSlot = (mPowerSlot + 1) % mPower.size();
    }

    //! VAM is the climb rate over the whole window, so a flat section reads zero
    //! instead of jittering with every barometric wobble.
    hidden function pushAltitude() as Void {
        var size = mAltitude.size();
        mAltitude[mAltitudeSlot] = altitude;
        mAltitudeSlot = (mAltitudeSlot + 1) % size;

        var newest = mAltitude[(mAltitudeSlot - 1 + size) % size];
        var oldest = mAltitude[mAltitudeSlot];
        if (newest == null || oldest == null || mSamples < size) {
            return;
        }
        vam = (newest - oldest) * 3600.0 / size;
    }

    hidden function updateNormalizedPower(running as Boolean) as Void {
        if (!running || mSamples < Config.PWR_WINDOW) {
            return;
        }
        var rolling = rollingPower(Config.PWR_WINDOW);
        if (rolling == null) {
            return;
        }
        var scaled = rolling / 100.0;
        mNpSum += scaled * scaled * scaled * scaled;
        mNpCount++;
        normalizedPower = 100.0 * Math.pow(mNpSum / mNpCount, 0.25);
    }

    //! One second of power is one joule-second worth of work; keep it in joules
    //! and divide when displaying.
    hidden function updateWork(running as Boolean) as Void {
        if (running && power != null) {
            work += power.toNumber();
        }
    }

    hidden function updateTimeInZone(running as Boolean) as Void {
        var zone = (hr != null) ? Zones.hrZone(hr) : null;
        if (zone == null || zone != mZone) {
            mZone = zone;
            timeInZoneMs = 0;
            return;
        }
        if (running) {
            timeInZoneMs += 1000;
        }
    }

    hidden function updateLap(running as Boolean) as Void {
        if (running) {
            lap.addSample(power, hr, cadence);
        }

        var elapsed = timerMs - lap.startMs;
        lap.timeMs = (elapsed > 0) ? elapsed : 0;

        if (distance != null) {
            var covered = distance - lap.startDistance;
            lap.distance = (covered > 0) ? covered : 0.0;
        }
        if (ascent != null) {
            var climbed = ascent.toNumber() - lap.startAscent;
            lap.ascent = (climbed > 0) ? climbed : 0;
        }
        if (descent != null) {
            var dropped = descent.toNumber() - lap.startDescent;
            lap.descent = (dropped > 0) ? dropped : 0;
        }
    }

    hidden function updateGrade() as Void {
        var alt = altitude;
        var dist = distance;
        if (alt == null || dist == null) {
            return;
        }
        if (mRefAltitude == null || mRefDistance == null) {
            mRefAltitude = alt;
            mRefDistance = dist;
            return;
        }

        var run = dist - (mRefDistance as Numeric);
        if (run < Config.GRADE_SPAN_M) {
            return;
        }

        var rise = alt - (mRefAltitude as Numeric);
        var sample = rise / run * 100.0;
        var previous = grade;
        grade = (previous == null)
            ? sample
            : (previous * (1.0 - Config.GRADE_SMOOTHING)) + (sample * Config.GRADE_SMOOTHING);

        mRefAltitude = alt;
        mRefDistance = dist;
    }

    //! Data fields may not touch Sensor.getInfo(), so the device thermometer is
    //! read through its history instead - once every few seconds, which is plenty.
    hidden function updateTemperature() as Void {
        if (mTempTick > 0) {
            mTempTick--;
            return;
        }
        mTempTick = Config.TEMP_PERIOD;

        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getTemperatureHistory)) {
            return;
        }
        var history = SensorHistory.getTemperatureHistory({
            :period => 1,
            :order => SensorHistory.ORDER_NEWEST_FIRST
        });
        if (history == null) {
            return;
        }
        var sample = history.next();
        if (sample != null && sample.data != null) {
            temperature = sample.data;
        }
    }

    hidden function updateSystemStats() as Void {
        if (mStatsTick > 0) {
            mStatsTick--;
            return;
        }
        mStatsTick = Config.STATS_PERIOD;

        var stats = System.getSystemStats();
        if (stats == null) {
            return;
        }
        battery = stats.battery;
        if (stats has :batteryInDays && stats.batteryInDays != null) {
            batteryHours = (stats.batteryInDays as Numeric) * 24.0;
        }
    }

    hidden function updateWeather() as Void {
        if (mWeatherTick > 0) {
            mWeatherTick--;
            return;
        }
        mWeatherTick = Config.WEATHER_PERIOD;

        if (!(Toybox has :Weather)) {
            return;
        }
        weather = Weather.getCurrentConditions();
    }
}
