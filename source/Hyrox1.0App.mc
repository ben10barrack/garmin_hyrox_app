using Toybox.Application;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Lang;
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
    var summaryPage = 0;

    // Timing
    var activityStartTime = 0;
    var segmentStartTime = 0;
    var segmentDistanceStart = 0.0;
    var stationHeartRateTotal = 0;
    var stationHeartRateSamples = 0;
    var runHeartRateTotal = 0;
    var runHeartRateSamples = 0;
    var currentSummaryRecorded = false;
    var completedWorkoutSeconds = 0;
    var completedWorkoutDistance = 0.0;
    var completedWorkoutCalories = 0;

    // Analysis data shown after the workout. FIT laps are also created below.
    var runRecords = [];
    var stationRecords = [];

    // HYROX has 8 stations
    const TOTAL_STATIONS = 8;

    // Edit these names to customize the station order for your routine.
    var stationNames as Lang.Array<Lang.String> = [
        "100m BEAR CRAWL",
        "100m CARRY 40",
        "PULL UPS 50",
        "BURPEE",
        "750m ROW",
        "150m FARMERS CARRY",
        "75m LUNGES",
        "75 WALL BALLS"
    ];

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

    function getRunRecords() as Lang.Array<Lang.Dictionary> {
        return runRecords;
    }

    function getStationRecords() as Lang.Array<Lang.Dictionary> {
        return stationRecords;
    }

    function getStationName(number) {
        var index = number - 1;
        if (index >= 0 && index < stationNames.size() && stationNames[index] != null) {
            return stationNames[index];
        }

        return "STN " + number.format("%d");
    }

    function recordActivitySample(info) {
        if (!isActivityActive() || info == null) {
            return;
        }

        if (info.currentHeartRate != null) {
            if (isRunningSegment) {
                runHeartRateTotal += info.currentHeartRate;
                runHeartRateSamples += 1;
            } else {
                stationHeartRateTotal += info.currentHeartRate;
                stationHeartRateSamples += 1;
            }
        }

        if (info.calories != null) {
            completedWorkoutCalories = info.calories;
        }
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

        var selection = endMenuSelection;
        endMenuOpen = false;

        if (selection == 0) {
            stopActivity(true);
            summaryPage = 0;
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.pushView(
                new Hyrox1_0SummaryView(),
                new Hyrox1_0SummaryDelegate(),
                WatchUi.SLIDE_UP
            );
            WatchUi.requestUpdate();
            return;
        }

        if (selection == 1) {
            stopActivity(false);
            WatchUi.switchToView(
                new Hyrox1_0StartView(),
                new Hyrox1_0StartDelegate(),
                WatchUi.SLIDE_DOWN
            );
            WatchUi.requestUpdate();
            return;
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (selection < 2) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        WatchUi.requestUpdate();
    }

    function getSummaryPage() {
        return summaryPage;
    }

    function moveSummaryPage(direction) {
        var segmentCount = runRecords.size() + stationRecords.size();
        var pageCount = 3 + ((segmentCount + 1) / 2);

        summaryPage += direction;
        if (summaryPage < 0) {
            summaryPage = pageCount - 1;
        } else if (summaryPage >= pageCount) {
            summaryPage = 0;
        }
        WatchUi.requestUpdate();
    }

    function closeSummary() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
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
                :sport => Activity.SPORT_GENERIC,
                :subSport => Activity.SUB_SPORT_GENERIC,
                :name => "HYROX"
            };

            session = ActivityRecording.createSession(sessionOptions);

            session.start();

            activityStarted = true;

            isRunningSegment = true;
            stationNumber = 1;
            runRecords = [];
            stationRecords = [];

            var now = System.getTimer();

            activityStartTime = now;
            segmentStartTime = now;
            segmentDistanceStart = 0.0;
            stationHeartRateTotal = 0;
            stationHeartRateSamples = 0;
            runHeartRateTotal = 0;
            runHeartRateSamples = 0;
            currentSummaryRecorded = false;
            completedWorkoutSeconds = 0;
            completedWorkoutDistance = 0.0;
            completedWorkoutCalories = 0;

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

            recordActivitySample(Activity.getActivityInfo());

            if (!currentSummaryRecorded) {
                recordSegmentSummary();
            }

            completedWorkoutSeconds = getActivityElapsedSeconds();
            completedWorkoutDistance = getTotalRunDistance();

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

    // Capture analysis values before closing the corresponding FIT lap.
    recordSegmentSummary();

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
        stationHeartRateTotal = 0;
        stationHeartRateSamples = 0;
        runHeartRateTotal = 0;
        runHeartRateSamples = 0;
        currentSummaryRecorded = false;

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
            segmentDistanceStart = getCurrentDistanceMeters();
            stationHeartRateTotal = 0;
            stationHeartRateSamples = 0;
            runHeartRateTotal = 0;
            runHeartRateSamples = 0;
            currentSummaryRecorded = false;

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

    function getCurrentDistanceMeters() {
        var info = Activity.getActivityInfo();

        if (info != null && info.elapsedDistance != null) {
            return info.elapsedDistance;
        }

        return segmentDistanceStart;
    }

    function recordSegmentSummary() {
        if (currentSummaryRecorded) {
            return;
        }

        var elapsed = ((System.getTimer() - segmentStartTime) / 1000).toNumber();

        if (isRunningSegment) {
            var distance = getCurrentDistanceMeters() - segmentDistanceStart;
            if (distance < 0) {
                distance = 0;
            }

            runRecords.add({
                :number => stationNumber,
                :distance => distance,
                :time => elapsed,
                :speed => (elapsed > 0) ? distance / elapsed : 0,
                :heartRate => (runHeartRateSamples > 0)
                    ? runHeartRateTotal / runHeartRateSamples
                    : 0
            });
            completedWorkoutDistance += distance;
        } else {
            var averageHeartRate = (stationHeartRateSamples > 0)
                ? stationHeartRateTotal / stationHeartRateSamples
                : 0;

            stationRecords.add({
                :number => stationNumber,
                :heartRate => averageHeartRate,
                :time => elapsed
            });
        }

        currentSummaryRecorded = true;
    }

    function getCompletedWorkoutSeconds() {
        return completedWorkoutSeconds;
    }

    function getCompletedWorkoutDistance() {
        return completedWorkoutDistance;
    }

    function getCompletedWorkoutCalories() {
        return completedWorkoutCalories;
    }

    function getTotalRunDistance() {
        return completedWorkoutDistance;
    }
}