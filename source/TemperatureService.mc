import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;

//! The two constants the background service and the field have to agree on.
//!
//! Kept here, in their own module, rather than in Config: only code marked
//! (:background) is compiled into the background image, and Config cannot be
//! marked because it references Graphics, which background processes do not
//! have. This module references nothing, so it is safe in both.
(:background)
module Temperature {
    const KEY = "temperature";
    const POLL_SECONDS = 300;  //!< The platform's floor for temporal events.
}

//! Fetches the Edge's own thermometer, which the data field cannot reach itself.
//!
//! Sensor.getInfo() is documented to crash when called from a data field, and
//! there is no way round it in the foreground: Activity.Info carries no
//! temperature, and SensorHistory.getTemperatureHistory() lists only watches
//! among its supported devices - no Edge at all. A background service runs in a
//! different context where the Sensor call is allowed, so the reading is taken
//! there and left in Storage for the field to pick up.
//!
//! Temporal events fire at most every five minutes, so the value is that stale.
//! For ambient air that is fine; it is not a number that moves quickly.
(:background)
class TemperatureService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var value = null;
        var info = Sensor.getInfo();
        if (info != null && info has :temperature) {
            value = info.temperature;
        }
        if (value != null) {
            Storage.setValue(Temperature.KEY, value);
        }
        Background.exit(value);
    }
}
