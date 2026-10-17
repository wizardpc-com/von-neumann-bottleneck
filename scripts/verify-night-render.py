#!/usr/bin/env python3
"""Render existing checks in an imported, isolated verify-project copy."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time
import uuid

SUITES = {
    'hub': ('test_hub_first_screen', ['--hub-capture']),
    'map': ('test_tree_journey_presentation', ['--journey-map-capture']),
    'handbook': ('test_learning_handbook', ['--handbook-capture']),
    'creation': ('test_creation_workbench', ['--creation-capture']),
    'tutorial': ('test_recovery_game_input', ['--recovery-capture', '--interaction-only']),
    'narrative': ('test_night_narrative', ['--narrative-capture', '--candidate-journey']),
    'rules': ('test_rule_practice_input', ['--rule-capture']),
    'route': ('test_creation_route_access', ['--route-capture']),
    'theme': ('test_instrument_theme', ['--theme-capture']),
    'system': ('test_system_evidence_guidance', ['--system-guidance-capture']),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--suite', choices=SUITES, action='append', required=True)
    parser.add_argument('--baseline', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    project = args.project.resolve()
    if project.name != 'project' or not project.is_relative_to(root / '.godot/verification'):
        parser.error('Use only a fresh imported verify-project copy in this checkout')
    engine = args.godot.resolve()
    version = subprocess.check_output([str(engine), '--version'], text=True).strip()
    if not version.startswith('4.7.1.stable.'):
        parser.error('Pinned Godot 4.7.1 stable is required')
    stamp = uuid.uuid4().hex[:12]
    output = root / '.godot/night-render' / stamp
    output.mkdir(parents=True)
    runtime = output / 'runtime'
    runtime.mkdir()
    env = dict(os.environ, APPDATA=str(runtime), LOCALAPPDATA=str(runtime))
    settings_file = project / 'project.godot'
    original = settings_file.read_bytes()
    settings = original.decode('utf-8')
    source_files = {}
    for directory in ('src', 'experiments', 'localization', 'assets', 'tests'):
        for path in sorted((project / directory).rglob('*')):
            if path.is_file():
                source_files[path.relative_to(project).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    source_bytes = json.dumps(source_files, sort_keys=True).encode('utf-8')
    source_identity = hashlib.sha256(source_bytes).hexdigest()
    (output / 'source-files.json').write_text(json.dumps(source_files, indent=2), encoding='utf-8')
    results = []
    print('Rendered controller evidence: ' + str(output), flush=True)
    try:
        for name in args.suite:
            stem, user_args = SUITES[name]
            cases = [(name, user_args)]
            if name == 'theme':
                cases = [(f'theme-{locale}-{size}', user_args + ['--capture-locale=' + locale,
                          '--capture-size=' + size]) for locale in ('zh_CN', 'en')
                         for size in ('1280x720', '1920x1080', '1440x900')]
            for label, case_args in cases:
                custom = 'VonNeumannBottleneckChecks/NightRender-' + stamp + '/' + label
                isolated = re.sub(r'^config/custom_user_dir_name=.*$',
                                  'config/custom_user_dir_name=' + json.dumps(custom),
                                  settings, flags=re.MULTILINE)
                if isolated == settings:
                    raise ValueError('Expected existing isolated custom user directory')
                settings_file.write_text(isolated, encoding='utf-8')
                log = output / (label + '.log')
                command = [str(engine), '--path', str(project), '--script',
                           'res://tests/' + stem + '.gd', '--', '--playtest-source=automated'] + case_args
                started_ns = time.time_ns()
                with log.open('wb') as stream:
                    try:
                        code = subprocess.run(command, env=env, stdout=stream,
                                              stderr=subprocess.STDOUT, timeout=600).returncode
                    except subprocess.TimeoutExpired:
                        code = -1
                text = log.read_text(encoding='utf-8', errors='replace')
                errors = [line for line in text.splitlines()
                          if ('ERROR:' in line or line.startswith('FAIL:'))
                          and 'root certificate store' not in line]
                captures = []
                for directory in (project / '.godot', runtime):
                    for picture in sorted(directory.rglob('*.png')):
                        if picture.stat().st_mtime_ns < started_ns:
                            continue
                        relative = picture.relative_to(directory)
                        destination = output / 'captures' / label / directory.name / relative
                        destination.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(picture, destination)
                        data = destination.read_bytes()
                        if data[:8] != b'\x89PNG\r\n\x1a\n':
                            errors.append('Invalid PNG: ' + str(relative))
                            continue
                        captures.append(dict(path=str(destination.relative_to(output)),
                                             sha256=hashlib.sha256(data).hexdigest(),
                                             bytes=len(data), width=int.from_bytes(data[16:20], 'big'),
                                             height=int.from_bytes(data[20:24], 'big')))
                if not captures:
                    errors.append('Requested capture produced no fresh PNG evidence')
                result = dict(name=label, command=command, exit=code,
                              passed=code == 0 and not errors and 'PASS:' in text,
                              errors=errors, captures=captures, log=str(log.relative_to(root)),
                              effective_settings_sha256=hashlib.sha256(isolated.encode('utf-8')).hexdigest(),
                              test_sha256=hashlib.sha256((project / 'tests' / (stem + '.gd')).read_bytes()).hexdigest())
                results.append(result)
                receipt = dict(engine=version, caller_labels_baseline=args.baseline,
                               source_snapshot_sha256=source_identity, source_file_count=len(source_files),
                               original_settings_sha256=hashlib.sha256(original).hexdigest(),
                               renderer_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                               source_manifest='source-files.json',
                               project=str(project.relative_to(root)),
                               evidence_grade='rendered controller/viewport input; no native or human claim',
                               results=results)
                (output / 'results.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2), encoding='utf-8')
                print(label + ': ' + ('PASS' if result['passed'] else 'FAIL'), flush=True)
    finally:
        settings_file.write_bytes(original)
    return 0 if all(result['passed'] for result in results) else 1


if __name__ == '__main__':
    raise SystemExit(main())
