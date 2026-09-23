import Toybox.Application;
import Toybox.Lang;
import Toybox.UserProfile;

//! Zone lookup. Heart rate zones come straight from the device profile.
//! Power zones are derived from FTP, because the Edge 530 (CIQ 3.3) has no
//! API for the user's power zones - UserProfile.getPowerZones() needs 5.2.2.
module Zones {

    var mHrZones as Array<Number>? = null;
    var mHrChecked as Boolean = false;
    var mFtp as Number = Config.DEFAULT_FTP;

    function reload() as Void {
        mHrZones = null;
        mHrChecked = false;

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
    }

    //! 1-based zone number, or null when it cannot be told.
    function of(kind as Number, value as Numeric?) as Number? {
        if (value == null || kind == Fields.Z_NONE) {
            return null;
        }
        if (kind == Fields.Z_HR) {
            return hrZone(value);
        }
        return powerZone(value);
    }

    function colorFor(kind as Number, zone as Number?) as Number? {
        if (zone == null) {
            return null;
        }
        var palette = (kind == Fields.Z_HR) ? Config.HR_COLORS : Config.PWR_COLORS;
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
