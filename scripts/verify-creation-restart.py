#!/usr/bin/env python3
"""Verify a generated work and its fork in three fresh isolated Godot processes."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', type=Path, required=True)
    args = parser.parse_args()
    project = args.project.resolve()
    if project == Path(__file__).resolve().parents[1] or '.godot' not in project.parts:
        parser.error('Use an imported isolated verification project')
    version = subprocess.check_output([args.godot, '--version'], text=True).strip()
    if not version.startswith('4.7.1.stable.'):
        parser.error('Godot 4.7.1 stable is required')
    settings_path = project / 'project.godot'
    original = settings_path.read_bytes()
    settings = original.decode('utf-8')
    if 'config/use_custom_user_dir=true' not in settings:
        parser.error('The verification project must already isolate user data')
    stamp = uuid.uuid4().hex[:12]
    identity = 'VonNeumannBottleneckChecks/creation-restart-' + stamp
    settings, count = re.subn(r'config/custom_user_dir_name="[^"]+"',
                             'config/custom_user_dir_name=' + json.dumps(identity), settings)
    if count != 1:
        parser.error('Expected one isolated custom user directory')
    evidence = project.parent / ('creation-restart-' + stamp)
    evidence.mkdir()
    runtime = evidence / 'runtime'
    runtime.mkdir()
    environment = dict(os.environ, APPDATA=str(runtime), LOCALAPPDATA=str(runtime),
                       PYTHONIOENCODING='utf-8')
    checks = []
    try:
        settings_path.write_text(settings, encoding='utf-8')
        for phase in ('write', 'fork', 'read'):
            command = [args.godot, '--headless', '--path', str(project), '--script',
                       'res://tests/fixture_creation_restart.gd', '--', '--creation-phase=' + phase]
            process = subprocess.run(command, capture_output=True, text=True,
                                     encoding='utf-8', errors='replace', env=environment, timeout=120)
            output = process.stdout + process.stderr
            (evidence / (phase + '.txt')).write_text(output, encoding='utf-8')
            errors = [line for line in output.splitlines() if
                      ('ERROR:' in line or line.startswith('FAIL:')) and
                      'root certificate store' not in line]
            passed = process.returncode == 0 and 'PASS:' in output and not errors
            checks.append(dict(phase=phase, passed=passed, exit=process.returncode, errors=errors))
            print(phase + ': ' + ('PASS' if passed else 'FAIL'), flush=True)
            if not passed:
                print(output)
                break
    finally:
        settings_path.write_bytes(original)
    (evidence / 'results.json').write_text(json.dumps(dict(engine=version,
        separate_processes=True, profile=identity, checks=checks), indent=2) + '\n', encoding='utf-8')
    print('Evidence: ' + str(evidence))
    return 0 if len(checks) == 3 and all(check['passed'] for check in checks) else 1


if __name__ == '__main__':
    raise SystemExit(main())
