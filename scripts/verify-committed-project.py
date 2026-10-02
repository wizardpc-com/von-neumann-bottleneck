#!/usr/bin/env python3
"""Verify an exact Git commit in a clean detached clone and prove copied-source identity."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import uuid


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args]).decode().strip()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def normalized_settings(data):
    # Only the verifier's documented save-isolation lines may differ.
    return '\n'.join(line for line in data.decode().splitlines()
                     if not line.startswith(('config/use_custom_user_dir=',
                                             'config/custom_user_dir_name='))).encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--ref', default='HEAD')
    parser.add_argument('--suite', action='append')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    commit = git(root, 'rev-parse', '--verify', args.ref + '^{commit}')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:8]
    output = root / '.godot' / 'committed-verification' / stamp
    output.mkdir(parents=True)
    checkout = output / 'checkout'
    subprocess.run(['git', 'clone', '--quiet', '--no-hardlinks', '--no-checkout', str(root), str(checkout)], check=True)
    subprocess.run(['git', '-C', str(checkout), 'checkout', '--quiet', '--detach', commit], check=True)
    if git(checkout, 'status', '--porcelain'):
        raise RuntimeError('Detached checkout is not clean before verification')
    files = subprocess.check_output(['git', '-C', str(checkout), 'ls-files', '-z']).decode().split('\0')
    hashes = {}
    for name in filter(None, files):
        path = checkout / name
        if path.is_symlink():
            raise RuntimeError('Review symbolic link: ' + name)
        hashes[name] = digest(path.read_bytes())
    manifest = {'commit': commit, 'tree': git(checkout, 'rev-parse', 'HEAD^{tree}'),
                'clean_before': True, 'tracked_sha256': hashes}
    (output / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    command = [sys.executable, str(checkout / 'scripts/verify-project.py'), '--godot', args.godot]
    for suite in args.suite or []:
        command += ['--suite', suite]
    print('Committed verification: ' + str(output), flush=True)
    with (output / 'verification.txt').open('w') as stream:
        code = subprocess.run(command, cwd=checkout, stdout=stream, stderr=subprocess.STDOUT).returncode
    runs = list((checkout / '.godot/verification').glob('*/results.json'))
    if len(runs) != 1:
        raise RuntimeError('Expected one verification result; inspect ' + str(output))
    result_path = runs[0]
    source_copy = result_path.parent / 'project'
    mismatches = []
    for name, expected in hashes.items():
        original = checkout / name
        copied = source_copy / name
        if not copied.is_file() or digest(original.read_bytes()) != expected:
            mismatches.append(name)
        elif name == 'project.godot':
            if normalized_settings(original.read_bytes()) != normalized_settings(copied.read_bytes()):
                mismatches.append(name)
        elif digest(copied.read_bytes()) != expected:
            mismatches.append(name)
    results = json.loads(result_path.read_text())
    status = git(checkout, 'status', '--porcelain')
    passed = code == 0 and not mismatches and not status and all(r['passed'] for r in results['results'])
    receipt = {'commit': commit, 'passed': passed, 'verification_exit': code,
               'clean_after': not status, 'checkout_status': status,
               'source_mismatches': mismatches, 'checked_files': len(hashes),
               'project_settings_exception': 'Only two custom save-directory lines removed for comparison',
               'results': results}
    (output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    shutil.copy2(result_path, output / 'results.json')
    print((output / 'verification.txt').read_text())
    print('PASS: exact committed source and clean checkout' if passed else 'FAIL: committed verification')
    print('Receipt: ' + str(output / 'receipt.json'))
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
