#!/usr/bin/env python3
"""Read the Edge's Connect IQ crash log and turn the stack into source lines.

A crash on the device is logged to Garmin/Apps/LOGS/CIQ_LOG.YML as a list of
program counters. Those only mean something against the .debug.xml of the exact
build that crashed, and every rebuild overwrites it - which is why
tools/install.sh keeps a copy per installed build under bin/installed/.

    ./tools/crashlog.py                    newest crash, newest archived map
    ./tools/crashlog.py --all              every crash in the log
    ./tools/crashlog.py --map <file>       resolve against a particular map

If the map does not belong to the build that crashed, the addresses still
resolve - to the wrong symbols. The giveaway is a call chain that could not
happen, so read the result as a chain and distrust it if it makes no sense.
"""

import bisect
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOG = pathlib.Path("/Volumes/GARMIN/Garmin/Apps/LOGS/CIQ_LOG.YML")
ARCHIVE = ROOT / "bin" / "installed"
CURRENT = ROOT / "bin" / "ZebraTiles.prg.debug.xml"


def load_map(path):
    """Sorted (pc, file, line, symbol) so a crash address can be bracketed."""
    text = path.read_text(encoding="utf-8", errors="replace")
    rows = []
    for entry in re.findall(r"<entry\s+([^>]*)/>", text):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', entry))
        if "pc" not in attrs:
            continue
        rows.append((
            int(attrs["pc"]),
            attrs.get("filename", "?").split("/")[-1],
            attrs.get("lineNum", "?"),
            f'{attrs.get("parent", "?")}.{attrs.get("symbol", "?")}',
        ))
    rows.sort()
    return rows


def read_crashes(path):
    """Every log entry that carries a stack, newest last."""
    blocks = path.read_text(encoding="utf-8", errors="replace").split("---")
    crashes = []
    for block in blocks:
        if "Stack:" not in block:
            continue
        crashes.append({
            "error": (re.search(r"Error:\s*'?([^'\n]+)", block) or [None, "?"])[1].strip(),
            "details": (re.search(r"Details:\s*'?([^'\n]+)", block) or [None, ""])[1].strip(),
            "time": (re.search(r"Time:\s*(\S+)", block) or [None, "?"])[1],
            "pcs": [int(pc, 16) for pc in re.findall(r"pc:\s*0x([0-9a-fA-F]+)", block)],
        })
    return crashes


def pick_map(explicit):
    if explicit:
        return pathlib.Path(explicit)
    archived = sorted(ARCHIVE.glob("*.debug.xml"), key=lambda p: p.stat().st_mtime)
    if archived:
        return archived[-1]
    if CURRENT.exists():
        print("! no archived map; falling back to the current build, which is only\n"
              "  right if nothing has been rebuilt since the crash", file=sys.stderr)
        return CURRENT
    sys.exit("no .debug.xml to resolve against; build first")


def main(argv):
    if not LOG.exists():
        sys.exit(f"no log at {LOG} - is the Edge mounted?")

    explicit = argv[argv.index("--map") + 1] if "--map" in argv else None
    mapping = load_map(pick_map(explicit))
    addresses = [row[0] for row in mapping]

    crashes = read_crashes(LOG)
    if not crashes:
        print("no crashes in the log")
        return 0
    if "--all" not in argv:
        crashes = crashes[-1:]

    for crash in crashes:
        print(f"\n{crash['error']}" + (f" - {crash['details']}" if crash["details"] else ""))
        print(f"{crash['time']}\n")
        for pc in crash["pcs"]:
            i = bisect.bisect_right(addresses, pc) - 1
            if 0 <= i < len(mapping):
                _, filename, line, symbol = mapping[i]
                print(f"  0x{pc:08x}  {symbol:44} {filename}:{line}")
            else:
                print(f"  0x{pc:08x}  (outside the map)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
