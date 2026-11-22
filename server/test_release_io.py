"""Deterministic loop/cgroup fixtures. Never open a host mount or control file."""
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from test_release_edge import script


class ReleaseIOLimitsTests(unittest.TestCase):
    def setUp(self):
        self.guard = script("limit-release-io")
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        root = Path(folder.name)
        self.volumes = root / "vnb_release"
        self.sysfs = root / "sys"
        (self.sysfs / "dev/block").mkdir(parents=True)
        self.dev_numbers = {self.volumes: os.makedev(253, 2)}
        original_stat = type(root).stat

        def fixture_stat(path, *args, **kwargs):
            if path in self.dev_numbers:
                return SimpleNamespace(st_dev=self.dev_numbers[path])
            return original_stat(path, *args, **kwargs)

        mocked_stat = patch.object(type(root), "stat", fixture_stat)
        mocked_stat.start()
        self.addCleanup(mocked_stat.stop)
        self.control = root / "io.max"
        self.backing = "253:0"
        self.rows = {self.backing: (8_000_000, 4_000_000)}
        self.writes = []
        self.publish()

    def publish(self):
        self.control.write_text("".join(
            f"{device} rbps={rate[0]} wbps={rate[1]} riops=max wiops=max\n"
            for device, rate in self.rows.items()))

    def bind(self, lane, minor, *, other_backing=None, non_loop=False):
        device_name = "foreign" if non_loop else f"loop{minor}"
        sys_device = self.sysfs / device_name
        (sys_device / "loop").mkdir(parents=True)
        (sys_device / "loop/backing_file").write_text(
            str(other_backing or self.volumes / "images" / f"{lane}.img") + "\n")
        (self.sysfs / "dev/block" / f"7:{minor}").symlink_to(sys_device)
        self.dev_numbers[self.volumes / lane] = os.makedev(7, minor)

    def apply_kernel_command(self, control, device, read, write):
        self.assertEqual(control, self.control)
        self.writes.append((device, read, write))
        self.rows[device] = (read, write)
        self.publish()

    def enforce(self, role):
        return self.guard.enforce(role, self.control, self.volumes, self.sysfs, self.backing)

    def test_loop_assignment_is_resolved_again_after_rebind(self):
        self.bind("live", 0)
        self.bind("ops", 1)
        with patch.object(self.guard, "write_limit", side_effect=self.apply_kernel_command):
            self.assertEqual(self.enforce("receiver"), {"live": "7:0"})
            self.assertEqual(self.writes, [("7:0", 8_000_000, 4_000_000)])
            self.rows = {self.backing: (8_000_000, 4_000_000)}
            self.publish()
            self.writes.clear()
            self.bind("live", 12)
            self.bind("ops", 5)
            self.assertEqual(self.enforce("maintenance"), {"live": "7:12", "ops": "7:5"})
            self.assertEqual(self.writes, [("7:12", 4_000_000, 1_000_000), ("7:5", 4_000_000, 3_000_000)])
            self.assertEqual(self.rows[self.backing], (8_000_000, 4_000_000))
            self.assertNotIn("7:0", self.rows)
            self.assertNotIn("7:1", self.rows)

    def test_missing_or_foreign_mount_is_rejected_before_any_cgroup_write(self):
        self.bind("live", 0)
        self.dev_numbers[self.volumes / "ops"] = self.dev_numbers[self.volumes]
        with patch.object(self.guard, "write_limit") as write:
            with self.assertRaisesRegex(ValueError, "not mounted"):
                self.enforce("maintenance")
            self.bind("ops", 6, other_backing="/other/tenant.img")
            with self.assertRaisesRegex(ValueError, "wrong backing image"):
                self.enforce("maintenance")
            self.bind("ops", 7, non_loop=True)
            with self.assertRaisesRegex(ValueError, "no whole loop device"):
                self.enforce("maintenance")
            write.assert_not_called()

    def test_backing_only_or_wrong_kernel_readback_never_passes(self):
        self.bind("live", 0)
        self.rows["7:2"] = (8_000_000, 4_000_000)  # A prior/stale device must not qualify.
        self.publish()
        with patch.object(self.guard, "write_limit") as write:
            with self.assertRaisesRegex(ValueError, "required I/O limits for 7:0"):
                self.enforce("receiver")
            self.rows["7:0"] = (8_000_000, 40_000_000)
            self.publish()
            with self.assertRaisesRegex(ValueError, "required I/O limits for 7:0"):
                self.enforce("receiver")
            self.rows.pop(self.backing)
            self.publish()
            write.reset_mock()
            with self.assertRaisesRegex(ValueError, "required I/O limits for 253:0"):
                self.enforce("receiver")
            write.assert_not_called()

    def test_only_the_current_release_or_named_probe_cgroup_can_be_targeted(self):
        root = self.control.parent
        role = "receiver"
        for unit in ("vnb-release-receiver.service", "vnb-release-io-probe-receiver.service"):
            path = self.guard.io_control_file(role, f"0::/system.slice/{unit}\n", root)
            self.assertEqual(path, root / "system.slice" / unit / "io.max")
        for membership in ("0::/system.slice/other.service", "3:blkio:/system.slice/vnb-release-receiver.service",
                           "0::/system.slice/../another.service", "0::/system.slice/vnb-release-maintenance.service"):
            with self.assertRaisesRegex(ValueError, "expected dedicated"):
                self.guard.io_control_file(role, membership, root)

    def test_partial_kernel_write_fails_without_truncating_control_file(self):
        command = b"7:5 rbps=4000000 wbps=3000000\n"
        with patch.object(self.guard.os, "open", return_value=9) as open_file, \
                patch.object(self.guard.os, "write", return_value=len(command)-1) as write, \
                patch.object(self.guard.os, "close") as close:
            with self.assertRaisesRegex(OSError, "short io.max write"):
                self.guard.write_limit(self.control, "7:5", 4_000_000, 3_000_000)
        open_file.assert_called_once_with(self.control, os.O_WRONLY | os.O_CLOEXEC)
        write.assert_called_once_with(9, command)
        close.assert_called_once_with(9)


if __name__ == "__main__":
    unittest.main()
