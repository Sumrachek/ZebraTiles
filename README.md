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

| Token | Header | Value | Zone tint |
|---|---|---|---|
| `3s_pwr` | `3s PWR` | 3-second average power, W | power |
| `pwr` | `PWR` | instantaneous power, W | power |
| `lap_pwr` | `LAP PWR` | average power since the last lap, W | power |
| `hr` | `HR` | heart rate, bpm | heart rate |
| `cad` | `CAD` | cadence, rpm | — |
| `spd` | `SPD` | speed, km/h (one decimal below 10) | — |
| `grd` | `GRD %` | grade, % | — |
| `lap_time` | `LAP TIME` | time since the last lap, `mm:ss` or `h:mm:ss` | — |
| `day_time_24` | `TIME` | wall clock, 24 h | — |
| `dist` | `DIST` | activity distance, km | — |
| `temp_c` | `TEMP` | ambient temperature, °C | — |

Missing data renders as `--`.

### Changing the layout

Two ways, and the second wins when it is non-empty:

1. Edit `DEFAULT_LAYOUT` in `source/Config.mc` and rebuild.
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
  Zones.mc                zone lookup and zone -> colour mapping
  ZebraTilesView.mc       all drawing: rows, tiles, headers, status strip, font fitting
  ZebraTilesApp.mc        app entry point, reloads settings on change
resources/
  settings/properties.xml default values for the `ftp` and `layout` properties
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
  `drawCentered` reconstructs where the glyph block really is and centres that. It needs
  to know what fraction of the ascent the glyphs fill, and the device's two font families
  differ enough to need separate numbers: `Config.CAP_RATIO_NUMBER` for the DejaVu Fitness
  number fonts, `Config.CAP_RATIO_TEXT` for Roboto Condensed. Both were calibrated by
  screenshotting the simulator and comparing glyph bounds against tile bounds — redo that
  if the fonts or band heights change.
- Geometry is computed from `dc.getWidth()/getHeight()` on every draw, so the field
  degrades sensibly if it is placed in a half-screen slot instead of a full page.

### Adding a field

1. Add a constant to the `enum` in `Fields.mc`.
2. Map its token in `codeFor()`, its header in `labelFor()`, its formatting in `textFor()`.
3. If it should be zone-tinted, extend `zoneKind()` and `zoneInput()`.
4. If it needs new data, add a public variable to `Metrics` and populate it in `update()`.

---

## Derived metrics, and why

Three values in the mock are not available from the API and are computed here:

- **Grade** — `Activity.Info` has no grade field at all. It is differentiated over
  *distance* rather than time (20 m window, exponentially smoothed), so the value does not
  blow up when the bike stops.
- **Lap power / lap time** — data fields get no lap API, only an `onTimerLap()` callback.
  Power is accumulated while the timer is running and the accumulators reset on lap and on
  activity reset.
- **Temperature** — data fields are **not permitted to call `Sensor.getInfo()`**; doing so
  crashes the field with *"Symbol 'getInfo' not available to 'Data Field'"*. The device
  thermometer is read through `SensorHistory` instead, once every 10 seconds.

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
