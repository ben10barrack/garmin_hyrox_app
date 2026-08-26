using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;

class Hyrox1_0EndView extends WatchUi.View {

    var app;

    // ---------------------------------------------------------
    // COLOR PALETTE — matches the main data screen
    // ---------------------------------------------------------

    const COLOR_BG      = Graphics.COLOR_BLACK;
    const COLOR_PRIMARY = Graphics.COLOR_WHITE;
    const COLOR_MUTED   = Graphics.COLOR_DK_GRAY;
    const COLOR_SAVE    = Graphics.COLOR_GREEN;
    const COLOR_DISCARD = Graphics.COLOR_RED;
    const COLOR_RESUME  = Graphics.COLOR_BLUE;

    function initialize() {
        View.initialize();
        app = Application.getApp();
    }

    function onLayout(dc) {}

    function onUpdate(dc) {

        // =====================================================
        // SCREEN
        // =====================================================

        var W  = dc.getWidth();
        var H  = dc.getHeight();
        var cx = W / 2;

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        var pad = H * 0.016;

        // =====================================================
        // FONT METRICS
        // =====================================================

        var fTiny  = Graphics.FONT_XTINY;
        var fSmall = Graphics.FONT_SMALL;
        var fMed   = Graphics.FONT_MEDIUM;

        var hTiny  = dc.getFontHeight(fTiny);
        var hSmall = dc.getFontHeight(fSmall);
        var hMed   = dc.getFontHeight(fMed);

        // =====================================================
        // LAYOUT CURSOR
        // =====================================================

        var y = H * 0.06;

        // =====================================================
        // HEADER DIVIDER — top accent line, same style as the
        // main data screen.
        // =====================================================

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, y, W, y);
        y += pad * 0.8;

        // =====================================================
        // TITLE
        // =====================================================

        dc.setColor(COLOR_PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y,
            fSmall,
            "END WORKOUT",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += hSmall + pad * 0.5;

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, y, W, y);
        y += pad;

        // =====================================================
        // INSTRUCTION
        // =====================================================

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y,
            fTiny,
            "UP / DOWN  TO SELECT",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        y += hTiny + pad;

        // =====================================================
        // OPTION ROWS
        //
        // Each option is its own full-width row. The selected
        // row gets a solid filled background in its own accent
        // color — the same "filled cell" pattern as the main
        // data screen's right-hand field. Unselected options
        // are muted text on black.
        // =====================================================

        var options   = ["SAVE", "DISCARD", "RESUME"];
        var colors    = [COLOR_SAVE, COLOR_DISCARD, COLOR_RESUME];
        var selected  = app.getEndMenuSelection();

        var rowH      = hMed + (pad * 1.4);
        var rowRadius = rowH * 0.18;

        for (var i = 0; i < options.size(); i++) {

            var isSelected = (i == selected);
            var rowColor   = colors[i];

            if (isSelected) {

                // Solid filled pill for the active option
                dc.setColor(rowColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(
                    W * 0.08, y,
                    W * 0.84, rowH,
                    rowRadius
                );

                // Dark text on the fill so it's legible
                dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    cx, y + (rowH - hMed) / 2,
                    fMed,
                    options[i],
                    Graphics.TEXT_JUSTIFY_CENTER
                );

            } else {

                // Unselected: muted text, no background
                dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    cx, y + (rowH - hMed) / 2,
                    fMed,
                    options[i],
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            }

            y += rowH + pad * 0.6;
        }

        // =====================================================
        // DIVIDER — before confirm hint
        // =====================================================

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, y, W, y);
        y += pad * 0.8;

        // =====================================================
        // CONFIRM INSTRUCTION — anchored just below divider
        // =====================================================

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, y,
            fTiny,
            "SELECT TO CONFIRM",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
