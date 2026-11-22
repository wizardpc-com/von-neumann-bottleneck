#!/usr/bin/env python3
"""Check the fixed VNB release ingress; writes require the disposable rehearsal."""
import argparse
import http.client
import json
import secrets
import ssl
import sys
import time

HOSTNAME = "feedback.yanruiqing.com"
HEARTBEAT_MAX_AGE = 11 * 60
REHEARSAL_BUILD = {
    "build_version": "vnb-rehearsal",
    "source_commit": "0" * 40,
    "test_batch": "vnb-rehearsal-smoke",
    "mode": "test",
}


def call(connection, method, path, status, *, public=False, payload=None, headers=None, expected_headers=None):
    headers = dict(headers or {})
    body = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(payload).encode()
    connection.request(method, path, body, headers)
    with connection.getresponse() as response:
        if response.status != status:
            raise ValueError(f"{method} {path}: expected HTTP {status}, got {response.status}")
        if public and response.getheader("X-VNB-Environment") != "public-feedback":
            raise ValueError("unexpected TLS edge")
        for name, expected in (expected_headers or {}).items():
            if response.getheader(name) != expected:
                raise ValueError("unexpected header for " + path)
        value = response.read(131073)
        if len(value) > 131072:
            raise ValueError("unexpected response size")
        return value


def check_read_routes(connection, *, public, rehearsal, historical=False):
    health = json.loads(call(connection, "GET", "/v1/health" if public else "/health", 200, public=public))
    expected = {"ok": True, "api_version": 1, "schema_version": 2, "retention_days": 30}
    if not historical:
        expected["ingress"] = "release-rehearsal" if rehearsal else "release"
    if health != expected:
        raise ValueError("unexpected receiver mode or health")
    if public:
        qa_notice = call(connection, "GET", "/privacy.html", 200, public=True)
        if b"<title>" not in qa_notice:
            raise ValueError("QA privacy notice missing")
        if not historical:
            player_notice = call(connection, "GET", "/privacy-player.html", 200, public=True)
            if b"Player Feedback Privacy Notice</title>" not in player_notice:
                raise ValueError("player privacy notice missing")
        for path in ("/admin/report", "/v1/community/tasks", "/v1/leaderboards", "/v1/events", "/v1/data",
                     "/internal/release-health"):
            call(connection, "GET", path, 404, public=True)
        call(connection, "HEAD", "/privacy-player.html", 404, public=True)


def check_heartbeat(connection):
    def unique_object(fields):
        result = dict(fields)
        if len(result) != len(fields):
            raise ValueError("duplicate heartbeat fields")
        return result

    value = json.loads(call(connection, "GET", "/v1/status", 200, public=True),
                       object_pairs_hook=unique_object)
    if (not isinstance(value, dict) or set(value) != {"checked_utc", "ok"}
            or value["ok"] is not True or type(value["checked_utc"]) is not int
            or not 0 <= int(time.time()) - value["checked_utc"] <= HEARTBEAT_MAX_AGE):
        raise ValueError("heartbeat unavailable, stale or invalid")


def check_results_routes(connection):
    page = call(connection, "GET", "/my-results.html", 200, public=True,
                expected_headers={"Cache-Control": "no-store", "Referrer-Policy": "no-referrer",
                                  "X-Robots-Tag": "noindex, nofollow"})
    if b"data-vnb-results" not in page:
        raise ValueError("personal results page missing")
    call(connection, "HEAD", "/my-results.html", 404, public=True)
    call(connection, "GET", "/v1/my-results", 404, public=True)


def rehearse(connection):
    # The receiver rejects this installation namespace in production, including DELETE.
    identity = {"client_id": "vnb-rehearsal-" + secrets.token_hex(16), "deletion_token": secrets.token_hex(32)}
    event_id = secrets.token_hex(32)
    payload = dict(REHEARSAL_BUILD, source="external_player", source_batch=REHEARSAL_BUILD["test_batch"],
                   category="other", note="Synthetic VNB release rehearsal")
    record = {"event_id": event_id, "kind": "feedback", "payload": payload}
    body = dict(identity, records=[record])
    options = {"public": True, "headers": {"X-VNB-Client-IP": "invalid", "X-VNB-Edge-Token": "invalid",
                                          "X-Forwarded-For": "192.0.2.77"}}
    qa = dict(record, payload=dict(payload, source="automated"))
    value = json.loads(call(connection, "POST", "/v1/events", 403, payload=dict(identity, records=[record, qa]), **options))
    if value != {"error": "release_provenance"}:
        raise ValueError("unexpected QA rejection")
    for _ in range(2):
        if json.loads(call(connection, "POST", "/v1/events", 200, payload=body, **options)) != {"ack": [event_id]}:
            raise ValueError("wrong receipt")
    for _ in range(2):
        if json.loads(call(connection, "DELETE", "/v1/data", 200, payload=identity, **options)) != {"deleted": True}:
            raise ValueError("wrong deletion receipt")
    if json.loads(call(connection, "POST", "/v1/events", 410, payload=body, **options)) != {"error": "identity_deleted"}:
        raise ValueError("deleted installation accepted a replay")


def wait_for_local_receiver(rehearsal):
    deadline = time.monotonic() + 5
    while True:
        connection = http.client.HTTPConnection("127.0.0.1", 18082, timeout=5)
        try:
            return check_read_routes(connection, public=False, rehearsal=rehearsal)
        except ConnectionRefusedError:
            if time.monotonic() >= deadline:
                raise
        finally:
            connection.close()
        time.sleep(0.2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--local", action="store_true")
    target.add_argument("--public", action="store_true")
    target.add_argument("--public-historical", action="store_true")
    parser.add_argument("--rehearsal", action="store_true")
    parser.add_argument("--synthetic-write", action="store_true")
    parser.add_argument("--heartbeat", action="store_true", help="require a fresh healthy production heartbeat")
    parser.add_argument("--results", action="store_true", help="check the personal results page and private API method")
    args = parser.parse_args()
    if args.heartbeat and (not args.public or args.rehearsal):
        parser.error("--heartbeat requires production --public")
    if args.results and (not args.public or args.rehearsal):
        parser.error("--results requires production --public")
    if (args.rehearsal and args.public_historical) or (args.synthetic_write and not (args.public and args.rehearsal)):
        parser.error("synthetic writes require --public --rehearsal")
    public = args.public or args.public_historical
    try:
        if public:
            connection = http.client.HTTPSConnection(HOSTNAME, 8443, timeout=5, context=ssl.create_default_context())
            try:
                check_read_routes(connection, public=True, rehearsal=args.rehearsal, historical=args.public_historical)
                if args.heartbeat:
                    check_heartbeat(connection)
                if args.results:
                    check_results_routes(connection)
                if args.synthetic_write:
                    rehearse(connection)
            finally:
                connection.close()
        else:
            wait_for_local_receiver(args.rehearsal)
    except (OSError, ValueError, http.client.HTTPException):
        # Never print response bodies, URLs from exceptions, headers or credentials.
        print("VNB feedback validation failed; check the selected lane and scoped unit health.", file=sys.stderr)
        return 1
    print("VNB feedback checks passed" + (" including disposable synthetic writes" if args.synthetic_write else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
