#!/usr/bin/env python3
"""Run legacy-save recovery in three separate Godot processes on a QA project copy."""
import argparse
import json
from pathlib import Path
import subprocess
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', required=True, help='An already imported isolated verification project')
    args = parser.parse_args()
    project = Path(args.project).resolve()
    if project == Path(__file__).resolve().parents[1]:
        parser.error('Use an isolated verification copy, not the working checkout')
    version = subprocess.check_output([args.godot, '--version'], text=True).strip()
    if not version.startswith('4.7.1.stable.'):
        parser.error('Godot 4.7.1 stable is required')
    relative = '.godot/save-restart-' + uuid.uuid4().hex[:8]
    evidence = project / relative
    evidence.mkdir(parents=True)
    checks = []
    for name, phase in [('legacy-writer', 'write'), ('migration-reader', 'read'), ('stable-reader', 'read')]:
        command = [args.godot, '--headless', '--path', str(project), '--script',
                   'res://tests/test_save_signature_migration.gd', '--',
                   '--migration-' + phase + '=res://' + relative]
        result = subprocess.run(command, capture_output=True, text=True, timeout=120)
        output = result.stdout + result.stderr
        (evidence / (name + '.txt')).write_text(output)
        passed = result.returncode == 0 and 'PASS:' in output and 'ERROR:' not in output
        checks.append(dict(name=name, passed=passed, exit=result.returncode))
        print(name + ': ' + ('PASS' if passed else 'FAIL'), flush=True)
        if not passed:
            print(output)
            break
    report = dict(engine=version, separate_processes=True, checks=checks)
    digest = evidence / 'stable-digest.txt'
    if digest.exists():
        report['stable_library_sha256'] = digest.read_text()
    (evidence / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Evidence: ' + str(evidence))
    return 0 if len(checks) == 3 and all(c['passed'] for c in checks) else 1


if __name__ == '__main__':
    raise SystemExit(main())
