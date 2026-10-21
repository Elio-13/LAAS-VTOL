# LAAS VTOL

Team simulation workspace for the Lebanese Aerospace and Automotive Society VTOL project.

**Current milestone:** fly the upstream Iris quadcopter using **ArduCopter SITL + Gazebo Harmonic + the official ArduPilot Gazebo plugin**. Take off to 5 m, hover, and land. This provides the baseline for adding our custom VTOL with ArduPlane / QuadPlane later.

New members can clone this repository and run the installer below. The first setup downloads dependencies and compiles them; subsequent sessions only need the two launch scripts. No flight controller hardware is required.

## Start here

1. Prepare [native Ubuntu](#native-ubuntu) or [Windows with WSL 2](#windows-with-wsl-2).
2. [Clone and install](#clone-and-install) in an Ubuntu terminal.
3. [Launch and hover](#launch-and-hover).

| | Native Linux | Windows / WSL |
| --- | --- | --- |
| Supported project environment | Ubuntu 24.04 LTS, x86-64 | Ubuntu 24.04, x86-64, inside WSL 2 |
| Graphics | Ubuntu desktop and working GPU driver | WSLg and current Windows GPU driver |
| Repository location | Linux home directory | WSL Linux home directory, not `/mnt/c/...` |
| Install and launch commands | Shared Ubuntu commands below | Same commands, inside Ubuntu rather than PowerShell |
| Validation | Model display reported working on the project lead's Ubuntu computer; full acceptance pending | Team validation pending |

Other Linux distributions and ARM computers are not covered by the installer.

## Native Ubuntu

Use **Ubuntu 24.04 LTS** with a graphical desktop. Confirm the OS and architecture:

```bash
cat /etc/os-release
uname -m
```

Expect Ubuntu `24.04` and `x86_64`. Use a normal user with `sudo` access. Continue to [Clone and install](#clone-and-install).

## Windows with WSL 2

Use Windows 11, or Windows 10 **build 19044 or later**, with WSLg support and a current GPU driver from your GPU manufacturer. WSL 1 is not supported for this workflow.

**In PowerShell as administrator**, install Ubuntu 24.04:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart Windows if requested. Open Ubuntu 24.04 and create your Linux username and password. If WSL is already installed, install only the missing distribution; keep your existing distributions.

Update WSL and verify the distribution is using version 2, in PowerShell:

```powershell
wsl --update
wsl --list --verbose
```

If `Ubuntu-24.04` shows version `1`, convert it:

```powershell
wsl --set-version Ubuntu-24.04 2
```

**Now open Ubuntu 24.04.** Run all remaining commands there. Keep the project in `~/VTOL/LAAS-VTOL` for Linux filesystem performance. WSLg supplies the graphical display; a separate X server and manual `DISPLAY` setting should not be necessary.

If graphical apps fail, see [WSL graphics troubleshooting](docs/troubleshooting.md#wsl-graphics).

## Clone and install

The same commands apply to native Ubuntu and Ubuntu inside WSL 2:

```bash
sudo apt update
sudo apt install -y git
mkdir -p "$HOME/VTOL"
git clone https://github.com/Elio-13/LAAS-VTOL.git "$HOME/VTOL/LAAS-VTOL"
cd "$HOME/VTOL/LAAS-VTOL"
bash scripts/setup_ubuntu.sh
```

If you already have a clone, use that directory and pull the latest committed changes instead of cloning again. Preserve any uncommitted work first.

The installer:

- Installs Gazebo Harmonic and the required Ubuntu development and graphical packages.
- Checks Gazebo command discovery before compiling.
- Downloads the pinned ArduPilot and plugin source revisions into `.deps/`.
- Creates a Python environment and builds ArduCopter SITL and the plugin.
- Records installed versions under `.runs/`.

Run it as your normal user, without putting `sudo` before the script. It requests administrator access for system packages. Installation needs internet access, several downloads, and compilation time. It changes system packages; other project dependencies and output stay inside the clone by default.

**Expected result:** `Setup complete` followed by the launch commands. Check the installation:

```bash
bash scripts/check_setup.sh
```

The check reports missing components and does not install anything or start a flight. If compilation runs out of memory, retry with one build worker:

```bash
VTOL_BUILD_JOBS=1 bash scripts/setup_ubuntu.sh
```

The installer can be rerun. It reuses the expected dependency revisions and refuses to overwrite tracked changes or unrelated dependency clones.

## Launch and hover

Use two Ubuntu terminals in the same Linux environment. Leave both running during flight.

### Terminal 1: Gazebo

```bash
cd "$HOME/VTOL/LAAS-VTOL"
bash scripts/run_gazebo.sh
```

**Expected:** Gazebo opens with an Iris quadcopter on a runway. The launcher selects Gazebo Sim 8, sets the plugin and model paths, and starts the simulation. It also handles the command discovery fix needed when another Gazebo/ROS environment exposes only `gz sdf`.

### Terminal 2: ArduPilot

```bash
cd "$HOME/VTOL/LAAS-VTOL"
bash scripts/run_sitl.sh
```

**Expected:** ArduCopter starts, MAVProxy receives telemetry, and the console and map open. Wait for the simulated position estimate and pre-arm checks to become ready. Gazebo may wait for SITL before its simulation time advances normally.

### Command the flight

Seeing the drone in Gazebo does not start a flight. Enter the following **in the MAVProxy terminal prompt**, not in Bash, one command at a time:

```text
mode guided
```

Wait for GUIDED mode, then:

```text
arm throttle
```

Wait for confirmation that it is armed, then:

```text
takeoff 5
```

The drone should climb toward **5 m above its starting point** and hold position. Observe it for approximately 20 seconds. If it stays grounded, check that simulation time is advancing and read any `PreArm` or command rejection messages in MAVProxy. Keep arming checks enabled.

To land:

```text
mode land
```

Wait for touchdown and disarming. Then stop SITL and Gazebo with `Ctrl+C` in their respective terminals. Close the previous pair before starting another session.

**Next time:** repeat the two launch commands and MAVProxy flight commands. You do not need to rerun installation or manually activate the Python environment.

## Repository organization

| Path | Contents |
| --- | --- |
| `scripts/` | Installer, environment, setup check, and launchers |
| `config/dependencies.sh` | Pinned ArduPilot and plugin source revisions |
| `config/requirements-sitl.txt` | Python dependencies |
| `docs/troubleshooting.md` | Installation, graphics, connection, and flight fixes |
| `docs/validation.md` | Checks completed and target-platform acceptance procedure |
| `CONTRIBUTING.md` | Team workflow and rules for adding aircraft files |
| `.deps/` | Local dependency sources, builds, and Python environment; ignored by Git |
| `.runs/` | Local logs, saved simulation state, and version records; ignored by Git |

Custom aircraft assets will be added under `models/`, `worlds/`, and `params/` when available. The Iris model currently comes from the pinned upstream plugin dependency.

## Versions and configuration

| Component | Selection |
| --- | --- |
| Ubuntu | 24.04 LTS, x86-64 |
| Gazebo | Harmonic / Sim 8; Ubuntu package updates resolve at installation |
| ArduPilot | Copter-4.6.3, commit `92b0cd788ec29406f26c6f9c31d5ceedbd1cc538` |
| Gazebo plugin | Commit `082a0fe231f6e63bc8d1598f1cba461d9e2ea7f5` |
| Python | Ubuntu Python 3; Empy pinned to 3.3.4; other requirements resolve at installation |

The source revisions are pinned, but this is not a fully locked system image. `.runs/setup-versions.txt` and `.runs/python-packages.txt` record each computer's actual setup. Validation limits are recorded in [docs/validation.md](docs/validation.md).

The scripts locate the clone automatically, so another clone location also works. Optional environment variables must be consistent between installation and both launch terminals:

| Variable | Default | Purpose |
| --- | --- | --- |
| `VTOL_BUILD_JOBS` | `2` | Build worker count |
| `VTOL_DEPS_DIR` | `<clone>/.deps` | Absolute path for dependencies |
| `VTOL_RUNS_DIR` | `<clone>/.runs` | Absolute path for output and saved state |
| `VTOL_GZ_COMMAND` | `/usr/bin/gz` | Explicit Gazebo CLI path for an alternate installation |

No `.bashrc` edits or ROS installation are required. Each launcher loads `scripts/env.sh` itself.

## Help and contributing

Start with [troubleshooting](docs/troubleshooting.md). For a problem report, include the exact failing command, terminal output, native Ubuntu or WSL version, GPU, and the output of `bash scripts/check_setup.sh`. See [CONTRIBUTING.md](CONTRIBUTING.md) before pushing changes.

## References

- [ArduPilot: SITL with Gazebo and the Iris flight commands](https://ardupilot.org/dev/docs/sitl-with-gazebo.html)
- [Official ArduPilot Gazebo plugin](https://github.com/ArduPilot/ardupilot_gazebo)
- [Gazebo Harmonic Ubuntu installation](https://gazebosim.org/docs/harmonic/install_ubuntu/)
- [Gazebo command discovery and GZ_CONFIG_PATH](https://gazebosim.org/libs/sim/)
- [Microsoft: Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Microsoft: Linux GUI applications with WSL](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps)
