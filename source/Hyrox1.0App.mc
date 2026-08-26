using Toybox.Application;
using Toybox.ActivityRecording;
using Toybox.System;
using Toybox.WatchUi;

class Hyrox1_0App extends Application.AppBase {

    // Garmin FIT recording session
    var session = null;

    // HYROX state
    var isRunningSegment = true;
    var stationNumber = 1;
    var activityStarted = false;

    // Timing
    var activityStartTime = 0;
    var segmentStartTime = 0;

    // HYROX has 8 stations
    const TOTAL_STATIONS = 8;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new Hyrox1_0View();
        var delegate = new Hyrox1_0Delegate();

        return [view, delegate];
    }

    // ---------------------------------------------------------
    // Recording session
    // ---------------------------------------------------------

    function getSession() {
        return session;
    }

    function startActivity() {

        if (activityStarted) {
            return;
        }

        try {

            session = ActivityRecording.createSession({
                :sport => ActivityRecording.SPORT_RUNNING,
                :name => "HYROX"
            });

            session.start();

            activityStarted = true;

            isRunningSegment = true;
            stationNumber = 1;

            var now = System.getTimer();

            activityStartTime = now;
            segmentStartTime = now;

            System.println("HYROX activity started");

            WatchUi.requestUpdate();

        } catch (e) {

            System.println("ERROR starting HYROX: " + e);

            session = null;
            activityStarted = false;
        }
    }

    function stopActivity() {

        if (!activityStarted || session == null) {
            return;
        }

        try {

            if (session.isRecording()) {
                session.stop();
            }

            session.save();

            System.println("HYROX activity saved");

        } catch (e) {

            System.println("ERROR saving HYROX: " + e);
        }

        session = null;
        activityStarted = false;

        WatchUi.requestUpdate();
    }

    // ---------------------------------------------------------
    // HYROX state
    // ---------------------------------------------------------

    function getIsRunningSegment() {
        return isRunningSegment;
    }

    function getStationNumber() {
        return stationNumber;
    }

    function getTotalStations() {
        return TOTAL_STATIONS;
    }

    function isActivityActive() {
        return activityStarted && session != null;
    }

    // ---------------------------------------------------------
    // Timing
    // ---------------------------------------------------------

    function getSegmentElapsedSeconds() {

        if (!activityStarted) {
            return 0;
        }

        var elapsed = System.getTimer() - segmentStartTime;

        return (elapsed / 1000).toNumber();
    }

    function getActivityElapsedSeconds() {

        if (!activityStarted) {
            return 0;
        }

        var elapsed = System.getTimer() - activityStartTime;

        return (elapsed / 1000).toNumber();
    }

    // ---------------------------------------------------------
    // RUN <-> STATION transition
    // ---------------------------------------------------------

    function toggleSegment() {

    System.println("HYROX toggleSegment entered");

    if (!isActivityActive()) {
        System.println("HYROX transition ignored: activity inactive");
        return;
    }

    // Mark the end of the current segment.
    System.println("HYROX adding lap");
    session.addLap();
    System.println("HYROX lap added");

    if (isRunningSegment) {

        // -----------------------------------------
        // RUN -> STATION
        // -----------------------------------------

        isRunningSegment = false;

        System.println("HYROX state changed to STATION");

        segmentStartTime = System.getTimer();

        System.println(
            "Starting Station " +
            stationNumber
        );

    } else {

        // -----------------------------------------
        // STATION -> NEXT RUN
        // -----------------------------------------

        if (stationNumber < TOTAL_STATIONS) {

            stationNumber += 1;

            isRunningSegment = true;

            System.println("HYROX state changed to RUN");

            segmentStartTime = System.getTimer();

            System.println(
                "Starting Run " +
                stationNumber
            );

        } else {

            // -----------------------------------------
            // STATION 8 -> FINISH
            // -----------------------------------------

            System.println(
                "HYROX complete"
            );

            stopActivity();

            return;
        }
    }

    WatchUi.requestUpdate();
}
}