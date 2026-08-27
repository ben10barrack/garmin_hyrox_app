using Toybox.WatchUi;

class Hyrox1_0SummaryDelegate extends WatchUi.InputDelegate {

    var app;

    function initialize() {
        InputDelegate.initialize();
        app = Application.getApp();
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            app.moveSummaryPage(-1);
        } else if (key == WatchUi.KEY_DOWN) {
            app.moveSummaryPage(1);
        } else if (key == WatchUi.KEY_ESC) {
            app.closeSummary();
        }

        return true;
    }

    function onNextPage() {
        app.moveSummaryPage(1);
        return true;
    }

    function onPreviousPage() {
        app.moveSummaryPage(-1);
        return true;
    }

    function onBack() {
        app.closeSummary();
        return true;
    }
}
