#!/usr/bin/env python3
"""Private maintenance checks with synthetic SQLite data only."""
from contextlib import closing
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import stat
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock
from urllib.request import Request, urlopen

from deploy import maintain
from feedback_server import Receiver
from private_report import update_triage
from storage import migrate
from test_release_ingress import python_with_synthetic_capacity


class MaintenanceTests(unittest.TestCase):
    def command(self, *args):
        script = Path(__file__).parent / 'deploy' / 'maintain.py'
        python = (python_with_synthetic_capacity(script) if '--release-limits' in args
                  else [sys.executable, str(script)])
        result = subprocess.run([*python, *map(str, args)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout.splitlines()[-1])

    def seed(self, path):
        with closing(sqlite3.connect(path)) as db:
            migrate(db)
            self.insert_opinion(db)

    def insert_opinion(self, db):
        record = {'kind': 'feedback', 'payload': {'chapter_id': 'hardware_foundations', 'level_id': 'selector_4',
                  'source': 'automated', 'mode': 'test', 'note': 'Synthetic private opinion'}}
        body = json.dumps(record)
        with db:
            db.execute('INSERT INTO clients VALUES (?,?)',
                       ('synthetic-client', hashlib.sha256(('a' * 64).encode()).hexdigest()))
            db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',
                       ('synthetic-feedback-id', 'synthetic-client', int(time.time()), 'feedback', body,
                        hashlib.sha256(body.encode()).hexdigest()))

    def delete_via_http(self, path):
        server = Receiver(('127.0.0.1', 0), path, '')
        response = []
        def client():
            request = Request('http://127.0.0.1:' + str(server.server_port) + '/v1/data', method='DELETE',
                              data=json.dumps({'client_id': 'synthetic-client', 'deletion_token': 'a' * 64}).encode(),
                              headers={'Content-Type': 'application/json'})
            with urlopen(request, timeout=5) as result:
                response.append((result.status, json.load(result)))
        worker = threading.Thread(target=client)
        try:
            worker.start(); server.handle_request(); worker.join(timeout=5)
            self.assertFalse(worker.is_alive())
            self.assertEqual(response, [(200, {'deleted': True})])
        finally:
            server.server_close()

    def test_backup_delete_report_and_tombstone_safe_restore(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            live = root / 'live' / 'feedback.sqlite'; live.parent.mkdir()
            backups = root / 'backups'; reports = root / 'reports' / 'current'
            triage = root / 'reports' / 'private-triage.sqlite'
            restored = root / 'restored' / 'feedback.sqlite'
            self.seed(live)
            args = ('daily', '--database', live, '--backup-dir', backups, '--report-dir', reports,
                    '--triage', triage, '--source-commit', 'a' * 40)
            first = self.command(*args)
            snapshot = Path(first['backup']); info = json.loads(snapshot.with_suffix('.json').read_text(encoding='utf-8'))
            self.assertEqual(info['source_commit'], 'a' * 40)
            self.assertEqual(info['schema_version'], 2)
            self.assertEqual(info['counts']['events'], 1)
            self.assertEqual(info['sha256'], maintain.sha256(snapshot))
            self.assertEqual(len(json.loads((reports / 'report.json').read_text(encoding='utf-8'))['received_feedback']), 1)
            if os.name == 'posix':
                self.assertEqual(stat.S_IMODE(backups.stat().st_mode), 0o700)
                self.assertEqual(stat.S_IMODE(reports.stat().st_mode), 0o700)
                self.assertEqual(stat.S_IMODE(snapshot.stat().st_mode), 0o600)
                self.assertEqual(stat.S_IMODE(snapshot.with_suffix('.json').stat().st_mode), 0o600)
                self.assertEqual(stat.S_IMODE((reports / 'report.json').stat().st_mode), 0o600)
                self.assertEqual(stat.S_IMODE((reports / 'report.html').stat().st_mode), 0o600)
                self.assertEqual(stat.S_IMODE(triage.stat().st_mode), 0o600)
            update_triage(live, triage, 'synthetic-feedback-id', 'reproduced')
            self.delete_via_http(live)
            self.command(*args)
            self.assertEqual(json.loads((reports / 'report.json').read_text(encoding='utf-8'))['received_feedback'], [])
            self.assertNotIn('Synthetic private opinion', (reports / 'report.html').read_text(encoding='utf-8'))
            with closing(sqlite3.connect(triage)) as db:
                self.assertEqual(db.execute('SELECT COUNT(*) FROM actions').fetchone()[0], 0)
            result = self.command('restore', '--backup', snapshot, '--latest', live, '--destination', restored)
            self.assertEqual(result['counts']['events'], 0)
            with closing(sqlite3.connect(restored)) as db:
                self.assertEqual(db.execute('SELECT COUNT(*) FROM events').fetchone()[0], 0)
                self.assertEqual(db.execute('SELECT COUNT(*) FROM tombstones').fetchone()[0], 1)
            with self.assertRaises(ValueError): maintain.restore_safe(snapshot, live, live)
            with self.assertRaises(ValueError): maintain.restore_safe(snapshot, live, snapshot)
            with self.assertRaises(ValueError): maintain.restore_safe(snapshot, live, restored)
            snapshot.write_bytes(snapshot.read_bytes() + b'tampered')
            with self.assertRaises(ValueError): maintain.restore_safe(snapshot, live, root / 'second-restore' / 'feedback.sqlite')

    def test_rotate_only_managed_pairs_older_than_30_days(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            live = root / 'live.sqlite'; self.seed(live)
            backups = root / 'backups'
            original, info = maintain.make_backup(live, backups, 'b' * 40)
            now = datetime.now(timezone.utc).replace(microsecond=0)
            def dated(days, suffix):
                at = now - timedelta(days=days)
                snapshot = backups / ('vnb-feedback-' + at.strftime('%Y%m%dT%H%M%SZ') + '-' + suffix + '.sqlite')
                shutil.copyfile(original, snapshot)
                metadata = info | {'snapshot': snapshot.name, 'created_utc': at.strftime('%Y-%m-%dT%H:%M:%SZ')}
                snapshot.with_suffix('.json').write_text(json.dumps(metadata), encoding='utf-8')
                return snapshot
            old = dated(31, '11111111')
            recent = dated(29, '22222222')
            impostor = dated(31, '44444444')
            altered = json.loads(impostor.with_suffix('.json').read_text(encoding='utf-8'))
            altered['format'] = 'unrelated-backup'
            impostor.with_suffix('.json').write_text(json.dumps(altered), encoding='utf-8')
            orphan = backups / ('vnb-feedback-' + (now - timedelta(days=31)).strftime('%Y%m%dT%H%M%SZ') + '-33333333.sqlite')
            shutil.copyfile(original, orphan)
            unrelated = backups / 'unrelated.sqlite'; unrelated.write_text('keep', encoding='utf-8')
            removed = maintain.rotate(backups, now)
            self.assertEqual(removed, [old.name])
            self.assertFalse(old.exists())
            self.assertFalse(old.with_suffix('.json').exists())
            for path in (recent, recent.with_suffix('.json'), original, original.with_suffix('.json'),
                         impostor, impostor.with_suffix('.json'), orphan, unrelated):
                self.assertTrue(path.exists(), str(path))

    def test_backup_name_collision_preserves_existing_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            live = root / 'live.sqlite'; self.seed(live)
            backups = root / 'backups'; backups.mkdir()
            fixed = datetime(2026, 10, 17, 12, 0, tzinfo=timezone.utc)
            class FixedDateTime(datetime):
                @classmethod
                def now(cls, tz=None):
                    return fixed.astimezone(tz) if tz else fixed.replace(tzinfo=None)
            with mock.patch.object(maintain, 'datetime', FixedDateTime):
                for suffix, snapshot_exists in (('11111111', True), ('22222222', False)):
                    snapshot = backups / ('vnb-feedback-20261017T120000Z-' + suffix + '.sqlite')
                    metadata = snapshot.with_suffix('.json')
                    if snapshot_exists: snapshot.write_bytes(b'existing snapshot bytes')
                    metadata.write_bytes(b'existing metadata bytes')
                    with mock.patch.object(maintain.secrets, 'token_hex', return_value=suffix):
                        with self.assertRaises((ValueError, FileExistsError)):
                            maintain.make_backup(live, backups, 'a' * 40)
                    self.assertEqual(metadata.read_bytes(), b'existing metadata bytes')
                    if snapshot_exists:
                        self.assertEqual(snapshot.read_bytes(), b'existing snapshot bytes')
                    else:
                        self.assertFalse(snapshot.exists())

    def test_daily_fails_and_preserves_incomplete_managed_backups(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            live = root / 'live' / 'feedback.sqlite'; live.parent.mkdir(); self.seed(live)
            backups = root / 'backups'; backups.mkdir()
            orphan = backups / 'vnb-feedback-20260901T000000Z-11111111.sqlite'
            orphan.write_bytes(b'orphan snapshot bytes')
            partial = backups / 'vnb-feedback-20260901T000000Z-22222222.partial'
            partial.write_bytes(b'partial metadata bytes')
            damaged = backups / 'vnb-feedback-20260901T000000Z-33333333.sqlite'
            damaged.write_bytes(b'existing snapshot bytes')
            damaged.with_suffix('.json').write_bytes(b'{invalid metadata')
            reservation = backups / 'vnb-feedback-20260901T000000Z-44444444.json'
            reservation.write_bytes(b'unfinished reservation')
            source, info = maintain.make_backup(live, backups, 'a' * 40)
            tampered = backups / 'vnb-feedback-20260901T000000Z-55555555.sqlite'
            shutil.copyfile(source, tampered)
            tampered.with_suffix('.json').write_text(json.dumps(info | {'snapshot': tampered.name,
                'created_utc': '2026-09-01T00:00:00Z', 'sha256': '0' * 64}), encoding='utf-8')
            args = ['daily', '--database', str(live), '--backup-dir', str(backups),
                    '--report-dir', str(root / 'reports' / 'current'),
                    '--triage', str(root / 'reports' / 'triage.sqlite'), '--source-commit', 'a' * 40]
            result = subprocess.run([sys.executable, str(Path(__file__).parent / 'deploy' / 'maintain.py'), *args],
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('maintenance anomalies', result.stderr)
            self.assertIn(orphan.name + ': missing metadata', result.stderr)
            self.assertIn(partial.name + ': unexpected managed-prefix file', result.stderr)
            self.assertIn(damaged.name + ': invalid backup pair', result.stderr)
            self.assertIn(reservation.name + ': missing snapshot', result.stderr)
            self.assertIn(tampered.name + ': hash mismatch', result.stderr)
            self.assertTrue(tampered.exists(), 'Audit must precede rotation of a damaged old pair')
            self.assertEqual(orphan.read_bytes(), b'orphan snapshot bytes')
            self.assertEqual(partial.read_bytes(), b'partial metadata bytes')
            self.assertEqual(damaged.read_bytes(), b'existing snapshot bytes')
            self.assertEqual(damaged.with_suffix('.json').read_bytes(), b'{invalid metadata')
            self.assertEqual(reservation.read_bytes(), b'unfinished reservation')

    def test_release_maintenance_reads_group_private_wal_with_readonly_mode(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            live = root / 'live'; live.mkdir(mode=0o700)
            database = live / 'feedback.sqlite'
            reports = root / 'reports'; reports.mkdir(mode=0o700)
            backups = root / 'backups'
            mask = os.umask(0o027)
            try:
                with closing(sqlite3.connect(database)) as writer:
                    migrate(writer)
                    self.assertEqual(writer.execute('PRAGMA journal_mode=WAL').fetchone(), ('wal',))
                    writer.execute('PRAGMA wal_autocheckpoint=0')
                    main_before_opinion = database.read_bytes()
                    # Commit on the connection that remains open. On Linux a connection
                    # that only sets PRAGMAs may not keep another writer's sidecars alive.
                    self.insert_opinion(writer)
                    sidecars = [database, Path(str(database) + '-wal'), Path(str(database) + '-shm')]
                    self.assertGreater(sidecars[1].stat().st_size, 32, 'The WAL contains committed frames')
                    self.assertEqual(database.read_bytes(), main_before_opinion, 'The opinion is only in the WAL')
                    for path in sidecars:
                        self.assertEqual(path.stat().st_uid, os.getuid())
                        self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o640)
                        path.chmod(0o440)
                    live.chmod(0o550)
                    try:
                        args = ('daily', '--release-limits', '--database', database, '--backup-dir', backups,
                                '--report-dir', reports / 'current', '--triage', reports / 'triage.sqlite',
                                '--source-commit', 'a' * 40)
                        first = self.command(*args)
                        second = self.command(*args)
                        self.assertEqual(first['counts']['events'], 1)
                        self.assertTrue(second['reused_daily_snapshot'])
                        self.assertEqual(len(list(backups.glob('*.sqlite'))), 1)
                        self.assertEqual(len(json.loads((reports / 'current' / 'report.json').read_text())['received_feedback']), 1)
                    finally:
                        live.chmod(0o750)
                        for path in sidecars:
                            path.chmod(0o640)
            finally:
                os.umask(mask)

    def test_release_storage_guard_removes_stale_report_and_rotates_valid_expiry(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            database = root / 'live.sqlite'; self.seed(database)
            backups = root / 'backups'
            report = root / 'reports' / 'current'
            report.mkdir(parents=True)
            for name in ('report.json', 'report.html'):
                (report / name).write_text('old report')
            snapshot, info = maintain.make_backup(database, backups, 'b' * 40)
            expired = datetime.now(timezone.utc) - timedelta(days=31)
            expired_name = expired.strftime('vnb-feedback-%Y%m%dT%H%M%SZ-00000001.sqlite')
            old = backups / expired_name
            snapshot.rename(old)
            snapshot.with_suffix('.json').unlink()
            old.with_suffix('.json').write_text(json.dumps(info | {'snapshot': expired_name,
                'created_utc': expired.strftime('%Y-%m-%dT%H:%M:%SZ')}))
            for guard in (mock.patch.object(maintain, 'host_has_reserve', return_value=False),
                          mock.patch.object(maintain, 'available_bytes', return_value=0)):
                with guard, self.assertRaisesRegex(ValueError, 'report paused'):
                    maintain.current_report(database, report, report.parent / 'triage.sqlite', release=True)
            self.assertEqual(list(report.iterdir()), [])
            with mock.patch.object(maintain, 'host_has_reserve', return_value=False):
                with self.assertRaisesRegex(ValueError, 'backup paused'):
                    maintain.release_backup(database, backups, 'b' * 40)
            self.assertEqual(list(backups.iterdir()), [])

    def test_release_backup_limits_actual_file_wal_pages_and_staged_snapshot(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            database = root / 'live.sqlite'; self.seed(database)
            backups = root / 'backups'
            with closing(sqlite3.connect(database)) as writer:
                writer.execute('PRAGMA journal_mode=WAL')
                writer.execute('PRAGMA wal_autocheckpoint=0')
                baseline = database.stat().st_size
                with writer:
                    writer.execute('CREATE TABLE synthetic_padding (data BLOB)')
                    writer.execute('INSERT INTO synthetic_padding VALUES (zeroblob(65536))')
                self.assertEqual(database.stat().st_size, baseline, 'Growth is still committed only in WAL')
                with mock.patch.object(maintain, 'host_has_reserve', return_value=True), \
                        mock.patch.object(maintain, 'available_bytes', return_value=8 * 1024**3), \
                        mock.patch.object(maintain, 'RELEASE_BACKUP_LIMIT', baseline):
                    with self.assertRaisesRegex(ValueError, 'backup paused'):
                        maintain.release_backup(database, backups, 'b' * 40)
                    with self.assertRaisesRegex(ValueError, 'snapshot exceeds budget'):
                        maintain.make_backup(database, backups, 'b' * 40, release=True)
                    with writer:
                        writer.execute('DROP TABLE synthetic_padding')
                    writer.execute('PRAGMA wal_checkpoint(TRUNCATE)')
                    self.assertGreater(database.stat().st_size, baseline, 'Freelist does not shrink the actual file')
                    with self.assertRaisesRegex(ValueError, 'backup paused'):
                        maintain.release_backup(database, backups, 'b' * 40)
            self.assertEqual(list(backups.iterdir()), [])


if __name__ == '__main__': unittest.main(verbosity=2)
