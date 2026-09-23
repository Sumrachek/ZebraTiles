#!/usr/bin/env bash
#
# Builds, then loads the data field into the Connect IQ simulator.
# A simulator that is already running is reused, so the new build simply
# replaces the old one and you keep your simulated activity data.
#
# Any argument is forwarded to build.sh (e.g. ./run.sh --release).
#
# monkeydo stays attached and prints runtime errors and stack traces.
# Ctrl-C detaches; the simulator keeps running.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build.sh"

SIM_PROCESS='ConnectIQ.app/Contents/MacOS/simulator'
SIM_PORT=1234

sim_ready() {
    nc -z 127.0.0.1 "$SIM_PORT" >/dev/null 2>&1
}

ciq_build "$@"

if pgrep -f "$SIM_PROCESS" >/dev/null; then
    echo "simulator already running - loading the new build into it"
else
    echo "starting the simulator"
    nohup "$SDK/bin/connectiq" >/dev/null 2>&1 &
fi

# The simulator accepts sideloads only once it is listening.
if command -v nc >/dev/null 2>&1; then
    for _ in $(seq 1 60); do
        sim_ready && break
        sleep 0.5
    done
    sim_ready || die "simulator did not start listening on port $SIM_PORT"
else
    sleep 8
fi

exec "$SDK/bin/monkeydo" "$PRG" "$DEVICE"
