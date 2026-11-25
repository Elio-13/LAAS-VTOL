# LAAS QuadPlane Simulation Guide

This guide covers the experimental custom QuadPlane simulation
using ArduPlane SITL and Gazebo Harmonic.

For the original Iris / ArduCopter simulation, see README.md.
For development status, see quadplane-status.md.

## Requirements

- Ubuntu 24.04 LTS
- Gazebo Harmonic / Gazebo Sim 8
- ArduPilot ArduPlane SITL
- ArduPilot Gazebo plugin
- Python Gazebo transport bindings
- CMake and a C++ compiler

The original installer supports the Iris baseline. The QuadPlane
additionally requires ArduPlane and the motor watchdog.

## Build

Run from the repository root:

    bash scripts/build_quadplane_watchdog.sh

The first ArduPlane SITL launch also builds ArduPlane.

## Launch

Open three Ubuntu terminals in the repository root.

Terminal 1 — Gazebo:

    bash scripts/run_quadplane_gazebo.sh

Terminal 2 — ArduPlane SITL:

    bash scripts/run_quadplane_sitl.sh

Terminal 3 — Motor bridge:

    bash scripts/run_quadplane_bridge.sh --live

Omitting --live keeps the bridge in monitor-only mode.

Start Gazebo first, then SITL, then the bridge.
Make sure Gazebo is unpaused.

## Flight controls

Enter these commands in MAVProxy, not Ubuntu Bash.

Prepare QHOVER:

    mode QHOVER
    rc 1 1500
    rc 2 1500
    rc 3 1000
    rc 4 1500
    arm throttle

To request a gentle climb in the tested simulation:

    rc 3 1550

Once airborne, request altitude hold:

    rc 3 1500

To test horizontal position control while airborne:

    mode QLOITER

IMPORTANT: QLOITER currently produces sustained oscillations.
Return to QHOVER if oscillations become significant.

## Monitoring

Check aircraft position and orientation:

    gz model -m laas_quadplane -p

Monitor continuously:

    watch -n 0.2 'gz model -m laas_quadplane -p'

## Current capabilities

- ArduPlane SITL and custom Gazebo model integration
- Four physically simulated lift rotors
- Verified roll, pitch, and yaw motor responses
- Python motor bridge and Gazebo watchdog
- QSTABILIZE flight
- QHOVER automatic altitude hold
- Experimental QLOITER XY position hold

## Known limitations

QLOITER exhibits sustained horizontal velocity and attitude
oscillations. Controller tuning remains incomplete.

The simulated 15 kg mass, inertia, geometry, and propulsion
parameters are provisional.

Fixed-wing aerodynamics, aerodynamic control surfaces, pusher
propulsion, transitions, autonomous missions, and hardware
validation have not yet been implemented.

Do not transfer the current simulation parameters directly
to a physical aircraft.


## Parameter configuration

A partial configuration snapshot is available at
`config/quadplane/hover-tested.parm`.

The launch script does not automatically load this file.
It contains experimental QLOITER tuning values and is not
a validated baseline.

A fresh installation may require additional configuration
before it reproduces the demonstrated flight behavior.
