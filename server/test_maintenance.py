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
from urllib.request import Request, urlopen

from deploy import maintain
from feedback_server import Receiver
from private_report import update_triage
from storage import migrate


class MaintenanceTests(unittest.TestCase):
    def command(self, *args):
        result = subprocess.run([sys.executable, str(Path(__file__).parent / 'deploy' / 'maintain.py'), *map(str, args)],
                                capture_output=True, text=True, check=True)
        return json.loads(result.stdout.splitlines()[-1])

    def seed(self, path):
        with closing(sqlite3.connect(path)) as db:
            migrate(db)
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


if __name__ == '__main__': unittest.main(verbosity=2)
