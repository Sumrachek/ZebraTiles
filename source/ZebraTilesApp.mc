import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

(:background)
class ZebraTilesApp extends Application.AppBase {

    hidden var mView as ZebraTilesView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        scheduleTemperatureReads();
    }

    function onStop(state as Dictionary?) as Void {
    }

    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new ZebraTilesView();
        mView = view;
        return [view];
    }

    //! Runs the temperature service. See TemperatureService for why the reading
    //! has to be taken out of process.
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new TemperatureService()];
    }


    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() as Void {
        var view = mView;
        if (view != null) {
            view.reload();
        }
        WatchUi.requestUpdate();
    }

    //! Five minutes is the platform's floor for temporal events, not a choice.
    hidden function scheduleTemperatureReads() as Void {
        if (!(Toybox has :Background)) {
            return;
        }
        try {
            Background.registerForTemporalEvent(new Time.Duration(Temperature.POLL_SECONDS));
        } catch (e) {
            // Registration can be refused - the field then simply shows no temperature.
        }
    }
}
