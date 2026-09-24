# Field reference

Every token you can put in a layout. Pick the ones you want, arrange them into rows, and
put the result in `DEFAULT_LAYOUT` in `source/Config.mc` or in the **Layout** app setting.
See [README](README.md#layout-language) for the layout syntax.

```
3s_PWR
SPD HR
CAD GRD
LAP_PWR LAP_TIME
= day_time_24 dist temp_c =
```

Case does not matter: `3s_pwr`, `3S_PWR` and `3s_Pwr` are the same token.

A few things worth knowing before you choose:

- **Units are metric.** Speed in km/h, distance in km, altitude and ascent in metres,
  temperature in °C.
- **A field with nothing to show renders `--`.** That is normal for navigation fields with
  no course loaded, or power fields with no power meter paired.
- **A token that does not exist renders its own name with a `?`**, so a typo is visible on
  the screen rather than silently blank.
- **Zone tinting applies to instantaneous fields only** — current and rolling power, heart
  rate, cadence, the zone numbers and the percentages. Averages, maxima and lap figures
  stay on the plain background, because a colour there would read as your present effort.
- **Fill in your FTP and your cadence range** in the app settings. The Edge cannot share
  its power zones with Connect IQ, so every power zone is derived from your FTP; the
  cadence colours come from the range.

---

## Power

Needs a power meter.

| Token | Shows |
|---|---|
| `PWR` | Current power, W |
| `3S_PWR` | Power averaged over the last 3 seconds, W |
| `5S_PWR` | Power averaged over the last 5 seconds, W |
| `10S_PWR` | Power averaged over the last 10 seconds, W |
| `30S_PWR` | Power averaged over the last 30 seconds, W |
| `AVG_PWR` | Average power for the whole ride, W |
| `MAX_PWR` | Highest power recorded this ride, W |
| `LAP_PWR` | Average power for the current lap, W |
| `LAST_LAP_PWR` | Average power for the previous lap, W |
| `NP` | Normalized power for the ride, W |
| `IF` | Intensity factor — normalized power divided by FTP |
| `TSS` | Training stress score accumulated this ride |
| `PWR_PCT_FTP` | Current power as a percentage of FTP |
| `W_KG` | Current power per kilogram, using the weight in your Garmin profile |
| `PWR_ZONE` | Current power zone, 1 to 7 |
| `KJ` | Total work done this ride, kilojoules |

## Heart rate

| Token | Shows |
|---|---|
| `HR` | Current heart rate, bpm |
| `AVG_HR` | Average heart rate for the whole ride, bpm |
| `MAX_HR` | Highest heart rate recorded this ride, bpm |
| `LAP_HR` | Average heart rate for the current lap, bpm |
| `LAST_LAP_HR` | Average heart rate for the previous lap, bpm |
| `HR_PCT_MAX` | Current heart rate as a percentage of your maximum |
| `HR_PCT_RESERVE` | Current heart rate as a percentage of heart rate reserve |
| `HR_ZONE` | Current heart rate zone, 1 to 5 |
| `TIME_IN_ZONE` | Time spent in the current zone, restarting whenever the zone changes |

`HR_PCT_RESERVE` needs a resting heart rate in your Garmin profile.

## Cadence

| Token | Shows |
|---|---|
| `CAD` | Current cadence, rpm |
| `AVG_CAD` | Average cadence for the whole ride, rpm |
| `MAX_CAD` | Highest cadence recorded this ride, rpm |
| `LAP_CAD` | Average cadence for the current lap, rpm |
| `LAST_LAP_CAD` | Average cadence for the previous lap, rpm |

`CAD` is tinted against a target range you set in the app settings, 85 to 95 rpm by
default: green inside the range, blue below it, orange above. Unlike power and heart rate
these are not numbered zones, so the tile carries no `z` badge. Coasting reads as blue,
since a cadence of zero really is below your range.

## Speed and distance

| Token | Shows |
|---|---|
| `SPD` | Current speed, km/h |
| `AVG_SPD` | Average speed for the whole ride, km/h |
| `MAX_SPD` | Highest speed recorded this ride, km/h |
| `LAP_SPD` | Average speed for the current lap, km/h |
| `LAST_LAP_SPD` | Average speed for the previous lap, km/h |
| `DIST` | Distance covered this ride, km |
| `LAP_DIST` | Distance covered in the current lap, km |
| `LAST_LAP_DIST` | Distance covered in the previous lap, km |

## Time

| Token | Shows |
|---|---|
| `DAY_TIME_24` | Time of day, 24-hour clock |
| `DAY_TIME_12` | Time of day, 12-hour clock |
| `TIMER` | Riding time, with stops excluded by auto-pause |
| `ELAPSED` | Total time since the ride started, stops included |
| `STOPPED_TIME` | Time spent stopped — elapsed time minus riding time |
| `LAP_TIME` | Time on the current lap |
| `LAST_LAP_TIME` | Time the previous lap took |
| `LAP_NUMBER` | Which lap you are on |

## Elevation

| Token | Shows |
|---|---|
| `ALT` | Current altitude, m |
| `ASCENT` | Total climbing this ride, m |
| `DESCENT` | Total descending this ride, m |
| `LAP_ASCENT` | Climbing on the current lap, m |
| `LAP_DESCENT` | Descending on the current lap, m |
| `GRD` | Current gradient, % |
| `VAM` | Climb rate, metres per hour |

`GRD` and `VAM` are worked out from altitude and distance, so both need a short run-up
before they settle: the gradient after about 20 m of riding, the climb rate after 30 s.

## Navigation

Blank unless you are following a course or navigating to a destination.

| Token | Shows |
|---|---|
| `DIST_TO_DEST` | Distance still to go, km |
| `TIME_TO_DEST` | Estimated time still to go |
| `ETA` | Estimated time of arrival, clock time |
| `ALT_AT_DEST` | Altitude at the destination, m |
| `DIST_TO_NEXT` | Distance to the next course point, km |
| `ALT_AT_NEXT` | Altitude at the next course point, m |
| `NEXT_POINT` | Name of the next course point |
| `DEST_NAME` | Name of the destination |
| `OFF_COURSE` | How far you are from the course, m |
| `BEARING` | Direction to the destination, degrees |
| `HEADING` | Direction you are facing, degrees |
| `TRACK` | Direction you are travelling, from GPS, degrees |
| `BEARING_START` | Direction back to where you started, degrees |

`TIME_TO_DEST` and `ETA` use your current speed, falling back to the ride average while
you are stopped, so they do not disappear at every traffic light.

## Drivetrain

Needs electronic shifting that broadcasts over ANT.

| Token | Shows |
|---|---|
| `GEAR_FRONT` | Front chainring position |
| `GEAR_REAR` | Rear sprocket position |
| `GEARS` | Both at once, as teeth if the groupset reports them, otherwise positions |
| `GEAR_RATIO` | Front teeth divided by rear teeth |

## Weather

Needs a phone connected; the figures are whatever was last downloaded.

| Token | Shows |
|---|---|
| `WEATHER_TEMP` | Air temperature from the forecast, °C |
| `FEELS_LIKE` | Wind chill or heat index, °C |
| `WIND_SPD` | Wind speed, km/h |
| `WIND_DIR` | Direction the wind blows from, degrees |
| `WIND_REL` | Wind relative to your heading — `HEAD`, `TAIL` or `CROSS` |
| `HUMIDITY` | Relative humidity, % |
| `PRECIP_CHANCE` | Chance of precipitation, % |
| `DEW_POINT` | Dew point, °C |
| `UV_INDEX` | UV index |

`DEW_POINT` always shows `--` on the Edge 530: the value is part of the Connect IQ
weather API but this device does not supply it.

## Device and environment

| Token | Shows |
|---|---|
| `TEMP_C` | Temperature from the Edge's own thermometer, °C |
| `PRESSURE` | Barometric pressure where you are, hPa |
| `SEA_PRESSURE` | Pressure corrected to sea level, hPa |
| `BATTERY` | Battery charge, % |
| `BATTERY_HOURS` | Rough estimate of battery life left, hours |
| `GPS_ACCURACY` | GPS quality — `GOOD`, `OK`, `POOR`, `OLD` or `NONE` |
| `CALORIES` | Calories burned this ride, kcal |
| `TRAINING_EFFECT` | Aerobic training effect score for this ride |

---

## Not available

Some things a native Garmin screen shows cannot be reached from a Connect IQ data field on
this device, so there are no tokens for them:

- **Pedalling dynamics** — left/right balance, torque effectiveness, pedal smoothness.
- **Di2 battery level**, and **radar** warnings about traffic behind you.
- **Sunrise and sunset** times.
- **Power zones from your Garmin profile.** Set your FTP in the app settings instead;
  reading the device's own power zones needs a newer Edge.
- **ClimbPro, training status, recovery time, stamina, Grit and Flow** — either absent from
  the API or exclusive to later Edge models.
