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
        "CAD ALT\n" +
        "LAP_PWR LAP_TIME\n" +
        "= day_time_24 dist temp_c =";

    const DEFAULT_FTP = 200;

    // Chrome
    const HEADER_BG = 0x424242;
    const HEADER_FG = 0xBDBDBD;
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
    //! These are calibration constants, not typography. The ratio of glyph height
    //! to ascent would be 39/43 and 15/17, but feeding those in still leaves the
    //! text a pixel high: TEXT_JUSTIFY_VCENTER does not place the box exactly
    //! where the reported metrics say it should. So the values below are solved
    //! backwards from where the ink has to land, and they absorb that error along
    //! with the half-pixel rounding of the band centres.
    //!
    //! Measured from a screenshot the Edge took of itself - Settings > System >
    //! Display > Screen Capture, files land in Garmin/Screenshots. The device
    //! draws without anti-aliasing, so glyph bounds come out exact. Never
    //! calibrate against the simulator: it anti-aliases, which pads the measured
    //! bounds and cost this project two wrong guesses.
    //!
    //! To redo it: screenshot, find each band, find the first and last row of ink
    //! inside it, and solve for the ratio that centres that ink.
    //!
    //!   numbers  ascent 43, ink 39 tall in a 53 px band -> 7 px clear each side
    //!   text     ascent 17, ink 15 tall in a 22 px band -> 3 above, 4 below,
    //!            since 7 px of slack will not split evenly
    const CAP_RATIO_NUMBER = 0.97;
    const CAP_RATIO_TEXT = 0.88;


    //! Edge hints: as a value drifts towards the edge of its zone, a stripe of the
    //! neighbouring zone's colour creeps in from that side of the tile - right for
    //! the upper threshold, left for the lower one. A warning that you are about
    //! to change zone, readable without reading the number.
    const HINT_TRIGGER = 0.10;    //!< Starts this far into the zone, as a fraction of its span.
    const HINT_MAX_WIDTH = 0.20;  //!< Width at the threshold itself, as a fraction of the tile.

    // Geometry. STATUS_H and HEADER_H are both exactly LABEL_FONT's height.
    const STATUS_H = 22;
    const HEADER_H = 22;
    const PAD = 3;
    const LABEL_GAP = 7;

    // Garmin-style zone colors: Z1 grey, then blue / green / yellow / orange / red.
    const HR_COLORS = [0x9A9A9A, 0x3399FF, 0x55CC55, 0xFF9900, 0xFF3322];
    const PWR_COLORS = [0x9A9A9A, 0x3399FF, 0x55CC55, 0xFFCC33, 0xFF9900, 0xFF3322, 0xCC0055];

    // Derived metrics
    const PWR_WINDOW = 30;       //!< Longest rolling power window, seconds. Also the NP window.
    const VAM_WINDOW = 30;       //!< Climb rate is measured over this many seconds.
    const GRADE_SPAN_M = 20.0;   //!< Grade is differentiated over this much distance.
    const GRADE_SMOOTHING = 0.4;

    // How often the expensive lookups run, in seconds
    const TEMP_PERIOD = 10;
    const STATS_PERIOD = 10;
    const WEATHER_PERIOD = 30;

    //! Cadence is the one scale here that is not monotonic: too low means
    //! grinding, too high means spinning out, and the good place is in between.
    //! So it gets a diverging palette - below the range, inside, above - rather
    //! than the intensity ramp the power and heart rate zones use.
    const CAD_COLORS = [0x3399FF, 0x55CC55, 0xFF9900];
    const DEFAULT_CAD_MIN = 85;
    const DEFAULT_CAD_MAX = 95;

    // Coggan zone edges as a fraction of FTP (Z2..Z7 lower bounds).
    const PWR_PCT = [0.55, 0.75, 0.90, 1.05, 1.20, 1.50];
}
