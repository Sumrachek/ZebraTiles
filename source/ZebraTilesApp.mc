import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ZebraTilesApp extends Application.AppBase {

    hidden var mView as ZebraTilesView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new ZebraTilesView();
        mView = view;
        return [view];
    }

    function onSettingsChanged() as Void {
        var view = mView;
        if (view != null) {
            view.reload();
        }
        WatchUi.requestUpdate();
    }
}
