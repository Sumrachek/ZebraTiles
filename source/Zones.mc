import Toybox.Application;
import Toybox.Lang;
import Toybox.UserProfile;

//! Zone lookup. Heart rate zones come straight from the device profile.
//! Power zones are derived from FTP, because the Edge 530 (CIQ 3.3) has no
//! API for the user's power zones - UserProfile.getPowerZones() needs 5.2.2.
module Zones {

    var mHrZones as Array<Number>? = null;
    var mHrChecked as Boolean = false;
    var mProfile as UserProfile.Profile? = null;
    var mProfileChecked as Boolean = false;
    var mFtp as Number = Config.DEFAULT_FTP;
    var mCadMin as Number = Config.DEFAULT_CAD_MIN;
    var mCadMax as Number = Config.DEFAULT_CAD_MAX;

    function reload() as Void {
        mHrZones = null;
        mHrChecked = false;
        mProfile = null;
        mProfileChecked = false;

        var ftp = null;
        try {
            ftp = Application.Properties.getValue("ftp");
        } catch (e) {
            ftp = null;
        }
        if (ftp instanceof Lang.Number && ftp > 0) {
            mFtp = ftp;
        } else {
            mFtp = Config.DEFAULT_FTP;
        }

        mCadMin = setting("cadenceMin", Config.DEFAULT_CAD_MIN);
        mCadMax = setting("cadenceMax", Config.DEFAULT_CAD_MAX);
        if (mCadMin >= mCadMax) {
            mCadMin = Config.DEFAULT_CAD_MIN;
            mCadMax = Config.DEFAULT_CAD_MAX;
        }
    }

    function setting(key as String, fallback as Number) as Number {
        var value = null;
        try {
            value = Application.Properties.getValue(key);
        } catch (e) {
            value = null;
        }
        return (value instanceof Lang.Number && value > 0) ? value : fallback;
    }

    //! 1-based zone number, or null when it cannot be told.
    function of(kind as Number, value as Numeric?) as Number? {
        if (value == null || kind == Fields.Z_NONE) {
            return null;
        }
        if (kind == Fields.Z_HR) {
            return hrZone(value);
        }
        if (kind == Fields.Z_CAD) {
            return cadenceZone(value);
        }
        return powerZone(value);
    }

    //! Three bands: below the target range, inside it, above it. A coasting
    //! cadence of zero lands in the low band, which is the honest answer.
    function cadenceZone(rpm as Numeric) as Number {
        if (rpm < mCadMin) { return 1; }
        if (rpm > mCadMax) { return 3; }
        return 2;
    }

    //! How many zones the scale has, which is also the top zone's number.
    function count(kind as Number) as Number {
        if (kind == Fields.Z_HR) { return 5; }
        if (kind == Fields.Z_CAD) { return 3; }
        return Config.PWR_PCT.size() + 1;
    }

    //! The value at which a zone begins. Always finite: nothing here goes below
    //! zero, even where no zone sits underneath.
    function lowerEdge(kind as Number, zone as Number) as Numeric {
        if (kind == Fields.Z_HR) {
            var z = mHrZones;
            return (z != null && z.size() >= 6) ? z[zone - 1] : 0;
        }
        if (kind == Fields.Z_CAD) {
            if (zone == 1) { return 0; }
            return (zone == 2) ? mCadMin : mCadMax;
        }
        return (zone == 1) ? 0 : mFtp * Config.PWR_PCT[zone - 2];
    }

    //! The value at which a zone ends, or null for the open-ended top zone.
    function upperEdge(kind as Number, zone as Number) as Numeric? {
        if (kind == Fields.Z_HR) {
            var z = mHrZones;
            return (z != null && z.size() >= 6) ? z[zone] : null;
        }
        if (kind == Fields.Z_CAD) {
            if (zone == 1) { return mCadMin; }
            return (zone == 2) ? mCadMax : null;
        }
        return (zone > Config.PWR_PCT.size()) ? null : mFtp * Config.PWR_PCT[zone - 1];
    }

    //! The zone's width, used to size the 10 % approach band. The top zone has no
    //! width of its own, so it borrows the one below it.
    function span(kind as Number, zone as Number) as Numeric {
        var upper = upperEdge(kind, zone);
        if (upper != null) {
            return upper - lowerEdge(kind, zone);
        }
        if (zone <= 1) {
            return 0;
        }
        var below = upperEdge(kind, zone - 1);
        return (below != null) ? below - lowerEdge(kind, zone - 1) : 0;
    }

    //! 0.0 well inside the zone, rising to 1.0 at the upper threshold. Zero when
    //! there is no zone above to warn about.
    function upperHint(kind as Number, value as Numeric?, zone as Number?) as Numeric {
        if (value == null || zone == null || zone >= count(kind)) {
            return 0.0;
        }
        var upper = upperEdge(kind, zone);
        var width = span(kind, zone);
        if (upper == null || width <= 0) {
            return 0.0;
        }
        var trigger = upper - (width * Config.HINT_TRIGGER);
        if (value <= trigger || upper <= trigger) {
            return 0.0;
        }
        var t = (value - trigger) / (upper - trigger);
        return (t > 1.0) ? 1.0 : t;
    }

    //! The mirror image, for the lower threshold.
    function lowerHint(kind as Number, value as Numeric?, zone as Number?) as Numeric {
        if (value == null || zone == null || zone <= 1) {
            return 0.0;
        }
        var lower = lowerEdge(kind, zone);
        var width = span(kind, zone);
        if (width <= 0) {
            return 0.0;
        }
        var trigger = lower + (width * Config.HINT_TRIGGER);
        if (value >= trigger || trigger <= lower) {
            return 0.0;
        }
        var t = (trigger - value) / (trigger - lower);
        return (t > 1.0) ? 1.0 : t;
    }

    //! The badge only means something where the zones are numbered. Cadence
    //! bands are not zones, so those tiles carry the colour and no badge.
    function badgeFor(kind as Number, zone as Number?) as String? {
        if (zone == null || kind == Fields.Z_NONE || kind == Fields.Z_CAD) {
            return null;
        }
        return "z" + zone.format("%d");
    }

    function colorFor(kind as Number, zone as Number?) as Number? {
        if (zone == null) {
            return null;
        }
        var palette = Config.PWR_COLORS;
        if (kind == Fields.Z_HR) {
            palette = Config.HR_COLORS;
        } else if (kind == Fields.Z_CAD) {
            palette = Config.CAD_COLORS;
        }
        var i = zone - 1;
        if (i < 0) { i = 0; }
        if (i >= palette.size()) { i = palette.size() - 1; }
        return palette[i];
    }

    //! getHeartRateZones returns [z1 min, z1 max, z2 max, z3 max, z4 max, z5 max].
    function hrZone(hr as Numeric) as Number? {
        if (!mHrChecked) {
            mHrChecked = true;
            try {
                mHrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
            } catch (e) {
                mHrZones = null;
            }
        }
        var z = mHrZones;
        if (z == null || z.size() < 6) {
            return null;
        }
        var zone = 1;
        for (var i = 1; i <= 4; i++) {
            if (hr >= z[i]) {
                zone = i + 1;
            }
        }
        return zone;
    }

    //! FTP from the app settings; there is no way to read the device's own.
    function ftp() as Number {
        return mFtp;
    }

    //! The top of zone 5 is the profile's maximum heart rate.
    function maxHr() as Number? {
        hrZone(0);
        var z = mHrZones;
        return (z != null && z.size() >= 6) ? z[5] : null;
    }

    function restingHr() as Number? {
        var p = profile();
        return (p != null) ? p.restingHeartRate : null;
    }

    //! Profile weight is in grams.
    function weightKg() as Numeric? {
        var p = profile();
        if (p == null || p.weight == null) {
            return null;
        }
        return (p.weight as Numeric) / 1000.0;
    }

    function profile() as UserProfile.Profile? {
        if (!mProfileChecked) {
            mProfileChecked = true;
            try {
                mProfile = UserProfile.getProfile();
            } catch (e) {
                mProfile = null;
            }
        }
        return mProfile;
    }

    function powerZone(watts as Numeric) as Number {
        var zone = 1;
        for (var i = 0; i < Config.PWR_PCT.size(); i++) {
            if (watts >= mFtp * Config.PWR_PCT[i]) {
                zone = i + 2;
            }
        }
        return zone;
    }
}
