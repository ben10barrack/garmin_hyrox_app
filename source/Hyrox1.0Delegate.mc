using Toybox.WatchUi;
using Toybox.System;

class Hyrox1_0Delegate extends WatchUi.BehaviorDelegate {

    var app;

    function initialize() {
        BehaviorDelegate.initialize();
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

        return BehaviorDelegate.onKey(keyEvent);
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

        if (app.isActivityActive()) {

            return true;
        }

        return false;
    }


    // ---------------------------------------------------------
    // UP
    // ---------------------------------------------------------

    function onPreviousPage() {

        if (app.isActivityActive()) {

            return true;
        }

        return false;
    }


    // ---------------------------------------------------------
    // SELECT
    // ---------------------------------------------------------

    function onSelect() {

        if (!app.isActivityActive()) {

            System.println(
                "START -> HYROX"
            );

            app.startActivity();

        } else {

            System.println(
                "START/STOP -> Finish HYROX"
            );

            app.stopActivity();
        }

        return true;
    }


    // ---------------------------------------------------------
    // MENU
    // ---------------------------------------------------------

    function onMenu() {
        return false;
    }
}
