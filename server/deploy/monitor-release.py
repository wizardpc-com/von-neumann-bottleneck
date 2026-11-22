#!/usr/bin/env python3
"""VNB-only local probes and durable, aggregate journal alerts."""
from datetime import datetime, timezone
import http.client
import ipaddress
import json
import os
from pathlib import Path
import socket
import ssl
import subprocess
import time

from importlib.util import module_from_spec, spec_from_file_location
from maintain import RELEASE_BACKUP_LIMIT, RELEASE_OPS_FREE, available_bytes, host_has_reserve, metadata_for
from release_ingress import HEARTBEAT

check_spec = spec_from_file_location("release_check", Path(__file__).with_name("check-release-feedback.py"))
check = module_from_spec(check_spec)
check_spec.loader.exec_module(check)

ROOT = Path("/srv/ray/vnb_release")
STATE = Path("/var/lib/vnb-release-monitor/status.json")
COUNTERS = {"rate_limit", "storage_limit", "storage_unavailable", "retention_failed"}
FRESH = 36 * 3600
REMIND = 24 * 3600


class LocalEdge(http.client.HTTPSConnection):
    def __init__(self, bind):
        self.bind = str(ipaddress.IPv4Address(bind))
        super().__init__(check.HOSTNAME, 8443, timeout=5, context=ssl.create_default_context())

    def connect(self):
        with socket.create_connection((self.bind, self.port), self.timeout) as raw:
            self.sock = self._context.wrap_socket(raw, server_hostname=self.host)


def probe_edge(bind):
    connection = LocalEdge(bind)
    try:
        connection.connect()
        peer = connection.sock.getpeercert()
        certificate = connection.sock.getpeercert(binary_form=True)
        check.check_read_routes(connection, public=True, rehearsal=False)
        return ssl.cert_time_to_seconds(peer["notAfter"]), certificate
    finally:
        connection.close()


def receiver_status():
    connection = http.client.HTTPConnection("127.0.0.1", 18082, timeout=5)
    try:
        check.check_read_routes(connection, public=False, rehearsal=False)
        value = json.loads(check.call(connection, "GET", "/internal/release-health", 200))
    finally:
        connection.close()
    counts = value.get("counts", {}) if isinstance(value, dict) else {}
    if (set(counts) != COUNTERS or any(type(n) is not int or n < 0 for n in counts.values())
            or not isinstance(value.get("epoch"), str) or not value["epoch"].isdigit()
            or type(value.get("intake_open")) is not bool):
        raise ValueError("bad aggregate receiver status")
    return value


def fresh(timestamp, now):
    return -300 <= now - timestamp <= FRESH


def storage_issues(root, now):
    issues = set()
    if not host_has_reserve(root):
        issues.add("backing_space_low")
    if available_bytes(root / "ops") < RELEASE_OPS_FREE:
        issues.add("ops_space_low")
    try:
        newest = max((root / "ops/backups").glob("vnb-feedback-*.sqlite"), default=None)
        if newest is None:
            raise ValueError("no snapshot")
        info = metadata_for(newest)
        when = datetime.strptime(info["created_utc"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        if not fresh(when.timestamp(), now) or not 0 < newest.stat().st_size <= RELEASE_BACKUP_LIMIT:
            raise ValueError("stale snapshot")
    except (OSError, ValueError, KeyError, TypeError):
        issues.add("backup_missing_stale_or_invalid")
    for name in ("report.json", "report.html"):
        path = root / "ops/reports/current" / name
        try:
            if path.is_symlink() or not fresh(path.stat().st_mtime, now) or not path.stat().st_size:
                raise ValueError("stale report")
        except (OSError, ValueError):
            issues.add("report_missing_or_stale")
    return issues


def job_issues():
    issues = set()
    for code, args, expected in (
        ("maintenance_timer_inactive", ["is-active", "vnb-release-maintenance.timer"], "active"),
        ("maintenance_failed", ["show", "-p", "Result", "--value", "vnb-release-maintenance.service"], "success"),
    ):
        result = subprocess.run(["/usr/bin/systemctl", *args], capture_output=True, text=True, timeout=4)
        if result.returncode or result.stdout.strip() != expected:
            issues.add(code)
    return issues


def receiver_issues(current, previous):
    issues = set() if current["intake_open"] else {"ingress_storage_closed"}
    before = previous.get("receiver", {})
    same = current["epoch"] == before.get("epoch")
    previous_counts = before.get("counts", {}) if same else {}
    deltas = {key: max(0, current["counts"][key] - previous_counts.get(key, 0)) for key in COUNTERS}
    if deltas["rate_limit"] >= 30:
        issues.add("rate_limit_activity")
    for key in ("storage_limit", "storage_unavailable", "retention_failed"):
        if deltas[key]:
            issues.add(key)
    return issues


def read_status(path):
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def publish(path, previous, issues, now, receiver):
    active = sorted(issues)
    old = previous.get("issues", [])
    last = previous.get("last_notice", 0)
    if old != active or (active and now - last >= REMIND):
        print("VNB_RELEASE_ALERT " + ",".join(active) if active else "VNB_RELEASE_RECOVERED", flush=True)
        last = now
    status = {"checked_utc": now, "issues": active, "last_notice": last, "receiver": receiver}
    staging = path.with_suffix(".next")
    staging.write_text(json.dumps(status, sort_keys=True) + "\n")
    staging.replace(path)
    return bool(active)


def publish_heartbeat(path, now, ok):
    staging = path.with_suffix(".next")
    staging.write_text(json.dumps({"checked_utc": now, "ok": ok}) + "\n")
    staging.chmod(0o640)
    staging.replace(path)


def main():
    now = int(time.time())
    previous = read_status(STATE)
    issues = set()
    current = previous.get("receiver", {})
    try:
        current = receiver_status()
        issues |= receiver_issues(current, previous)
    except (OSError, ValueError, KeyError, TypeError, http.client.HTTPException):
        issues.add("receiver_probe_failed")
    try:
        expiry, _ = probe_edge(os.environ["VNB_PUBLIC_BIND"])
        if expiry - now <= 30 * 86400:
            issues.add("certificate_due_within_30d")
    except (OSError, ValueError, KeyError, http.client.HTTPException):
        issues.add("edge_tls_or_route_failed")
    try:
        issues |= storage_issues(ROOT, now)
    except OSError:
        issues.add("ops_space_probe_failed")
    try:
        issues |= job_issues()
    except (OSError, subprocess.SubprocessError):
        issues.add("maintenance_probe_failed")
    failed = publish(STATE, previous, issues, now, current)
    publish_heartbeat(HEARTBEAT, now, not failed)
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
