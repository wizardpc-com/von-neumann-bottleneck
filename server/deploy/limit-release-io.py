#!/usr/bin/env python3
"""Apply and verify the current VNB loop devices' cgroup v2 limits before startup."""
import argparse
import os
from pathlib import Path
import re
import stat
import sys


UNITS = {
    "receiver": "vnb-release-receiver.service",
    "maintenance": "vnb-release-maintenance.service",
}
LOOP_LIMITS = {
    "receiver": {"live": (8_000_000, 4_000_000)},
    # Split the job's original 8/4 MB/s ceiling across the two volumes.
    "maintenance": {"live": (4_000_000, 1_000_000), "ops": (4_000_000, 3_000_000)},
}
BACKING_LIMIT = (8_000_000, 4_000_000)


def device_number(number):
    return f"{os.major(number)}:{os.minor(number)}"


def mounted_loop(volume_root, sysfs, lane):
    device = (volume_root / lane).stat().st_dev
    if device == volume_root.stat().st_dev:
        raise ValueError(f"{lane} volume is not mounted")
    number = device_number(device)
    kernel_device = (sysfs / "dev/block" / number).resolve(strict=True)
    if not re.fullmatch(r"loop[0-9]+", kernel_device.name):
        raise ValueError(f"{lane} volume has no whole loop device")
    image = (kernel_device / "loop/backing_file").read_text().rstrip("\n")
    if image != str(volume_root / "images" / f"{lane}.img"):
        raise ValueError(f"{lane} loop device has the wrong backing image")
    return number


def io_control_file(role, membership, cgroup_root):
    locations = [line[3:] for line in membership.splitlines() if line.startswith("0::")]
    allowed = {f"/system.slice/{UNITS[role]}", f"/system.slice/vnb-release-io-probe-{role}.service"}
    if len(locations) != 1 or locations[0] not in allowed:
        raise ValueError("not in the expected dedicated systemd cgroup")
    return cgroup_root / locations[0].lstrip("/") / "io.max"


def require_limits(control, expected):
    rows = {}
    for line in control.read_text().splitlines():
        if not line.strip():
            continue
        device, *options = line.split()
        if device in rows:
            raise ValueError("duplicate io.max device")
        rows[device] = dict(option.split("=", 1) for option in options)
    for device, (read, write) in expected.items():
        limits = rows.get(device, {})
        if (limits.get("rbps"), limits.get("wbps")) != (str(read), str(write)):
            raise ValueError(f"kernel did not confirm required I/O limits for {device}")


def write_limit(control, device, read, write):
    # io.max consumes one device command at a time and preserves other rows.
    command = f"{device} rbps={read} wbps={write}\n".encode("ascii")
    fd = os.open(control, os.O_WRONLY | os.O_CLOEXEC)
    try:
        if os.write(fd, command) != len(command):
            raise OSError("short io.max write")
    finally:
        os.close(fd)


def enforce(role, control, volumes, sysfs, backing):
    resolved = {lane: mounted_loop(volumes, sysfs, lane) for lane in LOOP_LIMITS[role]}
    if backing in resolved.values() or len(set(resolved.values())) != len(resolved):
        raise ValueError("release volumes must map to separate loop devices")
    expected = {backing: BACKING_LIMIT}
    require_limits(control, expected)
    for lane, device in resolved.items():
        limit = LOOP_LIMITS[role][lane]
        write_limit(control, device, *limit)
        expected[device] = limit
    require_limits(control, expected)
    return resolved


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("role", choices=UNITS)
    role = parser.parse_args().role
    try:
        backing = Path("/dev/vda").stat()
        if not stat.S_ISBLK(backing.st_mode):
            raise ValueError("backing path is not a block device")
        control = io_control_file(role, Path("/proc/self/cgroup").read_text(), Path("/sys/fs/cgroup"))
        devices = enforce(role, control, Path("/srv/ray/vnb_release"), Path("/sys"), device_number(backing.st_rdev))
    except (OSError, ValueError) as error:
        print(f"VNB release I/O startup gate failed: {error}", file=sys.stderr)
        return 1
    print("VNB release I/O limits verified: " + " ".join(f"{lane}={device}" for lane, device in devices.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
