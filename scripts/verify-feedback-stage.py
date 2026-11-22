#!/usr/bin/env python3
"""Verify staging HTTPS from an isolated macOS Test Edition and read back SQLite via SSH."""

import argparse
import hashlib
import http.client
import json
from pathlib import Path
import re
import runpy
import ssl
import subprocess
from urllib.parse import urlsplit
import uuid


DATABASE = "/var/lib/vnb-feedback-staging/feedback.sqlite"
READ_ROW = f"""
import json, sqlite3
import sys
event_id = sys.argv[1]
with sqlite3.connect("file:{DATABASE}?mode=ro", uri=True) as db:
    row = db.execute("SELECT body FROM events WHERE id=? AND kind='feedback'", (event_id,)).fetchone()
print(json.dumps(json.loads(row[0])["payload"] if row else None))
"""


def check_routes(url, context):
    checks = {
        ("GET", "/v1/health"): 200,
        ("GET", "/privacy.html"): 200,
        ("GET", "/admin/report"): 404,
        ("GET", "/v1/community/tasks"): 404,
        ("GET", "/v1/leaderboards"): 404,
        ("GET", "/v1/events"): 404,
        ("POST", "/v1/health"): 404,
        ("GET", "/"): 404,
    }
    result = {}
    for (method, path), expected in checks.items():
        connection = http.client.HTTPSConnection(url.hostname, url.port, context=context, timeout=8)
        try:
            connection.request(method, path)
            response = connection.getresponse()
            body = response.read(131073)
            if response.status != expected or len(body) > 131072:
                raise RuntimeError(f"Unexpected response for {method} {path}: {response.status}")
            if path == "/v1/health" and method == "GET":
                if response.getheader("X-VNB-Environment") != "staging":
                    raise RuntimeError("Endpoint does not identify itself as VNB staging")
                health = json.loads(body)
                if health.get("ok") is not True or health.get("api_version") != 1 or health.get("schema_version") != 2:
                    raise RuntimeError("Unexpected receiver health contract")
            result[f"{method} {path}"] = response.status
        finally:
            connection.close()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path, help="Original offline macOS Test Edition .app")
    parser.add_argument("--endpoint", required=True, help="Staging HTTPS API root ending in /v1")
    parser.add_argument("--ssh", default="ray-vps", help="Existing staging SSH alias")
    parser.add_argument("--ca-file", type=Path, help="Private CA for loopback SSH forwarding only")
    args = parser.parse_args()
    url = urlsplit(args.endpoint)
    if (url.scheme != "https" or url.path != "/v1" or not url.hostname or url.username
            or url.password or url.query or url.fragment or args.endpoint.endswith(("?", "#"))):
        parser.error("Use a canonical HTTPS staging API root ending in /v1")
    if args.ca_file and url.hostname not in ("localhost", "127.0.0.1", "::1"):
        parser.error("Private CA trust is allowed only for the loopback SSH tunnel")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]*", args.ssh):
        parser.error("Invalid SSH alias")

    root = Path(__file__).resolve().parents[1]
    work = root / ".godot/feedback-connectivity" / uuid.uuid4().hex
    work.mkdir(mode=0o700, parents=True)
    print(f"Private evidence directory: {work}", flush=True)
    context = ssl.create_default_context(cafile=str(args.ca_file) if args.ca_file else None)
    if args.ca_file:
        try:
            check_routes(url, ssl.create_default_context())
        except ssl.SSLCertVerificationError:
            pass
        else:
            raise RuntimeError("The private staging CA is already in the system trust store")
    routes = check_routes(url, context)

    helpers = runpy.run_path(str(root / "scripts/verify-package-feedback.py"))
    manifest, package, binary, hashes, _ = helpers["prepare_package"](args.app.resolve(), "macOS", work)
    if manifest.get("edition") != "test" or manifest.get("feedback_endpoint") != "":
        parser.error("Use an original offline Test Edition package")
    scene = work / "probe.tscn"
    helpers["write_probe_scene"](scene, root / "scripts/staging-feedback-probe.gd")
    profile = f"PackageFeedback-Staging-{work.name}"
    user_dir = f"VonNeumannBottleneckChecks/{profile}"
    override = binary.parent / "override.cfg"

    def phase(name):
        helpers["write_override"](override, user_dir, scene, profile, name, work)
        config = override.read_text(encoding="utf-8").replace(
            "[application]\n", "[application]\nfeedback_endpoint=" + json.dumps(args.endpoint) + "\n", 1)
        config += "[playtest]\noffline_feedback=false\n"
        if args.ca_file:
            config += "[network]\ntls/certificate_bundle_override=" + json.dumps(str(args.ca_file.resolve())) + "\n"
        override.write_text(config, encoding="utf-8")
        command = [str(binary), "--headless", "--log-file", str(work / f"{name}-engine.log"),
                   "--", "--enable-playtest-telemetry", "--enable-playtest-feedback"]
        result = subprocess.run(command, cwd=work, capture_output=True, text=True, timeout=35)
        (work / f"{name}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        if result.returncode or "SCRIPT ERROR" in result.stderr:
            raise RuntimeError(f"{name} failed; inspect {work / (name + '.log')}")
        return result.stdout

    def read_row(event_id):
        result = subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8", args.ssh,
             "sudo", "-n", "python3", "-B", "-", event_id],
            input=READ_ROW, capture_output=True, text=True, check=True, timeout=20)
        return json.loads(result.stdout)

    try:
        result = phase("submit")
        match = re.search(r"^STAGING_RECEIVED ([a-f0-9]{64})$", result, re.MULTILINE)
        if not match:
            raise RuntimeError("No stable client receipt")
        event_id = match.group(1)
        expected = {
            "chapter_id": "creation", "level_id": "G2_intent", "mode": "test",
            "source": "automated", "sharing_mode": "opinion",
            "build_version": manifest["display_version"], "source_commit": manifest["source_commit"],
            "test_batch": manifest["test_batch"], "note": "SYNTHETIC VNB staging connectivity",
        }
        row = read_row(event_id)
        if row is None or any(row.get(key) != value for key, value in expected.items()):
            raise RuntimeError("SQLite did not contain the matching staging opinion and identity")
    finally:
        delete_result = phase("delete")
    if "STAGING_DELETED" not in delete_result or read_row(event_id) is not None:
        raise RuntimeError("SQLite cleanup did not match the client deletion acknowledgement")

    if any(hashlib.sha256((package / name).read_bytes()).hexdigest() != digest for name, digest in hashes.items()):
        raise RuntimeError("QA executable or pack changed")
    evidence = {"passed": True, "scope": "private HTTPS" if args.ca_file else "HTTPS with system trust",
                "engine": manifest["engine"], "build_id": manifest["build_id"], "source_commit": manifest["source_commit"],
                "test_batch": manifest["test_batch"], "feedback_id": event_id, "routes": routes,
                "sqlite_row_verified": True, "sqlite_row_removed": True, "test_edition_hashes": hashes}
    if args.ca_file:
        evidence["private_ca_rejected_by_default_trust"] = True
    (work / "receipt.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: Test Edition → HTTPS → VPS SQLite → matching receipt and deletion. {event_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
