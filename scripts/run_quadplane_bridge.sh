#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

# Live motor commands are intentionally explicit.
# Default operation is monitor-only.
exec /usr/bin/python3 \
    "$VTOL_REPO/scripts/sitl_motor_bridge.py" "$@"
