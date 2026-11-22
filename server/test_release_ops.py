"""Synthetic monitor, heartbeat and renewal checks. No host services are invoked."""
from contextlib import redirect_stdout
from datetime import datetime, timezone
import hashlib
from io import StringIO
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from test_release_edge import DEPLOY, script
from test_release_ingress import python_with_synthetic_capacity
import release_ingress
from storage import migrate


class ReleaseOpsTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        with patch.object(sys, "path", [str(DEPLOY), *sys.path]):
            self.monitor = script("monitor-release")
            self.installer = script("install-release-certificate")

    def test_heartbeat_fails_closed_and_exposes_only_two_fields(self):
        path = self.root / "heartbeat.json"
        with patch.object(release_ingress, "HEARTBEAT", path):
            self.assertEqual(release_ingress.heartbeat(1000), {"checked_utc": None, "ok": False})
            self.monitor.publish_heartbeat(path, 1000, True)
            self.assertEqual(path.stat().st_mode & 0o777, 0o640)
            self.assertEqual(release_ingress.heartbeat(1660), {"checked_utc": 1000, "ok": True})
            self.assertEqual(release_ingress.heartbeat(1661), {"checked_utc": 1000, "ok": False})
            self.assertFalse(release_ingress.heartbeat(999)["ok"])
            self.monitor.publish_heartbeat(path, 1000, False)
            self.assertFalse(release_ingress.heartbeat(1060)["ok"])
            path.write_text(json.dumps({"checked_utc": 1000, "ok": True, "private": "synthetic data"}))
            self.assertEqual(release_ingress.heartbeat(1060), {"checked_utc": None, "ok": False})

    def test_public_heartbeat_checker_requires_exact_fresh_healthy_json(self):
        checker = self.monitor.check
        self.assertEqual(checker.HEARTBEAT_MAX_AGE, release_ingress.HEARTBEAT_MAX_AGE)
        with patch.object(checker.time, "time", return_value=1660):
            with patch.object(checker, "call", return_value=b'{"checked_utc":1000,"ok":true}') as call:
                checker.check_heartbeat(None)
                call.assert_called_once_with(None, "GET", "/v1/status", 200, public=True)
            for body in (b'{"checked_utc":999,"ok":true}', b'{"checked_utc":1661,"ok":true}',
                         b'{"checked_utc":1000,"ok":false}', b'{"checked_utc":true,"ok":true}',
                         b'{"checked_utc":1000,"ok":1}', b'{"checked_utc":1000,"ok":true,"extra":1}',
                         b'{"checked_utc":1000,"ok":false,"ok":true}', b'[]'):
                with self.subTest(body=body), patch.object(checker, "call", return_value=body):
                    with self.assertRaises(ValueError):
                        checker.check_heartbeat(None)

    def test_heartbeat_flag_is_production_public_only(self):
        checker = self.monitor.check
        for args in (["--local"], ["--public-historical"], ["--public", "--rehearsal"]):
            with self.subTest(args=args), patch.object(sys, "argv", ["checker", *args, "--heartbeat"]):
                with patch("sys.stderr", StringIO()):
                    with self.assertRaises(SystemExit) as exit_result:
                        checker.main()
                self.assertEqual(exit_result.exception.code, 2)

    def test_monitor_deduplicates_incidents_and_records_recovery(self):
        status = self.root / "status.json"
        with redirect_stdout(StringIO()) as journal:
            self.assertTrue(self.monitor.publish(status, {}, {"maintenance_failed"}, 1000, {}))
            self.assertTrue(self.monitor.publish(status, self.monitor.read_status(status),
                                                 {"maintenance_failed"}, 1300, {}))
            self.assertFalse(self.monitor.publish(status, self.monitor.read_status(status), set(), 1600, {}))
        self.assertEqual(journal.getvalue().splitlines(),
                         ["VNB_RELEASE_ALERT maintenance_failed", "VNB_RELEASE_RECOVERED"])

    def test_monitor_flags_stale_backup_report_pressure_and_rate_delta(self):
        now = 1_800_000_000
        backups = self.root / "ops/backups"
        reports = self.root / "ops/reports/current"
        backups.mkdir(parents=True)
        reports.mkdir(parents=True)
        for name in ("report.json", "report.html"):
            path = reports / name
            path.write_text("synthetic")
            os.utime(path, (now, now))
        timestamp = datetime.fromtimestamp(now, timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        snapshot = backups / f"vnb-feedback-{timestamp}-12345678.sqlite"
        snapshot.write_bytes(b"synthetic")
        metadata = {"created_utc": datetime.fromtimestamp(now, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}
        with patch.object(self.monitor, "host_has_reserve", return_value=True), \
                patch.object(self.monitor, "available_bytes", return_value=2 * 1024**3), \
                patch.object(self.monitor, "metadata_for", return_value=metadata):
            self.assertEqual(self.monitor.storage_issues(self.root, now), set())
            self.assertEqual(self.monitor.storage_issues(self.root, now + 40 * 3600),
                             {"backup_missing_stale_or_invalid", "report_missing_or_stale"})
        counts = dict.fromkeys(self.monitor.COUNTERS, 0)
        before = {"receiver": {"epoch": "123", "counts": counts}}
        current = {"epoch": "123", "intake_open": False,
                   "counts": dict(counts, rate_limit=30, storage_limit=1)}
        self.assertEqual(self.monitor.receiver_issues(current, before),
                         {"ingress_storage_closed", "rate_limit_activity", "storage_limit"})

    def test_failed_certificate_activation_restores_both_previous_files(self):
        active = self.root / "tls"
        active.mkdir()
        old_cert, old_key = active / "fullchain.pem", active / "key.pem"
        old_cert.write_bytes(b"old cert")
        old_key.write_bytes(b"old key")
        new_cert, new_key = self.root / "candidate.pem", self.root / "candidate.key"
        new_cert.write_bytes(b"new cert")
        new_key.write_bytes(b"new key")
        calls = []

        def restart_only_edge():
            calls.append((old_cert.read_bytes(), old_key.read_bytes()))

        with patch.object(self.installer, "validate"), \
                patch.object(self.installer, "leaf", side_effect=Path.read_bytes), \
                patch.object(self.installer, "expiry", side_effect=[2, 1]), \
                patch.object(self.installer, "restart_edge", side_effect=restart_only_edge), \
                patch.object(self.installer, "require_served", side_effect=[ValueError, None]):
            with self.assertRaisesRegex(RuntimeError, "prior certificate restored"):
                self.installer.rotate(active, new_cert, new_key, "127.0.0.1")
        self.assertEqual(calls, [(b"new cert", b"new key"), (b"old cert", b"old key")])
        self.assertEqual(sorted(p.name for p in active.iterdir()), ["fullchain.pem", "key.pem"])

    def test_certificate_validation_uses_trust_hostname_and_matching_key(self):
        executable = shutil.which("openssl")
        if executable is None:
            self.skipTest("OpenSSL unavailable")
        help_text = subprocess.run([executable, "verify", "-help"], capture_output=True).stderr
        if b"-verify_hostname" not in help_text:
            self.skipTest("OpenSSL hostname verification unavailable")
        ca, ca_key = self.root / "ca.pem", self.root / "ca.key"
        leaf, key, request = (self.root / name for name in ("leaf.pem", "leaf.key", "request.pem"))
        extensions = self.root / "extensions"
        extensions.write_text("subjectAltName=DNS:feedback.yanruiqing.com\nextendedKeyUsage=serverAuth\n")

        def generate(*args):
            subprocess.run([executable, *map(str, args)], check=True, timeout=10,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        generate("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "120",
                 "-subj", "/CN=VNB synthetic CA", "-keyout", ca_key, "-out", ca)
        generate("req", "-new", "-newkey", "rsa:2048", "-nodes",
                 "-subj", "/CN=feedback.yanruiqing.com", "-keyout", key, "-out", request)
        generate("x509", "-req", "-in", request, "-CA", ca, "-CAkey", ca_key, "-set_serial", "1",
                 "-days", "90", "-extfile", extensions, "-out", leaf)
        with patch.dict(os.environ, {"SSL_CERT_FILE": str(ca)}), patch.object(self.installer, "OPENSSL", executable):
            self.installer.validate(leaf, key)
            with self.assertRaisesRegex(ValueError, "do not match"):
                self.installer.validate(leaf, ca_key)
            with patch.object(self.installer, "HOST", "different.invalid"), self.assertRaises(subprocess.CalledProcessError):
                self.installer.validate(leaf, key)

    def test_release_triage_cli_refreshes_private_report_from_synthetic_receipt(self):
        database = self.root / "feedback.sqlite"
        report = self.root / "reports/current"
        report.parent.mkdir()
        triage = report.parent / "triage.sqlite"
        backup = self.root / "backups"
        receipt = "synthetic-test-receipt"
        body = json.dumps({"kind": "feedback", "payload": {"source": "external_player",
                          "mode": "test", "test_batch": "public-test-fixture", "note": "Synthetic test note"}})
        db = sqlite3.connect(database)
        try:
            migrate(db)
            with db:
                db.execute("INSERT INTO events VALUES (?,?,?,?,?,?)", (receipt, "fixture-client", 123, "feedback",
                           body, hashlib.sha256(body.encode()).hexdigest()))
        finally:
            db.close()
        subprocess.run([sys.executable, "-B", str(DEPLOY.parent / "private_report.py"), "--database", str(database),
                        "--triage", str(triage), "--set-status", receipt, "needs_retest"], check=True, capture_output=True)
        subprocess.run([*python_with_synthetic_capacity(DEPLOY / "maintain.py"), "daily", "--release-limits",
                        "--database", str(database), "--backup-dir", str(backup), "--report-dir", str(report),
                        "--triage", str(triage), "--source-commit", "a" * 40], check=True, capture_output=True)
        result = json.loads((report / "report.json").read_text())["received_feedback"][0]
        self.assertEqual((result["event_id"], result["mode"], result["triage"]["status"]),
                         (receipt, "test", "needs_retest"))
        self.assertIn('data-triage="needs_retest" data-mode="test"', (report / "report.html").read_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
