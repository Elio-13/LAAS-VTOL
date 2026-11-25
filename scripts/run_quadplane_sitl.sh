#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

if [[ ! -f "$VTOL_ARDUPILOT_DIR/Tools/autotest/sim_vehicle.py" ]]; then
    echo "ArduPilot source is missing."
    echo "Run: bash scripts/setup_ubuntu.sh"
    exit 1
fi

mkdir -p "$VTOL_RUNS_DIR/laas-gazebo-quadplane"
cd "$VTOL_RUNS_DIR/laas-gazebo-quadplane"

exec "$VTOL_VENV/bin/python" \
    "$VTOL_ARDUPILOT_DIR/Tools/autotest/sim_vehicle.py" \
    -v ArduPlane \
    -f quadplane \
    --model JSON \
    --console --map "$@"
