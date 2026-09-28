#!/usr/bin/env python3
"""Refresh the data the layout builder is built on, from the source of truth.

tools/layout-builder.html carries a `const DATA = {...}` line holding every
token, its tile header, whether it is zone-tinted and the zone palettes. Those
all exist in the Monkey C source already, so retyping them into the page would
guarantee drift. This reads them back out and rewrites that one line, leaving
the page's markup, styles and script untouched.

    ./tools/build-layout-builder.py            rewrite the page
    ./tools/build-layout-builder.py --check    report drift, change nothing

Run it after adding a field or changing a palette. It also cross-checks the two
places a token has to appear - FIELDS.md and Fields.mc - and complains when one
of them is missing it, which is the mistake that is otherwise invisible until
the field renders as `?` on the bike.

The sample values below are the one thing not derived from source: they exist
only so the preview shows plausible numbers.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIELDS_MC = ROOT / "source" / "Fields.mc"
CONFIG_MC = ROOT / "source" / "Config.mc"
FIELDS_MD = ROOT / "FIELDS.md"
PAGE = ROOT / "tools" / "layout-builder.html"

SAMPLES = {
    "PWR": "212", "3S_PWR": "204", "5S_PWR": "201", "10S_PWR": "197", "30S_PWR": "193",
    "AVG_PWR": "186", "MAX_PWR": "642", "LAP_PWR": "198", "LAST_LAP_PWR": "205",
    "NP": "201", "IF": "1.01", "TSS": "64", "PWR_PCT_FTP": "102%", "W_KG": "2.9",
    "PWR_ZONE": "4", "KJ": "1240",
    "HR": "148", "AVG_HR": "142", "MAX_HR": "176", "LAP_HR": "145", "LAST_LAP_HR": "139",
    "HR_PCT_MAX": "84%", "HR_PCT_RESERVE": "71%", "HR_ZONE": "2", "TIME_IN_ZONE": "04:12",
    "CAD": "91", "AVG_CAD": "87", "MAX_CAD": "118", "LAP_CAD": "89", "LAST_LAP_CAD": "92",
    "SPD": "31", "AVG_SPD": "28", "MAX_SPD": "64", "LAP_SPD": "29", "LAST_LAP_SPD": "30",
    "DIST": "42.7", "LAP_DIST": "8.4", "LAST_LAP_DIST": "9.1",
    "DAY_TIME_24": "19:41", "DAY_TIME_12": "7:41", "TIMER": "1:24:07",
    "ELAPSED": "1:31:52", "STOPPED_TIME": "07:45", "LAP_TIME": "14:22",
    "LAST_LAP_TIME": "12:58", "LAP_NUMBER": "4",
    "ALT": "412", "ASCENT": "684", "DESCENT": "611", "LAP_ASCENT": "142",
    "LAP_DESCENT": "98", "GRD": "-3", "VAM": "640",
    "DIST_TO_DEST": "18.6", "TIME_TO_DEST": "38:20", "ETA": "20:15", "ALT_AT_DEST": "96",
    "DIST_TO_NEXT": "2.4", "ALT_AT_NEXT": "501", "NEXT_POINT": "Col", "DEST_NAME": "Home",
    "OFF_COURSE": "12", "BEARING": "142°", "HEADING": "138°",
    "TRACK": "140°", "BEARING_START": "318°",
    "GEAR_FRONT": "2", "GEAR_REAR": "7", "GEARS": "50/17", "GEAR_RATIO": "2.94",
    "GEAR_MAP": "52-15",
    "WEATHER_TEMP": "16°C", "FEELS_LIKE": "14°C", "WIND_SPD": "12",
    "WIND_DIR": "290°", "WIND_REL": "HEAD", "HUMIDITY": "62%",
    "PRECIP_CHANCE": "10%", "DEW_POINT": "--", "UV_INDEX": "3",
    "TEMP_C": "18°C", "PRESSURE": "1013", "SEA_PRESSURE": "1019", "BATTERY": "82%",
    "BATTERY_HOURS": "14h", "GPS_ACCURACY": "GOOD", "CALORIES": "980",
    "TRAINING_EFFECT": "3.4",
}

ZONE_NAMES = {"Z_PWR": "pwr", "Z_HR": "hr", "Z_CAD": "cad"}


def read_fields_mc():
    """token -> enum name, enum name -> header, enum name -> zone kind."""
    src = FIELDS_MC.read_text(encoding="utf-8")

    tok2code = dict(re.findall(
        r'token\.equals\("([^"]+)"\)\)\s*\{\s*return\s+(F_[A-Z0-9_]+);', src))
    code2label = dict(re.findall(
        r'case\s+(F_[A-Z0-9_]+):\s*return\s+"([^"]*)";', src))

    # zoneKind() groups fall-through cases onto a single return, so collect the
    # pending labels and attach them when the return arrives.
    kinds, pending = {}, []
    block = re.search(r"function zoneKind.*?\n    \}", src, re.S)
    if block is None:
        sys.exit("could not find zoneKind() in Fields.mc")
    for line in block.group(0).splitlines():
        case = re.match(r"\s*case\s+(F_[A-Z0-9_]+):", line)
        ret = re.match(r"\s*return\s+(Z_[A-Z]+);", line)
        if case:
            pending.append(case.group(1))
        elif ret:
            for name in pending:
                kinds[name] = ret.group(1)
            pending = []
    return tok2code, code2label, kinds


def read_palettes():
    cfg = CONFIG_MC.read_text(encoding="utf-8")

    def array(name):
        found = re.search(name + r"\s*=\s*\[([^\]]+)\]", cfg)
        if found is None:
            sys.exit(f"could not find {name} in Config.mc")
        return [v.strip() for v in found.group(1).split(",")]

    return {"pwr": array("PWR_COLORS"), "hr": array("HR_COLORS"), "cad": array("CAD_COLORS")}


def read_groups(tok2code, code2label, kinds):
    """Groups and descriptions come from the table rows in FIELDS.md."""
    md = FIELDS_MD.read_text(encoding="utf-8").split("## Not available")[0]
    groups, current = [], None
    for line in md.splitlines():
        heading = re.match(r"^## (.+)$", line)
        if heading:
            current = {"name": heading.group(1).strip(), "items": []}
            groups.append(current)
            continue
        row = re.match(r"^\|\s*`([A-Z0-9_]+)`\s*\|\s*(.+?)\s*\|$", line)
        if row and current is not None:
            token = row.group(1)
            code = tok2code.get(token)
            current["items"].append({
                "t": token,
                "h": code2label.get(code, token),
                "d": row.group(2),
                "z": ZONE_NAMES.get(kinds.get(code, ""), ""),
                "v": SAMPLES.get(token, "--"),
            })
    return [g for g in groups if g["items"]]


def main(argv):
    check_only = "--check" in argv

    tok2code, code2label, kinds = read_fields_mc()
    groups = read_groups(tok2code, code2label, kinds)
    documented = [i["t"] for g in groups for i in g["items"]]

    problems = []
    for token in documented:
        if token not in tok2code:
            problems.append(f"{token} is in FIELDS.md but Fields.mc will not parse it")
    for token in tok2code:
        if token not in documented:
            problems.append(f"{token} is in Fields.mc but missing from FIELDS.md")
    for token in documented:
        if token not in SAMPLES:
            problems.append(f"{token} has no sample value; the preview will show --")

    data = {"groups": groups, "palette": read_palettes()}
    line = "const DATA = " + json.dumps(data, ensure_ascii=False) + ";"

    page = PAGE.read_text(encoding="utf-8")
    updated, count = re.subn(r"^const DATA = .*;$", lambda _: line, page, count=1, flags=re.M)
    if count != 1:
        sys.exit("could not find the `const DATA = ...;` line in layout-builder.html")

    print(f"{len(documented)} tokens across {len(groups)} groups")
    for problem in problems:
        print("  ! " + problem)

    if check_only:
        print("up to date" if updated == page else "OUT OF DATE - run without --check")
        return 1 if (problems or updated != page) else 0

    if updated == page:
        print("already up to date")
    else:
        PAGE.write_text(updated, encoding="utf-8")
        print(f"rewrote {PAGE.relative_to(ROOT)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
