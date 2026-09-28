#!/usr/bin/env bash
#
# Copies a release build to a connected Edge and keeps the debug map that goes
# with it.
#
# Two reasons this exists rather than a plain cp. macOS writes an AppleDouble
# sidecar (._ZebraTiles.prg) onto the FAT volume, which the Edge then tries to
# load as an app and logs "Signature check failed" about, every boot, forever.
# COPYFILE_DISABLE stops that. And a crash log is unreadable without the exact
# .debug.xml of the build that crashed, which the next build overwrites, so a
# copy is kept here under the installed build's checksum.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VOLUME="${GARMIN_VOLUME:-/Volumes/GARMIN}"
PRG="$ROOT/bin/ZebraTiles.prg"
MAP="$ROOT/bin/ZebraTiles.prg.debug.xml"
ARCHIVE="$ROOT/bin/installed"

[[ -d "$VOLUME" ]] || { echo "error: no Edge mounted at $VOLUME" >&2; exit 1; }
"$ROOT/build.sh" --release

sum="$(md5 -q "$PRG")"
mkdir -p "$ARCHIVE"
cp "$MAP" "$ARCHIVE/$sum.debug.xml"

COPYFILE_DISABLE=1 cp "$PRG" "$VOLUME/Garmin/Apps/ZebraTiles.prg"
find "$VOLUME/Garmin/Apps" -name "._*" -delete 2>/dev/null || true

echo "installed $sum"
echo "debug map kept at bin/installed/$sum.debug.xml"
echo "now eject: diskutil eject $VOLUME"
