# Connect IQ Store listing

Text to paste into the store portal. Each block below is plain text, because the store
does not render Markdown.

---

## App name

ZebraTiles

## Short description / tagline

A full-screen tile grid for the Edge 530, with zone-coloured power, heart rate and cadence.

## Description

```
ZebraTiles turns one data screen of your Edge 530 into a grid of tiles that you lay out yourself, and colours the important ones by training zone so you can read your effort at a glance.

ZONE COLOURS
- Power and heart rate tiles are filled with the colour of your current zone and carry a zone badge (z1, z2, ...).
- Heart rate zones come from your Garmin profile. Power zones are calculated from the FTP you enter in the settings, because the Edge 530 does not share its power zones with apps.
- As you approach the next zone, a stripe of its colour slides in from the edge of the tile, so you see a zone change coming before it happens.
- Cadence is coloured against a target range you choose: blue below it, green inside it, orange above it.
- Averages, maximums and lap figures stay on a plain background, so a colour always means what you are doing right now.

YOUR OWN LAYOUT
Pick from 87 fields and arrange them in rows by typing a short line in the app settings in Garmin Connect, for example:
3s_pwr; spd hr; cad grd; lap_pwr lap_time; = day_time_24 dist temp_c =
- Rows are separated by ";" and fields within a row by spaces.
- A row wrapped in "=" becomes a slim status strip.
- Leave the setting empty to use the built-in layout.
The full list of fields is in the guide (link below).

FIELDS INCLUDE
- Power: 3/5/10/30 s power, average, max, lap, NP, IF, TSS, W/kg, kJ, power zone.
- Heart rate: current, average, max, lap, % of max, % of reserve, zone, time in zone.
- Cadence, speed, distance and per-lap versions of each.
- Grade (with a tilted coloured wedge behind the number), VAM, ascent, descent, altitude.
- Navigation: distance and time to destination, ETA, next point, off-course distance.
- Electronic shifting: gears, gear ratio, and a drawn gear map.
- Weather from your phone, the Edge's own temperature, battery, GPS accuracy and more.

GOOD TO KNOW
- Units are metric: km/h, km, metres, degrees C.
- A field with no data shows "--". For example, power fields show "--" with no power meter paired, and navigation fields show "--" with no course loaded.
- A mistyped field name shows the name with "?", so typos are easy to spot.
- The temperature field reads the Edge's built-in thermometer every 5 minutes.
- Weather fields need a connected phone.
- Gear fields need electronic shifting that broadcasts over ANT+.

SETTINGS (in Garmin Connect)
- FTP: the basis for power zones.
- Cadence target, low and high.
- Header background and text colour: hex, e.g. 2B2B2B.
- Layout: see above.

Guide and field list: https://github.com/Sumrachek/ZebraTiles/blob/main/FIELDS.md
```

## What's new (1.0.0)

```
First release.
```

## Permissions: why each one is needed

The store shows users a permission list at install time. Use this text where the
description or a reviewer asks why each permission is needed.

```
- Background: reads the Edge's built-in thermometer every 5 minutes. Data fields are not allowed to read it directly, so a small background task takes the reading.
- Sensor: the thermometer reading above.
- User Profile: your heart rate zones, resting heart rate (for % of HR reserve) and weight (for W/kg).

ZebraTiles does not connect to the internet and does not collect, store or send any personal data. Everything stays on your Edge.
```

## Support

- Support URL: https://github.com/Sumrachek/ZebraTiles/issues
- Source code: https://github.com/Sumrachek/ZebraTiles

## Category

Data fields (cycling)

## Devices

Edge 530 only, for 1.0.0.

## Price

Free.

## Assets

Everything uploaded to the store is under 150 KB with no metadata beyond JFIF, which
are the store's limits.

- `icon.svg`: 1024×1024 master of the launcher icon.
- `zebra-icon-128.png`: store icon.
- `screenshot-1.png`, `screenshot-2.png`: simulator captures with the window frame cropped away.
- `zebra-promoter-1440x720.jpg`, `zebra-promoter-bigger-2.jpg` (1024×1024),
  `zebra-promoter-big-500.jpg`: promo art.
- `originals/` holds the uncompressed sources and is not committed: one of them carries C2PA
  metadata and is 1.2 MB.
