#!/usr/bin/env python3
"""ArduPlane motor outputs -> Gazebo multicopter motor commands."""

import argparse
import math
import threading
import time

from gz.transport13 import Node
from gz.msgs10.double_pb2 import Double
from gz.msgs10.actuators_pb2 import Actuators

TOPICS = [
    f"/laas_quadplane/sitl/motor_{i}"
    for i in range(1, 5)
]
OUTPUT = "/laas_quadplane/gazebo/command/motor_speed"

MAX_SPEED = 800.0
TIMEOUT = 0.5
RATE = 50

parser = argparse.ArgumentParser()
parser.add_argument(
    "--live", action="store_true",
    help="Enable actual motor output (default: monitor only)"
)
args = parser.parse_args()

node = Node()
lock = threading.Lock()

values = [0.0] * 4
updated = [0.0] * 4


def make_callback(index):
    def callback(msg):
        with lock:
            values[index] = msg.data
            updated[index] = time.monotonic()
    return callback


for index, topic in enumerate(TOPICS):
    if not node.subscribe(Double, topic, make_callback(index)):
        raise RuntimeError(f"Cannot subscribe to {topic}")

publisher = (
    node.advertise(OUTPUT, Actuators)
    if args.live else None
)


def publish_speeds(speeds):
    msg = Actuators()
    msg.velocity.extend(speeds)
    publisher.publish(msg)


print("Bridge started.")
print("Mode:", "LIVE" if args.live else "MONITOR ONLY")
print("Motor order: FR, RL, FL, RR")

last_print = 0.0

try:
    while True:
        now = time.monotonic()

        with lock:
            raw = values.copy()
            fresh = all(
                stamp > 0 and now - stamp < TIMEOUT
                for stamp in updated
            )

        valid = all(
            math.isfinite(v) and 0 <= v <= 1
            for v in raw
        )

        if fresh and valid:
            speeds = [v * MAX_SPEED for v in raw]
        else:
            speeds = [0.0] * 4

        if args.live:
            publish_speeds(speeds)

        if now - last_print >= 1.0:
            status = (
                "OK" if fresh and valid
                else "STALE / INVALID"
            )
            print(
                status,
                "raw:", [round(v, 3) for v in raw],
                "rpm-equivalent rad/s:",
                [round(v) for v in speeds],
                flush=True
            )
            last_print = now

        time.sleep(1.0 / RATE)

except KeyboardInterrupt:
    if args.live:
        publish_speeds([0.0] * 4)
    print("\nBridge stopped.")
