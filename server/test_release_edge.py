"""Optional real Caddy TLS test. Run with VNB_TEST_CADDY=/path/to/caddy-2.6.2."""
import configparser
from contextlib import contextmanager
import http.client
import importlib.util
import json
import os
from pathlib import Path
import shutil
import socket
import ssl
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import Mock, patch

from storage import counts
from test_release_ingress import BUILD, python_with_synthetic_capacity


SERVER = Path(__file__).resolve().parent
DEPLOY = SERVER / "deploy"
CADDY = os.environ.get("VNB_TEST_CADDY")


def script(name):
    spec = importlib.util.spec_from_file_location(name, DEPLOY / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def free_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


class ReleaseReadinessTests(unittest.TestCase):
    def test_readiness_reopens_refused_connection(self):
        check = script("check-release-feedback")
        refused, ready = Mock(), Mock()
        with patch.object(check.http.client, "HTTPConnection", side_effect=[refused, ready]), \
                patch.object(check, "check_read_routes", side_effect=[ConnectionRefusedError(), None]) as route, \
                patch.object(check.time, "sleep"):
            check.wait_for_local_receiver(False)
        self.assertEqual([invocation.args[0] for invocation in route.call_args_list], [refused, ready])
        refused.close.assert_called_once()
        ready.close.assert_called_once()

    def test_release_units_isolate_writers_and_target_the_measured_device(self):
        def load(name):
            unit = configparser.ConfigParser(interpolation=None, strict=False)
            self.assertEqual(unit.read(DEPLOY / name), [str(DEPLOY / name)])
            return unit

        receiver = load("vnb-release-receiver.service")
        maint = load("vnb-release-maintenance.service")
        edge = load("vnb-feedback-public-release.conf")
        self.assertNotEqual(receiver["Service"]["User"], maint["Service"]["User"])
        self.assertNotEqual(maint["Service"]["User"], "root")
        self.assertEqual(maint["Service"]["SupplementaryGroups"], "vnb-feedback-read")
        self.assertEqual(maint["Service"]["CapabilityBoundingSet"], "")
        self.assertEqual(receiver["Service"]["ReadWritePaths"], "/srv/ray/vnb_release/live/data")
        self.assertIn("/srv/ray/vnb_release/ops", receiver["Service"]["InaccessiblePaths"])
        self.assertEqual(maint["Service"]["ReadOnlyPaths"], "/srv/ray/vnb_release/live")
        self.assertTrue(all(path.startswith("/srv/ray/vnb_release/ops/")
                            for path in maint["Service"]["ReadWritePaths"].split()))
        for service, lane in ((receiver, "live"), (maint, "ops")):
            self.assertIn(f"vnb-release-volume@{lane}.service", service["Unit"]["Requires"].split())
            self.assertEqual(service["Unit"]["BindsTo"], f"srv-ray-vnb_release-{lane}.mount")
        for service, limits in ((receiver, ("8M", "4M")), (maint, ("8M", "4M")), (edge, ("1M", "1M"))):
            self.assertEqual(service["Service"]["IOAccounting"], "true")
            self.assertEqual(service["Service"]["IOReadBandwidthMax"], "/dev/vda " + limits[0])
            self.assertEqual(service["Service"]["IOWriteBandwidthMax"], "/dev/vda " + limits[1])


@unittest.skipUnless(CADDY, "set VNB_TEST_CADDY to run real loopback TLS checks")
class ReleaseEdgeTests(unittest.TestCase):
    @contextmanager
    def service(self, command, port, env=None, *, forbidden_log_value=None):
        with tempfile.TemporaryFile() as log:
            child = subprocess.Popen(command, env=env, stdout=log, stderr=log)
            try:
                for _ in range(100):
                    if child.poll() is not None:
                        break
                    try:
                        with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                            break
                    except OSError:
                        time.sleep(0.05)
                else:
                    self.fail("test service did not bind")
                if child.poll() is not None:
                    self.fail("test service exited before opening the listener")
                yield
            finally:
                if child.poll() is None:
                    child.terminate()
                    try:
                        child.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait(timeout=5)
                if forbidden_log_value:
                    log.seek(0)
                    self.assertFalse(forbidden_log_value in log.read(), "service wrote a credential to its log")

    def test_real_tls_historical_switch_and_disposable_rehearsal(self):
        check = script("check-release-feedback")
        prepare = script("prepare-release-edge")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            certs = root / "credentials"
            certs.mkdir(mode=0o700)
            token_path = certs / "edge.token"
            fragment = certs / "vnb-release-upstream-auth.caddy"
            prepare.prepare(token_path)
            shutil.copyfile(DEPLOY / fragment.name, fragment)
            self.assertEqual(token_path.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(FileExistsError):
                prepare.prepare(token_path)
            subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
                            "-subj", "/CN=127.0.0.1", "-addext", "subjectAltName=IP:127.0.0.1",
                            "-keyout", str(certs / "key.pem"), "-out", str(certs / "fullchain.pem")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            site = root / "www"
            site.mkdir()
            for notice in ("privacy-public.html", "privacy-player.html"):
                target = "privacy.html" if notice == "privacy-public.html" else notice
                shutil.copyfile(DEPLOY / notice, site / target)
            historical, release, edge = (free_port() for _ in range(3))
            self.assertEqual(len({historical, release, edge}), 3)
            config = root / "Caddyfile"
            template = (DEPLOY / "vnb-feedback-public.caddy").read_text()
            template = template.replace("feedback.yanruiqing.com:8443", f"127.0.0.1:{edge}")
            template = template.replace("/etc/vnb-feedback-public/www", str(site))
            config.write_text(template.replace(":18081}", f":{historical}" + "}"))
            context = ssl.create_default_context(cafile=str(certs / "fullchain.pem"))
            proxy = [CADDY, "run", "--config", str(config), "--adapter", "caddyfile"]
            python = python_with_synthetic_capacity(SERVER / "feedback_server.py")
            legacy_db = root / "historical.sqlite"
            rehearsal_db = root / "rehearsal.sqlite"
            production_db = root / "production.sqlite"
            admissions = root / "admissions.json"
            admissions.write_text(json.dumps([check.REHEARSAL_BUILD]))
            env = dict(os.environ, VNB_PUBLIC_BIND="127.0.0.1", CREDENTIALS_DIRECTORY=str(certs),
                       XDG_CONFIG_HOME=str(root / "config"), XDG_DATA_HOME=str(root / "data"))
            env.pop("VNB_FEEDBACK_UPSTREAM_PORT", None)
            env.pop("VNB_FEEDBACK_ADMIN_TOKEN", None)
            with self.service(python + ["--port", str(historical), "--database", str(legacy_db)], historical, env):
                held_fragment = fragment.with_suffix(".hold")
                fragment.rename(held_fragment)
                with self.service(proxy, edge, env):
                    connection = http.client.HTTPSConnection("127.0.0.1", edge, context=context, timeout=5)
                    try:
                        check.check_read_routes(connection, public=True, rehearsal=False, historical=True)
                    finally:
                        connection.close()
                held_fragment.rename(fragment)
                env["VNB_FEEDBACK_UPSTREAM_PORT"] = str(release)
                options = ["--release-admissions", str(admissions), "--release-edge-token-file", str(token_path)]
                release_proxy = ["/bin/sh", str(DEPLOY / "run-release-edge.sh"), *proxy]
                with self.service(python + ["--port", str(release), "--database", str(rehearsal_db), *options,
                                            "--release-rehearsal"], release, env):
                    with self.service(release_proxy, edge, env, forbidden_log_value=token_path.read_bytes().strip()):
                        connection = http.client.HTTPSConnection("127.0.0.1", edge, context=context, timeout=5)
                        try:
                            check.check_read_routes(connection, public=True, rehearsal=True)
                            check.rehearse(connection)
                        finally:
                            connection.close()
                    autosave = root / "config" / "caddy" / "autosave.json"
                    self.assertFalse(token_path.read_text().strip() in autosave.read_text(),
                                     "autosave must contain only a credential placeholder")
                admissions.write_text(json.dumps([BUILD]))
                token_path.unlink()
                prepare.prepare(token_path)
                with self.service(python + ["--port", str(release), "--database", str(production_db), *options], release, env):
                    with self.service(release_proxy, edge, env):
                        connection = http.client.HTTPSConnection("127.0.0.1", edge, context=context, timeout=5)
                        try:
                            check.check_read_routes(connection, public=True, rehearsal=False)
                        finally:
                            connection.close()
                    (root / "reports").mkdir()
                    subprocess.run([*python_with_synthetic_capacity(DEPLOY / "maintain.py"), "daily", "--release-limits",
                                    "--database", str(production_db), "--backup-dir", str(root / "backups"),
                                    "--report-dir", str(root / "reports" / "current"),
                                    "--triage", str(root / "reports" / "triage.sqlite"),
                                    "--source-commit", BUILD["source_commit"]], check=True, capture_output=True)
                    self.assertEqual(len(list((root / "backups").glob("*.sqlite"))), 1)
            self.assertEqual(counts(legacy_db), {"schema_version": 2, "clients": 0, "events": 0, "tombstones": 0})
            self.assertEqual(counts(rehearsal_db), {"schema_version": 2, "clients": 0, "events": 0, "tombstones": 1})
            self.assertEqual(counts(production_db), {"schema_version": 2, "clients": 0, "events": 0, "tombstones": 0})


if __name__ == "__main__":
    unittest.main()
