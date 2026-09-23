import Toybox.Lang;
import Toybox.System;

//! The catalogue of supported tokens: label, formatting and zone behaviour.
module Fields {

    enum {
        F_UNKNOWN = 0,
        F_PWR3S,
        F_PWR,
        F_SPD,
        F_HR,
        F_CAD,
        F_GRD,
        F_LAP_PWR,
        F_LAP_TIME,
        F_CLOCK,
        F_DIST,
        F_TEMP
    }

    // Which zone palette colors the tile, if any.
    enum {
        Z_NONE = 0,
        Z_HR,
        Z_PWR
    }

    const NO_DATA = "--";

    function codeFor(token as String) as Number {
        if (token.equals("3S_PWR")) { return F_PWR3S; }
        if (token.equals("PWR")) { return F_PWR; }
        if (token.equals("SPD")) { return F_SPD; }
        if (token.equals("HR")) { return F_HR; }
        if (token.equals("CAD")) { return F_CAD; }
        if (token.equals("GRD")) { return F_GRD; }
        if (token.equals("LAP_PWR")) { return F_LAP_PWR; }
        if (token.equals("LAP_TIME")) { return F_LAP_TIME; }
        if (token.equals("DAY_TIME_24")) { return F_CLOCK; }
        if (token.equals("DIST")) { return F_DIST; }
        if (token.equals("TEMP_C")) { return F_TEMP; }
        return F_UNKNOWN;
    }

    function labelFor(cell as Cell) as String {
        switch (cell.code) {
            case F_PWR3S:    return "3s PWR";
            case F_PWR:      return "PWR";
            case F_SPD:      return "SPD";
            case F_HR:       return "HR";
            case F_CAD:      return "CAD";
            case F_GRD:      return "GRD %";
            case F_LAP_PWR:  return "LAP PWR";
            case F_LAP_TIME: return "LAP TIME";
            case F_CLOCK:    return "TIME";
            case F_DIST:     return "DIST";
            case F_TEMP:     return "TEMP";
        }
        return cell.name;
    }

    function zoneKind(code as Number) as Number {
        if (code == F_HR) { return Z_HR; }
        if (code == F_PWR3S || code == F_PWR) { return Z_PWR; }
        return Z_NONE;
    }

    //! The number the zone is looked up by, or null when the tile is not zoned.
    function zoneInput(code as Number, m as Metrics) as Numeric? {
        switch (code) {
            case F_HR:      return m.hr;
            case F_PWR3S:   return m.pwr3s;
            case F_PWR:     return m.power;
            case F_LAP_PWR: return m.lapPower;
        }
        return null;
    }

    function textFor(cell as Cell, m as Metrics) as String {
        switch (cell.code) {
            case F_PWR3S:    return whole(m.pwr3s);
            case F_PWR:      return whole(m.power);
            case F_LAP_PWR:  return whole(m.lapPower);
            case F_HR:       return whole(m.hr);
            case F_CAD:      return whole(m.cadence);
            case F_SPD:      return speed(m.speed);
            case F_GRD:      return grade(m.grade);
            case F_LAP_TIME: return duration(m.lapTimeMs);
            case F_CLOCK:    return clock();
            case F_DIST:     return distance(m.distance);
            case F_TEMP:     return temperature(m.temperature);
        }
        return "?";
    }

    function whole(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        return v.toNumber().format("%d");
    }

    //! m/s to km/h; one decimal only while it still fits the eye.
    function speed(v as Numeric?) as String {
        if (v == null) { return NO_DATA; }
        var kmh = v * 3.6;
        if (kmh < 10.0) { return kmh.format("%.1f"); }
        return kmh.format("%.0f");
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

    function clock() as String {
        var t = System.getClockTime();
        return t.hour.format("%02d") + ":" + t.min.format("%02d");
    }

    function distance(meters as Numeric?) as String {
        if (meters == null) { return NO_DATA; }
        var km = meters / 1000.0;
        if (km < 100.0) { return km.format("%.1f") + "km"; }
        return km.format("%.0f") + "km";
    }

    function temperature(c as Numeric?) as String {
        if (c == null) { return NO_DATA; }
        return c.format("%.0f") + "°C";
    }
}
