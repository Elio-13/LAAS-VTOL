#!/usr/bin/env bash
# Source this file; do not execute it in a separate shell.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    printf 'Use: source scripts/env.sh\n' >&2
    exit 1
fi

export VTOL_REPO
VTOL_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export VTOL_DEPS_DIR="${VTOL_DEPS_DIR:-$VTOL_REPO/.deps}"
export VTOL_RUNS_DIR="${VTOL_RUNS_DIR:-$VTOL_REPO/.runs}"
export VTOL_ARDUPILOT_DIR="$VTOL_DEPS_DIR/ardupilot"
export VTOL_GAZEBO_DIR="$VTOL_DEPS_DIR/ardupilot_gazebo"
export VTOL_VENV="$VTOL_DEPS_DIR/venv"
export GZ_VERSION=harmonic
# Prefer the distro's CLI over a ROS/other workspace copy. Keep other command
# config directories available, but search the Harmonic package configs first.
export VTOL_GZ_COMMAND="${VTOL_GZ_COMMAND:-/usr/bin/gz}"
export GZ_CONFIG_PATH="/usr/share/gz${GZ_CONFIG_PATH:+:$GZ_CONFIG_PATH}"
export PATH="$VTOL_ARDUPILOT_DIR/Tools/autotest:$PATH"
export GZ_SIM_SYSTEM_PLUGIN_PATH="$VTOL_GAZEBO_DIR/build${GZ_SIM_SYSTEM_PLUGIN_PATH:+:$GZ_SIM_SYSTEM_PLUGIN_PATH}"
export GZ_SIM_RESOURCE_PATH="$VTOL_GAZEBO_DIR/models:$VTOL_GAZEBO_DIR/worlds${GZ_SIM_RESOURCE_PATH:+:$GZ_SIM_RESOURCE_PATH}"

if [[ -f "$VTOL_VENV/bin/activate" ]]; then
    source "$VTOL_VENV/bin/activate"
fi
