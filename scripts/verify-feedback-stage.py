#!/usr/bin/env python3
"""Verify Test Edition feedback over private staging or the restricted public HTTPS ingress."""

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


PUBLIC_ENDPOINT = "https://feedback.yanruiqing.com:8443/v1"
STAGING_DATABASE = "/var/lib/vnb-feedback-staging/feedback.sqlite"
PUBLIC_DATABASE = "/srv/ray/data/vnb/local/feedback.sqlite"
READ_ROW = """
import json, sqlite3
import sys
database, event_id = sys.argv[1:]
with sqlite3.connect("file:" + database + "?mode=ro", uri=True) as db:
    rows = db.execute("SELECT body FROM events WHERE id=? AND kind='feedback'", (event_id,)).fetchall()
print(json.dumps([json.loads(row[0])["payload"] for row in rows]))
"""


def check_routes(url, context, environment):
    checks = {
        ("GET", "/v1/health"): 200,
        ("GET", "/privacy.html"): 200,
        ("GET", "/admin/report"): 404,
        ("POST", "/admin/report"): 404,
        ("GET", "/v1/report"): 404,
        ("GET", "/v1/data"): 404,
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
                if response.getheader("X-VNB-Environment") != environment:
                    raise RuntimeError("Endpoint does not identify the expected VNB environment")
                health = json.loads(body)
                if health.get("ok") is not True or health.get("api_version") != 1 or health.get("schema_version") != 2:
                    raise RuntimeError("Unexpected receiver health contract")
            result[f"{method} {path}"] = response.status
        finally:
            connection.close()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path, help="Original macOS Test Edition .app for this environment")
    parser.add_argument("--endpoint", required=True, help="HTTPS API root ending in /v1")
    parser.add_argument("--ssh", default="ray-vps", help="Existing staging SSH alias")
    parser.add_argument("--ca-file", type=Path, help="Private CA for loopback SSH forwarding only")
    parser.add_argument("--public-receiver", action="store_true",
                        help="Use the restricted public endpoint and existing live VNB database")
    args = parser.parse_args()
    if args.public_receiver and (args.endpoint != PUBLIC_ENDPOINT or args.ca_file):
        parser.error("The restricted public endpoint requires the fixed host and default TLS trust")
    environment = "public-feedback" if args.public_receiver else "staging"
    database = PUBLIC_DATABASE if args.public_receiver else STAGING_DATABASE
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
            check_routes(url, ssl.create_default_context(), environment)
        except ssl.SSLCertVerificationError:
            pass
        else:
            raise RuntimeError("The private staging CA is already in the system trust store")
    routes = check_routes(url, context, environment)

    helpers = runpy.run_path(str(root / "scripts/verify-package-feedback.py"))
    manifest, package, binary, hashes, _ = helpers["prepare_package"](args.app.resolve(), "macOS", work)
    expected_package_endpoint = args.endpoint if args.public_receiver else ""
    if (manifest.get("edition") != "test" or manifest.get("feedback_endpoint") != expected_package_endpoint
            or bool(manifest.get("network_feedback_test")) != args.public_receiver):
        parser.error("Use the network feedback Test Edition for public mode or the offline Test Edition for staging")
    scene = work / "probe.tscn"
    helpers["write_probe_scene"](scene, root / "scripts/staging-feedback-probe.gd")
    profile = f"PackageFeedback-Staging-{work.name}"
    user_dir = f"VonNeumannBottleneckChecks/{profile}"
    override = binary.parent / "override.cfg"

    def phase(name):
        helpers["write_override"](override, user_dir, scene, profile, name, work)
        config = override.read_text(encoding="utf-8")
        config += "expected_endpoint=" + json.dumps(args.endpoint) + "\n"
        if args.public_receiver:
            config += "public_receiver=true\n"
        else:
            config = config.replace(
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
             "sudo", "-n", "python3", "-B", "-", database, event_id],
            input=READ_ROW, capture_output=True, text=True, check=True, timeout=20)
        return json.loads(result.stdout)

    try:
        result = phase("submit")
        match = re.search(r"^STAGING_RECEIVED ([a-f0-9]{64})$", result, re.MULTILINE)
        if not match:
            raise RuntimeError("No stable client receipt")
        event_id = match.group(1)
        if f"STAGING_RETRIED {event_id}" not in result.splitlines():
            raise RuntimeError("No acknowledgement of the exact outbox retry")
        expected = {
            "chapter_id": "creation", "level_id": "G2_intent", "mode": "test",
            "source": "automated", "sharing_mode": "opinion",
            "build_version": manifest["display_version"], "source_commit": manifest["source_commit"],
            "test_batch": manifest["test_batch"], "note": "SYNTHETIC VNB staging connectivity",
        }
        rows = read_row(event_id)
        if len(rows) != 1 or any(rows[0].get(key) != value for key, value in expected.items()):
            raise RuntimeError("SQLite did not contain exactly one matching opinion after retry")
    finally:
        delete_result = phase("delete")
    if "STAGING_DELETED" not in delete_result or read_row(event_id):
        raise RuntimeError("SQLite cleanup did not match the client deletion acknowledgement")

    if any(hashlib.sha256((package / name).read_bytes()).hexdigest() != digest for name, digest in hashes.items()):
        raise RuntimeError("QA executable or pack changed")
    evidence = {"passed": True, "scope": "restricted public HTTPS" if args.public_receiver else "private HTTPS",
                "engine": manifest["engine"], "build_id": manifest["build_id"], "source_commit": manifest["source_commit"],
                "test_batch": manifest["test_batch"], "feedback_id": event_id, "routes": routes,
                "sqlite_row_verified": True, "duplicate_rows": 1, "sqlite_row_removed": True, "test_edition_hashes": hashes}
    if args.ca_file:
        evidence["private_ca_rejected_by_default_trust"] = True
    (work / "receipt.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: Test Edition → HTTPS → VPS SQLite → matching receipt and deletion. {event_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
