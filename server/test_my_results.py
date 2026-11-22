"""Loopback and catalog fixtures for the private personal results feature."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from feedback_server import RETENTION_DAYS, Receiver
from community import CONTENT_MANIFESTS
import my_results
from release_ingress import ReleaseIngress
import test_release_ingress as fixture


GAME = fixture.BUILD
TEST = dict(GAME, mode="test", test_batch="synthetic-release-test")
PLAYER_A, PLAYER_B = "a" * 32, "b" * 32
TOKEN_A, TOKEN_B = "c" * 64, "d" * 64
TASKS = "tasks-20261013-journey-v1"
RESULTS = "/v1/my-results"


def fixture_key(client, token):
    digest = hashlib.sha256(token.encode("ascii")).hexdigest()
    return hashlib.sha256(("vnb-results-v1:" + client + ":" + digest).encode("ascii")).hexdigest()


class MyResultsTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        safe_space = patch("release_ingress.available_bytes", return_value=8 * 1024**3)
        safe_space.start()
        self.addCleanup(safe_space.stop)
        clock = patch("release_ingress.time", SimpleNamespace(monotonic=lambda: 60))
        clock.start()
        self.addCleanup(clock.stop)
        release = ReleaseIngress([GAME, TEST], fixture.EDGE_FIXTURE)
        self.server = Receiver(("127.0.0.1", 0), Path(directory.name) / "feedback.sqlite", "", release=release)
        self.server.timeout = 3
        self.addCleanup(self.server.server_close)

    def request(self, method, path, body=None, **options):
        return fixture.ReleaseIngressTests.request(self, self.server, method, path, body, **options)

    def event(self, identifier, *, edition=GAME, task="tutorial", event="level_complete", **extra):
        payload = dict(edition, source="external_player", source_batch=edition["test_batch"], event=event,
                       sharing_mode="basic", chapter_id="hardware_foundations", level_id=task,
                       visit_id="private-visit", session_id="private-session", task_version=TASKS,
                       consent_version="sharing-2", privacy_notice_version="2026-10-17",
                       consent_timestamp="2026-11-22T00:00:00Z", background_cohort="unspecified")
        payload.update(CONTENT_MANIFESTS[TASKS]["identities"].get("hardware_foundations/" + task, {}))
        payload.update(extra)
        return {"event_id": identifier, "kind": "event", "payload": payload}

    def opinion(self):
        record = self.event("private-opinion-row", event="level_feedback", sharing_mode="opinion",
                            note="Private text should never be returned")
        return dict(record, kind="feedback")

    def upload(self, client, token, *records):
        return self.request("POST", "/v1/events", {"client_id": client, "deletion_token": token, "records": records})

    def results(self, client=PLAYER_A, key=None, **options):
        return self.request("POST", RESULTS, {"client_id": client, "key": key or fixture_key(client, TOKEN_A)}, **options)

    def test_two_installations_are_isolated_and_results_key_cannot_write_or_delete(self):
        first = self.event("first-private-row", cycles=21)
        second = self.event("second-private-row", edition=TEST, task="half_adder", cycles=42)
        self.assertEqual(self.upload(PLAYER_A, TOKEN_A, first)[0], 200)
        self.assertEqual(self.upload(PLAYER_B, TOKEN_B, second)[0], 200)
        a_key, b_key = fixture_key(PLAYER_A, TOKEN_A), fixture_key(PLAYER_B, TOKEN_B)
        self.assertEqual(my_results.read_key(PLAYER_A, hashlib.sha256(TOKEN_A.encode()).hexdigest()), a_key)
        self.assertEqual(self.results()[1]["levels"], [{"mode": "game", "chapter_id": "hardware_foundations",
            "level_id": "tutorial", "completion_metrics": {"cycles": 21}}])
        self.assertEqual(self.results(PLAYER_B, b_key)[1]["levels"], [{"mode": "test", "chapter_id": "hardware_foundations",
            "level_id": "half_adder", "completion_metrics": {"cycles": 42}}])
        unavailable = (401, {"error": "unavailable"})
        for client, key in ((PLAYER_A, b_key), (PLAYER_B, a_key), (PLAYER_A, TOKEN_A), ("f" * 32, a_key)):
            self.assertEqual(self.results(client, key), unavailable)
        self.assertEqual(self.upload(PLAYER_A, a_key, first)[0], 403)
        self.assertEqual(self.request("DELETE", "/v1/data", {"client_id": PLAYER_A, "deletion_token": a_key})[0], 403)
        self.assertEqual(self.results()[0], 200)
        for _ in range(2):
            self.assertEqual(self.request("DELETE", "/v1/data", {"client_id": PLAYER_A, "deletion_token": TOKEN_A}),
                             (200, {"deleted": True}))
        self.assertEqual(self.results(), unavailable)
        self.assertEqual(self.results(PLAYER_B, b_key)[0], 200)

    def test_only_current_opted_in_completed_task_data_and_actual_metrics_are_returned(self):
        completed = self.event("actual-completion", cycles=25, cost=3)
        summary = self.event("completed-visit-summary", event="visit_summary", completed=True,
                             completed_during_visit=True, duration_unknown=False, foreground_ms=4000,
                             feedback_ms=600, background_ms=30, debug_runs=0, official_runs=2,
                             max_hint_stage=2, cycles=999)
        previously_completed = self.event("entered-completed-task", task="half_adder", event="visit_summary",
                                          completed=True, completed_on_entry=True, completed_during_visit=False,
                                          foreground_ms=0, background_ms=0, feedback_ms=0, max_hint_stage=0)
        self.assertEqual(self.upload(PLAYER_A, TOKEN_A, completed, summary, previously_completed, self.opinion())[0], 200)
        excluded = [
            self.event("expired-supported", task="half_adder"),
            self.event("different-consent-mode", task="selector", sharing_mode="local"),
            self.event("wrong-source", task="selector4", source="automated"),
            self.event("not-admitted", task="alarm", source_batch="old-unlisted"),
            self.event("unknown-task-version", task="ram", task_version="legacy"),
            self.event("never-completed", task="cpu", event="level_start"),
        ]
        with self.server.db:
            for index, record in enumerate(excluded):
                self.server.db.execute("INSERT INTO events VALUES (?,?,?,?,?,?)", (record["event_id"], PLAYER_A,
                    int(time.time()) - (RETENTION_DAYS * 86400 + 10 if index == 0 else 0), "event", json.dumps(record), "fixture"))
        result = self.results()
        self.assertEqual(result, (200, {"levels": [{"mode": "game", "chapter_id": "hardware_foundations",
            "level_id": "tutorial", "completion_metrics": {"cycles": 25, "cost": 3},
            "visit_metrics": {"foreground_ms": 4000, "official_runs": 2, "debug_runs": 0, "max_hint_stage": 2}}],
            "limited": False, "retention_days": RETENTION_DAYS}))
        for private in ("private-session", "private-visit", "actual-completion", "Private text", "999"):
            self.assertNotIn(private, json.dumps(result))
        self.assertEqual(self.server.db.execute("SELECT COUNT(*) FROM events").fetchone()[0], 4 + len(excluded))

    def test_result_scope_uses_a_bounded_owner_index_and_flags_truncation(self):
        for index in range(3):
            self.assertEqual(self.upload(PLAYER_A, TOKEN_A, self.event(f"owner-scan-event-{index}", cycles=index))[0], 200)
        query = self.server.db.execute("EXPLAIN QUERY PLAN " + my_results.OWNER_READ, (0, PLAYER_A, 2)).fetchall()
        self.assertTrue(any("USING INDEX event_owner_idx" in row[3] for row in query), query)
        self.assertFalse(any("TEMP" in row[3] for row in query), query)
        with patch.object(my_results, "SCAN_LIMIT", 2):
            result = self.results()[1]
        self.assertTrue(result["limited"])
        self.assertEqual(result["levels"][0]["completion_metrics"], {"cycles": 2})

    def test_empty_unavailable_and_quota_paths_do_not_mutate_storage(self):
        self.assertEqual(self.results(), (401, {"error": "unavailable"}))
        self.assertEqual(self.results(credential=None), (403, {"error": "unavailable"}))
        self.assertEqual(self.upload(PLAYER_A, TOKEN_A, self.opinion())[0], 200)
        with patch.dict("release_ingress.LIMITS", {"results_install": (1, 120)}):
            self.assertEqual(self.results(), (200, {"levels": [], "limited": False, "retention_days": RETENTION_DAYS}))
            self.assertEqual(self.results(address="192.0.2.9"), (429, {"error": "rate_limit"}))
        self.assertEqual(self.request("POST", RESULTS, {"extra": "x" * 260})[0], 400)
        self.assertEqual(self.request("GET", RESULTS)[0], 404)
        self.assertEqual(self.server.db.execute("SELECT COUNT(*) FROM events").fetchone()[0], 1)
        self.assertEqual(self.server.db.execute("SELECT COUNT(*) FROM tombstones").fetchone()[0], 0)
        with patch.dict("release_ingress.LIMITS", {"results_peer": (1, 120)}):
            self.assertEqual(self.results(), (429, {"error": "rate_limit"}))
            self.assertEqual(self.upload(PLAYER_A, TOKEN_A, self.opinion())[0], 200)
        self.assertEqual(self.request("DELETE", "/v1/data", {"client_id": PLAYER_A, "deletion_token": TOKEN_A})[0], 200)

    def test_page_contains_all_current_canonical_titles_and_matching_csp(self):
        deploy = Path(__file__).with_name("deploy")
        subprocess.run([sys.executable, "-B", str(deploy / "refresh-results-titles.py"), "--check"],
                       check=True, capture_output=True)
        page = (deploy / "my-results.html").read_text(encoding="utf-8")
        titles = json.loads(re.search(r"const taskTitles = (\{.*?\});", page, re.S)[1])
        self.assertEqual(set(titles), set().union(*(set(manifest["tasks"]) for manifest in CONTENT_MANIFESTS.values())))
        self.assertTrue(all(all(pair) for pair in titles.values()))
        self.assertIn("我的成绩", page)
        self.assertIn('referrerPolicy: "no-referrer"', page)


if __name__ == "__main__":
    unittest.main(verbosity=2)
