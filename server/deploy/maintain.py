#!/usr/bin/env python3
"""Private daily feedback backup/report and deletion-safe restore."""
import argparse
from contextlib import closing
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import sqlite3
import subprocess
import sys
import tempfile

SERVER = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SERVER))
from storage import backup, counts, merge
from release_ingress import available_bytes, host_has_reserve

FORMAT = 'vnb-feedback-backup-v1'
RELEASE_BACKUP_LIMIT = 64 * 1024**2
RELEASE_OPS_FREE = 512 * 1024**2
NAME = re.compile(r'^vnb-feedback-(\d{8}T\d{6}Z)-[0-9a-f]{8}\.sqlite$')


def private_dir(path):
    path = Path(path)
    if path.is_symlink(): raise ValueError('private directory is a symlink')
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.chmod(0o700)
    return path


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def metadata_for(snapshot):
    snapshot = Path(snapshot)
    if not NAME.fullmatch(snapshot.name) or snapshot.is_symlink(): raise ValueError('not a managed backup')
    metadata = snapshot.with_suffix('.json')
    if metadata.is_symlink(): raise ValueError('backup metadata is a symlink')
    info = json.loads(metadata.read_text(encoding='utf-8'))
    if (not isinstance(info, dict) or info.get('format') != FORMAT or info.get('snapshot') != snapshot.name
            or not isinstance(info.get('source_commit'), str)
            or not re.fullmatch(r'[0-9a-f]{40}', info['source_commit'])
            or not isinstance(info.get('sha256'), str)
            or not re.fullmatch(r'[0-9a-f]{64}', info['sha256'])
            or not isinstance(info.get('counts'), dict)
            or info.get('schema_version') != info['counts'].get('schema_version')):
        raise ValueError('invalid backup metadata')
    stamp = datetime.strptime(NAME.fullmatch(snapshot.name)[1], '%Y%m%dT%H%M%SZ').replace(tzinfo=timezone.utc)
    if info.get('created_utc') != stamp.strftime('%Y-%m-%dT%H:%M:%SZ'):
        raise ValueError('backup timestamp mismatch')
    return info


def make_backup(database, directory, source_commit, *, release=False, now=None):
    if not re.fullmatch(r'[0-9a-f]{40}', source_commit): raise ValueError('full source commit required')
    database = Path(database).resolve()
    directory = Path(directory).absolute()
    if directory.resolve() == database.parent: raise ValueError('backups need a separate directory')
    private_dir(directory)
    now = (now or datetime.now(timezone.utc)).replace(microsecond=0)
    snapshot = directory / ('vnb-feedback-' + now.strftime('%Y%m%dT%H%M%SZ') + '-' + secrets.token_hex(4) + '.sqlite')
    metadata = snapshot.with_suffix('.json')
    if os.path.lexists(snapshot): raise ValueError('backup name already exists')
    if os.path.lexists(metadata): raise ValueError('backup metadata already exists')
    # Stage both files so a failed copy does not leave a persistent reservation.
    with tempfile.TemporaryDirectory(prefix='.snapshot-', dir=directory) as folder:
        staged_metadata = Path(folder) / 'metadata.json'
        with staged_metadata.open('x', encoding='utf-8') as output:
            staged = Path(folder) / 'feedback.sqlite'
            summary = backup(database, staged, pages=128 if release else -1)
            with closing(sqlite3.connect(staged)) as db:
                if db.execute('PRAGMA journal_mode=DELETE').fetchone()[0] != 'delete':
                    raise ValueError('backup journal mode could not be finalized')
            if release and staged.stat().st_size > RELEASE_BACKUP_LIMIT:
                raise ValueError('release snapshot exceeds budget')
            staged.chmod(0o600)
            info = {'format': FORMAT, 'snapshot': snapshot.name, 'created_utc': now.strftime('%Y-%m-%dT%H:%M:%SZ'),
                    'source_commit': source_commit, 'schema_version': summary['schema_version'],
                    'counts': summary, 'sha256': sha256(staged)}
            json.dump(info, output, sort_keys=True, indent=2)
            output.write('\n')
        staged_metadata.chmod(0o600)
        os.link(staged, snapshot)
        try:
            os.link(staged_metadata, metadata)
        except OSError:
            snapshot.unlink()
            raise
    return snapshot, info


def rotate(directory, now=None, *, verify_hash=False):
    cutoff = (now or datetime.now(timezone.utc)) - timedelta(days=30)
    removed = []
    for metadata in Path(directory).glob('vnb-feedback-*.json'):
        snapshot = metadata.with_suffix('.sqlite')
        if not snapshot.is_file() or snapshot.is_symlink(): continue
        try:
            info = metadata_for(snapshot)
            created = datetime.strptime(info['created_utc'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
        except (ValueError, OSError, KeyError, TypeError, json.JSONDecodeError):
            continue
        if created >= cutoff: continue
        if verify_hash and sha256(snapshot) != info['sha256']: continue
        snapshot.unlink()
        metadata.unlink()
        removed.append(snapshot.name)
    return removed


def audit_backups(directory, *, verify_hash=True, verify_before=None):
    anomalies = []
    entries = {path.name: path for path in Path(directory).glob('vnb-feedback-*')}
    for name, path in sorted(entries.items()):
        if not name.endswith('.sqlite'):
            if not name.endswith('.json'): anomalies.append(name + ': unexpected managed-prefix file')
            continue
        metadata = path.with_suffix('.json')
        if metadata.name not in entries:
            anomalies.append(name + ': missing metadata')
            continue
        try:
            info = metadata_for(path)
            check = verify_hash or (verify_before is not None and info['created_utc'] < verify_before)
            if check and sha256(path) != info['sha256']:
                anomalies.append(name + ': hash mismatch')
        except (ValueError, OSError, KeyError, TypeError, json.JSONDecodeError):
            anomalies.append(name + ': invalid backup pair')
    for name, path in sorted(entries.items()):
        if name.endswith('.json') and path.with_suffix('.sqlite').name not in entries:
            anomalies.append(name + ': missing snapshot')
    return anomalies


def invalidate_report(report_dir):
    if report_dir.is_symlink(): raise ValueError('private report directory is a symlink')
    for name in ('report.json', 'report.html'):
        (report_dir / name).unlink(missing_ok=True)


def current_report(database, report_dir, triage, *, release=False):
    database = Path(database).resolve()
    report_dir = Path(report_dir).absolute()
    triage = Path(triage).absolute()
    if report_dir.resolve() == database.parent or triage.parent.resolve() == database.parent:
        raise ValueError('private report and triage need separate directories from live data')
    if triage.is_symlink(): raise ValueError('triage is a symlink')
    # A failed refresh must not leave a deleted opinion in a stale "current" report.
    invalidate_report(report_dir)
    if release and (not host_has_reserve(report_dir.parent)
                    or available_bytes(report_dir.parent) < RELEASE_OPS_FREE):
        raise ValueError('release report paused at storage budget')
    private_dir(report_dir)
    private_dir(triage.parent)
    command = [sys.executable, str(SERVER / 'private_report.py'), '--database', str(database),
               '--triage', str(triage), '--purge-triage', '--output']
    if release:
        with tempfile.TemporaryDirectory(prefix='.report-', dir=report_dir) as staging:
            subprocess.run(command + [staging], check=True)
            for name in ('report.json', 'report.html'):
                os.replace(Path(staging) / name, report_dir / name)
    else:
        subprocess.run(command + [str(report_dir)], check=True)


def release_backup(database, directory, source_commit):
    private_dir(directory)
    now = datetime.now(timezone.utc)
    removed = rotate(directory, now, verify_hash=True)
    cutoff = (now - timedelta(days=30)).strftime('%Y-%m-%dT%H:%M:%SZ')
    anomalies = audit_backups(directory, verify_hash=False, verify_before=cutoff)
    if anomalies:
        raise ValueError('maintenance anomalies; preserve files for private review')
    today = now.strftime('%Y%m%dT')
    existing = sorted(directory.glob('vnb-feedback-' + today + '*.sqlite'))
    if existing:
        return {'backup': str(existing[-1]), 'rotated': removed, 'reused_daily_snapshot': True}
    if (not host_has_reserve(directory) or available_bytes(directory) < RELEASE_OPS_FREE
            or database.stat().st_size > RELEASE_BACKUP_LIMIT):
        raise ValueError('release backup paused at storage budget')
    # The file's length can lag committed growth that is still in WAL.
    with closing(sqlite3.connect(database.resolve().as_uri() + '?mode=ro', uri=True)) as live:
        pages = live.execute('PRAGMA page_count').fetchone()[0]
        page_size = live.execute('PRAGMA page_size').fetchone()[0]
        if pages * page_size > RELEASE_BACKUP_LIMIT:
            raise ValueError('release backup paused at storage budget')
    snapshot, info = make_backup(database, directory, source_commit, release=True, now=now)
    return {'backup': str(snapshot), 'sha256': info['sha256'], 'counts': info['counts'], 'rotated': removed}


def daily_release(args):
    import fcntl

    private_dir(args.backup_dir)
    with (args.backup_dir / '.maintenance.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        # Retire stale output before either job. Try report refresh even if
        # backup fails, and finish the backup before the larger report job.
        invalidate_report(args.report_dir)
        try:
            return release_backup(args.database, args.backup_dir, args.source_commit)
        finally:
            current_report(args.database, args.report_dir, args.triage, release=True)


def restore_safe(snapshot, latest, destination):
    snapshot = Path(snapshot).absolute()
    if snapshot.is_symlink(): raise ValueError('backup is a symlink')
    snapshot = snapshot.resolve()
    latest = Path(latest).resolve()
    destination = Path(destination).absolute()
    if not snapshot.is_file() or not latest.is_file() or snapshot == latest:
        raise ValueError('backup and latest full database must be distinct files')
    if (destination.resolve() in (snapshot, latest) or os.path.lexists(destination)
            or destination.parent.resolve() in (snapshot.parent, latest.parent)):
        raise ValueError('restore requires a new path in a separate directory')
    info = metadata_for(snapshot)
    if sha256(snapshot) != info['sha256'] or counts(snapshot) != info['counts']:
        raise ValueError('backup hash or counts mismatch')
    private_dir(destination.parent)
    with tempfile.TemporaryDirectory(prefix='.vnb-restore-', dir=destination.parent) as folder:
        work = Path(folder)
        newest = work / 'latest.sqlite'
        merged = work / 'merged.sqlite'
        finished = work / 'finished.sqlite'
        backup(latest, newest)
        backup(snapshot, merged)
        merge(merged, newest)
        summary = backup(merged, finished)
        finished.chmod(0o600)
        os.link(finished, destination)  # Exclusive creation; never replace live data or a prior restore.
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    daily = commands.add_parser('daily', help='private backup, current report, and 30-day backup rotation')
    daily.add_argument('--database', type=Path, required=True)
    daily.add_argument('--backup-dir', type=Path, required=True)
    daily.add_argument('--report-dir', type=Path, required=True)
    daily.add_argument('--triage', type=Path, required=True)
    daily.add_argument('--source-commit', required=True)
    daily.add_argument('--release-limits', action='store_true')
    recovery = commands.add_parser('restore', help='merge a managed backup with the latest full database')
    recovery.add_argument('--backup', type=Path, required=True)
    recovery.add_argument('--latest', type=Path, required=True)
    recovery.add_argument('--destination', type=Path, required=True)
    args = parser.parse_args()
    os.umask(0o077)
    if args.command == 'daily' and args.release_limits:
        print(json.dumps(daily_release(args), sort_keys=True))
    elif args.command == 'daily':
        snapshot, info = make_backup(args.database, args.backup_dir, args.source_commit)
        current_report(args.database, args.report_dir, args.triage)
        anomalies = audit_backups(args.backup_dir)
        if anomalies:
            parser.exit(1, 'maintenance anomalies; preserve files for private review:\n' + '\n'.join(anomalies) + '\n')
        removed = rotate(args.backup_dir)
        print(json.dumps({'backup': str(snapshot), 'sha256': info['sha256'], 'counts': info['counts'],
                          'rotated': removed}, sort_keys=True))
    else:
        summary = restore_safe(args.backup, args.latest, args.destination)
        print(json.dumps({'restored': str(args.destination), 'counts': summary}, sort_keys=True))


if __name__ == '__main__': main()
