using Toybox.Application;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Application.Storage;
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
    var gpsWaitStartTime = 0;
    var gpsWaitTimeoutMs = 30000;
    var startSelection = 0;
    var endMenuOpen = false;
    var endMenuSelection = 0;
    var summaryPage = 0;
    var historyPage = 0;
    var historyActivity = 0;
    var historyPreview = false;

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
    var runRecords as Lang.Array<Lang.Dictionary> = [];
    var stationRecords as Lang.Array<Lang.Dictionary> = [];

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

    function getStartSelection() {
        return startSelection;
    }

    function moveStartSelection(direction) {
        startSelection += direction;

        if (startSelection < 0) {
            startSelection = 2;
        } else if (startSelection > 2) {
            startSelection = 0;
        }

        if (startSelection < 2) {
            indoorMode = startSelection == 1;
        }

        WatchUi.requestUpdate();
    }

    function showHistory() {
        historyPage = -1;
        historyActivity = 0;
        WatchUi.pushView(
            new Hyrox1_0HistoryView(),
            new Hyrox1_0HistoryDelegate(),
            WatchUi.SLIDE_UP
        );
    }

    function getHistoryPage() {
        return historyPage;
    }

    function getHistoryActivity() {
        return historyActivity;
    }

    function getHistoryCount() {
        var count = Storage.getValue("historyCount");
        if (count != null) {
            return count;
        }

        return Storage.getValue("summaryRunCount") != null ? 1 : 0;
    }

    function selectHistoryActivity(direction) {
        var count = getHistoryCount();
        if (count == 0) {
            return;
        }

        historyActivity += direction;
        if (historyActivity < 0) {
            historyActivity = count - 1;
        } else if (historyActivity >= count) {
            historyActivity = 0;
        }

        WatchUi.requestUpdate();
    }

    function openHistoryActivity() {
        if (getHistoryCount() > 0) {
            loadHistoryActivity();
            historyPreview = true;
            summaryPage = 0;
            WatchUi.switchToView(
                new Hyrox1_0SummaryView(),
                new Hyrox1_0SummaryDelegate(),
                WatchUi.SLIDE_UP
            );
        }
    }

    function loadHistoryActivity() {
        runRecords = [];
        stationRecords = [];
        completedWorkoutSeconds = getHistoryNumber("summaryTime");
        completedWorkoutDistance = getHistoryNumber("summaryDistance");
        completedWorkoutCalories = getHistoryNumber("summaryCalories");

        var runCount = getHistoryNumber("summaryRunCount");
        for (var i = 0; i < runCount; i++) {
            runRecords.add(getSavedRun(i, historyActivity));
        }

        var stationCount = getHistoryNumber("summaryStationCount");
        for (var j = 0; j < stationCount; j++) {
            stationRecords.add(getSavedStation(j, historyActivity));
        }
    }

    function moveHistoryPage(direction) {
        if (historyPage < 0 || getHistoryCount() == 0) {
            return;
        }

        var runCount = getHistoryValue("summaryRunCount");
        var stationCount = getHistoryValue("summaryStationCount");
        var pageCount = 1 + runCount + stationCount;

        historyPage += direction;
        if (historyPage < 0) {
            historyPage = pageCount - 1;
        } else if (historyPage >= pageCount) {
            historyPage = 0;
        }

        WatchUi.requestUpdate();
    }

    function closeHistory() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function backHistory() {
        if (historyPage >= 0) {
            historyPage = -1;
            WatchUi.requestUpdate();
        } else {
            closeHistory();
        }
    }

    function hasSavedSummary() {
        return getHistoryCount() > 0;
    }

    function getHistoryValue(key as Lang.String) {
        var count = Storage.getValue("historyCount");
        if (count == null) {
            return Storage.getValue(key);
        }

        return Storage.getValue("history" + historyActivity + key);
    }

    function getHistoryValueFor(activityIndex, key as Lang.String) {
        var count = Storage.getValue("historyCount");
        if (count == null) {
            return Storage.getValue(key);
        }

        return Storage.getValue("history" + activityIndex + key);
    }

    function getHistoryNumber(key as Lang.String) as Lang.Number {
        var value = getHistoryValue(key);
        return value == null ? 0 : value.toNumber();
    }

    function getHistoryNumberFor(activityIndex, key as Lang.String) as Lang.Number {
        var value = getHistoryValueFor(activityIndex, key);
        return value == null ? 0 : value.toNumber();
    }

    function getSavedRun(index, activityIndex) as Lang.Dictionary {
        var prefix = "summaryRun" + index.format("%d");
        if (Storage.getValue("historyCount") != null) {
            prefix = "history" + activityIndex + "Run" + index.format("%d");
        }

        return {
            :number => Storage.getValue(prefix + "Number"),
            :distance => Storage.getValue(prefix + "Distance"),
            :time => Storage.getValue(prefix + "Time"),
            :speed => Storage.getValue(prefix + "Speed"),
            :heartRate => Storage.getValue(prefix + "HeartRate")
        };
    }

    function getSavedStation(index, activityIndex) as Lang.Dictionary {
        var prefix = "summaryStation" + index.format("%d");
        if (Storage.getValue("historyCount") != null) {
            prefix = "history" + activityIndex + "Station" + index.format("%d");
        }
        return {
            :number => Storage.getValue(prefix + "Number"),
            :time => Storage.getValue(prefix + "Time"),
            :heartRate => Storage.getValue(prefix + "HeartRate")
        };
    }

    function saveSummary() {
        var historyCount = Storage.getValue("historyCount");
        if (historyCount == null) {
            historyCount = 0;
        }

        var maxActivities = historyCount < 5 ? historyCount : 4;
        for (var activity = maxActivities; activity > 0; activity--) {
            copyHistoryActivity(activity - 1, activity);
        }

        historyCount += 1;
        if (historyCount > 5) {
            historyCount = 5;
        }
        Storage.setValue("historyCount", historyCount);
        saveHistoryActivity(0);

        Storage.setValue("summaryTime", completedWorkoutSeconds);
        Storage.setValue("summaryDistance", completedWorkoutDistance);
        Storage.setValue("summaryCalories", completedWorkoutCalories);
        Storage.setValue("summaryRunCount", runRecords.size());
        Storage.setValue("summaryStationCount", stationRecords.size());

        for (var i = 0; i < runRecords.size(); i++) {
            var run = runRecords[i];
            var prefix = "summaryRun" + i.format("%d");
            Storage.setValue(prefix + "Number", run[:number]);
            Storage.setValue(prefix + "Distance", run[:distance]);
            Storage.setValue(prefix + "Time", run[:time]);
            Storage.setValue(prefix + "Speed", run[:speed]);
            Storage.setValue(prefix + "HeartRate", run[:heartRate]);
        }

        for (var j = 0; j < stationRecords.size(); j++) {
            var station = stationRecords[j];
            var prefix = "summaryStation" + j.format("%d");
            Storage.setValue(prefix + "Number", station[:number]);
            Storage.setValue(prefix + "Time", station[:time]);
            Storage.setValue(prefix + "HeartRate", station[:heartRate]);
        }
    }

    function copyHistoryActivity(fromIndex, toIndex) {
        var from = "history" + fromIndex;
        var to = "history" + toIndex;
        Storage.setValue(to + "summaryTime", Storage.getValue(from + "summaryTime"));
        Storage.setValue(to + "summaryDistance", Storage.getValue(from + "summaryDistance"));
        Storage.setValue(to + "summaryCalories", Storage.getValue(from + "summaryCalories"));
        Storage.setValue(to + "summaryRunCount", Storage.getValue(from + "summaryRunCount"));
        Storage.setValue(to + "summaryStationCount", Storage.getValue(from + "summaryStationCount"));

        var runCount = Storage.getValue(from + "summaryRunCount");
        for (var i = 0; i < runCount; i++) {
            copyHistorySegment(from + "Run" + i.format("%d"), to + "Run" + i.format("%d"), true);
        }

        var stationCount = Storage.getValue(from + "summaryStationCount");
        for (var j = 0; j < stationCount; j++) {
            copyHistorySegment(from + "Station" + j.format("%d"), to + "Station" + j.format("%d"), false);
        }
    }

    function saveHistoryActivity(index) {
        var prefix = "history" + index;
        Storage.setValue(prefix + "summaryTime", completedWorkoutSeconds);
        Storage.setValue(prefix + "summaryDistance", completedWorkoutDistance);
        Storage.setValue(prefix + "summaryCalories", completedWorkoutCalories);
        Storage.setValue(prefix + "summaryRunCount", runRecords.size());
        Storage.setValue(prefix + "summaryStationCount", stationRecords.size());

        for (var i = 0; i < runRecords.size(); i++) {
            saveHistorySegment(prefix + "Run" + i.format("%d"), runRecords[i], true);
        }
        for (var j = 0; j < stationRecords.size(); j++) {
            saveHistorySegment(prefix + "Station" + j.format("%d"), stationRecords[j], false);
        }
    }

    function copyHistorySegment(from, to, isRun) {
        Storage.setValue(to + "Number", Storage.getValue(from + "Number"));
        Storage.setValue(to + "Time", Storage.getValue(from + "Time"));
        Storage.setValue(to + "HeartRate", Storage.getValue(from + "HeartRate"));
        if (isRun) {
            Storage.setValue(to + "Distance", Storage.getValue(from + "Distance"));
            Storage.setValue(to + "Speed", Storage.getValue(from + "Speed"));
        }
    }

    function saveHistorySegment(prefix, segment as Lang.Dictionary, isRun) {
        Storage.setValue(prefix + "Number", segment[:number]);
        Storage.setValue(prefix + "Time", segment[:time]);
        Storage.setValue(prefix + "HeartRate", segment[:heartRate]);
        if (isRun) {
            Storage.setValue(prefix + "Distance", segment[:distance]);
            Storage.setValue(prefix + "Speed", segment[:speed]);
        }
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
        historyPreview = false;
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
            gpsWaitStartTime = System.getTimer();
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
            System.println("HYROX waiting for GPS");
            WatchUi.requestUpdate();
            return;
        }

        beginActivity();
    }

    function onPosition(info as Position.Info) as Void {
        if (!waitingForGps) {
            return;
        }

        if (info.position != null) {
            waitingForGps = false;
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
            System.println("HYROX GPS ready");
            beginActivity();
            return;
        }

        if ((System.getTimer() - gpsWaitStartTime) > gpsWaitTimeoutMs) {
            waitingForGps = false;
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
            System.println("HYROX GPS timeout - continuing without fix");
            beginActivity();
        }
    }

    function beginActivity() {

        try {

            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);

            var sessionOptions = {
                :sport => Activity.SPORT_RUNNING,
                :subSport => indoorMode ? Activity.SUB_SPORT_TREADMILL : Activity.SUB_SPORT_GENERIC,
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
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
            WatchUi.requestUpdate();
            return;
        }

        if (!activityStarted || session == null) {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
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
                saveSummary();
                System.println("HYROX activity saved");
            } else {
                session.discard();
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

    function getRunElapsedSeconds() {
        var totalSeconds = 0;

        for (var i = 0; i < runRecords.size(); i++) {
            totalSeconds += runRecords[i][:time];
        }

        if (activityStarted && isRunningSegment && !currentSummaryRecorded) {
            totalSeconds += ((System.getTimer() - segmentStartTime) / 1000).toNumber();
        }

        return totalSeconds;
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

    function getRunDistanceBeforeCurrentSegment() {
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
        var totalDistance = 0.0;

        for (var i = 0; i < runRecords.size(); i++) {
            totalDistance += runRecords[i][:distance];
        }

        if (activityStarted && isRunningSegment && !currentSummaryRecorded) {
            var currentDistance = getCurrentDistanceMeters() - segmentDistanceStart;
            if (currentDistance > 0) {
                totalDistance += currentDistance;
            }
        }

        return totalDistance;
    }
}