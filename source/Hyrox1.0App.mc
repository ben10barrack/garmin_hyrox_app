using Toybox.Application;
using Toybox.ActivityRecording;
using Toybox.Position;
using Toybox.System;
using Toybox.WatchUi;

class Hyrox1_0App extends Application.AppBase {

    // Garmin FIT recording session
    var session = null;

    // HYROX state
    var isRunningSegment = true;
    var stationNumber = 1;
    var activityStarted = false;
    var indoorMode = false;
    var waitingForGps = false;
    var endMenuOpen = false;
    var endMenuSelection = 0;

    // Timing
    var activityStartTime = 0;
    var segmentStartTime = 0;

    // HYROX has 8 stations
    const TOTAL_STATIONS = 8;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new Hyrox1_0StartView();
        var delegate = new Hyrox1_0StartDelegate();

        return [view, delegate];
    }

    // ---------------------------------------------------------
    // Recording session
    // ---------------------------------------------------------

    function getSession() {
        return session;
    }

    function isIndoorMode() {
        return indoorMode;
    }

    function isWaitingForGps() {
        return waitingForGps;
    }

    function isEndMenuOpen() {
        return endMenuOpen;
    }

    function getEndMenuSelection() {
        return endMenuSelection;
    }

    function requestEndMenu() {
        if (!activityStarted || session == null) {
            return;
        }

        endMenuOpen = true;
        endMenuSelection = 0;
        WatchUi.pushView(
            new Hyrox1_0EndView(),
            new Hyrox1_0EndDelegate(),
            WatchUi.SLIDE_UP
        );
        WatchUi.requestUpdate();
    }

    function moveEndMenuSelection(direction) {
        if (!endMenuOpen) {
            return;
        }

        endMenuSelection += direction;

        if (endMenuSelection < 0) {
            endMenuSelection = 2;
        } else if (endMenuSelection > 2) {
            endMenuSelection = 0;
        }

        WatchUi.requestUpdate();
    }

    function cancelEndMenu() {
        if (!endMenuOpen) {
            return;
        }

        endMenuOpen = false;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function confirmEndMenu() {
        if (!endMenuOpen) {
            return;
        }

        endMenuOpen = false;

        if (endMenuSelection == 0) {
            stopActivity(true);
        } else if (endMenuSelection == 1) {
            stopActivity(false);
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (endMenuSelection < 2) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        WatchUi.requestUpdate();
    }

    function toggleIndoorMode() {
        if (activityStarted || waitingForGps) {
            return;
        }

        indoorMode = !indoorMode;
        WatchUi.requestUpdate();
    }

    function showWorkoutView() {
        WatchUi.pushView(
            new Hyrox1_0View(),
            new Hyrox1_0Delegate(),
            WatchUi.SLIDE_UP
        );
    }

    function startActivity() {

        if (activityStarted || waitingForGps) {
            return;
        }

        if (!indoorMode) {
            waitingForGps = true;
            Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
            System.println("HYROX waiting for GPS");
            WatchUi.requestUpdate();
            return;
        }

        beginActivity();
    }

    function onPosition(info as Position.Info) as Void {
        if (!waitingForGps || info == null || info.position == null) {
            return;
        }

        waitingForGps = false;
        System.println("HYROX GPS ready");
        beginActivity();
    }

    function beginActivity() {

        try {

            var sessionOptions = {
                :sport => ActivityRecording.SPORT_RUNNING,
                :name => "HYROX"
            };

            if (indoorMode) {
                sessionOptions[:subSport] = ActivityRecording.SUB_SPORT_TREADMILL;
            }

            session = ActivityRecording.createSession(sessionOptions);

            session.start();

            activityStarted = true;

            isRunningSegment = true;
            stationNumber = 1;

            var now = System.getTimer();

            activityStartTime = now;
            segmentStartTime = now;

            System.println("HYROX activity started");

            showWorkoutView();
            WatchUi.requestUpdate();

        } catch (e) {

            System.println("ERROR starting HYROX: " + e);

            session = null;
            activityStarted = false;
            waitingForGps = false;
        }
    }

    function stopActivity(saveActivity) {

        if (waitingForGps) {
            waitingForGps = false;
            WatchUi.requestUpdate();
            return;
        }

        if (!activityStarted || session == null) {
            return;
        }

        try {

            if (session.isRecording()) {
                session.stop();
            }

            if (saveActivity) {
                session.save();
                System.println("HYROX activity saved");
            } else {
                System.println("HYROX activity discarded");
            }

        } catch (e) {

            System.println("ERROR saving HYROX: " + e);
        }

        session = null;
        activityStarted = false;
        endMenuOpen = false;

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

            requestEndMenu();

            return;
        }
    }

    WatchUi.requestUpdate();
}
}