import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
using Toybox.Weather;

//! The catalogue of supported tokens: label, formatting and zone behaviour.
//!
//! Optional members are reached through `has` checks: the SDK documents fields
//! that a Connect IQ 3.3 device does not actually carry - Weather.dewPoint being
//! the one that crashed here - and touching a missing symbol is a hard error.
//! Tokens are resolved to codes once, when the layout is parsed, so the 1 Hz
//! draw path never compares strings.
module Fields {

    enum {
        F_UNKNOWN = 0,

        // Power
        F_PWR, F_PWR3S, F_PWR5S, F_PWR10S, F_PWR30S,
        F_AVG_PWR, F_MAX_PWR, F_LAP_PWR, F_LAST_LAP_PWR,
        F_NP, F_IF, F_TSS, F_PWR_PCT_FTP, F_W_KG, F_PWR_ZONE, F_KJ,

        // Heart rate
        F_HR, F_AVG_HR, F_MAX_HR, F_LAP_HR, F_LAST_LAP_HR,
        F_HR_PCT_MAX, F_HR_PCT_RESERVE, F_HR_ZONE, F_TIME_IN_ZONE,

        // Cadence
        F_CAD, F_AVG_CAD, F_MAX_CAD, F_LAP_CAD, F_LAST_LAP_CAD,

        // Speed and distance
        F_SPD, F_AVG_SPD, F_MAX_SPD, F_LAP_SPD, F_LAST_LAP_SPD,
        F_DIST, F_LAP_DIST, F_LAST_LAP_DIST,

        // Time
        F_CLOCK, F_CLOCK12, F_TIMER, F_ELAPSED, F_STOPPED,
        F_LAP_TIME, F_LAST_LAP_TIME, F_LAP_NUMBER,

        // Elevation
        F_ALT, F_ASCENT, F_DESCENT, F_LAP_ASCENT, F_LAP_DESCENT, F_GRD, F_VAM,

        // Navigation
        F_DIST_TO_DEST, F_TIME_TO_DEST, F_ETA, F_ALT_AT_DEST,
        F_DIST_TO_NEXT, F_ALT_AT_NEXT, F_NEXT_POINT, F_DEST_NAME,
        F_OFF_COURSE, F_BEARING, F_HEADING, F_TRACK, F_BEARING_START,

        // Drivetrain
        F_GEAR_FRONT, F_GEAR_REAR, F_GEARS, F_GEAR_RATIO,

        // Weather
        F_WEATHER_TEMP, F_FEELS_LIKE, F_WIND_SPD, F_WIND_DIR, F_WIND_REL,
        F_HUMIDITY, F_PRECIP, F_DEW_POINT, F_UV,

        // Device and environment
        F_TEMP, F_PRESSURE, F_SEA_PRESSURE, F_BATTERY, F_BATTERY_HOURS,
        F_GPS, F_CALORIES, F_TRAINING_EFFECT
    }

    // Which zone palette colours the tile, if any.
    enum {
        Z_NONE = 0,
        Z_HR,
        Z_PWR,
        Z_CAD
    }

    const NO_DATA = "--";

    function codeFor(token as String) as Number {
        // Power
        if (token.equals("PWR")) { return F_PWR; }
        if (token.equals("3S_PWR")) { return F_PWR3S; }
        if (token.equals("5S_PWR")) { return F_PWR5S; }
        if (token.equals("10S_PWR")) { return F_PWR10S; }
        if (token.equals("30S_PWR")) { return F_PWR30S; }
        if (token.equals("AVG_PWR")) { return F_AVG_PWR; }
        if (token.equals("MAX_PWR")) { return F_MAX_PWR; }
        if (token.equals("LAP_PWR")) { return F_LAP_PWR; }
        if (token.equals("LAST_LAP_PWR")) { return F_LAST_LAP_PWR; }
        if (token.equals("NP")) { return F_NP; }
        if (token.equals("IF")) { return F_IF; }
        if (token.equals("TSS")) { return F_TSS; }
        if (token.equals("PWR_PCT_FTP")) { return F_PWR_PCT_FTP; }
        if (token.equals("W_KG")) { return F_W_KG; }
        if (token.equals("PWR_ZONE")) { return F_PWR_ZONE; }
        if (token.equals("KJ")) { return F_KJ; }

        // Heart rate
        if (token.equals("HR")) { return F_HR; }
        if (token.equals("AVG_HR")) { return F_AVG_HR; }
        if (token.equals("MAX_HR")) { return F_MAX_HR; }
        if (token.equals("LAP_HR")) { return F_LAP_HR; }
        if (token.equals("LAST_LAP_HR")) { return F_LAST_LAP_HR; }
        if (token.equals("HR_PCT_MAX")) { return F_HR_PCT_MAX; }
        if (token.equals("HR_PCT_RESERVE")) { return F_HR_PCT_RESERVE; }
        if (token.equals("HR_ZONE")) { return F_HR_ZONE; }
        if (token.equals("TIME_IN_ZONE")) { return F_TIME_IN_ZONE; }

        // Cadence
        if (token.equals("CAD")) { return F_CAD; }
        if (token.equals("AVG_CAD")) { return F_AVG_CAD; }
        if (token.equals("MAX_CAD")) { return F_MAX_CAD; }
        if (token.equals("LAP_CAD")) { return F_LAP_CAD; }
        if (token.equals("LAST_LAP_CAD")) { return F_LAST_LAP_CAD; }

        // Speed and distance
        if (token.equals("SPD")) { return F_SPD; }
        if (token.equals("AVG_SPD")) { return F_AVG_SPD; }
        if (token.equals("MAX_SPD")) { return F_MAX_SPD; }
        if (token.equals("LAP_SPD")) { return F_LAP_SPD; }
        if (token.equals("LAST_LAP_SPD")) { return F_LAST_LAP_SPD; }
        if (token.equals("DIST")) { return F_DIST; }
        if (token.equals("LAP_DIST")) { return F_LAP_DIST; }
        if (token.equals("LAST_LAP_DIST")) { return F_LAST_LAP_DIST; }

        // Time
        if (token.equals("DAY_TIME_24")) { return F_CLOCK; }
        if (token.equals("DAY_TIME_12")) { return F_CLOCK12; }
        if (token.equals("TIMER")) { return F_TIMER; }
        if (token.equals("ELAPSED")) { return F_ELAPSED; }
        if (token.equals("STOPPED_TIME")) { return F_STOPPED; }
        if (token.equals("LAP_TIME")) { return F_LAP_TIME; }
        if (token.equals("LAST_LAP_TIME")) { return F_LAST_LAP_TIME; }
        if (token.equals("LAP_NUMBER")) { return F_LAP_NUMBER; }

        // Elevation
        if (token.equals("ALT")) { return F_ALT; }
        if (token.equals("ASCENT")) { return F_ASCENT; }
        if (token.equals("DESCENT")) { return F_DESCENT; }
        if (token.equals("LAP_ASCENT")) { return F_LAP_ASCENT; }
        if (token.equals("LAP_DESCENT")) { return F_LAP_DESCENT; }
        if (token.equals("GRD")) { return F_GRD; }
        if (token.equals("VAM")) { return F_VAM; }

        // Navigation
        if (token.equals("DIST_TO_DEST")) { return F_DIST_TO_DEST; }
        if (token.equals("TIME_TO_DEST")) { return F_TIME_TO_DEST; }
        if (token.equals("ETA")) { return F_ETA; }
        if (token.equals("ALT_AT_DEST")) { return F_ALT_AT_DEST; }
        if (token.equals("DIST_TO_NEXT")) { return F_DIST_TO_NEXT; }
        if (token.equals("ALT_AT_NEXT")) { return F_ALT_AT_NEXT; }
        if (token.equals("NEXT_POINT")) { return F_NEXT_POINT; }
        if (token.equals("DEST_NAME")) { return F_DEST_NAME; }
        if (token.equals("OFF_COURSE")) { return F_OFF_COURSE; }
        if (token.equals("BEARING")) { return F_BEARING; }
        if (token.equals("HEADING")) { return F_HEADING; }
        if (token.equals("TRACK")) { return F_TRACK; }
        if (token.equals("BEARING_START")) { return F_BEARING_START; }

        // Drivetrain
        if (token.equals("GEAR_FRONT")) { return F_GEAR_FRONT; }
        if (token.equals("GEAR_REAR")) { return F_GEAR_REAR; }
        if (token.equals("GEARS")) { return F_GEARS; }
        if (token.equals("GEAR_RATIO")) { return F_GEAR_RATIO; }

        // Weather
        if (token.equals("WEATHER_TEMP")) { return F_WEATHER_TEMP; }
        if (token.equals("FEELS_LIKE")) { return F_FEELS_LIKE; }
        if (token.equals("WIND_SPD")) { return F_WIND_SPD; }
        if (token.equals("WIND_DIR")) { return F_WIND_DIR; }
        if (token.equals("WIND_REL")) { return F_WIND_REL; }
        if (token.equals("HUMIDITY")) { return F_HUMIDITY; }
        if (token.equals("PRECIP_CHANCE")) { return F_PRECIP; }
        if (token.equals("DEW_POINT")) { return F_DEW_POINT; }
        if (token.equals("UV_INDEX")) { return F_UV; }

        // Device and environment
        if (token.equals("TEMP_C")) { return F_TEMP; }
        if (token.equals("PRESSURE")) { return F_PRESSURE; }
        if (token.equals("SEA_PRESSURE")) { return F_SEA_PRESSURE; }
        if (token.equals("BATTERY")) { return F_BATTERY; }
        if (token.equals("BATTERY_HOURS")) { return F_BATTERY_HOURS; }
        if (token.equals("GPS_ACCURACY")) { return F_GPS; }
        if (token.equals("CALORIES")) { return F_CALORIES; }
        if (token.equals("TRAINING_EFFECT")) { return F_TRAINING_EFFECT; }

        return F_UNKNOWN;
    }

    function labelFor(cell as Cell) as String {
        switch (cell.code) {
            case F_PWR:            return "PWR";
            case F_PWR3S:          return "3s PWR";
            case F_PWR5S:          return "5s PWR";
            case F_PWR10S:         return "10s PWR";
            case F_PWR30S:         return "30s PWR";
            case F_AVG_PWR:        return "AVG PWR";
            case F_MAX_PWR:        return "MAX PWR";
            case F_LAP_PWR:        return "LAP PWR";
            case F_LAST_LAP_PWR:   return "LAST PWR";
            case F_NP:             return "NP";
            case F_IF:             return "IF";
            case F_TSS:            return "TSS";
            case F_PWR_PCT_FTP:    return "% FTP";
            case F_W_KG:           return "W/KG";
            case F_PWR_ZONE:       return "PWR ZONE";
            case F_KJ:             return "KJ";

            case F_HR:             return "HR";
            case F_AVG_HR:         return "AVG HR";
            case F_MAX_HR:         return "MAX HR";
            case F_LAP_HR:         return "LAP HR";
            case F_LAST_LAP_HR:    return "LAST HR";
            case F_HR_PCT_MAX:     return "% MAX HR";
            case F_HR_PCT_RESERVE: return "% HRR";
            case F_HR_ZONE:        return "HR ZONE";
            case F_TIME_IN_ZONE:   return "IN ZONE";

            case F_CAD:            return "CAD";
            case F_AVG_CAD:        return "AVG CAD";
            case F_MAX_CAD:        return "MAX CAD";
            case F_LAP_CAD:        return "LAP CAD";
            case F_LAST_LAP_CAD:   return "LAST CAD";

            case F_SPD:            return "SPD";
            case F_AVG_SPD:        return "AVG SPD";
            case F_MAX_SPD:        return "MAX SPD";
            case F_LAP_SPD:        return "LAP SPD";
            case F_LAST_LAP_SPD:   return "LAST SPD";
            case F_DIST:           return "DIST";
            case F_LAP_DIST:       return "LAP DIST";
            case F_LAST_LAP_DIST:  return "LAST DIST";

            case F_CLOCK:          return "TIME";
            case F_CLOCK12:        return "TIME";
            case F_TIMER:          return "TIMER";
            case F_ELAPSED:        return "ELAPSED";
            case F_STOPPED:        return "STOPPED";
            case F_LAP_TIME:       return "LAP TIME";
            case F_LAST_LAP_TIME:  return "LAST LAP";
            case F_LAP_NUMBER:     return "LAP";

            case F_ALT:            return "ALT";
            case F_ASCENT:         return "ASCENT";
            case F_DESCENT:        return "DESCENT";
            case F_LAP_ASCENT:     return "LAP ASC";
            case F_LAP_DESCENT:    return "LAP DESC";
            case F_GRD:            return "GRD %";
            case F_VAM:            return "VAM";

            case F_DIST_TO_DEST:   return "DIST LEFT";
            case F_TIME_TO_DEST:   return "TIME LEFT";
            case F_ETA:            return "ETA";
            case F_ALT_AT_DEST:    return "DEST ALT";
            case F_DIST_TO_NEXT:   return "NEXT DIST";
            case F_ALT_AT_NEXT:    return "NEXT ALT";
            case F_NEXT_POINT:     return "NEXT";
            case F_DEST_NAME:      return "DEST";
            case F_OFF_COURSE:     return "OFF CRS";
            case F_BEARING:        return "BEARING";
            case F_HEADING:        return "HEADING";
            case F_TRACK:          return "TRACK";
            case F_BEARING_START:  return "TO START";

            case F_GEAR_FRONT:     return "FRONT";
            case F_GEAR_REAR:      return "REAR";
            case F_GEARS:          return "GEARS";
            case F_GEAR_RATIO:     return "RATIO";

            case F_WEATHER_TEMP:   return "AIR TEMP";
            case F_FEELS_LIKE:     return "FEELS";
            case F_WIND_SPD:       return "WIND";
            case F_WIND_DIR:       return "WIND DIR";
            case F_WIND_REL:       return "WIND REL";
            case F_HUMIDITY:       return "HUMID";
            case F_PRECIP:         return "RAIN %";
            case F_DEW_POINT:      return "DEW PT";
            case F_UV:             return "UV";

            case F_TEMP:           return "TEMP";
            case F_PRESSURE:       return "PRESS";
            case F_SEA_PRESSURE:   return "SEA PRESS";
            case F_BATTERY:        return "BATT";
            case F_BATTERY_HOURS:  return "BATT HRS";
            case F_GPS:            return "GPS";
            case F_CALORIES:       return "CAL";
            case F_TRAINING_EFFECT:return "TE";
        }
        return cell.name;
    }

    //! Only what the rider is doing right now gets a zone tint - including the
    //! percentages, which are just the current value against a reference.
    //! Averages, maxima and whole-ride totals stay on the plain background: a
    //! colour there would read as the current effort and be wrong.
    function zoneKind(code as Number) as Number {
        switch (code) {
            case F_HR:
            case F_HR_ZONE:
            case F_HR_PCT_MAX:
            case F_HR_PCT_RESERVE:
            case F_TIME_IN_ZONE:
                return Z_HR;

            case F_PWR:
            case F_PWR3S:
            case F_PWR5S:
            case F_PWR10S:
            case F_PWR30S:
            case F_PWR_ZONE:
            case F_PWR_PCT_FTP:
            case F_W_KG:
                return Z_PWR;

            case F_CAD:
                return Z_CAD;
        }
        return Z_NONE;
    }

    //! The number the zone is looked up by, or null when the tile is not zoned.
    function zoneInput(code as Number, m as Metrics) as Numeric? {
        switch (code) {
            case F_HR:
            case F_HR_ZONE:
            case F_HR_PCT_MAX:
            case F_HR_PCT_RESERVE:
            case F_TIME_IN_ZONE:
                return m.hr;

            case F_PWR:
            case F_PWR_ZONE:
            case F_PWR_PCT_FTP:
            case F_W_KG:
                return m.power;

            case F_CAD:            return m.cadence;

            case F_PWR3S:          return m.rollingPower(3);
            case F_PWR5S:          return m.rollingPower(5);
            case F_PWR10S:         return m.rollingPower(10);
            case F_PWR30S:         return m.rollingPower(30);
        }
        return null;
    }

    function textFor(cell as Cell, m as Metrics) as String {
        switch (cell.code) {
            // Power
            case F_PWR:            return whole(m.power);
            case F_PWR3S:          return whole(m.rollingPower(3));
            case F_PWR5S:          return whole(m.rollingPower(5));
            case F_PWR10S:         return whole(m.rollingPower(10));
            case F_PWR30S:         return whole(m.rollingPower(30));
            case F_AVG_PWR:        return whole(m.avgPower);
            case F_MAX_PWR:        return whole(m.maxPower);
            case F_LAP_PWR:        return whole(m.lap.avgPower());
            case F_LAST_LAP_PWR:   return whole(lastLapPower(m));
            case F_NP:             return whole(m.normalizedPower);
            case F_IF:             return intensityFactor(m);
            case F_TSS:            return trainingStress(m);
            case F_PWR_PCT_FTP:    return ratioPercent(m.power, Zones.ftp());
            case F_W_KG:           return wattsPerKg(m);
            case F_PWR_ZONE:       return zoneNumber(Z_PWR, m.power);
            case F_KJ:             return whole(m.work / 1000);

            // Heart rate
            case F_HR:             return whole(m.hr);
            case F_AVG_HR:         return whole(m.avgHr);
            case F_MAX_HR:         return whole(m.maxHr);
            case F_LAP_HR:         return whole(m.lap.avgHr());
            case F_LAST_LAP_HR:    return whole(lastLapHr(m));
            case F_HR_PCT_MAX:     return ratioPercent(m.hr, Zones.maxHr());
            case F_HR_PCT_RESERVE: return heartRateReserve(m);
            case F_HR_ZONE:        return zoneNumber(Z_HR, m.hr);
            case F_TIME_IN_ZONE:   return duration(m.timeInZoneMs);

            // Cadence
            case F_CAD:            return whole(m.cadence);
            case F_AVG_CAD:        return whole(m.avgCadence);
            case F_MAX_CAD:        return whole(m.maxCadence);
            case F_LAP_CAD:        return whole(m.lap.avgCadence());
            case F_LAST_LAP_CAD:   return whole(lastLapCadence(m));

            // Speed and distance
            case F_SPD:            return speed(m.speed);
            case F_AVG_SPD:        return speed(m.avgSpeed);
            case F_MAX_SPD:        return speed(m.maxSpeed);
            case F_LAP_SPD:        return speed(m.lap.avgSpeed());
            case F_LAST_LAP_SPD:   return speed(lastLapSpeed(m));
            case F_DIST:           return distance(m.distance);
            case F_LAP_DIST:       return distance(m.lap.distance);
            case F_LAST_LAP_DIST:  return distance(lastLapDistance(m));

            // Time
            case F_CLOCK:          return clock24();
            case F_CLOCK12:        return clock12();
            case F_TIMER:          return duration(m.timerMs);
            case F_ELAPSED:        return duration(m.elapsedMs);
            case F_STOPPED:        return duration(m.stoppedMs());
            case F_LAP_TIME:       return duration(m.lap.timeMs);
            case F_LAST_LAP_TIME:  return lastLapTime(m);
            case F_LAP_NUMBER:     return m.lapNumber.format("%d");

            // Elevation
            case F_ALT:            return whole(m.altitude);
            case F_ASCENT:         return whole(m.ascent);
            case F_DESCENT:        return whole(m.descent);
            case F_LAP_ASCENT:     return whole(m.lap.ascent);
            case F_LAP_DESCENT:    return whole(m.lap.descent);
            case F_GRD:            return grade(m.grade);
            case F_VAM:            return whole(m.vam);

            // Navigation
            case F_DIST_TO_DEST:   return distance(m.distToDest);
            case F_TIME_TO_DEST:   return timeToDestination(m);
            case F_ETA:            return eta(m);
            case F_ALT_AT_DEST:    return whole(m.altAtDest);
            case F_DIST_TO_NEXT:   return distance(m.distToNext);
            case F_ALT_AT_NEXT:    return whole(m.altAtNext);
            case F_NEXT_POINT:     return name(m.nextPointName);
            case F_DEST_NAME:      return name(m.destName);
            case F_OFF_COURSE:     return whole(m.offCourse);
            case F_BEARING:        return degrees(m.bearing);
            case F_HEADING:        return degrees(m.heading);
            case F_TRACK:          return degrees(m.track);
            case F_BEARING_START:  return degrees(m.bearingFromStart);

            // Drivetrain
            case F_GEAR_FRONT:     return whole(m.frontGear);
            case F_GEAR_REAR:      return whole(m.rearGear);
            case F_GEARS:          return gears(m);
            case F_GEAR_RATIO:     return gearRatio(m);

            // Weather
            case F_WEATHER_TEMP:   return celsius(weatherTemp(m));
            case F_FEELS_LIKE:     return celsius(feelsLike(m));
            case F_WIND_SPD:       return speed(windSpeed(m));
            case F_WIND_DIR:       return windDirection(m);
            case F_WIND_REL:       return relativeWind(m);
            case F_HUMIDITY:       return percent(humidity(m));
            case F_PRECIP:         return percent(precipitation(m));
            case F_DEW_POINT:      return celsius(dewPoint(m));
            case F_UV:             return whole(uvIndex(m));

            // Device and environment
            case F_TEMP:           return celsius(m.temperature);
            case F_PRESSURE:       return hectopascals(m.pressure);
            case F_SEA_PRESSURE:   return hectopascals(m.seaPressure);
            case F_BATTERY:        return percent(m.battery);
            case F_BATTERY_HOURS:  return hours(m.batteryHours);
            case F_GPS:            return gpsQuality(m.gpsQuality);
            case F_CALORIES:       return whole(m.calories);
            case F_TRAINING_EFFECT:return decimal1(m.trainingEffect);
        }
        return "?";
    }

    // --- Last lap accessors -------------------------------------------------

    function lastLapPower(m as Metrics) as Numeric? {
        var l = m.lastLap;
        return (l != null) ? l.avgPower() : null;
    }

    function lastLapHr(m as Metrics) as Numeric? {
        var l = m.lastLap;
        return (l != null) ? l.avgHr() : null;
    }

    function lastLapCadence(m as Metrics) as Numeric? {
        var l = m.lastLap;
        return (l != null) ? l.avgCadence() : null;
    }

    function lastLapSpeed(m as Metrics) as Numeric? {
        var l = m.lastLap;
        return (l != null) ? l.avgSpeed() : null;
    }

    function lastLapDistance(m as Metrics) as Numeric? {
        var l = m.lastLap;
        return (l != null) ? l.distance : null;
    }

    function lastLapTime(m as Metrics) as String {
        var l = m.lastLap;
        return (l != null) ? duration(l.timeMs) : NO_DATA;
    }

    // --- Weather accessors --------------------------------------------------

    function weatherTemp(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :temperature) ? w.temperature : null;
    }

    function feelsLike(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :feelsLikeTemperature) ? w.feelsLikeTemperature : null;
    }

    function windSpeed(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :windSpeed) ? w.windSpeed : null;
    }

    function humidity(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :relativeHumidity) ? w.relativeHumidity : null;
    }

    function precipitation(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :precipitationChance) ? w.precipitationChance : null;
    }

    function dewPoint(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :dewPoint) ? w.dewPoint : null;
    }

    function uvIndex(m as Metrics) as Numeric? {
        var w = m.weather;
        return (w != null && w has :uvIndex) ? w.uvIndex : null;
    }

    function windDirection(m as Metrics) as String {
        var w = m.weather;
        if (w == null) {
            return NO_DATA;
        }
        if (!(w has :windBearing) || w.windBearing == null) {
            return NO_DATA;
        }
        return (w.windBearing as Numeric).toNumber().format("%d") + "°";
    }

    //! Where the wind sits relative to travel. windBearing is the direction the
    //! wind blows from, so a bearing close to the heading is a headwind.
    function relativeWind(m as Metrics) as String {
        var w = m.weather;
        if (w == null || m.heading == null) {
            return NO_DATA;
        }
        if (!(w has :windBearing) || w.windBearing == null) {
            return NO_DATA;
        }
        var headingDeg = (m.heading as Numeric) * 180.0 / Math.PI;
        var delta = (w.windBearing as Numeric) - headingDeg;
        delta = delta - (360.0 * Math.floor(delta / 360.0));

        if (delta <= 45.0 || delta >= 315.0) {
            return "HEAD";
        }
        if (delta >= 135.0 && delta <= 225.0) {
            return "TAIL";
        }
        return "CROSS";
    }

    // --- Computed values ----------------------------------------------------

    function intensityFactor(m as Metrics) as String {
        var np = m.normalizedPower;
        if (np == null) {
            return NO_DATA;
        }
        return (np / Zones.ftp()).format("%.2f");
    }

    //! TSS = duration * NP * IF / (FTP * 3600) * 100, with IF = NP / FTP.
    function trainingStress(m as Metrics) as String {
        var np = m.normalizedPower;
        if (np == null || m.timerMs <= 0) {
            return NO_DATA;
        }
        var ftp = Zones.ftp();
        var seconds = m.timerMs / 1000.0;
        var tss = seconds * np * np / (ftp * ftp * 36.0);
        return tss.toNumber().format("%d");
    }

    function wattsPerKg(m as Metrics) as String {
        var weight = Zones.weightKg();
        if (m.power == null || weight == null || weight <= 0.0) {
            return NO_DATA;
        }
        return ((m.power as Numeric) / weight).format("%.1f");
    }

    function heartRateReserve(m as Metrics) as String {
        var max = Zones.maxHr();
        var rest = Zones.restingHr();
        if (m.hr == null || max == null || rest == null || max <= rest) {
            return NO_DATA;
        }
        var pct = ((m.hr as Numeric) - rest) * 100.0 / (max - rest);
        return pct.toNumber().format("%d");
    }

    function zoneNumber(kind as Number, value as Numeric?) as String {
        var zone = Zones.of(kind, value);
        return (zone != null) ? zone.format("%d") : NO_DATA;
    }

    function timeToDestination(m as Metrics) as String {
        var seconds = secondsToDestination(m);
        return (seconds != null) ? duration((seconds * 1000).toNumber()) : NO_DATA;
    }

    function eta(m as Metrics) as String {
        var seconds = secondsToDestination(m);
        if (seconds == null) {
            return NO_DATA;
        }
        var now = System.getClockTime();
        var total = now.hour * 3600 + now.min * 60 + now.sec + seconds.toNumber();
        total = total % 86400;
        return (total / 3600).format("%02d") + ":" + ((total % 3600) / 60).format("%02d");
    }

    //! Prefers current speed, falling back to the ride average when stopped, so
    //! the estimate does not vanish at every traffic light.
    function secondsToDestination(m as Metrics) as Numeric? {
        var left = m.distToDest;
        if (left == null || left <= 0) {
            return null;
        }
        var v = m.speed;
        if (v == null || v < 1.0) {
            v = m.avgSpeed;
        }
        if (v == null || v < 0.5) {
            return null;
        }
        return left / v;
    }

    function gears(m as Metrics) as String {
        if (m.frontTeeth != null && m.rearTeeth != null) {
            return (m.frontTeeth as Number).format("%d") + "/" + (m.rearTeeth as Number).format("%d");
        }
        if (m.frontGear != null && m.rearGear != null) {
            return (m.frontGear as Number).format("%d") + "/" + (m.rearGear as Number).format("%d");
        }
        return NO_DATA;
    }

    function gearRatio(m as Metrics) as String {
        var front = m.frontTeeth;
        var rear = m.rearTeeth;
        if (front == null || rear == null || rear <= 0) {
            return NO_DATA;
        }
        return ((front as Number) * 1.0 / (rear as Number)).format("%.2f");
    }

    // --- Formatting ---------------------------------------------------------

    function whole(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        return v.toNumber().format("%d");
    }

    function decimal1(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        return v.format("%.1f");
    }

    function percent(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        return v.toNumber().format("%d") + "%";
    }

    function ratioPercent(value as Numeric?, reference as Numeric?) as String {
        if (value == null || reference == null || reference <= 0) {
            return NO_DATA;
        }
        return (value * 100.0 / reference).toNumber().format("%d") + "%";
    }

    //! m/s to km/h; one decimal only while it still fits the eye.
    function speed(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        var kmh = v * 3.6;
        if (kmh < 10.0) { return kmh.format("%.1f"); }
        return kmh.format("%.0f");
    }

    //! Always kilometres, one decimal, no unit. The header already says what the
    //! tile is, and a fixed shape stops the number changing form mid-ride. Being
    //! pure digits, it also qualifies for the large number fonts.
    function distance(meters as Numeric?) as String {
        if (meters == null) { return NO_DATA; }
        return (meters / 1000.0).format("%.1f");
    }

    function grade(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        var s = v.format("%.0f");
        if (s.equals("-0")) { return "0"; }
        return s;
    }

    function duration(ms as Number?) as String {
        if (ms == null || ms < 0) { return NO_DATA; }
        var total = ms / 1000;
        var h = total / 3600;
        var min = (total % 3600) / 60;
        var sec = total % 60;
        if (h > 0) {
            return h.format("%d") + ":" + min.format("%02d") + ":" + sec.format("%02d");
        }
        return min.format("%02d") + ":" + sec.format("%02d");
    }

    function clock24() as String {
        var t = System.getClockTime();
        return t.hour.format("%02d") + ":" + t.min.format("%02d");
    }

    function clock12() as String {
        var t = System.getClockTime();
        var h = t.hour % 12;
        if (h == 0) { h = 12; }
        return h.format("%d") + ":" + t.min.format("%02d");
    }

    function celsius(c as Numeric?) as String {
        if (c == null) { return NO_DATA; }
        return c.format("%.0f") + "°C";
    }

    function hectopascals(pascals as Numeric?) as String {
        if (pascals == null) { return NO_DATA; }
        return (pascals / 100.0).toNumber().format("%d");
    }

    function hours(h as Numeric?) as String {
        if (h == null) { return NO_DATA; }
        return h.format("%.0f") + "h";
    }

    function degrees(radians as Numeric?) as String {
        if (radians == null) { return NO_DATA; }
        var deg = radians * 180.0 / Math.PI;
        deg = deg - (360.0 * Math.floor(deg / 360.0));
        return deg.toNumber().format("%d") + "°";
    }

    function name(s as String?) as String {
        if (s == null || s.length() == 0) { return NO_DATA; }
        return s;
    }

    function gpsQuality(quality as Number?) as String {
        if (quality == null) { return NO_DATA; }
        switch (quality) {
            case Position.QUALITY_NOT_AVAILABLE: return "NONE";
            case Position.QUALITY_LAST_KNOWN:    return "OLD";
            case Position.QUALITY_POOR:          return "POOR";
            case Position.QUALITY_USABLE:        return "OK";
            case Position.QUALITY_GOOD:          return "GOOD";
        }
        return NO_DATA;
    }
}
