#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/env.sh"

if [[ ! -x "$VTOL_VENV/bin/python" ]] ||
   [[ ! -f "$VTOL_ARDUPILOT_DIR/Tools/autotest/sim_vehicle.py" ]] ||
   [[ ! -x "$VTOL_ARDUPILOT_DIR/build/sitl/bin/arducopter" ]]; then
    printf 'ArduCopter SITL is not built. Run: bash scripts/setup_ubuntu.sh\n' >&2
    exit 1
fi

mkdir -p "$VTOL_RUNS_DIR/iris"
cd "$VTOL_RUNS_DIR/iris"
exec "$VTOL_VENV/bin/python" "$VTOL_ARDUPILOT_DIR/Tools/autotest/sim_vehicle.py" \
    -v ArduCopter -f gazebo-iris --model JSON \
    --console --map -j "${VTOL_BUILD_JOBS:-2}" "$@"
