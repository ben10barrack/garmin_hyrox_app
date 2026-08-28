using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.System;
using Toybox.Lang;

class Hyrox1_0SummaryView extends WatchUi.View {

    var app;

    const COLOR_BG      = Graphics.COLOR_BLACK;
    const COLOR_PRIMARY = Graphics.COLOR_WHITE;
    const COLOR_SECOND  = Graphics.COLOR_LT_GRAY;
    const COLOR_MUTED   = Graphics.COLOR_DK_GRAY;
    const COLOR_DIVIDER = Graphics.COLOR_DK_GRAY;
    const COLOR_HR      = Graphics.COLOR_RED;
    const COLOR_RUN     = Graphics.COLOR_GREEN;
    const COLOR_STATION = Graphics.COLOR_BLUE;
    const COLOR_STATION_TEXT = Graphics.COLOR_BLUE;

    function initialize() {
        View.initialize();
        app = Application.getApp();
    }

    function onLayout(dc) {}

    function onUpdate(dc) {

        var W  = dc.getWidth();
        var H  = dc.getHeight();

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        // =====================================================
        // FONTS & METRICS
        // Compute once per frame — everything derives from these
        // so nothing can silently drift out of proportion.
        // =====================================================

        var fTiny  = Graphics.FONT_XTINY;
        var fSmall = Graphics.FONT_SMALL;
        var fNum   = Graphics.FONT_NUMBER_MEDIUM;

        var hTiny  = dc.getFontHeight(fTiny);
        var hSmall = dc.getFontHeight(fSmall);
        var hNum   = dc.getFontHeight(fNum);

        // Single padding unit; all spacing is a multiple of this.
        var pad = H * 0.016;

        // =====================================================
        // DATA
        // =====================================================

        var runs     = app.getRunRecords();
        var stations = app.getStationRecords();
        var segments = buildChronologicalList(runs, stations);
        var segCount = segments.size();

        var page      = app.getSummaryPage();
        var pageCount = 3 + ((segCount + 1) / 2);

        // =====================================================
        // PAGINATION DOTS — right-edge column
        //
        // Dots are drawn before content so content z-order is
        // naturally on top (draw order = painter's algorithm).
        //
        // dotsX is the center-x of the dot column; content
        // rightBound stops short of it to avoid overlap.
        // =====================================================

        var dotR       = 3;
        var dotGap     = dotR * 2 + 4;
        var dotsX      = W - dotR - (W * 0.04);
        var totalDots  = pageCount;
        var dotsHeight = (totalDots - 1) * dotGap;
        var dotStartY  = (H - dotsHeight) / 2;

        for (var d = 0; d < totalDots; d++) {
            var dotY   = dotStartY + d * dotGap;
            var active = (d == page);

            dc.setColor(
                active ? COLOR_PRIMARY : COLOR_MUTED,
                Graphics.COLOR_TRANSPARENT
            );

            if (active) {
                dc.fillCircle(dotsX, dotY, dotR);
            } else {
                dc.fillCircle(dotsX, dotY, dotR - 1);
            }
        }

        // Content area stops before the dot column.
        var contentRight = dotsX - dotR - (W * 0.03);
        var contentLeft  = W * 0.04;
        var contentW     = contentRight - contentLeft;

        // =====================================================
        // HEADER — title + divider
        // =====================================================

        var y = H * 0.04;

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            contentLeft + contentW / 2, y,
            fTiny, "SUMMARY",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += hTiny + pad * 0.4;

        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(contentLeft, y, contentRight, y);
        y += pad * 0.6;

        // =====================================================
        // PAGE 0 — OVERVIEW
        // =====================================================

        if (page == 0) {
            drawOverviewPage(
                dc, contentLeft, contentRight, contentW, H,
                y, pad,
                fTiny, fSmall, fNum,
                hTiny, hSmall, hNum,
                segments
            );
            return;
        }

        if (page == 1 || page == 2) {
            drawGroupedListPage(
                dc, contentLeft, contentRight, contentW, H, y, pad,
                fTiny, hTiny, segments, page == 1
            );
        } else {
            drawDetailPage(
                dc, contentLeft, contentRight, contentW, H, y, pad,
                fTiny, fSmall, fNum,
                hTiny, hSmall, hNum,
                segments, page - 3
            );
        }
    }


    // =========================================================
    // OVERVIEW PAGE
    //
    // Workout totals are stacked above the segment pages.
    // =========================================================

    function drawOverviewPage(
        dc, left, right, cw, H,
        y, pad,
        fTiny, fSmall, fNum,
        hTiny, hSmall, hNum,
        segments as Lang.Array<Lang.Dictionary>
    ) {
        // -- Totals: one compact row per metric --
        var rowH = hTiny + hSmall + pad * 0.6;
        var rowCenter = left + cw / 2;

        drawTotalRow(
            dc, left, right, rowCenter, y, rowH, pad, fTiny, fSmall,
            "TIME", formatTime(app.getCompletedWorkoutSeconds()), COLOR_PRIMARY
        );
        y += rowH;
        drawTotalRow(
            dc, left, right, rowCenter, y, rowH, pad, fTiny, fSmall,
            "DISTANCE", formatDistance(app.getCompletedWorkoutDistance()), COLOR_SECOND
        );
        y += rowH;
        drawTotalRow(
            dc, left, right, rowCenter, y, rowH, pad, fTiny, fSmall,
            "CALORIES", formatCalories(app.getCompletedWorkoutCalories()), COLOR_SECOND
        );
    }

    function drawTotalRow(dc, left, right, cx, y, rowH, pad, fTiny, fSmall, label, value, valueColor) {
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, fTiny, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y + dc.getFontHeight(fTiny) + pad * 0.2, fSmall, value, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left + (right - left) * 0.1, y + rowH - pad * 0.2, right - (right - left) * 0.1, y + rowH - pad * 0.2);
    }

    function drawGroupedListPage(
        dc, left, right, cw, H, y, pad,
        fTiny, hTiny, segments as Lang.Array<Lang.Dictionary>, showRuns
    ) {
        var cx = left + cw / 2;
        var title = showRuns ? "RUNS" : "STATIONS";
        var accent = showRuns ? COLOR_RUN : COLOR_STATION;

        dc.setColor(showRuns ? accent : COLOR_STATION_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, fTiny, title, Graphics.TEXT_JUSTIFY_CENTER);
        y += hTiny + (showRuns ? pad * 0.25 : pad * 0.05);

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, fTiny, "LAP       TIME", Graphics.TEXT_JUSTIFY_CENTER);
        y += hTiny + (showRuns ? pad * 0.15 : 0);

        var rowH = showRuns ? hTiny + pad * 0.25 : hTiny * 0.82;
        var rowCenter = cx;
        var shown = 0;

        for (var i = 0; i < segments.size(); i++) {
            var segment = segments[i];
            var isRun = segment[:type].equals("run");

            if (isRun != showRuns) {
                continue;
            }

            var rowY = y + shown * rowH;
            var labelFont = isRun ? fTiny : Graphics.FONT_XTINY;
            var labelColor = isRun ? accent : COLOR_STATION_TEXT;
            var labelX = isRun ? rowCenter - cw * 0.16 : left + cw * 0.08;
            var timeX = isRun ? rowCenter + cw * 0.16 : rowCenter + cw * 0.20;
            var timeFont = isRun ? fTiny : Graphics.FONT_XTINY;
            var label = isRun
                ? segment[:label]
                : fitStationLabel(segment[:label], labelFont, cw * 0.28, dc);

            dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                labelX, rowY, labelFont, label,
                isRun ? Graphics.TEXT_JUSTIFY_CENTER : Graphics.TEXT_JUSTIFY_LEFT
            );
            dc.setColor(COLOR_SECOND, Graphics.COLOR_TRANSPARENT);
            dc.drawText(timeX, rowY, timeFont, formatTime(segment[:time]), Graphics.TEXT_JUSTIFY_CENTER);
            shown += 1;

            if (shown >= 8 || rowY + rowH > H * 0.92) {
                break;
            }
        }
    }

    function fitStationLabel(label, font, maxWidth, dc) {
        if (dc.getTextWidthInPixels(label, font) <= maxWidth) {
            return label;
        }

        var shortened = label;
        while (shortened.length() > 3 &&
               dc.getTextWidthInPixels(shortened + "...", font) > maxWidth) {
            shortened = shortened.substring(0, shortened.length() - 1);
        }

        return shortened + "...";
    }

    function drawDetailPage(
        dc, left, right, cw, H, y, pad,
        fTiny, fSmall, fNum,
        hTiny, hSmall, hNum,
        segments as Lang.Array<Lang.Dictionary>, pairIndex
    ) {
        var firstIndex = pairIndex * 2;
        var available = H * 0.96 - y;
        var halfH = available / 2;

        if (firstIndex < segments.size()) {
            drawSegmentRow(
                dc, left, right, cw, y, halfH, pad,
                fTiny, fSmall, fNum,
                hTiny, hSmall, hNum,
                segments[firstIndex]
            );
        }

        var middle = y + halfH;
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left, middle, right, middle);

        if (firstIndex + 1 < segments.size()) {
            drawSegmentRow(
                dc, left, right, cw,
                middle + pad * 0.4, halfH - pad * 0.4, pad,
                fTiny, fSmall, fNum,
                hTiny, hSmall, hNum,
                segments[firstIndex + 1]
            );
        }
    }


    // =========================================================
    // SEGMENT ROW
    //
    // Renders one segment into a fixed vertical band (availH).
    // Layout:
    //   [accent bar — full width]
    //   [col1 label] | [col2 label] | [col3 label]
    //   [col1 value] | [col2 value] | [col3 value]
    //
    // All three value cells use FONT_SMALL — same size, no
    // hero number, so nothing can overflow its cell.
    // =========================================================

    function drawSegmentRow(
        dc, left, right, cw,
        y, availH, pad,
        fTiny, fSmall, fNum,
        hTiny, hSmall, hNum,
        seg as Lang.Dictionary
    ) {
        var isRun  = seg[:type].equals("run");
        var accent = isRun ? COLOR_RUN : COLOR_STATION;
        var cx     = left + cw / 2;

        // -- Accent label bar --
        var barH = hTiny + pad * 0.9;

        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(left, y, cw, barH);

        // Dark text on the filled bar
        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y + (barH - hTiny) / 2,
            fTiny, seg[:label],
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += barH + pad * 0.5;

        // -- Three equal columns --
        // Columns are positioned as thirds of cw so they never
        // overlap regardless of screen width.

        var col1X = left + cw * 0.17;
        var col2X = left + cw * 0.50;
        var col3X = left + cw * 0.83;

        var l1 = "";
        var v1 = "";
        var l2 = "";
        var v2 = "";
        var l3 = "";
        var v3 = "";

        if (isRun) {
            l1 = "AVG HR";  v1 = formatHeartRate(seg[:heartRate]);
            l2 = "DIST";    v2 = formatDistance(seg[:distance]);
            l3 = "PACE";    v3 = formatPace(seg[:distance], seg[:time]);
        } else {
            l1 = "TIME";    v1 = formatTime(seg[:time]);
            l2 = "AVG HR";  v2 = formatHeartRate(seg[:heartRate]);
            l3 = "EFFORT";  v3 = formatEffort(seg[:heartRate]);
        }

        // Labels row
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, y, fTiny, l1, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(col2X, y, fTiny, l2, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(col3X, y, fTiny, l3, Graphics.TEXT_JUSTIFY_CENTER);
        y += hTiny + pad * 0.2;

        // Values row — all FONT_SMALL, same height
        dc.setColor(COLOR_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, y, fSmall, v1, Graphics.TEXT_JUSTIFY_CENTER);

        // HR in red for quick scanning
        dc.setColor(isRun ? COLOR_PRIMARY : COLOR_HR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col2X, y, isRun ? fTiny : fSmall, v2, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col3X, y, isRun ? fTiny : fSmall, v3, Graphics.TEXT_JUSTIFY_CENTER);

        // Vertical dividers between cells, spanning both label
        // and value rows.
        var vTop    = y - hTiny - pad * 0.2 - pad * 0.2;
        var vBottom = y + hSmall;

        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left + cw * 0.34, vTop, left + cw * 0.34, vBottom);
        dc.drawLine(left + cw * 0.66, vTop, left + cw * 0.66, vBottom);
    }


    // =========================================================
    // BUILD CHRONOLOGICAL SEGMENT LIST
    // =========================================================

    function buildChronologicalList(
        runs     as Lang.Array<Lang.Dictionary>,
        stations as Lang.Array<Lang.Dictionary>
    ) as Lang.Array<Lang.Dictionary> {

        var list    = [];
        var runCount = runs.size();
        var stnCount = stations.size();
        var maxPairs = runCount > stnCount ? runCount : stnCount;

        for (var i = 0; i < maxPairs; i++) {

            if (i < runCount) {
                var r = runs[i] as Lang.Dictionary;
                list.add({
                    :type      => "run",
                    :label     => "RUN " + r[:number].format("%d"),
                    :number    => r[:number],
                    :time      => r[:time],
                    :distance  => r[:distance],
                    :heartRate => r[:heartRate]
                });
            }

            if (i < stnCount) {
                var s = stations[i] as Lang.Dictionary;
                list.add({
                    :type      => "station",
                    :label     => app.getStationName(s[:number]),
                    :number    => s[:number],
                    :time      => s[:time],
                    :distance  => 0,
                    :heartRate => s[:heartRate]
                });
            }
        }

        return list;
    }


    // =========================================================
    // FORMAT HELPERS
    // =========================================================

    function formatTime(seconds) {
        var t = seconds.toNumber();
        var h = t / 3600;
        var m = (t % 3600) / 60;
        var s = t % 60;

        if (h > 0) {
            return h.format("%d") + ":" +
                   m.format("%02d") + ":" +
                   s.format("%02d");
        }

        return m.format("%d") + ":" + s.format("%02d");
    }

    function formatDistance(meters) {
        if (meters == null || meters <= 0) { return "--"; }

        var settings = System.getDeviceSettings();

        if (settings != null &&
            settings.distanceUnits == System.UNIT_STATUTE) {
            return (meters / 1609.34).format("%.2f") + "mi";
        }

        if (meters >= 1000) {
            return (meters / 1000.0).format("%.2f") + "km";
        }

        return meters.format("%.0f") + "m";
    }

    function formatPace(meters, secs) {
        if (meters == null || meters <= 10 ||
            secs   == null || secs   <= 0)  { return "--:--"; }

        var settings = System.getDeviceSettings();
        var unitM  = 1000.0;
        var label  = "/k";

        if (settings != null &&
            settings.distanceUnits == System.UNIT_STATUTE) {
            unitM = 1609.34;
            label = "/m";
        }

        var spu = (secs.toFloat() / meters.toFloat()) * unitM;
        var m   = spu.toNumber() / 60;
        var r   = spu.toNumber() % 60;

        return m.format("%d") + ":" + r.format("%02d") + label;
    }

    function formatHeartRate(hr) {
        if (hr == null || hr <= 0) { return "--"; }
        return hr.format("%.0f");
    }

    function formatCalories(calories) {
        if (calories == null || calories <= 0) { return "--"; }
        return calories.format("%.0f") + "kcal";
    }

    function formatEffort(hr) {
        if (hr == null || hr <= 0) { return "--"; }
        var bpm = hr.toNumber();
        if (bpm < 120) { return "EASY"; }
        if (bpm < 140) { return "MOD"; }
        if (bpm < 160) { return "HARD"; }
        if (bpm < 175) { return "V.HARD"; }
        return "MAX";
    }
}
