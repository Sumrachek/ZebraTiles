# ZebraTiles

A Connect IQ **data field** for the Garmin Edge 530 that takes over a full data screen
and draws a grid of tiles. The tile arrangement is described by a few lines of text
rather than hard-coded; heart-rate and power tiles are tinted by training zone and
carry a zone badge (`z4`) in their header.

The layout in *Layout language* below is the one the original design mock specified,
and is what the field ships with.

- Target device: Edge 530 only (246 × 322, Connect IQ 3.3, buttons — no touch)
- App type: `datafield`, min API level 3.3.0
- Data field memory budget on this device: 128 KB

---

## Prerequisites

| What | Notes |
|---|---|
| JDK 17+ | `brew install --cask temurin@17`. The Monkey C compiler is a Java program. |
| Connect IQ SDK | Installed through the [SDK Manager](https://developer.garmin.com/connect-iq/sdk/). Currently built against **9.2.0**. |
| `edge530` device files | Tick the device inside the SDK Manager — the SDK alone is not enough. |
| A Garmin account | Only to sign in to the SDK Manager. No developer registration is needed for local work. |
| Developer key | Already in this repo at `developer_key`. Generate a new one with the VS Code command *Monkey C: Generate a Developer Key* if it is ever lost. |
| VS Code + *Monkey C* extension | Optional — the command line below is sufficient. |

Keep the checkout out of paths containing apostrophes; `monkeyc` fails on them with an
opaque error.

---

## Layout language

The screen is described by plain text. This is the built-in default:

```
3s_PWR
SPD HR
CAD GRD
LAP_PWR LAP_TIME
= day_time_24 dist temp_c =
```

Rules:

- One line per row. Rows split the screen height evenly.
- Whitespace-separated tokens are the tiles of that row; they split the row width evenly.
- A row wrapped in `=` is a **status strip**: shorter, no headers, no zone tint. Its first
  tile is left-aligned, its last right-aligned, anything between is centred.
- Token case is irrelevant. Rows may also be separated by `;` instead of a newline.
- An unknown token renders as its own name with a `?` value, so typos are visible rather
  than silent.

### Supported tokens

**[FIELDS.md](FIELDS.md) is the reference to open when you are putting a layout
together.** It lists all 87 tokens with what each one shows, grouped by power, heart rate,
cadence, speed and distance, time, elevation, navigation, drivetrain, weather and device
status, and it says which ones need a power meter, a loaded course, a paired phone or a
setting filled in.

Missing data renders as `--`, and an unrecognised token renders as its own name with a
`?` value, so typos are visible rather than silent.

### Changing the layout

Two ways, and the second wins when it is non-empty:

1. Edit `DEFAULT_LAYOUT` in `source/Config.mc` and rebuild. Tokens are listed in
   [FIELDS.md](FIELDS.md).
2. Set the **Layout** app setting from Garmin Connect Mobile. That input is single-line,
   so separate rows with `;`:
   `3s_pwr; spd hr; cad grd; lap_pwr lap_time; = day_time_24 dist temp_c =`

---

## Code map

```
build.sh                  compile; also the shared path resolution run.sh sources
run.sh                    compile, then load into the simulator
developer_key             signs the .prg; local only, never registered with Garmin
manifest.xml              app id, target device, permissions (UserProfile, SensorHistory)
monkey.jungle             build config
source/
  Config.mc               default layout, colours, zone palettes, geometry constants
  Spec.mc                 layout-text parser -> Row / Cell objects
  Fields.mc               token registry: code, header label, value formatting, zone kind
  Metrics.mc              per-second data collection and derived values
  Lap.mc                  per-lap accumulators, current and previous lap
  Zones.mc                zone lookup and zone -> colour mapping
  ZebraTilesView.mc       all drawing: rows, tiles, headers, status strip, font fitting
  ZebraTilesApp.mc        app entry point, reloads settings on change
resources/
  settings/properties.xml defaults for the `ftp`, cadence, header colour and layout settings
  settings/settings.xml   how those properties appear in Garmin Connect Mobile
  strings/strings.xml     app name and setting labels
  drawables/              launcher icon
bin/                      build output, ZebraTiles.prg
```

The interesting seams:

- **Parsing happens once**, at startup and on a settings change. Tokens are resolved to
  integer field codes there, so the 1 Hz draw path does no string matching.
- **`Metrics.update(info)`** is the only place that touches `Activity.Info`. Anything a
  tile needs must end up as a public field on `Metrics`.
- **Two font paths.** Chrome — tile headers, zone badges and the status strip — all use
  `Config.LABEL_FONT` (`FONT_SMALL`, 22 px here), falling back through `FONT_TINY` and
  `FONT_XTINY` only when a label is too wide for its tile. Values use
  `ZebraTilesView.pickFont`, which takes the largest font that fits; number fonts (digits,
  `:`, `.`, `-` only) are allowed ~15 % vertical overflow because they reserve descender
  space that digits never occupy.
- **All text goes through `drawCentered`**, never `dc.drawText` directly.
  `TEXT_JUSTIFY_VCENTER` centres the font *box*, which is padded on both sides of the
  visible glyphs: descender space below the baseline, and the gap from the cap line up to
  the ascent line. `FONT_NUMBER_HOT` reports a 56 px box, ascent 43 and descent 13, but
  draws digits only ~40 px tall — so box-centred digits sit about 4 px high in a tile.
  `drawCentered` reconstructs where the glyph block really is and centres that, scaling the
  ascent by `Config.CAP_RATIO_NUMBER` or `Config.CAP_RATIO_TEXT` depending on the font
  family. Those two constants are solved backwards from measurement, not taken from the
  typeface — `VCENTER` does not place the box exactly where the reported metrics say, so
  the pure ratio is about a pixel out. **Calibrate them from a screenshot the Edge takes of
  itself** (Settings > System > Display > Screen Capture): the device renders without
  anti-aliasing, so glyph bounds are exact. The simulator anti-aliases and will send you
  wrong.
- Geometry is computed from `dc.getWidth()/getHeight()` on every draw, so the field
  degrades sensibly if it is placed in a half-screen slot instead of a full page.

### Adding a field

1. Add a constant to the `enum` in `Fields.mc`.
2. Map its token in `codeFor()`, its header in `labelFor()`, its formatting in `textFor()`.
3. If it should be zone-tinted, extend `zoneKind()` and `zoneInput()`.
4. If it needs new data, add a public variable to `Metrics` and populate it in `update()`.

---

## Derived metrics, and why

Connect IQ hands over about half of what a native Garmin data screen shows. The rest is
reconstructed in `Metrics`:

- **Grade** — `Activity.Info` has no grade field at all. It is differentiated over
  *distance* rather than time (20 m window, exponentially smoothed), so the value does not
  blow up when the bike stops.
- **VAM** — climb rate over a 30 s altitude window, so flat ground reads zero instead of
  jittering with every barometric wobble.
- **Everything per-lap** — data fields get no lap API, only an `onTimerLap()` callback.
  `Lap` tallies power, heart rate, cadence, distance, ascent and descent, and the previous
  lap is kept whole so the `LAST_*` fields have something to show.
- **Rolling power** — one 30-slot ring buffer serves the 3 / 5 / 10 / 30 s averages.
- **NP, IF, TSS, kJ** — normalized power is the fourth-power mean of the 30 s rolling
  average. The running total is scaled down by 100 W so it stays inside a Float; IF and
  TSS follow from it and the FTP setting.
- **Temperature** — data fields are **not permitted to call `Sensor.getInfo()`**; doing so
  crashes the field with *"Symbol 'getInfo' not available to 'Data Field'"*. The device
  thermometer is read through `SensorHistory` instead, once every 10 seconds.
- **Battery and weather** — polled on their own timers rather than at 1 Hz.

### Optional API members need `has`

The SDK documents members that a Connect IQ 3.3 device does not actually carry, and
touching a missing symbol is a hard crash, not a null. `Weather.dewPoint` is documented
and absent on the Edge 530 — it took the field down on first run. Anything reached
through `Weather`, `SensorHistory` or `System.Stats` therefore goes through a `has` check.

## Zones

- **Heart rate zones are read from the device profile** via
  `UserProfile.getHeartRateZones()` — these are the user's real Garmin zones.
- **Power zones cannot be read on this device.** `UserProfile.getPowerZones()` requires
  API level 5.2.2 and the Edge 530 caps out at 3.3. Power zones are therefore derived from
  an **FTP app setting** (default 200 W) using the standard Coggan boundaries
  55 / 75 / 90 / 105 / 120 / 150 % of FTP. Set your FTP in Garmin Connect Mobile or the
  simulator's settings editor, or the tints will be wrong.

Palettes live in `Config.mc`: 5 heart-rate zones and 7 power zones, grey → blue → green →
yellow → orange → red.

The header strip's own two colours — background and label text — are app settings, typed
as `RRGGBB` hex (a leading `#` is accepted). Connect IQ settings have no colour type, only
lists and text, and a list would have boxed you into whatever swatches were picked here.
`Config.HEADER_BG` and `Config.HEADER_FG` are the defaults, used whenever the setting is
empty or will not parse.

**Setting `HEADER_BG` to `Config.HEADER_BG_NONE` switches the header off entirely.** The
zone fill then runs the full height of the tile with the label riding on top of it, and
rows are separated by a one-pixel rule in `Config.HEADER_RULE` rather than by a strip of
contrasting background. The top row gets no rule, having nothing above it to be separated
from. Any value outside the 24-bit colour range triggers this, `Graphics.COLOR_TRANSPARENT`
included — Monkey C colours carry no alpha, so "transparent" has to be a sentinel.

One layout tweak comes with the mode: the value is raised by
`Config.HEADERLESS_VALUE_LIFT`. With no strip the tile reads as a single block, and a value
centred in the band below the label sits closer to the bottom edge than to the label —
measured on device, 12.6 px of air above the digits against 4.0 px below. The lift evens
that out.

The zone badge follows suit automatically: with no strip beneath it, it sits on the same
surface as the value, so it switches from `ZONE_FG` to `VALUE_FG`. `HEADER_FG` does not —
it stays whatever you set, so a light grey tuned for a dark strip will nearly vanish
against the zone colour. Expect to darken it in this mode.
This mode is reachable only from `Config`: the colour setting parses six hex digits, which
cannot express the sentinel.

**Zone edges announce themselves.** As a value drifts towards the edge of its zone, a
stripe of the neighbouring zone's colour creeps in from that side of the tile — right for
the upper threshold, left for the lower one. It starts once the value is within
`Config.HINT_TRIGGER` of the edge (10 % of the zone's span) and grows linearly to
`Config.HINT_MAX_WIDTH` of the tile (20 %) at the threshold itself. The top and bottom
zones have nothing beyond them, so they get no stripe on that side; the open-ended top
zone borrows the zone below it for the span it lacks. Stripes are drawn over the fill but
before the value, so the number stays legible on top.

**Cadence is tinted too, but on a different kind of scale.** Power and heart rate are
monotonic — more is harder — so an intensity ramp reads correctly. Cadence is not: low
means grinding, high means spinning out, and the good place is in between. It therefore
gets a diverging three-colour palette against a target range from the app settings
(85–95 rpm by default): blue below, green inside, orange above. Those bands are not
numbered zones, so those tiles carry no `z` badge. A coasting cadence of zero falls in the
low band and is left to do so.

Only instantaneous fields are tinted — current and rolling power, heart rate, cadence, the
zone numbers, and the percentages (`% FTP`, `% MAX HR`, `% HRR`, `W/KG`), which are just
the current value measured against a reference. Averages, maxima, lap and whole-ride
figures render on the plain background, because a colour there reads as present effort and
would be misleading.

---

## Building and running

Two scripts in the repo root do the usual work:

```sh
./build.sh              # debug build, warnings and strict type checking on
./build.sh --release    # optimised build, for sideloading onto the device
./run.sh                # build, then load into the simulator
```

`run.sh` starts the simulator if it is not up yet and **reuses it if it is**, so a rebuild
lands in the running simulator and your simulated activity data survives. It waits for the
simulator to start listening on port 1234 before sideloading, then stays attached printing
runtime errors and stack traces — Ctrl-C detaches and leaves the simulator running. Any
argument is forwarded to `build.sh`.

Both scripts find the SDK through `current-sdk.cfg`, the file the SDK Manager writes to
record the active SDK, and fail with a specific message if the SDK, the `edge530` device
files or the developer key are missing. Override with `CIQ_SDK`, `CIQ_DEVICE` or `CIQ_KEY`.

### Doing it by hand

```fish
set SDK ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-*
$SDK/bin/monkeyc -d edge530 -f monkey.jungle -o bin/ZebraTiles.prg -y developer_key
```

(In bash/zsh use `SDK=$(echo ~/Library/...-9.2.0-*)`.)

Useful `monkeyc` flags:

- `-w` — enable warnings
- `-l 2` — stricter type checking; the project is clean at this level, keep it that way
- `-r` — build a release (optimised, no debug symbols) `.prg` for sideloading
- `-e` — build a `.iq` bundle for store submission (not needed for personal use)

In VS Code the same thing is *Monkey C: Build for Device* / *Run App*.

Three warnings are expected and harmless: no declared languages, a launcher icon that gets
scaled from 24×24 to the device's 35×35, and an unreachable `return` in
`Metrics.updateTemperature()` — the compiler can prove `getTemperatureHistory()` is
non-null on this device, but the null check is kept as it is part of the documented API.

The simulator equivalent, which is what `run.sh` automates:

```fish
$SDK/bin/connectiq                                   # start the simulator, once
$SDK/bin/monkeydo bin/ZebraTiles.prg edge530         # load the field into it
```

`monkeydo` is where permission errors and null dereferences surface — keep an eye on it.

## Working in the simulator

A freshly launched field shows `--` everywhere because there is no activity data. Two
things to find in the simulator's menus:

- the **activity data simulator**, which can either inject individual values or replay a
  real `.fit` file. Playback is by far the best way to check the layout against plausible
  numbers, including how wide the values actually get.
- the **application settings editor**, which lets you change `ftp` and `layout` without
  rebuilding.

## Installing on the Edge 530

1. Build with `-r`.
2. Connect the Edge over USB; it mounts as a `GARMIN` volume.
3. Copy `bin/ZebraTiles.prg` into `GARMIN/Apps/` on the device.
4. Eject, disconnect, and let the Edge restart.
5. On the device: *Activity Profiles → \<profile\> → Data Screens → Add Data Screen →
   Single Field → Connect IQ → ZebraTiles*.

No Garmin account, store submission or app review is involved — the device only checks
that the `.prg` is signed with some developer key, not with a registered one.

---

## Known limitations

- A data field is redrawn at 1 Hz, and only while its page is on screen. No animation.
- Data fields receive no button input, and the Edge 530 has no touchscreen, so the layout
  cannot be changed from the device during a ride.
- Cadence is drawn on a white background. The design mock shows it green; per the current
  rule only power and heart rate are zone-tinted. Adding a cadence band is a one-line
  change in `Fields.zoneKind()`.
- Font sizing is tuned to the Edge 530's actual metrics, measured in the simulator with
  `dc.getFontHeight()`: `XTINY 13, TINY 20, SMALL 22, MEDIUM 26, LARGE 41, NUMBER_MILD 36,
  NUMBER_MEDIUM 42, NUMBER_HOT 56, NUMBER_THAI_HOT 70`. `STATUS_H` and `HEADER_H` are both
  22, exactly `LABEL_FONT`'s height. Porting to another device means re-measuring these.
