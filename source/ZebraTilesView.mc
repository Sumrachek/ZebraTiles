import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ZebraTilesView extends WatchUi.DataField {

    hidden var mRows as Array<Row>;
    hidden var mMetrics as Metrics;

    // Ordered widest-first so the first fit is the biggest that fits.
    hidden var mNumberFonts as Array<FontDefinition> = [
        Graphics.FONT_NUMBER_HOT,
        Graphics.FONT_NUMBER_MEDIUM,
        Graphics.FONT_NUMBER_MILD
    ] as Array<FontDefinition>;

    // Chrome font, then fallbacks for labels too long for their tile.
    hidden var mLabelFonts as Array<FontDefinition> = [
        Config.LABEL_FONT,
        Graphics.FONT_TINY,
        Graphics.FONT_XTINY
    ] as Array<FontDefinition>;

    hidden var mTextFonts as Array<FontDefinition> = [
        Graphics.FONT_LARGE,
        Graphics.FONT_MEDIUM,
        Graphics.FONT_SMALL,
        Graphics.FONT_TINY,
        Graphics.FONT_XTINY
    ] as Array<FontDefinition>;

    function initialize() {
        DataField.initialize();
        mMetrics = new Metrics();
        mRows = Spec.parse(Config.DEFAULT_LAYOUT);
        reload();
    }

    //! Re-read the app settings. Called on start and whenever they change.
    function reload() as Void {
        Zones.reload();

        var text = null;
        try {
            text = Application.Properties.getValue("layout");
        } catch (e) {
            text = null;
        }
        if (!(text instanceof Lang.String) || (text as String).length() == 0) {
            text = Config.DEFAULT_LAYOUT;
        }
        mRows = Spec.parse(text as String);
    }

    function compute(info as Activity.Info) as Void {
        mMetrics.update(info);
    }

    function onTimerLap() as Void {
        mMetrics.onLap(Activity.getActivityInfo());
    }

    function onTimerReset() as Void {
        mMetrics.onReset();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var statusRows = 0;
        for (var i = 0; i < mRows.size(); i++) {
            if (mRows[i].isStatus) {
                statusRows++;
            }
        }
        var tileRows = mRows.size() - statusRows;

        var statusH = (h < 120) ? 16 : Config.STATUS_H;
        if (statusRows * statusH > h / 2) {
            statusH = (h / 2) / (statusRows > 0 ? statusRows : 1);
        }
        var tileBand = h - (statusH * statusRows);
        var tileH = (tileRows > 0) ? tileBand.toFloat() / tileRows : 0.0;

        var edge = 0.0;
        for (var i = 0; i < mRows.size(); i++) {
            var row = mRows[i];
            var top = edge;
            edge += row.isStatus ? statusH : tileH;

            var y = top.toNumber();
            var rowH = edge.toNumber() - y;
            if (row.isStatus) {
                drawStatusRow(dc, row, y, w, rowH);
            } else {
                drawTileRow(dc, row, y, w, rowH);
            }
        }
    }

    hidden function drawTileRow(dc as Dc, row as Row, y as Number, w as Number, h as Number) as Void {
        // Tiles butt up against each other: no vertical rule inside a row.
        var n = row.cells.size();
        for (var i = 0; i < n; i++) {
            var left = (i * w) / n;
            var right = ((i + 1) * w) / n;
            drawTile(dc, row.cells[i], left, y, right - left, h);
        }
    }

    hidden function drawTile(dc as Dc, cell as Cell, x as Number, y as Number, w as Number, h as Number) as Void {
        var headerH = (h < 56) ? h / 3 : Config.HEADER_H;
        var valueH = h - headerH;

        var kind = Fields.zoneKind(cell.code);
        var zone = Zones.of(kind, Fields.zoneInput(cell.code, mMetrics));
        var fill = Zones.colorFor(kind, zone);
        if (fill == null) {
            fill = Config.VALUE_BG;
        }

        dc.setColor(Config.HEADER_BG, Config.HEADER_BG);
        dc.fillRectangle(x, y, w, headerH);
        drawHeader(dc, Fields.labelFor(cell), zone, x, y, w, headerH);

        dc.setColor(fill, fill);
        dc.fillRectangle(x, y + headerH, w, valueH);

        var text = Fields.textFor(cell, mMetrics);
        var font = pickFont(dc, text, w - (2 * Config.PAD), valueH);
        dc.setColor(Config.VALUE_FG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + (w / 2), y + headerH + (valueH / 2), font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Label, and for zoned tiles the zone badge, centred together as one group.
    hidden function drawHeader(dc as Dc, label as String, zone as Number?, x as Number, y as Number, w as Number, h as Number) as Void {
        var badge = (zone != null) ? "z" + zone.format("%d") : null;
        var gap = (badge != null) ? Config.LABEL_GAP : 0;
        var avail = w - (2 * Config.PAD);

        // Largest chrome font whose label-plus-badge group still fits the tile.
        var font = mLabelFonts[mLabelFonts.size() - 1];
        var labelW = 0;
        var badgeW = 0;
        for (var i = 0; i < mLabelFonts.size(); i++) {
            var candidate = mLabelFonts[i];
            var lw = dc.getTextWidthInPixels(label, candidate);
            var bw = (badge != null) ? dc.getTextWidthInPixels(badge, candidate) : 0;
            font = candidate;
            labelW = lw;
            badgeW = bw;
            if (dc.getFontHeight(candidate) <= h && lw + gap + bw <= avail) {
                break;
            }
        }

        var start = x + ((w - (labelW + gap + badgeW)) / 2);
        if (start < x + Config.PAD) {
            start = x + Config.PAD;
        }
        var mid = y + (h / 2);

        dc.setColor(Config.HEADER_FG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(start, mid, font, label,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (badge != null) {
            dc.setColor(Config.ZONE_FG, Graphics.COLOR_TRANSPARENT);
            dc.drawText(start + labelW + gap, mid, font, badge,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Compact strip: first tile hugs the left, last the right, rest centred.
    hidden function drawStatusRow(dc as Dc, row as Row, y as Number, w as Number, h as Number) as Void {
        var n = row.cells.size();
        var mid = y + (h / 2);
        dc.setColor(Config.STATUS_FG, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < n; i++) {
            var left = (i * w) / n;
            var cellW = ((i + 1) * w) / n - left;
            var text = Fields.textFor(row.cells[i], mMetrics);
            var font = fitLabelFont(dc, text, cellW - (2 * Config.PAD), h);

            if (n == 1) {
                dc.drawText(left + (cellW / 2), mid, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (i == 0) {
                dc.drawText(left + Config.PAD, mid, font, text,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (i == n - 1) {
                dc.drawText(left + cellW - Config.PAD, mid, font, text,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawText(left + (cellW / 2), mid, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    //! Largest chrome font that fits, for headers and the status strip alike.
    hidden function fitLabelFont(dc as Dc, text as String, maxW as Number, maxH as Number) as FontDefinition {
        for (var i = 0; i < mLabelFonts.size(); i++) {
            var f = mLabelFonts[i];
            if (dc.getFontHeight(f) <= maxH && dc.getTextWidthInPixels(text, f) <= maxW) {
                return f;
            }
        }
        return mLabelFonts[mLabelFonts.size() - 1];
    }

    //! Largest font whose glyphs fit the box. Number fonts are allowed a little
    //! overflow: they reserve descender space that digits never use.
    hidden function pickFont(dc as Dc, text as String, maxW as Number, maxH as Number) as FontDefinition {
        if (isNumeric(text)) {
            for (var i = 0; i < mNumberFonts.size(); i++) {
                var f = mNumberFonts[i];
                if (dc.getFontHeight(f) <= maxH * 1.15 && dc.getTextWidthInPixels(text, f) <= maxW) {
                    return f;
                }
            }
        }
        for (var i = 0; i < mTextFonts.size(); i++) {
            var f = mTextFonts[i];
            if (dc.getFontHeight(f) <= maxH && dc.getTextWidthInPixels(text, f) <= maxW) {
                return f;
            }
        }
        return Graphics.FONT_XTINY;
    }

    //! Number fonts only carry digits, ':', '.' and '-'.
    hidden function isNumeric(text as String) as Boolean {
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i];
            var ok = (c >= '0' && c <= '9') || c == ':' || c == '.' || c == '-';
            if (!ok) {
                return false;
            }
        }
        return chars.size() > 0;
    }
}
