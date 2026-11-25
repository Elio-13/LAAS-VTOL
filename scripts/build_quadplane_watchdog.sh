#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

BUILD_DIR="$VTOL_REPO/plugins/motor_watchdog/build"

cmake -S "$VTOL_REPO/plugins/motor_watchdog" \
      -B "$BUILD_DIR"

cmake --build "$BUILD_DIR" -j "${VTOL_BUILD_JOBS:-2}"

echo "Watchdog built successfully."
