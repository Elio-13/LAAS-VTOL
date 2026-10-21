#!/usr/bin/env bash
# Read-only checks; no package changes, builds, or flight commands.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/env.sh"
failures=0
fail() { printf '[FAIL] %s\n' "$1"; failures=$((failures + 1)); }
pass() { printf '[OK] %s\n' "$1"; }

source /etc/os-release
printf 'OS: %s; architecture: %s\n' "$PRETTY_NAME" "$(uname -m)"
if [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 && "$(uname -m)" == x86_64 ]]; then
    pass 'Supported Ubuntu environment'
else
    fail 'Expected Ubuntu 24.04 x86-64'
fi
if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    pass 'Graphical display variable available (renderer not tested)'
else
    fail 'No graphical display configured; use a desktop terminal or WSLg'
fi
printf 'Gazebo CLI: %s\nCommand config paths: %s\n' "$VTOL_GZ_COMMAND" "$GZ_CONFIG_PATH"
if versions="$("$VTOL_GZ_COMMAND" sim --versions 2>&1)"; then
    if [[ "$versions" =~ (^|[[:space:]])8\. ]]; then
        pass "Gazebo Sim 8 found: $versions"
    else
        fail "Harmonic/Sim 8 not found: $versions"
    fi
else
    fail "Gazebo command discovery: $versions"
fi
for component in     "$VTOL_GAZEBO_DIR/build/libArduPilotPlugin.so"     "$VTOL_GAZEBO_DIR/worlds/iris_runway.sdf"     "$VTOL_ARDUPILOT_DIR/Tools/autotest/sim_vehicle.py"; do
    if [[ -f "$component" ]]; then pass "$component"; else fail "Missing $component"; fi
done
if [[ -x "$VTOL_ARDUPILOT_DIR/build/sitl/bin/arducopter" ]]; then
    pass 'ArduCopter SITL binary'
else
    fail 'ArduCopter SITL binary missing; run the installer'
fi
if [[ -x "$VTOL_VENV/bin/python" ]]; then
    if "$VTOL_VENV/bin/python" -c 'import pymavlink, MAVProxy, wx, matplotlib, cv2, numpy, em' ; then
        pass 'SITL Python environment and GUI imports'
    else
        fail 'Python imports failed; review dependency installation output'
    fi
else
    fail 'Project Python environment missing; run the installer'
fi
if (( failures > 0 )); then
    printf '\n%s check(s) failed. See docs/troubleshooting.md.\n' "$failures"
    exit 1
fi
printf '\nLocal setup checks passed. Follow README.md to launch and test a flight.\n'
