using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;

class Hyrox1_0StartView extends WatchUi.View {

    var app;

    const COLOR_BG = Graphics.COLOR_BLACK;
    const COLOR_PRIMARY = Graphics.COLOR_WHITE;
    const COLOR_MUTED = Graphics.COLOR_DK_GRAY;
    const COLOR_GPS = Graphics.COLOR_BLUE;
    const COLOR_TREADMILL = Graphics.COLOR_ORANGE;

    function initialize() {
        View.initialize();
        app = Application.getApp();
    }

    function onLayout(dc) {}

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var selected = app.isIndoorMode() ? 1 : 0;

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        dc.setColor(COLOR_GPS, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.10, Graphics.FONT_SMALL,
            "HYROX", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.20, Graphics.FONT_XTINY,
            "SELECT ACTIVITY TYPE", Graphics.TEXT_JUSTIFY_CENTER);

        var options = ["GPS RUN", "TREADMILL"];
        var colors = [COLOR_GPS, COLOR_TREADMILL];
        var buttonFont = Graphics.FONT_SMALL;
        var buttonTextHeight = dc.getFontHeight(buttonFont);
        var rowHeight = height * 0.13;
        var rowTop = height * 0.34;

        for (var i = 0; i < options.size(); i++) {
            var y = rowTop + i * (rowHeight + height * 0.03);
            if (i == selected) {
                dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(width * 0.14, y, width * 0.72,
                    rowHeight, rowHeight * 0.18);
                dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(centerX, y + (rowHeight - buttonTextHeight) / 2,
                buttonFont,
                options[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
