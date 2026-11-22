"""Release admission, trusted-edge rate limits and deletion over real local HTTP."""
from contextlib import contextmanager
import http.client
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from threading import Thread
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from feedback_server import Receiver
from release_ingress import ReleaseIngress
from storage import backup, merge


BUILD = {"build_version": "release-1", "source_commit": "c" * 40, "test_batch": "public-1", "mode": "game"}
OLD_BUILD = dict(BUILD, build_version="release-0", test_batch="public-0")
EDGE_FIXTURE = "f" * 64
CLIENT = "synthetic-client-001"


def python_with_synthetic_capacity(script):
    bootstrap = """import runpy, sys
from unittest.mock import patch
sys.path.insert(0, sys.argv.pop(1))
sys.argv = sys.argv[1:]
with patch('release_ingress.available_bytes', return_value=8 * 1024**3):
    runpy.run_path(sys.argv[0], run_name='__main__')
"""
    return [sys.executable, "-B", "-c", bootstrap, str(Path(__file__).resolve().parent), str(script)]


class ReleaseIngressTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.folder = Path(directory.name)
        space = patch("release_ingress.available_bytes", return_value=8 * 1024**3)
        space.start()
        self.addCleanup(space.stop)

    @contextmanager
    def receiver(self, path=None, *, legacy=False, rehearsal=False):
        build = dict(BUILD, test_batch="vnb-rehearsal-test") if rehearsal else BUILD
        admission = None if legacy else ReleaseIngress([build] if rehearsal else [BUILD, OLD_BUILD],
                                                       EDGE_FIXTURE, rehearsal=rehearsal)
        server = Receiver(("127.0.0.1", 0), path or self.folder / "live.sqlite", "", release=admission)
        server.timeout = 3
        with server:
            yield server

    def request(self, server, method, path, body=None, *, address="192.0.2.1", credential=EDGE_FIXTURE, extra=()):
        response = []
        def client():
            connection = http.client.HTTPConnection("127.0.0.1", server.server_port, timeout=4)
            try:
                connection.putrequest(method, path)
                if address is not None:
                    connection.putheader("X-VNB-Client-IP", address)
                if credential is not None:
                    connection.putheader("X-VNB-Edge-Token", credential)
                for name, value in extra:
                    connection.putheader(name, value)
                data = None if body is None else json.dumps(body).encode()
                if data is not None:
                    connection.putheader("Content-Type", "application/json")
                    connection.putheader("Content-Length", str(len(data)))
                connection.endheaders(data)
                with connection.getresponse() as result:
                    response.append((result.status, json.load(result)))
            except Exception as error:
                response.append(error)
            finally:
                connection.close()
        thread = Thread(target=client)
        thread.start()
        server.handle_request()
        thread.join(timeout=5)
        self.assertFalse(thread.is_alive())
        self.assertEqual(len(response), 1)
        if isinstance(response[0], Exception):
            raise response[0]
        return response[0]

    def identity(self, client=CLIENT, token="a" * 64):
        return {"client_id": client, "deletion_token": token}

    def envelope(self, client=CLIENT, event="release-test-event-001", **fields):
        payload = dict(BUILD, source="external_player", source_batch=OLD_BUILD["test_batch"], note="Synthetic")
        payload.update(fields)
        return dict(self.identity(client), records=[{"event_id": event, "kind": "feedback", "payload": payload}])

    def test_release_provenance_is_atomic_and_legacy_qa_stays_enabled(self):
        with self.receiver() as server:
            good = self.envelope()
            for fields in ({"source": "automated"}, {"source": "agent_native"}, {"source": "developer"},
                           {"test_batch": "isolated-qa"}, {"source_batch": "isolated-qa"}, {"mode": "test"},
                           {"source_commit": "b" * 40}):
                with self.subTest(fields=fields):
                    bad = self.envelope(event="release-test-event-002", **fields)
                    batch = dict(good, records=good["records"] + bad["records"])
                    self.assertEqual(self.request(server, "POST", "/v1/events", batch),
                                     (403, {"error": "release_provenance"}))
                    self.assertEqual(server.db.execute("SELECT COUNT(*) FROM clients").fetchone(), (0,))
                    self.assertEqual(server.db.execute("SELECT COUNT(*) FROM events").fetchone(), (0,))
            for _ in range(2):
                self.assertEqual(self.request(server, "POST", "/v1/events", good),
                                 (200, {"ack": ["release-test-event-001"]}))
            for path in ("/admin/report", "/v1/community/tasks", "/v1/leaderboards"):
                self.assertEqual(self.request(server, "GET", path)[0], 404)
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM events").fetchone(), (1,))
        with self.receiver(self.folder / "legacy.sqlite", legacy=True) as legacy:
            self.assertNotIn("ingress", self.request(legacy, "GET", "/v1/health")[1])
            qa = self.envelope(source="automated", source_batch="isolated-qa", test_batch="isolated-qa")
            self.assertEqual(self.request(legacy, "POST", "/v1/events", qa, address=None, credential=None)[0], 200)

    def test_proxy_trust_disallows_spoofing_and_limits_peers_and_total(self):
        clock = SimpleNamespace(monotonic=lambda: 60)
        with patch("release_ingress.time", clock), patch.dict("release_ingress.LIMITS", {"upload": (1, 2)}), self.receiver() as server:
            body = self.envelope()
            for options in ({"credential": None}, {"credential": "0" * 64}, {"address": None},
                            {"address": "fe80::1%eth0"}, {"extra": [("X-VNB-Client-IP", "192.0.2.2")]},
                            {"extra": [("X-VNB-Edge-Token", EDGE_FIXTURE)]}):
                self.assertEqual(self.request(server, "POST", "/v1/events", body, **options),
                                 (403, {"error": "trusted_edge_required"}))
            self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity(), credential=None)[0], 403)
            self.assertEqual(self.request(server, "GET", "/v1/health", credential=None)[0], 403)
            self.assertEqual(self.request(server, "GET", "/health", address=None, credential=None)[1]["ingress"],
                             "release")
            self.assertEqual(self.request(server, "POST", "/v1/events", body)[0], 200)
            self.assertEqual(self.request(server, "POST", "/v1/events", body, address="::ffff:192.0.2.1",
                                          extra=[("X-Forwarded-For", "192.0.2.2")])[0], 429)
            self.assertEqual(self.request(server, "POST", "/v1/events", body, address="192.0.2.2")[0], 200)
            self.assertEqual(self.request(server, "POST", "/v1/events", body, address="192.0.2.3")[0], 429)
            clock.monotonic = lambda: 120
            self.assertEqual(self.request(server, "POST", "/v1/events", body, address="192.0.2.3")[0], 200)

    def test_delete_budget_survives_uploads_wrong_tokens_and_unknown_flood(self):
        limits = {"upload": (2, 2), "known_delete": (2, 2), "unknown_delete": (1, 1)}
        with patch("release_ingress.time", SimpleNamespace(monotonic=lambda: 60)), patch.dict("release_ingress.LIMITS", limits), self.receiver() as server:
            body = self.envelope()
            for status in (200, 200, 429):
                self.assertEqual(self.request(server, "POST", "/v1/events", body)[0], status)
            self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity(token="b" * 64))[0], 403)
            late = self.identity("synthetic-client-002")
            self.assertEqual(self.request(server, "DELETE", "/v1/data", late, address="192.0.2.2")[0], 429)
            for _ in range(2):
                self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity()), (200, {"deleted": True}))
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM events").fetchone(), (0,))

    def test_delete_before_upload_restart_and_restore_block_replay_at_capacity(self):
        older, latest, restored = (self.folder / name for name in ("older.sqlite", "latest.sqlite", "restored.sqlite"))
        with patch("feedback_server.MAX_EVENTS", 1), patch("feedback_server.UNKNOWN_DELETE_CEILING", 1):
            with self.receiver() as server:
                good = self.envelope()
                self.assertEqual(self.request(server, "POST", "/v1/events", good)[0], 200)
                backup(self.folder / "live.sqlite", older)
                waiting = self.identity("synthetic-client-002")
                self.assertEqual(self.request(server, "DELETE", "/v1/data", waiting)[0], 200)
                self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity("synthetic-client-003")),
                                 (503, {"error": "storage_limit"}))
                self.assertEqual(self.request(server, "POST", "/v1/events",
                                              self.envelope(client=waiting["client_id"], event="release-test-event-002"))[0], 410)
                self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity())[0], 200)
            with self.receiver() as server:
                self.assertEqual(self.request(server, "POST", "/v1/events", good)[0], 410)
                backup(self.folder / "live.sqlite", latest)
        backup(older, restored)
        merge(restored, latest)
        with self.receiver(restored) as server:
            self.assertEqual(self.request(server, "POST", "/v1/events", good)[0], 410)
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM events").fetchone(), (0,))
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM tombstones").fetchone(), (2,))

    def test_rehearsal_has_distinct_health_and_cannot_write_production(self):
        client = "vnb-rehearsal-12345678"
        event = self.envelope(client=client, test_batch="vnb-rehearsal-test", source_batch="vnb-rehearsal-test")
        with self.receiver() as production:
            self.assertEqual(self.request(production, "GET", "/v1/health")[1]["ingress"], "release")
            self.assertEqual(self.request(production, "POST", "/v1/events", event)[0], 403)
            self.assertEqual(self.request(production, "DELETE", "/v1/data", self.identity(client))[0], 403)
            self.assertEqual(production.db.execute("SELECT COUNT(*) FROM tombstones").fetchone(), (0,))
        with self.receiver(self.folder / "rehearsal.sqlite", rehearsal=True) as rehearsal:
            self.assertEqual(self.request(rehearsal, "GET", "/v1/health")[1]["ingress"], "release-rehearsal")
            self.assertEqual(self.request(rehearsal, "POST", "/v1/events", event)[0], 200)
            self.assertEqual(self.request(rehearsal, "DELETE", "/v1/data", self.identity())[0], 403)
            self.assertEqual(self.request(rehearsal, "DELETE", "/v1/data", self.identity(client))[0], 200)

    def test_storage_reserve_pauses_new_writes_but_preserves_receipts_and_known_delete(self):
        with patch("release_ingress.available_bytes", return_value=8 * 1024**3) as space, self.receiver() as server:
            first = self.envelope()
            receipt = self.request(server, "POST", "/v1/events", first)
            self.assertEqual(receipt[0], 200)
            second = self.envelope(client="synthetic-client-002", event="release-test-event-002")
            for cap in (patch("release_ingress.HOST_FREE_RESERVE", 9 * 1024**3),
                        patch("release_ingress.LIVE_FREE_RESERVE", 9 * 1024**3),
                        patch("release_ingress.LIVE_USED_LIMIT", 100),
                        patch("release_ingress.LIVE_FILE_LIMIT", 100)):
                with cap:
                    self.assertEqual(self.request(server, "POST", "/v1/events", second),
                                     (503, {"error": "storage_limit"}))
                    self.assertEqual(self.request(server, "POST", "/v1/events", first), receipt)
            space.return_value = 0
            self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity("synthetic-client-002")),
                             (503, {"error": "storage_limit"}))
            self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity()), (200, {"deleted": True}))
            self.assertEqual(self.request(server, "POST", "/v1/events", first), (410, {"error": "identity_deleted"}))
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM tombstones").fetchone(), (1,))
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM events").fetchone(), (0,))
            space.return_value = 8 * 1024**3
            self.assertEqual(self.request(server, "POST", "/v1/events", second)[0], 200)

    def test_failed_known_delete_keeps_event_and_returns_no_receipt(self):
        with self.receiver() as server:
            self.assertEqual(self.request(server, "POST", "/v1/events", self.envelope())[0], 200)
            with server.db:
                server.db.execute("""CREATE TRIGGER reject_tombstone BEFORE INSERT ON tombstones BEGIN
                                     SELECT RAISE(ABORT, 'synthetic write failure'); END""")
            self.assertEqual(self.request(server, "DELETE", "/v1/data", self.identity()),
                             (503, {"error": "storage_unavailable"}))
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM events").fetchone(), (1,))
            self.assertEqual(server.db.execute("SELECT COUNT(*) FROM tombstones").fetchone(), (0,))

    def test_cli_requires_paired_configuration_before_touching_storage(self):
        script = Path(__file__).with_name("feedback_server.py")
        database = self.folder / "must-not-exist" / "storage.sqlite"
        admissions = self.folder / "admissions.json"
        credential = self.folder / "edge.token"
        credential.write_text(EDGE_FIXTURE)
        admissions.write_text(json.dumps([dict(BUILD, test_batch="vnb-rehearsal-test")]))
        config = ["--release-admissions", str(admissions), "--release-edge-token-file", str(credential)]
        for args in (config[:2], config, config + ["--host", "0.0.0.0"], ["--release-rehearsal"]):
            result = subprocess.run([sys.executable, "-B", str(script), "--database", str(database), *args],
                                    text=True, capture_output=True, timeout=5)
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertNotIn(EDGE_FIXTURE, result.stderr)
            self.assertFalse(database.parent.exists())


if __name__ == "__main__":
    unittest.main()
