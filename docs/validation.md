# Iris hover setup validation

Updated on 21 October 2026.

## Completed checks

- Verified the ArduPilot Copter-4.6.3 commit and plugin commit against their upstream repositories.
- Inspected the pinned `gazebo-iris` frame, default parameters, and plugin Iris world/model.
- Checked every shell script and README Bash block with `bash -n`.
- Exercised both launchers with temporary stand-ins for the external programs. Confirmed the Iris world, matching ArduCopter/JSON arguments, plugin/resource search paths, and forwarding of optional arguments.
- Confirmed SITL uses its separate run directory and resets saved parameters only when explicitly given `-w`.
- Confirmed missing dependency files produce an actionable setup error.
- Confirmed launcher paths handle spaces in dependency/run directory names.
- Confirmed the installer stops when run as root, before system package changes.
- Checked the Git diff for whitespace errors.

The stand-in checks verify launcher behavior, not a simulated flight. The inspection environment had neither Gazebo nor a graphical desktop. System package installation, compilation, and actual flight have not been executed there.

## Team feedback and this update

On 21 October 2026, the project lead reported that Gazebo displayed the drone on native Ubuntu after setting `GZ_CONFIG_PATH=/usr/share/gz` and selecting `/usr/bin/gz`. The previous CLI exposed only `sdf`. The follow-up indicated the example was working, but did not record a timed hover, landing, exact OS release, or GPU. This is useful user feedback, not a complete acceptance record.

The environment script now applies that command-discovery workaround for every launcher without changing `.bashrc`. The Gazebo launcher explicitly selects Sim 8. Setup checks command discovery before downloading/building dependencies and records the successful version result. A read-only setup check and separate WSL preparation instructions were added.

Checks repeated for this update: shell syntax and README Bash blocks; local Markdown file/anchor links; Git whitespace checks; mocked Gazebo and SITL launcher arguments, custom paths, and missing-dependency errors. The mock checks do not validate simulation physics or GUI operation. Neither clean native Ubuntu installation nor WSL flight was executed in the editing environment.

## Target-computer acceptance

Complete these on native Ubuntu 24.04 and, separately, WSL 2 / Ubuntu 24.04:

1. Run `bash scripts/setup_ubuntu.sh` to completion from a fresh clone.
2. Start Gazebo and ArduCopter using the README commands.
3. Confirm MAVProxy receives live telemetry and position estimation becomes ready.
4. Command GUIDED mode, arm, and take off to 5 m.
5. Observe approximately 20 seconds of stable height and position.
6. Command LAND, confirm touchdown and disarming, and stop both processes.
7. Repeat the launch without reinstalling to check the everyday workflow.
8. Record the date, OS, GPU, repository commit, `.runs/setup-versions.txt`, and any fixes in this document.

| Platform | Installation/build | Takeoff/hover/land | Test date |
| --- | --- | --- | --- |
| Native Ubuntu 24.04 x86-64 | Pending | Pending | — |
| WSL 2 / Ubuntu 24.04 x86-64 | Pending | Pending | — |
