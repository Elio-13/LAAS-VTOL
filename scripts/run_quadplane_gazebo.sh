#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

WATCHDOG_DIR="$VTOL_REPO/plugins/motor_watchdog/build"

if [[ ! -f "$WATCHDOG_DIR/liblaas_motor_watchdog.so" ]]; then
    echo "Watchdog not built."
    echo "Run: bash scripts/build_quadplane_watchdog.sh"
    exit 1
fi

if [[ ! -f "$VTOL_GAZEBO_DIR/build/libArduPilotPlugin.so" ]]; then
    echo "ArduPilot Gazebo plugin missing."
    exit 1
fi

export GZ_SIM_SYSTEM_PLUGIN_PATH="$WATCHDOG_DIR:$GZ_SIM_SYSTEM_PLUGIN_PATH"
export GZ_SIM_RESOURCE_PATH="$VTOL_REPO/models:$VTOL_REPO/worlds:$GZ_SIM_RESOURCE_PATH"

exec "$VTOL_GZ_COMMAND" sim --force-version 8 -v4 -r \
    "$VTOL_REPO/worlds/laas_gravity_test.sdf" \
    --render-engine ogre2 "$@"
