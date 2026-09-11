"""Transactional schema and offline maintenance; no game engine dependencies."""
import argparse
import hashlib
import json
from pathlib import Path
import sqlite3

SCHEMA_VERSION = 2
MIGRATIONS = {
    1: ["CREATE TABLE IF NOT EXISTS clients(id TEXT PRIMARY KEY,deletion_hash TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS events(id TEXT PRIMARY KEY,client_id TEXT NOT NULL,received INTEGER NOT NULL,kind TEXT NOT NULL,body TEXT NOT NULL,digest TEXT NOT NULL)",
        "CREATE INDEX IF NOT EXISTS received_idx ON events(received)"],
    2: ["CREATE TABLE tombstones(client_id TEXT PRIMARY KEY,deletion_hash TEXT NOT NULL,deleted_at INTEGER NOT NULL)",
        "CREATE INDEX event_owner_idx ON events(client_id)"]}

def migrate(db):
    version = db.execute('PRAGMA user_version').fetchone()[0]
    if version > SCHEMA_VERSION: raise ValueError('future schema: use a newer receiver')
    with db:
        for next_version in range(version + 1, SCHEMA_VERSION + 1):
            for statement in MIGRATIONS[next_version]: db.execute(statement)
            db.execute('PRAGMA user_version = %d' % next_version)

def backup(source, destination):
    if Path(destination).exists(): raise ValueError('destination exists; use a new snapshot name')
    with sqlite3.connect('file:%s?mode=ro' % Path(source).resolve(), uri=True) as src, sqlite3.connect(destination) as dst:
        src.backup(dst)
        if dst.execute('PRAGMA integrity_check').fetchone()[0] != 'ok': raise ValueError('integrity check')
    return counts(destination)

def counts(path):
    with sqlite3.connect('file:%s?mode=ro' % Path(path).resolve(), uri=True) as db:
        version = db.execute('PRAGMA user_version').fetchone()[0]
        return {'schema_version': version, **{t: db.execute('SELECT COUNT(*) FROM '+t).fetchone()[0]
                for t in ['clients', 'events'] + (['tombstones'] if version >= 2 else [])}}

def merge(destination, source):
    """Merge an immutable snapshot into an offline target; deletion wins, conflicts abort."""
    with sqlite3.connect(destination) as dst, sqlite3.connect('file:%s?mode=ro' % Path(source).resolve(), uri=True) as src:
        migrate(dst)
        version = src.execute('PRAGMA user_version').fetchone()[0]
        if version > SCHEMA_VERSION: raise ValueError('future source schema')
        with dst:
            if version >= 2:
                for client, token, deleted in src.execute('SELECT * FROM tombstones'):
                    old = dst.execute('SELECT deletion_hash FROM clients WHERE id=? UNION SELECT deletion_hash FROM tombstones WHERE client_id=?',(client,client)).fetchall()
                    if any(row[0] != token for row in old): raise ValueError('identity conflict')
                    dst.execute('INSERT INTO tombstones VALUES (?,?,?) ON CONFLICT(client_id) DO UPDATE SET deleted_at=MAX(deleted_at,excluded.deleted_at)',(client,token,deleted))
            for client, token in src.execute('SELECT * FROM clients'):
                old = dst.execute('SELECT deletion_hash FROM clients WHERE id=? UNION SELECT deletion_hash FROM tombstones WHERE client_id=?',(client,client)).fetchall()
                if any(row[0] != token for row in old): raise ValueError('identity conflict')
                if not dst.execute('SELECT 1 FROM tombstones WHERE client_id=?',(client,)).fetchone():
                    dst.execute('INSERT OR IGNORE INTO clients VALUES (?,?)',(client,token))
            for row in src.execute('SELECT * FROM events'):
                if dst.execute('SELECT 1 FROM tombstones WHERE client_id=?',(row[1],)).fetchone(): continue
                if hashlib.sha256(row[4].encode()).hexdigest() != row[5]: raise ValueError('event digest mismatch')
                if not dst.execute('SELECT 1 FROM clients WHERE id=?',(row[1],)).fetchone(): raise ValueError('orphan event')
                old=dst.execute('SELECT client_id,digest FROM events WHERE id=?',(row[0],)).fetchone()
                if old and old != (row[1],row[5]): raise ValueError('event conflict')
                dst.execute('INSERT OR IGNORE INTO events VALUES (?,?,?,?,?,?)',row)
            dst.execute('DELETE FROM events WHERE client_id IN (SELECT client_id FROM tombstones)')
            dst.execute('DELETE FROM clients WHERE id IN (SELECT client_id FROM tombstones)')
    return counts(destination)

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation',choices=['backup','restore','merge','check'])
    parser.add_argument('source',type=Path); parser.add_argument('destination',type=Path,nargs='?')
    args=parser.parse_args()
    if args.operation!='check' and args.destination is None: parser.error('destination required')
    result = counts(args.source) if args.operation=='check' else merge(args.destination,args.source) if args.operation=='merge' else backup(args.source,args.destination)
    print(json.dumps(result,sort_keys=True))
