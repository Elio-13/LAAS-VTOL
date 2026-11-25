# LAAS QuadPlane Simulation — Development Status

**Milestone:** Initial VTOL hover simulation
**Last updated:** 25 November 2026
**Development branch:** `jean-development`

## Overview

This is an early-stage simulation of the LAAS hybrid VTOL aircraft,
using ArduPlane QuadPlane SITL and Gazebo Harmonic.

The current focus is vertical-flight simulation and control.
Fixed-wing flight and transition have not yet been implemented.

The simulated aircraft is not yet a validated representation of
the final physical VTOL design.

## Implemented and tested

| Capability | Status | Notes |
|---|---|---|
| Custom Gazebo aircraft model | Implemented | Provisional geometry and mass |
| ArduPlane QuadPlane SITL integration | Working | JSON interface through Gazebo |
| Four lift rotors | Working | Physical rotation and thrust tested |
| Motor mixing | Verified | Roll, pitch, yaw directions tested |
| Python motor bridge | Working | Monitor-only and live modes |
| Gazebo motor watchdog | Tested | Stops commands after timeout |
| QSTABILIZE flight | Demonstrated | Takeoff and sustained flight |
| QHOVER altitude hold | Demonstrated | Automatic vertical stabilization |
| QLOITER position hold | Partial | Holds XY but sustained oscillations |

## Current simulation assumptions

- Aircraft mass: approximately 15 kg.
- Four vertical lift motors.
- Lift motor maximum command: 800 rad/s.
- Motor thrust coefficient: 0.00015.
- Motor rotation slowdown in Gazebo: 10.
- Hover thrust was manually set to 0.60 during testing;
  the later saved value was approximately 0.403.
- No validated aerodynamic model for fixed-wing flight.

These parameters are provisional and must be reviewed against
the actual aircraft design before interpreting simulation results
as physical performance predictions.

## Known limitations

### QLOITER oscillations

QLOITER can maintain approximate horizontal position, but sustained
roll/pitch and horizontal-velocity oscillations have been observed.

Experiments included:
- Reducing horizontal position P from 0.50 to 0.35.
- Reducing horizontal velocity P from 0.70 to 0.55.
- Reducing horizontal velocity I from 0.35 to 0.15.
- Testing horizontal velocity D at 0.

None clearly eliminated the oscillations.

The original gains were selected for restoration after testing.
The current saved SITL parameters should be verified before
subsequent tests.

Possible causes requiring investigation include controller tuning,
simulation timing, motor dynamics, and feedback delays.
No root cause has been confirmed.

### Unimplemented capabilities

- Fixed-wing lift, drag, and aerodynamic moments.
- Functional control surfaces.
- Rear pusher motor integration.
- VTOL-to-fixed-wing transition.
- Autonomous takeoff to a specified altitude.
- Autonomous navigation and mission execution.
- Validated flight failsafes beyond the motor-command watchdog.
- Hardware-in-the-loop testing.
- Physical prototype flight validation.

## Safety and testing notes

The Python motor bridge defaults to monitor-only mode.
Use `--live` explicitly to enable motor commands.

A Gazebo-side watchdog sends zero motor commands after a
command timeout. This does not protect against Gazebo itself
freezing or stopping.

For abnormal simulation behavior, return to a previously
working flight mode when possible and terminate the test.

Do not use the current simulation parameters directly on
physical aircraft hardware without separate validation.

## Next development priorities

1. Diagnose and reduce QLOITER oscillations.
2. Add repeatable flight logging and quantitative acceptance tests.
3. Validate mass, inertia, geometry, and propulsion parameters.
4. Implement fixed-wing aerodynamic forces and control surfaces.
5. Integrate the pusher motor.
6. Develop and validate transition control.
7. Expand SITL testing toward autonomous missions.
8. Prepare hardware-in-the-loop and prototype testing.

## Milestone interpretation

This milestone demonstrates closed-loop vertical flight using
a custom Gazebo aircraft coupled to ArduPlane SITL.

It does not yet demonstrate complete hybrid VTOL flight,
fixed-wing cruise, or a validated transition.


## Saved parameter snapshot

A selected parameter snapshot is provided at
`config/quadplane/hover-tested.parm`.

It includes motor-function assignments, QuadPlane frame settings,
and experimental horizontal-controller gains.

This is not a complete or independently validated parameter set.
The current SITL installation also uses local persistent state
that is not committed to Git.

Teammates should verify their parameters before reproducing
flight tests. A fresh-install validation remains pending.
