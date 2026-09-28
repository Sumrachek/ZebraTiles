import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ZebraTilesView extends WatchUi.DataField {

    hidden var mRows as Array<Row>;
    hidden var mMetrics as Metrics;
    hidden var mHeaderBg as Number = Config.HEADER_BG;
    hidden var mHeaderFg as Number = Config.HEADER_FG;

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
        mHeaderBg = colorSetting("headerBg", Config.HEADER_BG);
        mHeaderFg = colorSetting("headerFg", Config.HEADER_FG);

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

    //! Colours arrive as hex text - "2B2B2B", or "#2B2B2B" - so they can be typed
    //! into the phone app, which offers no colour picker. Anything unparseable
    //! falls back to the built-in value rather than painting a surprise colour.
    hidden function colorSetting(key as String, fallback as Number) as Number {
        var raw = null;
        try {
            raw = Application.Properties.getValue(key);
        } catch (e) {
            raw = null;
        }
        if (!(raw instanceof Lang.String)) {
            return fallback;
        }
        return parseColor(raw as String, fallback);
    }

    hidden function parseColor(input as String, fallback as Number) as Number {
        var text = input;
        if (text.length() == 7) {
            var head = text.substring(0, 1);
            var body = text.substring(1, 7);
            if (head != null && body != null && head.equals("#")) {
                text = body;
            }
        }
        if (text.length() != 6) {
            return fallback;
        }

        var value = text.toNumberWithBase(16);
        if (value == null || value < 0 || value > 0xFFFFFF) {
            return fallback;
        }
        return value;
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
        if (Fields.isGraphic(cell.code)) {
            dc.setColor(Config.VALUE_BG, Config.VALUE_BG);
            dc.fillRectangle(x, y, w, h);
            if (!headerIsPainted() && y > 0) {
                dc.setColor(Config.HEADER_RULE, Config.HEADER_RULE);
                dc.fillRectangle(x, y, w, 1);
            }
            drawGearMap(dc, x, y, w, h);
            return;
        }

        var headerH = (h < 56) ? h / 3 : Config.HEADER_H;
        var valueH = h - headerH;

        var kind = Fields.zoneKind(cell.code);
        var input = Fields.zoneInput(cell.code, mMetrics);
        var zone = Zones.of(kind, input);
        var fill = Zones.colorFor(kind, zone);
        if (fill == null) {
            fill = Config.VALUE_BG;
        }

        if (headerIsPainted()) {
            dc.setColor(mHeaderBg, mHeaderBg);
            dc.fillRectangle(x, y, w, headerH);
            dc.setColor(fill, fill);
            dc.fillRectangle(x, y + headerH, w, valueH);
            drawEdgeHints(dc, kind, input, zone, x, y + headerH, w, valueH);
        } else {
            // No header strip: the fill owns the whole tile and the label rides on
            // top of it. A hairline rule takes over the job of separating rows -
            // except on the top row, which has nothing above it to be separated from.
            dc.setColor(fill, fill);
            dc.fillRectangle(x, y, w, h);
            drawEdgeHints(dc, kind, input, zone, x, y, w, h);
            if (y > 0) {
                dc.setColor(Config.HEADER_RULE, Config.HEADER_RULE);
                dc.fillRectangle(x, y, w, 1);
            }
        }
        drawHeader(dc, Fields.labelFor(cell), Zones.badgeFor(kind, zone), x, y, w, headerH);

        var text = Fields.textFor(cell, mMetrics);
        var font = pickFont(dc, text, w - (2 * Config.PAD), valueH);
        var middle = y + headerH + (valueH / 2);
        if (!headerIsPainted()) {
            middle -= Config.HEADERLESS_VALUE_LIFT;
        }
        dc.setColor(Config.VALUE_FG, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, x + (w / 2), middle, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Colours outside the 24-bit range mean "do not paint the header strip".
    //! That covers both Graphics.COLOR_TRANSPARENT, which is -1, and the
    //! 0xFF000000 spelling, since Monkey C colours carry no alpha channel.
    hidden function headerIsPainted() as Boolean {
        return mHeaderBg >= 0 && mHeaderBg <= 0xFFFFFF;
    }


    //! Chainrings on the left, sprockets on the right, both as a ramp of bars with
    //! the engaged one picked out, and the ratio written across the top.
    //!
    //! The ramps are schematic: the drivetrain broadcasts the engaged sprocket's
    //! teeth and the number of positions, never the size of every sprocket, so the
    //! steps are even. Chainrings descend to the right and sprockets climb, both
    //! fixed whichever way the indices happen to run, so the shape of the picture
    //! never changes and only the highlight moves.
    hidden function drawGearMap(dc as Dc, x as Number, y as Number, w as Number, h as Number) as Void {
        var m = mMetrics;
        var ringTeeth = Config.CHAINRING_TEETH;
        var cogTeeth = Config.CASSETTE_TEETH;
        var rings = (ringTeeth.size() > 0)
            ? ringTeeth.size() : count(m.frontMax, Config.CHAINRINGS_FALLBACK, 1, 3);
        var cogs = (cogTeeth.size() > 0)
            ? cogTeeth.size() : count(m.rearMax, Config.SPROCKETS_FALLBACK, 5, 14);

        var pad = Config.PAD;
        var innerW = w - (2 * pad);
        var innerH = h - (2 * pad);
        if (innerW < 20 || innerH < 12) {
            return;
        }

        var split = innerW * 0.05;
        var slot = (innerW - split) / (rings + cogs);
        var barW = (slot * 0.66).toNumber();
        if (barW < 2) { barW = 2; }
        var floorY = y + h - pad;

        var front = seat(m.frontGear, rings, Config.FRONT_INDEX_1_IS_SMALLEST);
        var rear = seat(m.rearGear, cogs, Config.REAR_INDEX_1_IS_SMALLEST);

        // Chainrings run large to small, left to right - the mirror of the cassette
        // beside them, which is how a drivetrain looks from the side. `front` is
        // still counted from the small end, so the draw position is mirrored too.
        for (var i = 0; i < rings; i++) {
            var step = profile(ringTeeth, rings - 1 - i, rings);
            var tall = innerH * (Config.GEAR_RING_MIN
                + ((Config.GEAR_RING_MAX - Config.GEAR_RING_MIN) * step));
            drawBar(dc, (x + pad + (slot * i)).toNumber(), floorY, barW, tall.toNumber(),
                (rings - 1 - i) == front, y + pad);
        }
        // Sprockets: a long ramp, small cog to large, deliberately kept low so the
        // gear has room to be read above it.
        var spread = Config.GEAR_COG_MAX - Config.GEAR_COG_MIN;
        for (var j = 0; j < cogs; j++) {
            var high = innerH * (Config.GEAR_COG_MIN + (spread * profile(cogTeeth, j, cogs)));
            var left = x + pad + split + (slot * (rings + j));
            drawBar(dc, left.toNumber(), floorY, barW, high.toNumber(), j == rear, y + pad);
        }

        // The gear is read against the cassette, left aligned and reaching from the
        // top of the tile down to halfway up the tallest sprocket. It overlaps the
        // shallow end of the ramp, which is empty, and the depth buys a font size.
        var text = gearText(m, ringTeeth, cogTeeth, front, rear);
        var cassetteLeft = x + pad + split + (slot * rings);
        var cassetteW = slot * cogs;
        var textH = (innerH * (1.0 - (Config.GEAR_COG_MAX / 2.0))
            * Config.GEAR_TEXT_SCALE).toNumber();
        var font = pickFont(dc, text, cassetteW.toNumber(), textH);
        dc.setColor(Config.VALUE_FG, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cassetteLeft.toNumber(), y + pad + (textH / 2),
            font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Where a bar sits between the shortest and the tallest, 0.0 to 1.0. With a
    //! tooth list that is the real spread of the cassette; without one it falls
    //! back to an even staircase.
    hidden function profile(teeth as Array<Number>, at as Number, total as Number) as Float {
        if (total < 2) {
            return 1.0;
        }
        if (teeth.size() == total) {
            var low = teeth[0];
            var high = teeth[total - 1];
            if (high > low) {
                return (teeth[at] - low) * 1.0 / (high - low);
            }
        }
        return 1.0 * at / (total - 1);
    }

    //! The engaged gear as teeth. Prefers what the drivetrain broadcasts, and
    //! falls back to the configured list - which is the only way to get the rear
    //! number on a groupset that broadcasts zero for it.
    hidden function gearText(m as Metrics, ringTeeth as Array<Number>, cogTeeth as Array<Number>,
                             front as Number, rear as Number) as String {
        var f = teethAt(m.frontTeeth, ringTeeth, front);
        var r = teethAt(m.rearTeeth, cogTeeth, rear);
        if (f == null && r == null) {
            return Fields.NO_DATA;
        }
        // Only the known halves are joined. Padding a missing one out to "--"
        // reads as "52---", which looks like a fault rather than a missing value.
        if (f == null) {
            return r.format("%d");
        }
        if (r == null) {
            return f.format("%d");
        }
        return f.format("%d") + "-" + r.format("%d");
    }

    //! Zero means "not broadcast" here, not a real sprocket.
    hidden function teethAt(broadcast as Number?, teeth as Array<Number>, at as Number) as Number? {
        if (broadcast != null && broadcast > 0) {
            return broadcast;
        }
        if (at >= 0 && at < teeth.size()) {
            return teeth[at];
        }
        return null;
    }

    //! One bar, plus the arrowhead over it when it is the engaged one.
    //!
    //! The marker is drawn here rather than in a function of its own, and the
    //! whole tile is painted from drawTile rather than through a wrapper, because
    //! this is the deepest call chain in the field and it ran out of stack: the
    //! Edge reported a Stack Overflow Error against the innermost draw call, and
    //! only once a gear was engaged, since that is the only time the marker runs.
    //!
    //! The arrowhead is rows rather than Dc.fillPolygon, which is documented since
    //! API 1.0.0 and listed in the device's own API, yet throws when invoked here.
    hidden function drawBar(dc as Dc, left as Number, floorY as Number, width as Number, height as Number, on as Boolean, ceiling as Number) as Void {
        var color = on ? Config.GEAR_HILITE : Config.GEAR_BAR;
        dc.setColor(color, color);
        var top = floorY - height;
        dc.fillRectangle(left, top, width, height);
        if (!on) {
            return;
        }

        var point = (width < 3) ? 3 : width;
        var tipY = top - Config.GEAR_MARK_GAP;
        var baseY = tipY - point;
        if (baseY < ceiling) {
            return;
        }
        var cx = left + (width / 2);
        for (var row = 0; row < point; row++) {
            var half = width - ((width * row) / point);
            if (half < 1) { half = 1; }
            dc.fillRectangle(cx - half, baseY + row, half * 2, 1);
        }
    }

    //! Where a 1-based index sits when the positions are counted from the smallest
    //! upwards. Returns -1 when nothing is engaged, so no bar is highlighted.
    hidden function seat(index as Number?, total as Number, oneIsSmallest as Boolean) as Number {
        if (index == null || index < 1 || index > total) {
            return -1;
        }
        return oneIsSmallest ? index - 1 : total - index;
    }

    hidden function count(reported as Number?, fallback as Number, low as Number, high as Number) as Number {
        var n = (reported != null) ? reported : fallback;
        if (n < low) { n = low; }
        if (n > high) { n = high; }
        return n;
    }

    //! Stripes of the neighbouring zones' colours, creeping in from whichever side
    //! the value is drifting towards. Drawn over the fill but before the text, so
    //! the number stays on top of them.
    hidden function drawEdgeHints(dc as Dc, kind as Number, value as Numeric?, zone as Number?, x as Number, y as Number, w as Number, h as Number) as Void {
        if (zone == null) {
            return;
        }
        var widest = w * Config.HINT_MAX_WIDTH;

        var rising = Zones.upperHint(kind, value, zone);
        if (rising > 0) {
            var band = (widest * rising).toNumber();
            var color = Zones.colorFor(kind, zone + 1);
            if (band > 0 && color != null) {
                dc.setColor(color, color);
                dc.fillRectangle(x + w - band, y, band, h);
            }
        }

        var falling = Zones.lowerHint(kind, value, zone);
        if (falling > 0) {
            var band = (widest * falling).toNumber();
            var color = Zones.colorFor(kind, zone - 1);
            if (band > 0 && color != null) {
                dc.setColor(color, color);
                dc.fillRectangle(x, y, band, h);
            }
        }
    }

    //! Label, and for zoned tiles the zone badge, centred together as one group.
    hidden function drawHeader(dc as Dc, label as String, badge as String?, x as Number, y as Number, w as Number, h as Number) as Void {
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

        dc.setColor(mHeaderFg, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, start, mid, font, label, Graphics.TEXT_JUSTIFY_LEFT);

        if (badge != null) {
            // Without a header strip the badge sits on the zone fill, the same
            // surface the value does, so it takes the value's colour to stay legible.
            var badgeColor = headerIsPainted() ? Config.ZONE_FG : Config.VALUE_FG;
            dc.setColor(badgeColor, Graphics.COLOR_TRANSPARENT);
            drawCentered(dc, start + labelW + gap, mid, font, badge,
                Graphics.TEXT_JUSTIFY_LEFT);
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

            var justify = Graphics.TEXT_JUSTIFY_CENTER;
            var anchor = left + (cellW / 2);
            if (n > 1 && i == 0) {
                justify = Graphics.TEXT_JUSTIFY_LEFT;
                anchor = left + Config.PAD;
            } else if (n > 1 && i == n - 1) {
                justify = Graphics.TEXT_JUSTIFY_RIGHT;
                anchor = left + cellW - Config.PAD;
            }
            drawCentered(dc, anchor, mid, font, text, justify);
        }
    }

    //! Draws text whose glyphs, not whose font box, sit on the centre line.
    //!
    //! TEXT_JUSTIFY_VCENTER centres the font box. That box is padded on both sides
    //! of the visible glyphs: descender space below the baseline, and the gap
    //! between the cap line and the ascent line above. Neither is used by digits or
    //! capitals, and the descender is the larger of the two, so centring the box
    //! leaves the text sitting high. This works out where the glyph block actually
    //! is and puts its centre on the anchor.
    hidden function drawCentered(dc as Dc, x as Number, centerY as Number, font as FontDefinition, text as String, justify as Number) as Void {
        var ascent = Graphics.getFontAscent(font);
        var descent = Graphics.getFontDescent(font);
        var glyphH = ascent * capRatio(font);

        // Box centre sits (ascent - descent) / 2 above the baseline; the glyph
        // block's centre sits glyphH / 2 above it. Offset the anchor by the gap.
        var y = centerY - ((ascent - descent) / 2.0) + (glyphH / 2.0);
        dc.drawText(x, (y + 0.5).toNumber(), font, text, justify | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! The number fonts carry only digits and punctuation, and their glyphs fill
    //! more of the ascent than Roboto Condensed capitals do.
    hidden function capRatio(font as FontDefinition) as Float {
        for (var i = 0; i < mNumberFonts.size(); i++) {
            if (mNumberFonts[i] == font) {
                return Config.CAP_RATIO_NUMBER;
            }
        }
        return Config.CAP_RATIO_TEXT;
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
