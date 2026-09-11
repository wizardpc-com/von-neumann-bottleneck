import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from storage import migrate, backup, merge, counts, MIGRATIONS

class StorageTests(unittest.TestCase):
    def test_upgrade_restore_merge_and_deleted_identity(self):
        with tempfile.TemporaryDirectory() as folder:
            old=Path(folder)/'old.sqlite'; snap=Path(folder)/'snapshot.sqlite'; new=Path(folder)/'new.sqlite'
            with sqlite3.connect(old) as db:
                # Real legacy schema, before PRAGMA user_version existed.
                db.executescript('CREATE TABLE clients(id TEXT PRIMARY KEY,deletion_hash TEXT NOT NULL); CREATE TABLE events(id TEXT PRIMARY KEY,client_id TEXT,received INTEGER,kind TEXT,body TEXT,digest TEXT);')
                body=json.dumps({'kind':'event'}); digest=hashlib.sha256(body.encode()).hexdigest()
                db.execute('INSERT INTO clients VALUES (?,?)',('synthetic-client','hash'))
                db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',('synthetic-event','synthetic-client',1,'event',body,digest))
                migrate(db); migrate(db)
            self.assertEqual(counts(old)['schema_version'],2)
            backup(old,snap); backup(snap,new)
            merge(new,snap); self.assertEqual(counts(new)['events'],1)
            with sqlite3.connect(new) as db:
                db.execute('INSERT INTO tombstones VALUES (?,?,?)',('synthetic-client','hash',2))
            merge(new,snap)
            self.assertEqual(counts(new)['events'],0); self.assertEqual(counts(new)['clients'],0)
            self.assertEqual(counts(new)['tombstones'],1)
            merge(old,new); self.assertEqual(counts(old)['events'],0)
            with self.assertRaises(ValueError): backup(snap,new)
    def test_failed_ddl_upgrade_is_atomic(self):
        with sqlite3.connect(':memory:') as db:
            original=list(MIGRATIONS[2])
            MIGRATIONS[2].append('THIS IS NOT SQL')
            try:
                with self.assertRaises(sqlite3.Error): migrate(db)
                self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0],0)
                self.assertEqual(db.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'").fetchone()[0],0)
            finally: MIGRATIONS[2][:]=original
            migrate(db); self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0],2)
    def test_conflict_rolls_back(self):
        with tempfile.TemporaryDirectory() as folder:
            paths=[Path(folder)/x for x in ['a','b']]
            for index,path in enumerate(paths):
                with sqlite3.connect(path) as db:
                    migrate(db); db.execute('INSERT INTO clients VALUES (?,?)',('same-identity',str(index)))
            with self.assertRaises(ValueError): merge(*paths)
            with sqlite3.connect(paths[0]) as db:
                self.assertEqual(db.execute('SELECT deletion_hash FROM clients').fetchone()[0],'0')
if __name__=='__main__': unittest.main(verbosity=2)
