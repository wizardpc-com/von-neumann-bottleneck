"""Authenticated, bounded projection of an installation's opted-in statistics."""
import hashlib
import hmac
import json
import re

from community import validate_task_context


CLIENT_ID = re.compile(r"[0-9a-f]{32}")
READ_KEY = re.compile(r"[0-9a-f]{64}")
REQUEST_BYTES = 256
SCAN_LIMIT = 512
LEVEL_LIMIT = 120
KEY_DOMAIN = "vnb-results-v1:"
COMPLETION_FIELDS = ("cycles", "total_cycles", "cost")
VISIT_FIELDS = ("official_runs", "debug_runs", "max_hint_stage")

# The owner index includes rowid as its tie-breaker. This reads the newest
# bounded owner slice without walking other installations or sorting their rows.
OWNER_READ = """SELECT CASE WHEN kind='event' AND received>=? THEN body END
                FROM events INDEXED BY event_owner_idx WHERE client_id=?
                ORDER BY rowid DESC LIMIT ?"""


def read_key(client_id, deletion_hash):
    return hashlib.sha256(f"{KEY_DOMAIN}{client_id}:{deletion_hash}".encode("utf-8")).hexdigest()


def credentials(body):
    if set(body) != {"client_id", "key"}:
        raise ValueError("invalid results credentials")
    client, key = body["client_id"], body["key"]
    if (not isinstance(client, str) or not CLIENT_ID.fullmatch(client)
            or not isinstance(key, str) or not READ_KEY.fullmatch(key)):
        raise ValueError("invalid results credentials")
    return client, key


def authorized(db, client, key):
    row = db.execute("""SELECT deletion_hash FROM clients WHERE id=?
                        AND NOT EXISTS (SELECT 1 FROM tombstones WHERE client_id=?)""",
                     (client, client)).fetchone()
    expected = read_key(client, row[0] if row else "0" * 64)
    return hmac.compare_digest(key, expected) and row is not None


def metrics(payload, fields):
    return {name: payload[name] for name in fields
            if type(payload.get(name)) is int and 0 <= payload[name] <= 10**10}


def completed_stats(encoded, release):
    if encoded is None:
        return None
    try:
        record = json.loads(encoded)
        payload = record["payload"]
        if (record["kind"] != "event" or payload.get("sharing_mode") not in ("basic", "detailed")
                or payload.get("consent_version") != "sharing-2"
                or payload.get("privacy_notice_version") not in ("2026-09-11", "2026-10-17")
                or not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", payload.get("consent_timestamp", ""))
                or not release.admits([record])):
            return None
        event = payload.get("event")
        if event != "level_complete" and not (
                event == "visit_summary" and payload.get("completed_during_visit") is True
                and payload.get("completed") is True and payload.get("visit_id")):
            return None
        validate_task_context(payload, required=True)
        visit = payload.get("visit_id", "")
        if not isinstance(visit, str):
            return None
        return payload, event == "visit_summary", visit
    except (ValueError, TypeError, KeyError, AttributeError, RecursionError):
        return None


def view(db, release, client, now, retention_days):
    rows = db.execute(OWNER_READ, (now - retention_days * 86400, client, SCAN_LIMIT + 1)).fetchall()
    selected = {}
    limited = len(rows) > SCAN_LIMIT
    for encoded, in rows[:SCAN_LIMIT]:
        completed = completed_stats(encoded, release)
        if completed is None:
            continue
        payload, summary, visit = completed
        mode, chapter, level = payload["mode"], payload["chapter_id"], payload["level_id"]
        identity = (mode, chapter, level)
        previous = selected.get(identity)
        if previous is None:
            if len(selected) >= LEVEL_LIMIT:
                limited = True
                continue
            entry = {"mode": mode, "chapter_id": chapter, "level_id": level}
            selected[identity] = (visit, entry)
        else:
            latest_visit, entry = previous
            if not latest_visit or visit != latest_visit:
                continue
        if summary and "visit_metrics" not in entry:
            actual = metrics(payload, VISIT_FIELDS)
            if actual.get("max_hint_stage", 0) > 3:
                actual.pop("max_hint_stage")
            if payload.get("duration_unknown") is False:
                actual.update(metrics(payload, ("foreground_ms",)))
            entry["visit_metrics"] = actual
        if not summary and "completion_metrics" not in entry:
            # Summary metrics come from the final official run in a visit,
            # which can be a later failed experiment. Use only completion metrics here.
            entry["completion_metrics"] = metrics(payload, COMPLETION_FIELDS)
    return {"levels": [selected[key][1] for key in sorted(selected)],
            "limited": limited, "retention_days": retention_days}
