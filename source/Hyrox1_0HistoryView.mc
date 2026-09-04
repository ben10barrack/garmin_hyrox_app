using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;

class Hyrox1_0HistoryView extends WatchUi.View {

    var app;

    const COLOR_BG = Graphics.COLOR_BLACK;
    const COLOR_PRIMARY = Graphics.COLOR_WHITE;
    const COLOR_MUTED = Graphics.COLOR_DK_GRAY;

    function initialize() {
        View.initialize();
        app = Application.getApp();
    }

    function onLayout(dc) {}

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        dc.setColor(COLOR_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.07, Graphics.FONT_SMALL,
            "HISTORY", Graphics.TEXT_JUSTIFY_CENTER);

        var count = app.getHistoryCount();
        if (count == 0) {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 0.48, Graphics.FONT_SMALL,
                "NO SAVED WORKOUT", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.16, Graphics.FONT_XTINY,
            "SELECT WORKOUT", Graphics.TEXT_JUSTIFY_CENTER);

        var selected = app.getHistoryActivity();
        var rowHeight = height * 0.12;
        var firstY = height * 0.25;
        for (var i = 0; i < count; i++) {
            var y = firstY + i * rowHeight;
            var selectedRow = i == selected;
            dc.setColor(selectedRow ? COLOR_PRIMARY : COLOR_MUTED,
                Graphics.COLOR_TRANSPARENT);

            if (selectedRow) {
                dc.fillRoundedRectangle(width * 0.10, y, width * 0.80,
                    rowHeight * 0.78, 4);
                dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(width * 0.20, y + rowHeight * 0.18,
                Graphics.FONT_XTINY, "WORKOUT " + (i + 1).format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(width * 0.80, y + rowHeight * 0.18,
                Graphics.FONT_XTINY,
                formatTime(app.getHistoryNumberFor(i, "summaryTime")),
                Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(width / 2, y + rowHeight * 0.52,
                Graphics.FONT_XTINY,
                formatDistance(app.getHistoryNumberFor(i, "summaryDistance")),
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.91, Graphics.FONT_XTINY,
            "ENTER TO OPEN", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function formatTime(seconds) {
        var total = seconds.toNumber();
        return ((total % 3600) / 60).format("%d") + ":" +
            (total % 60).format("%02d");
    }

    function formatDistance(meters) {
        if (meters <= 0) { return "--"; }
        if (meters >= 1000) {
            return (meters / 1000.0).format("%.2f") + "km";
        }
        return meters.format("%.0f") + "m";
    }
}
