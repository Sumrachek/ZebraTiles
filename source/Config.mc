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
