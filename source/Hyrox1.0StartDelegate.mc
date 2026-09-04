using Toybox.WatchUi;
using Toybox.System;

class Hyrox1_0StartDelegate extends WatchUi.BehaviorDelegate {

    var app;

    function initialize() {
        BehaviorDelegate.initialize();
        app = Application.getApp();
    }

    function onNextPage() {
        if (!app.isWaitingForGps()) {
            app.moveStartSelection(1);
        }
        return true;
    }

    function onPreviousPage() {
        if (!app.isWaitingForGps()) {
            app.moveStartSelection(-1);
        }
        return true;
    }

    function onSelect() {
        if (!app.isWaitingForGps()) {
            if (app.getStartSelection() == 2) {
                app.showHistory();
            } else {
                app.startActivity();
            }
        }
        return true;
    }

    function onBack() {
        System.exit();
    }
}
