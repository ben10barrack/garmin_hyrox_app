using Toybox.WatchUi;

class Hyrox1_0StartDelegate extends WatchUi.BehaviorDelegate {

    var app;

    function initialize() {
        BehaviorDelegate.initialize();
        app = Application.getApp();
    }

    function onNextPage() {
        if (!app.isWaitingForGps()) {
            app.toggleIndoorMode();
        }
        return true;
    }

    function onPreviousPage() {
        if (!app.isWaitingForGps()) {
            app.toggleIndoorMode();
        }
        return true;
    }

    function onSelect() {
        if (!app.isWaitingForGps()) {
            app.startActivity();
        }
        return true;
    }

    function onBack() {
        return false;
    }
}
