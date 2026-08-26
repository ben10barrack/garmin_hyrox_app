using Toybox.WatchUi;

class Hyrox1_0EndDelegate extends WatchUi.InputDelegate {

    var app;

    function initialize() {
        InputDelegate.initialize();
        app = Application.getApp();
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            app.confirmEndMenu();
        } else if (key == WatchUi.KEY_ESC) {
            app.cancelEndMenu();
        } else if (key == WatchUi.KEY_DOWN) {
            app.moveEndMenuSelection(1);
        } else if (key == WatchUi.KEY_UP) {
            app.moveEndMenuSelection(-1);
        }

        return true;
    }

    function onSelect() {
        app.confirmEndMenu();
        return true;
    }

    function onTap(clickEvent) {
        return true;
    }

    function onSwipe(swipeEvent) {
        return true;
    }

    function onHold(clickEvent) {
        return true;
    }

    function onNextPage() {
        app.moveEndMenuSelection(1);
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() {
        app.moveEndMenuSelection(-1);
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() {
        app.cancelEndMenu();
        return true;
    }
}
