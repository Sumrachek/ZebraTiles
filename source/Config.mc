import Toybox.Graphics;
import Toybox.Lang;

//! Statically configured look and defaults.
module Config {

    //! The screen description. One line per row, tokens separated by spaces.
    //! A row wrapped in "=" is drawn as a compact status strip (no headers).
    //! Can be overridden at runtime by the "layout" app setting.
    const DEFAULT_LAYOUT =
        "3s_PWR\n" +
        "SPD HR\n" +
        "CAD GRD\n" +
        "LAP_PWR LAP_TIME\n" +
        "= day_time_24 dist temp_c =";

    const DEFAULT_FTP = 200;

    // Chrome
    const HEADER_BG = 0x000000;
    const HEADER_FG = 0xAAAAAA;
    const ZONE_FG = 0xFFFFFF;
    const VALUE_BG = 0xFFFFFF;
    const VALUE_FG = 0x000000;
    const STATUS_FG = 0xFFFFFF;

    //! One size for every piece of chrome: tile headers, zone badges and the
    //! status strip. Roboto Condensed 22 px on the Edge 530, which is what
    //! Garmin's own data field labels use. FONT_XTINY here is only 13 px.
    const LABEL_FONT = Graphics.FONT_SMALL;

    //! Height of the visible glyph block - capitals and digits, cap line to
    //! baseline - as a fraction of the font's reported ascent. The gap between the
    //! two is what makes box-centred text look too high, and the device's two font
    //! families differ enough that one number will not do: DejaVu Fitness for the
    //! number fonts, Roboto Condensed for everything else.
    //!
    //! Calibrated against device renders rather than taken from the typeface, so
    //! these also absorb the half-pixel rounding of the band centres. Re-measure by
    //! screenshotting the simulator and comparing glyph bounds to tile bounds.
    const CAP_RATIO_NUMBER = 0.87;
    const CAP_RATIO_TEXT = 0.69;

    // Geometry. STATUS_H and HEADER_H are both exactly LABEL_FONT's height.
    const STATUS_H = 22;
    const HEADER_H = 22;
    const PAD = 3;
    const LABEL_GAP = 7;

    // Garmin-style zone colors: Z1 grey, then blue / green / yellow / orange / red.
    const HR_COLORS = [0x9A9A9A, 0x3399FF, 0x55CC55, 0xFF9900, 0xFF3322];
    const PWR_COLORS = [0x9A9A9A, 0x3399FF, 0x55CC55, 0xFFCC33, 0xFF9900, 0xFF3322, 0xCC0055];

    // Coggan zone edges as a fraction of FTP (Z2..Z7 lower bounds).
    const PWR_PCT = [0.55, 0.75, 0.90, 1.05, 1.20, 1.50];
}
