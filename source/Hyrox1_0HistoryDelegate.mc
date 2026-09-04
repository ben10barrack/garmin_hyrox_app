using Toybox.WatchUi;

class Hyrox1_0HistoryDelegate extends WatchUi.InputDelegate {

    var app;

    function initialize() {
        InputDelegate.initialize();
        app = Application.getApp();
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            if (app.getHistoryPage() < 0) {
                app.selectHistoryActivity(-1);
            } else {
                app.moveHistoryPage(-1);
            }
        } else if (key == WatchUi.KEY_DOWN) {
            if (app.getHistoryPage() < 0) {
                app.selectHistoryActivity(1);
            } else {
                app.moveHistoryPage(1);
            }
        } else if (key == WatchUi.KEY_ENTER) {
            app.openHistoryActivity();
        } else if (key == WatchUi.KEY_ESC) {
            app.backHistory();
        }

        return true;
    }

    function onNextPage() {
        if (app.getHistoryPage() < 0) {
            app.selectHistoryActivity(1);
        } else {
            app.moveHistoryPage(1);
        }
        return true;
    }

    function onPreviousPage() {
        if (app.getHistoryPage() < 0) {
            app.selectHistoryActivity(-1);
        } else {
            app.moveHistoryPage(-1);
        }
        return true;
    }

    function onBack() {
        app.backHistory();
        return true;
    }

    function onSelect() {
        app.openHistoryActivity();
        return true;
    }
}
