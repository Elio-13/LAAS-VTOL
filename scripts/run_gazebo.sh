#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/env.sh"

if ! command -v "$VTOL_GZ_COMMAND" >/dev/null 2>&1 ||
   [[ ! -f "$VTOL_GAZEBO_DIR/build/libArduPilotPlugin.so" ]] ||
   [[ ! -f "$VTOL_GAZEBO_DIR/worlds/iris_runway.sdf" ]]; then
    printf 'Gazebo or its ArduPilot plugin is missing. Run: bash scripts/setup_ubuntu.sh\n' >&2
    exit 1
fi

# Extra Gazebo arguments can be supplied, e.g. --render-engine ogre.
exec "$VTOL_GZ_COMMAND" sim --force-version 8 -v4 -r "$VTOL_GAZEBO_DIR/worlds/iris_runway.sdf" "$@"
