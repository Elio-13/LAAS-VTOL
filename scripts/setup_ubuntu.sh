#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "Setup stopped at line %s. Resolve the error above, then rerun this script.\n" "$LINENO" >&2' ERR

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/env.sh"
source "$VTOL_REPO/config/dependencies.sh"

if (( EUID == 0 )); then
    printf 'Run as your normal Ubuntu user: bash scripts/setup_ubuntu.sh\nThe installer requests sudo for system packages.\n' >&2
    exit 1
fi

source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 24.04 ]]; then
    printf 'This installer targets Ubuntu 24.04 LTS. Detected: %s\n' "$PRETTY_NAME" >&2
    exit 1
fi
if [[ "$(uname -m)" != x86_64 ]]; then
    printf 'This initial setup targets x86-64 Ubuntu.\n' >&2
    exit 1
fi
build_jobs="${VTOL_BUILD_JOBS:-2}"
if [[ ! "$build_jobs" =~ ^[1-9][0-9]*$ ]]; then
    printf 'VTOL_BUILD_JOBS must be a positive integer.\n' >&2
    exit 1
fi

# Refuse to reuse unrelated or modified dependency checkouts.
check_checkout() {
    local destination="$1" expected_url="$2" expected_commit="$3"
    [[ -e "$destination" ]] || return 0
    if [[ ! -d "$destination/.git" ]]; then
        printf 'Existing path is not a dependency clone: %s\n' "$destination" >&2
        return 1
    fi
    if [[ "$(git -C "$destination" remote get-url origin)" != "$expected_url" ]] ||
       [[ "$(git -C "$destination" rev-parse HEAD)" != "$expected_commit" ]] ||
       [[ -n "$(git -C "$destination" status --porcelain --untracked-files=no)" ]]; then
        printf 'Dependency checkout differs from the pinned clean revision: %s\nKeep your changes and choose another VTOL_DEPS_DIR, or reconcile this clone before retrying.\n' "$destination" >&2
        return 1
    fi
}

ap_url=https://github.com/ArduPilot/ardupilot.git
plugin_url=https://github.com/ArduPilot/ardupilot_gazebo.git
if command -v git >/dev/null 2>&1; then
    check_checkout "$VTOL_ARDUPILOT_DIR" "$ap_url" "$VTOL_ARDUPILOT_COMMIT"
    check_checkout "$VTOL_GAZEBO_DIR" "$plugin_url" "$VTOL_GAZEBO_COMMIT"
fi

sudo -v
sudo apt-get update
sudo apt-get install -y git curl ca-certificates gnupg lsb-release \
    build-essential cmake pkg-config ccache gawk \
    python3-dev python3-venv python3-pip python3-wxgtk4.0 \
    python3-matplotlib python3-opencv python3-pygame python3-yaml \
    python3-numpy python3-pyparsing python3-psutil \
    libxml2-dev libxslt1-dev libsfml-dev libcsfml-dev xterm mesa-utils

gazebo_package_status="$(dpkg-query -W -f='${Status}' gz-harmonic 2>/dev/null || true)"
if [[ "$gazebo_package_status" != 'install ok installed' ]]; then
    gazebo_key="$(mktemp)"
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o "$gazebo_key"
    sudo install -m 0644 "$gazebo_key" /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
    rm -f "$gazebo_key"
    printf 'deb [arch=%s signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable %s main\n' \
        "$(dpkg --print-architecture)" "$(lsb_release -cs)" \
        | sudo tee /etc/apt/sources.list.d/gazebo-stable.list >/dev/null
    sudo apt-get update
fi
sudo apt-get install -y gz-harmonic gz-tools2 gz-sim8-cli libgz-sim8-dev rapidjson-dev \
    libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

# Verify command discovery before downloading and compiling the dependencies.
if ! gazebo_versions="$("$VTOL_GZ_COMMAND" sim --versions)"; then
    printf 'Gazebo Sim command discovery failed. Run: bash scripts/check_setup.sh\nSee docs/troubleshooting.md.\n' >&2
    exit 1
fi
if [[ ! "$gazebo_versions" =~ (^|[[:space:]])8\. ]]; then
    printf 'Gazebo Sim 8 (Harmonic) was not found. Detected:\n%s\nSee docs/troubleshooting.md.\n' "$gazebo_versions" >&2
    exit 1
fi

clone_pinned() {
    local url="$1" ref="$2" commit="$3" destination="$4"
    if [[ ! -e "$destination" ]]; then
        git clone --depth 1 --branch "$ref" "$url" "$destination"
        if [[ "$(git -C "$destination" rev-parse HEAD)" != "$commit" ]]; then
            git -C "$destination" fetch --depth 1 origin "$commit"
        fi
        git -C "$destination" checkout --detach "$commit"
    fi
    check_checkout "$destination" "$url" "$commit"
}

mkdir -p "$VTOL_DEPS_DIR" "$VTOL_RUNS_DIR"
clone_pinned "$ap_url" "$VTOL_ARDUPILOT_REF" "$VTOL_ARDUPILOT_COMMIT" "$VTOL_ARDUPILOT_DIR"
git -C "$VTOL_ARDUPILOT_DIR" submodule update --init --recursive
clone_pinned "$plugin_url" "$VTOL_GAZEBO_REF" "$VTOL_GAZEBO_COMMIT" "$VTOL_GAZEBO_DIR"

/usr/bin/python3 -m venv --system-site-packages "$VTOL_VENV"
source "$VTOL_VENV/bin/activate"
python -m pip install -r "$VTOL_REPO/config/requirements-sitl.txt"

(
    cd "$VTOL_ARDUPILOT_DIR"
    ./waf configure --board sitl
    ./waf copter -j "$build_jobs"
)
cmake -S "$VTOL_GAZEBO_DIR" -B "$VTOL_GAZEBO_DIR/build" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_DISABLE_FIND_PACKAGE_ament_cmake=ON
cmake --build "$VTOL_GAZEBO_DIR/build" -j "$build_jobs"

# Keep the resolved environment with local run output for troubleshooting.
python -m pip freeze > "$VTOL_RUNS_DIR/python-packages.txt"
{
    printf 'ArduPilot: %s\nPlugin: %s\n' \
        "$(git -C "$VTOL_ARDUPILOT_DIR" rev-parse HEAD)" \
        "$(git -C "$VTOL_GAZEBO_DIR" rev-parse HEAD)"
    printf 'Gazebo Sim versions: %s\n' "$gazebo_versions"
    python --version
} > "$VTOL_RUNS_DIR/setup-versions.txt"

printf '\nSetup complete. From this repository, open two Ubuntu terminals:\n'
printf '  Terminal 1: bash scripts/run_gazebo.sh\n'
printf '  Terminal 2: bash scripts/run_sitl.sh\n'
printf 'Then follow the hover commands in README.md.\n'
