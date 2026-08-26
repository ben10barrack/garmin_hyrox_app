using Toybox.WatchUi;
using Toybox.System;

class Hyrox1_0Delegate extends WatchUi.InputDelegate {

    var app;

    function initialize() {
        InputDelegate.initialize();
        app = Application.getApp();
    }

    // ---------------------------------------------------------
    // RAW KEY HANDLING
    // ---------------------------------------------------------
    //
    // During active ActivityRecording, the physical LAP button
    // is a dedicated hardware lap trigger and is not always
    // delivered as onBack(). Catch it here explicitly so the
    // RUN <-> STATION transition is reliable while recording.
    //

    function onKey(keyEvent) {

        var key = keyEvent.getKey();

        System.println("HYROX onKey received: " + key);

        if (app.isEndMenuOpen()) {
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

        if (key == WatchUi.KEY_LAP || key == WatchUi.KEY_ESC) {

            System.println("HYROX recognized LAP/ESC key");

            if (app.isActivityActive()) {

                System.println(
                    "HYROX LAP key -> transition"
                );

                app.toggleSegment();

                System.println("HYROX onKey transition requested");

                // Swallow it so the OS doesn't also add its own
                // lap on top of the one toggleSegment() adds.
                return true;
            }
        }

        if (key == WatchUi.KEY_ENTER) {
            if (app.isWaitingForGps()) {
                app.stopActivity(true);
            } else if (!app.isActivityActive()) {
                app.startActivity();
            } else {
                app.requestEndMenu();
            }
        }

        return true;
    }


    // ---------------------------------------------------------
    // BACK / LAP BUTTON
    // ---------------------------------------------------------
    //
    // On the FR165 this is the bottom-right button.
    //
    // While HYROX is active:
    //
    // RUN -> STATION
    // STATION -> RUN
    //
    // It must NOT pop the view.
    //
    // Kept as a fallback in case a given device/firmware routes
    // the button here instead of through onKey() (e.g. when not
    // recording, or on devices without a dedicated LAP key).
    //

    function onBack() {

        System.println("HYROX onBack received");

        if (app.isEndMenuOpen()) {
            app.cancelEndMenu();
            return true;
        }

        if (app.isActivityActive()) {

            System.println(
                "HYROX BACK/LAP -> transition"
            );

            app.toggleSegment();

            System.println("HYROX onBack transition requested");

            return true;
        }

        // If we aren't recording, allow normal navigation.
        return false;
    }


    // ---------------------------------------------------------
    // DOWN
    // ---------------------------------------------------------
    //
    // DOWN is deliberately NOT a transition button.
    //
    // Don't let it restart the activity.
    //

    function onNextPage() {

        if (app.isEndMenuOpen()) {
            app.moveEndMenuSelection(1);
            return true;
        }

        if (app.isActivityActive()) {

            return true;
        }

        app.toggleIndoorMode();

        return true;
    }


    // ---------------------------------------------------------
    // UP
    // ---------------------------------------------------------

    function onPreviousPage() {

        if (app.isEndMenuOpen()) {
            app.moveEndMenuSelection(-1);
            return true;
        }

        if (app.isActivityActive()) {

            return true;
        }

        app.toggleIndoorMode();

        return true;
    }


    // ---------------------------------------------------------
    // SELECT
    // ---------------------------------------------------------
}
