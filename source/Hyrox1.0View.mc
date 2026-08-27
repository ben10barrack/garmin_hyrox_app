using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Timer;
using Toybox.Activity;
using Toybox.Application;

class Hyrox1_0View extends WatchUi.View {

    var app;
    var updateTimer;
    var displayedDistanceMeters = null;

    // ---------------------------------------------------------
    // COLOR PALETTE
    // ---------------------------------------------------------

    const COLOR_BG           = Graphics.COLOR_BLACK;
    const COLOR_TEXT_PRIMARY = Graphics.COLOR_WHITE;
    const COLOR_TEXT_MUTED   = Graphics.COLOR_DK_GRAY;
    const COLOR_DIVIDER      = Graphics.COLOR_DK_GRAY;
    const COLOR_HR           = Graphics.COLOR_RED;
    const COLOR_RUN_FILL     = Graphics.COLOR_GREEN;
    const COLOR_STATION_FILL = Graphics.COLOR_ORANGE;
    const COLOR_READY_FILL   = Graphics.COLOR_BLUE;

    function initialize() {
        View.initialize();
        app = Application.getApp();
        updateTimer = new Timer.Timer();
    }

    function onLayout(dc) {}

    function onShow() {
        if (updateTimer != null) {
            updateTimer.start(method(:timerCallback), 1000, true);
        }
    }

    function onHide() {
        if (updateTimer != null) {
            updateTimer.stop();
        }
    }

    function timerCallback() {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {

        // =====================================================
        // SCREEN DIMENSIONS
        // =====================================================

        var W = dc.getWidth();
        var H = dc.getHeight();
        var cx = W / 2;

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        // =====================================================
        // APP STATE
        // =====================================================

        var active       = app.isActivityActive();
        var running      = app.getIsRunningSegment();
        var stationNum   = app.getStationNumber();
        var totalStation = app.getTotalStations();

        // =====================================================
        // ACTIVITY DATA
        // =====================================================

        var info = Activity.getActivityInfo();
        var hr            = null;
        var distMeters    = null;
        var speedMps      = null;

        if (info != null) {
            hr         = info.currentHeartRate;
            distMeters = info.elapsedDistance;
            speedMps   = info.currentSpeed;
            app.recordActivitySample(info);
        }

        if (!active) {
            displayedDistanceMeters = null;
        } else if (running && distMeters != null) {
            displayedDistanceMeters = distMeters;
        }

        // =====================================================
        // FONT METRICS — cached once per frame
        // =====================================================

        var fTiny   = Graphics.FONT_XTINY;
        var fSmall  = Graphics.FONT_SMALL;
        var fNumMed = Graphics.FONT_NUMBER_MEDIUM;

        var hTiny   = dc.getFontHeight(fTiny);
        var hSmall  = dc.getFontHeight(fSmall);
        var hNumMed = dc.getFontHeight(fNumMed);

        var pad = H * 0.012;   // compact spacing for the circular display

        // =====================================================
        // ACCENT FILL COLOR
        // =====================================================

        var accentFill;
        if (!active)        { accentFill = COLOR_READY_FILL; }
        else if (running)   { accentFill = COLOR_RUN_FILL; }
        else                { accentFill = COLOR_STATION_FILL; }

        // =====================================================
        // ROW 0 — CLOCK (top center, muted)
        // =====================================================

        var clockY = H * 0.03;

        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, clockY,
            fTiny,
            formatClockTime(),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        var y = clockY + hTiny + pad;

        // =====================================================
        // DIVIDER — under clock
        // =====================================================

        drawHRule(dc, W, y, COLOR_DIVIDER);
        y += pad * 0.5;

        // =====================================================
        // ROW 1 — TWO TOP FIELDS
        //
        // Left cell:  TOTAL TIME  (plain white on black)
        // Right cell: SEGMENT LABEL  (white text on solid fill)
        //
        // This mirrors the reference exactly: one of the two
        // top fields gets the solid accent-color background.
        // =====================================================

        var row1H    = hTiny + hNumMed + pad;  // label + number + inner pad
        var halfW    = W / 2;

        // -- LEFT CELL: total time --

        var totalSecs   = app.getActivityElapsedSeconds();
        var totalStr    = formatTime(totalSecs);

        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            halfW * 0.5, y + pad * 0.4,
            fTiny, "TOTAL",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(COLOR_TEXT_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            halfW * 0.5, y + hTiny + pad * 0.4,
            fSmall, totalStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // -- RIGHT CELL: accent fill + segment timer label --

        dc.setColor(accentFill, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(halfW, y, halfW, row1H);

        var segLabel;
        if (!active)      { segLabel = "PACE"; }
        else if (running) { segLabel = "PACE"; }
        else              { segLabel = "STATION"; }

        var segLabelValue;
        if (!active) {
            segLabelValue = "--:--";
        } else if (running) {
            segLabelValue = formatPace(speedMps);
        } else {
            segLabelValue = formatTime(app.getSegmentElapsedSeconds());
        }

        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            halfW + halfW * 0.5, y + pad * 0.4,
            fTiny, segLabel,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            halfW + halfW * 0.5, y + hTiny + pad * 0.4,
            fNumMed, segLabelValue,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        y += row1H + pad * 0.5;

        // vertical divider between cells
        drawVRule(dc, halfW, y - row1H - pad * 0.5, y, COLOR_BG);

        // =====================================================
        // DIVIDER — between row 1 and segment label
        // =====================================================

        drawHRule(dc, W, y, COLOR_DIVIDER);
        y += pad * 0.6;

        // =====================================================
        // SEGMENT LABEL ROW — centered section title
        // e.g. "1km Run" / "Sled Push" etc.
        // =====================================================

        var segmentTitle;
        if (app.isEndMenuOpen()) {
            segmentTitle = "END WORKOUT";
        } else if (app.isWaitingForGps()) {
            segmentTitle = "WAITING FOR GPS";
        } else if (!active) {
            segmentTitle = app.isIndoorMode() ? "TREADMILL" : "GPS RUN";
        } else if (running) {
            segmentTitle = "RUN " + stationNum + " of " + totalStation;
        } else {
            segmentTitle = "STATION " + stationNum + " of " + totalStation;
        }

        dc.setColor(COLOR_TEXT_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y,
            fSmall, segmentTitle,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        y += hSmall + pad * 0.6;
        drawHRule(dc, W, y, COLOR_DIVIDER);
        y += pad * 0.5;

        // =====================================================
        // ROW 2 — THREE-COLUMN HERO ROW
        //
        // Left:   distance  |  Center: segment timer  |  Right: heart rate
        //
        // The center cell is the biggest number on the screen —
        // matching the reference "4:26" hero field.
        // =====================================================

        var segSecs  = app.getSegmentElapsedSeconds();
        var segStr   = formatTime(segSecs);
        var distStr  = (running && displayedDistanceMeters != null)
            ? formatDistance(displayedDistanceMeters)
            : "--";
        var hrStr    = (hr != null) ? hr.format("%d") : "--";

        var col1X = W * 0.18;
        var col3X = W * 0.82;

        var row2H = hSmall + pad;

        // left: distance
        dc.setColor(COLOR_TEXT_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            col1X, y + (row2H - hSmall) / 2,
            fSmall, distStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // center: compact segment timer
        dc.setColor(COLOR_TEXT_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y,
            fSmall, segStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // right: heart rate
        dc.setColor(COLOR_HR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            col3X, y + (row2H - hSmall) / 2,
            fSmall, hrStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // column rule lines
        var row2Bottom = y + row2H + pad * 0.5 + hTiny + pad;
        drawVRule(dc, W * 0.36, y, row2Bottom, COLOR_DIVIDER);
        drawVRule(dc, W * 0.64, y, row2Bottom, COLOR_DIVIDER);

        y += row2H + pad * 0.5;

        // labels under each column
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, y, fTiny, "DIST", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx,    y, fTiny, running ? "RUN" : "STN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(col3X, y, fTiny, "HR", Graphics.TEXT_JUSTIFY_CENTER);

        y += hTiny + pad;

        // =====================================================
        // DIVIDER — before next-up / heart rate rows
        // =====================================================

        drawHRule(dc, W, y, COLOR_DIVIDER);
        y += pad * 0.6;

        // =====================================================
        // NEXT UP ROW
        //
        // Mirrors the "1km Run  NEXT UP - 4:30" text row in the
        // reference. Shows what segment comes after this one.
        // =====================================================

        var nextUp = getNextUpText(active, running, stationNum, totalStation);

        if (app.isEndMenuOpen()) {
            nextUp = getEndMenuText(app.getEndMenuSelection());
        }

        dc.setColor(COLOR_READY_FILL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y,
            fTiny, nextUp,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }


    // =========================================================
    // DRAWING HELPERS
    // =========================================================

    function drawHRule(dc, W, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, y, W, y);
    }

    function drawVRule(dc, x, yTop, yBottom, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, yTop, x, yBottom);
    }


    // =========================================================
    // NEXT-UP LOGIC
    // =========================================================

    function getNextUpText(active, running, stationNum, totalStation) {

        if (!active) {
            return "START";
        }

        if (running) {
            return "NEXT: STN " + stationNum;
        }

        if (stationNum < totalStation) {
            return "NEXT: RUN " + (stationNum + 1).format("%d");
        }

        return "FINISH";
    }

    function getEndMenuText(selection) {
        if (selection == 0) {
            return "> SAVE <";
        }

        if (selection == 1) {
            return "> DISCARD <";
        }

        return "> RESUME <";
    }


    // =========================================================
    // CLOCK
    // =========================================================

    function formatClockTime() {

        var t = System.getClockTime();
        var s = System.getDeviceSettings();
        var h = t.hour;
        var suffix = "";

        if (s != null && !s.is24Hour) {
            suffix = (h >= 12) ? "p" : "a";
            h = h % 12;
            if (h == 0) { h = 12; }
        }

        return h.format("%d") + ":" + t.min.format("%02d") + suffix;
    }


    // =========================================================
    // TIME
    // =========================================================

    function formatTime(totalSeconds) {

        var s = totalSeconds.toNumber();
        var h = s / 3600;
        var m = (s % 3600) / 60;
        var r = s % 60;

        if (h > 0) {
            return h.format("%d") + ":" +
                   m.format("%02d") + ":" +
                   r.format("%02d");
        }

        return m.format("%d") + ":" + r.format("%02d");
    }


    // =========================================================
    // PACE HELPERS
    // =========================================================

    function getUnitMeters() {

        var s = System.getDeviceSettings();

        if (s != null && s.distanceUnits == System.UNIT_STATUTE) {
            return 1609.34;
        }

        return 1000.0;
    }

    function getPaceLabel() {

        var s = System.getDeviceSettings();

        if (s != null && s.distanceUnits == System.UNIT_STATUTE) {
            return "/mi";
        }

        return "/km";
    }

    // Current pace from live speed
    function formatPace(speedMps) {

        if (speedMps == null || speedMps <= 0.3) {
            return "--:--";
        }

        var spu  = getUnitMeters() / speedMps;
        var secs = spu.toNumber();
        var m    = secs / 60;
        var r    = secs % 60;

        return m.format("%d") + ":" + r.format("%02d");
    }

    // Avg pace for this segment = segment elapsed / distance
    function formatAvgPace(distMeters, segSecs) {

        if (distMeters == null || distMeters <= 10) {
            return "--:--";
        }

        var unit = getUnitMeters();
        var spu  = (segSecs.toFloat() / distMeters.toFloat()) * unit;
        var secs = spu.toNumber();
        var m    = secs / 60;
        var r    = secs % 60;

        return m.format("%d") + ":" + r.format("%02d") + getPaceLabel();
    }


    // =========================================================
    // DISTANCE
    // =========================================================

    function formatDistance(distMeters) {

        if (distMeters == null || distMeters < 0) {
            return "--";
        }

        var s = System.getDeviceSettings();

        if (s != null && s.distanceUnits == System.UNIT_STATUTE) {
            return (distMeters / 1609.34).format("%.2f") + "mi";
        }

        return (distMeters / 1000.0).format("%.2f") + "km";
    }
}
