# Troubleshooting

Run diagnostics from the repository directory:

```bash
bash scripts/check_setup.sh
```

Include the output and the failing command when reporting an issue. The check verifies local files, imports, and command discovery; a pass does not prove a successful flight.

## Gazebo shows help with only sdf available

A Gazebo/ROS environment can hide Gazebo Sim's command configuration. The project scripts prefer `/usr/bin/gz` and prepend `/usr/share/gz` to `GZ_CONFIG_PATH`. Always use the launch scripts.

For a direct terminal check:

```bash
export GZ_CONFIG_PATH="/usr/share/gz${GZ_CONFIG_PATH:+:$GZ_CONFIG_PATH}"
/usr/bin/gz sim --versions
```

Expect a version beginning with `8.`. If it still fails, inspect the installed packages and CLI paths:

```bash
type -a gz
dpkg-query -W gz-harmonic gz-tools2 gz-sim8-cli
dpkg -L gz-sim8-cli
```

If the CLI package is absent or its files are missing, repair it:

```bash
sudo apt update
sudo apt install --reinstall gz-tools2 gz-sim8-cli
```

The installer now checks command discovery before building. Older versions checked it only at the end, which could stop setup after successful builds. Updating the scripts avoids needing the temporary manual path override on every launch.

## Python metadata warning

A warning such as `Skipping ... pybind11 ... invalid metadata entry 'name'` is not by itself proof that package installation failed. Read the actual failed command and the preceding error. Avoid deleting Ubuntu-managed Python files or using `sudo pip`. The project's virtual environment intentionally reads Ubuntu graphical packages through `--system-site-packages`.

## Gazebo opens but the drone stays on the ground

Start ArduPilot in the second terminal. In MAVProxy, switch to GUIDED, arm, and then issue `takeoff 5` as described in the README. Wait for each step to succeed. Confirm simulation time is advancing; click Play if the simulation was manually paused. If arming or takeoff is refused, report the complete `PreArm` or command rejection message. Do not disable arming checks to hide the issue.

## SITL waits for JSON data or telemetry is absent

Confirm the Iris world is open, both processes are in the same Ubuntu/WSL environment, and only one Gazebo/SITL pair is running. Check Gazebo's terminal for `ArduPilotPlugin` loading errors. Use the matching launchers rather than a generic SITL frame. The model uses local UDP communication; custom firewall rules must permit it.

## Native Ubuntu graphics

Inspect the renderer:

```bash
glxinfo -B
```

Check your GPU driver. For rendering problems, try the alternative renderer:

```bash
bash scripts/run_gazebo.sh --render-engine ogre
```

For a Qt/Wayland issue, try:

```bash
QT_QPA_PLATFORM=xcb bash scripts/run_gazebo.sh
```

## WSL graphics

In PowerShell, check/update WSL:

```powershell
wsl --list --verbose
wsl --update
```

Use WSL 2 and a Windows version supporting WSLg. Update the Windows GPU driver. Save work in all WSL sessions before using `wsl --shutdown`, then reopen Ubuntu if a WSL restart is needed. Remove conflicting legacy X-server/DISPLAY overrides from your shell configuration only after identifying them; WSLg normally supplies the display settings.

In Ubuntu, inspect display and graphics information:

```bash
printenv DISPLAY WAYLAND_DISPLAY
glxinfo -B
```

Use the graphics workarounds above if necessary. Keep the clone in the WSL Linux home directory. See [Microsoft's GUI instructions](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps).

## Build killed or compilation fails

If the compiler was killed, check memory and disk space and retry:

```bash
VTOL_BUILD_JOBS=1 bash scripts/setup_ubuntu.sh
```

For another build error, retain the first actual error and its surrounding output. A final `Setup stopped at line ...` message identifies where the script stopped, not the underlying cause.

## MAVProxy or Python module missing

Rerun the installer and inspect its dependency installation output. Launch with `run_sitl.sh` so the correct virtual environment is used. The installer supplies wxPython and other GUI packages through Ubuntu packages; do not install a second copy with system-wide pip.

## Unexpected parameters after an earlier run

SITL retains changed parameters under `.runs/iris/`. Save any settings you need, then explicitly reset the example's saved parameters with:

```bash
bash scripts/run_sitl.sh -w
```

## Installer refuses an existing dependency checkout

Preserve local work. The installer requires the expected remote, pinned revision, and no tracked modifications. Reconcile your dependency clone, or set a new absolute `VTOL_DEPS_DIR` consistently for installation and both launch terminals. The installer deliberately does not reset local changes.
