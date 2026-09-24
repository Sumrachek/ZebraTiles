import Toybox.Lang;

//! Accumulators for one lap. Connect IQ gives data fields no lap API beyond the
//! onTimerLap() callback, so every per-lap number is tallied here.
class Lap {

    public var startMs as Number = 0;
    public var startDistance as Numeric = 0.0;
    public var startAscent as Number = 0;
    public var startDescent as Number = 0;

    public var timeMs as Number = 0;
    public var distance as Numeric = 0.0;
    public var ascent as Number = 0;
    public var descent as Number = 0;

    hidden var mPowerSum as Number = 0;
    hidden var mPowerCount as Number = 0;
    hidden var mHrSum as Number = 0;
    hidden var mHrCount as Number = 0;
    hidden var mCadenceSum as Number = 0;
    hidden var mCadenceCount as Number = 0;

    function initialize() {
    }

    //! Fixes the lap's origin. Everything else is measured relative to it.
    function begin(timerMs as Number, distanceM as Numeric?, ascentM as Number?, descentM as Number?) as Void {
        startMs = timerMs;
        startDistance = (distanceM != null) ? distanceM : 0.0;
        startAscent = (ascentM != null) ? ascentM : 0;
        startDescent = (descentM != null) ? descentM : 0;
    }

    function addSample(power as Numeric?, hr as Numeric?, cadence as Numeric?) as Void {
        if (power != null) {
            mPowerSum += power.toNumber();
            mPowerCount++;
        }
        if (hr != null) {
            mHrSum += hr.toNumber();
            mHrCount++;
        }
        if (cadence != null) {
            mCadenceSum += cadence.toNumber();
            mCadenceCount++;
        }
    }

    function avgPower() as Numeric? {
        return (mPowerCount > 0) ? mPowerSum / mPowerCount : null;
    }

    function avgHr() as Numeric? {
        return (mHrCount > 0) ? mHrSum / mHrCount : null;
    }

    function avgCadence() as Numeric? {
        return (mCadenceCount > 0) ? mCadenceSum / mCadenceCount : null;
    }

    //! Lap distance over lap time; the timer already excludes stopped time.
    function avgSpeed() as Numeric? {
        if (timeMs <= 0) {
            return null;
        }
        return distance / (timeMs / 1000.0);
    }
}
