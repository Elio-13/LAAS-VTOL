#!/usr/bin/env python3
import math
import subprocess
import threading
import time

from gz.transport13 import Node
from gz.msgs10.pose_v_pb2 import Pose_V
from gz.msgs10.actuators_pb2 import Actuators

node = Node()
lock = threading.Lock()
samples = []
recording = False

def on_pose(msg):
    global recording

    for pose in msg.pose:
        if pose.name != "laas_quadplane":
            continue

        q = pose.orientation

        pitch = math.atan2(
            2 * (q.w * q.y - q.z * q.x),
            1 - 2 * (q.y*q.y + q.z*q.z)
        )

        with lock:
            if recording:
                samples.append(
                    (time.monotonic(), math.degrees(pitch))
                )

node.subscribe(
    Pose_V,
    "/world/laas_gravity_test/pose/info",
    on_pose
)

publisher = node.advertise(
    "/laas_quadplane/gazebo/command/motor_speed",
    Actuators
)

def send(speeds):
    msg = Actuators()
    msg.velocity.extend(speeds)
    publisher.publish(msg)

time.sleep(0.5)

# Reset to a level orientation above the ground
result = subprocess.run(
    [
        "gz", "service",
        "-s", "/world/laas_gravity_test/set_pose",
        "--reqtype", "gz.msgs.Pose",
        "--reptype", "gz.msgs.Boolean",
        "--timeout", "3000",
        "--req",
        'name: "laas_quadplane" '
        'position {x: 0 y: 0 z: 2.5} '
        'orientation {w: 1 x: 0 y: 0 z: 0}'
    ],
    capture_output=True,
    text=True
)

print("Reset response:", result.stdout.strip())

if result.returncode != 0 or "true" not in result.stdout.lower():
    raise RuntimeError("Aircraft reset failed")

with lock:
    samples.clear()
    recording = True

# Order: FR, RL, FL, RR
# Right motors faster -> expected negative Gazebo pitch
print("Applying motor pulse...", flush=True)

try:
    end = time.monotonic() + 0.25

    while time.monotonic() < end:
        send([450, 500, 450, 500])
        time.sleep(0.02)

finally:
    for _ in range(15):
        send([0, 0, 0, 0])
        time.sleep(0.02)

time.sleep(0.3)

with lock:
    recording = False
    data = samples.copy()

if not data:
    print("ERROR: No aircraft pose samples received.")
else:
    t0 = data[0][0]

    print("\nTime (s)   Pitch (deg)")
    for t, angle in data[::max(1, len(data)//20)]:
        print(f"{t-t0:7.3f}    {angle:+9.4f}")

    print("\nMinimum pitch:", round(min(a for _, a in data), 4))
    print("Maximum pitch:", round(max(a for _, a in data), 4))

print("\nTest completed.")
