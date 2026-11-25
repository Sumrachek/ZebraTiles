#!/usr/bin/env bash
#
# Builds the ZebraTiles data field. A single .prg is built for one model, the
# Edge 530 unless CIQ_DEVICE names another (edge1040, edge540, ...); the .iq
# store bundle covers every model in manifest.xml.
#
#   ./build.sh              debug build, warnings and strict type checking on
#   ./build.sh --release    optimised build, for sideloading onto the device
#   ./build.sh -e           .iq store bundle (any extra monkeyc flag is passed through)
#
# Overridable: CIQ_SDK, CIQ_DEVICE, CIQ_KEY.
#
# run.sh sources this file to reuse the paths and the build function below.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT"
DEVICE="${CIQ_DEVICE:-edge530}"
KEY="${CIQ_KEY:-$ROOT/developer_key}"
PRG="$PROJECT/bin/ZebraTiles.prg"
IQ="$PROJECT/bin/ZebraTiles.iq"

die() {
    echo "error: $*" >&2
    exit 1
}

# The SDK Manager records the active SDK here; CIQ_SDK overrides it.
resolve_sdk() {
    if [[ -n "${CIQ_SDK:-}" ]]; then
        printf '%s' "${CIQ_SDK%/}"
        return
    fi
    local cfg="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
    [[ -f "$cfg" ]] || die "no active SDK: open the Connect IQ SDK Manager once, or set CIQ_SDK"
    local path
    # Strip line endings only - the path itself contains spaces.
    path="$(tr -d '\r\n' < "$cfg")"
    printf '%s' "${path%/}"
}

SDK="$(resolve_sdk)"
[[ -x "$SDK/bin/monkeyc" ]] || die "no monkeyc under $SDK - reinstall the SDK or set CIQ_SDK"
[[ -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Devices/$DEVICE" ]] ||
    die "device '$DEVICE' not installed - tick it in the SDK Manager"
[[ -f "$KEY" ]] || die "no developer key at $KEY - VS Code: 'Monkey C: Generate a Developer Key'"

ciq_build() {
    local args=(-f "$PROJECT/monkey.jungle" -y "$KEY" -w -l 2)
    local out="$PRG" target="$DEVICE"

    for arg in "$@"; do
        case "$arg" in
            --release) args+=(-r) ;;
            # A store bundle covers every product in the manifest, and monkeyc
            # refuses an export whose output does not end in .iq.
            -e|--package-app) args+=("$arg"); out="$IQ"; target="" ;;
            *) args+=("$arg") ;;
        esac
    done
    args+=(-o "$out")
    [[ -n "$target" ]] && args+=(-d "$target")

    mkdir -p "$PROJECT/bin"
    # Run from the project so relative paths inside monkey.jungle resolve.
    (cd "$PROJECT" && "$SDK/bin/monkeyc" "${args[@]}")
    echo "built $out${target:+ for $target}"
}

# Only build when executed; do nothing extra when sourced by run.sh.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ciq_build "$@"
fi
