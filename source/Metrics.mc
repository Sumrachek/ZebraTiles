import Toybox.Activity;
import Toybox.Lang;
using Toybox.SensorHistory;

//! Everything the tiles can show, refreshed once per second by compute().
class Metrics {

    public var power as Numeric? = null;
    public var pwr3s as Numeric? = null;
    public var hr as Numeric? = null;
    public var cadence as Numeric? = null;
    public var speed as Numeric? = null;
    public var distance as Numeric? = null;
    public var temperature as Numeric? = null;
    public var lapPower as Numeric? = null;
    public var lapTimeMs as Number = 0;
    public var grade as Numeric? = 0.0;

    // 3 s rolling power window
    hidden var mWindow as Array<Numeric?> = [null, null, null] as Array<Numeric?>;
    hidden var mSlot as Number = 0;

    // Lap accumulators
    hidden var mLapSum as Number = 0;
    hidden var mLapCount as Number = 0;
    hidden var mLapStartMs as Number = 0;

    // Grade is differentiated over distance, not time, so it survives stops.
    hidden var mRefAltitude as Numeric? = null;
    hidden var mRefDistance as Numeric? = null;

    // Temperature comes from sensor history, which is too costly to poll at 1 Hz.
    hidden var mTempTick as Number = 0;

    const GRADE_SPAN_M = 20.0;
    const GRADE_SMOOTHING = 0.4;

    function initialize() {
    }

    function update(info as Activity.Info) as Void {
        power = info.currentPower;
        hr = info.currentHeartRate;
        cadence = info.currentCadence;
        speed = info.currentSpeed;
        distance = info.elapsedDistance;

        updatePwr3s();
        updateLap(info);
        updateGrade(info);
        updateTemperature();
    }

    function onLap(info as Activity.Info?) as Void {
        mLapSum = 0;
        mLapCount = 0;
        mLapStartMs = timerMs(info);
        lapPower = null;
        lapTimeMs = 0;
    }

    function onReset() as Void {
        onLap(null);
        grade = 0.0;
        mRefAltitude = null;
        mRefDistance = null;
    }

    hidden function timerMs(info as Activity.Info?) as Number {
        if (info != null && info.timerTime != null) {
            return info.timerTime as Number;
        }
        return 0;
    }

    hidden function updatePwr3s() as Void {
        mWindow[mSlot] = power;
        mSlot = (mSlot + 1) % mWindow.size();

        var sum = 0;
        var n = 0;
        for (var i = 0; i < mWindow.size(); i++) {
            var v = mWindow[i];
            if (v != null) {
                sum += v;
                n++;
            }
        }
        pwr3s = (n > 0) ? sum / n : null;
    }

    hidden function updateLap(info as Activity.Info) as Void {
        var now = timerMs(info);

        if (info.timerState == Activity.TIMER_STATE_ON && power != null) {
            mLapSum += (power as Numeric).toNumber();
            mLapCount++;
        }
        lapPower = (mLapCount > 0) ? mLapSum / mLapCount : null;

        var elapsed = now - mLapStartMs;
        lapTimeMs = (elapsed > 0) ? elapsed : 0;
    }

    hidden function updateGrade(info as Activity.Info) as Void {
        var alt = info.altitude;
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
        if (run < GRADE_SPAN_M) {
            return;
        }

        var rise = alt - (mRefAltitude as Numeric);
        var sample = rise / run * 100.0;
        var previous = grade;
        grade = (previous == null)
            ? sample
            : (previous * (1.0 - GRADE_SMOOTHING)) + (sample * GRADE_SMOOTHING);

        mRefAltitude = alt;
        mRefDistance = dist;
    }

    //! Data fields may not touch Sensor.getInfo(), so the device thermometer is
    //! read through its history instead - once every 10 s, which is plenty.
    hidden function updateTemperature() as Void {
        if (mTempTick > 0) {
            mTempTick--;
            return;
        }
        mTempTick = 10;

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
}
