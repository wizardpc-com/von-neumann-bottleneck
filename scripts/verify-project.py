#!/usr/bin/env python3
"""Verify a fresh project copy with a unique player-data directory per run."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, help='Godot 4.7.1 editor executable')
    parser.add_argument('--gui', action='store_true', help='Also replay the ordinary Game GUI')
    parser.add_argument('--locale', choices=('zh_CN', 'en'), default='zh_CN')
    parser.add_argument('--interaction-only', action='store_true', help='Short Tutorial GUI replay')
    args = parser.parse_args()
    engine = shutil.which(args.godot) or str(Path(args.godot).expanduser().resolve())
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    if not version.startswith('4.7.1.stable.'):
        parser.error('Godot 4.7.1 stable is required; found ' + version)

    root = Path(__file__).resolve().parents[1]
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:8]
    output = root / '.godot' / 'verification' / stamp
    project = output / 'project'
    project.mkdir(parents=True)
    filenames = subprocess.check_output(
        ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root
    ).decode('utf-8').split('\0')
    for filename in sorted(set(filenames) - {''}):
        source = root / filename
        if source.is_symlink():
            raise RuntimeError('Review symbolic link before copying: ' + filename)
        if source.is_file():
            target = project / filename
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    if (root / 'override.cfg').exists():
        raise RuntimeError('Review existing override.cfg before an isolated verification run')
    project_settings = (project / 'project.godot').read_text(encoding='utf-8')
    if 'config/use_custom_user_dir=' in project_settings or 'config/custom_user_dir_name=' in project_settings:
        raise RuntimeError('Review existing custom user directory settings before isolation')

    # Windows respects APPDATA; macOS uses the unique custom Godot directory below.
    runtime = output / 'runtime'
    runtime.mkdir()
    env = dict(os.environ, APPDATA=str(runtime), LOCALAPPDATA=str(runtime))
    results = []

    def run(name, arguments, require_pass=False, timeout=180):
        custom_dir = 'VonNeumannBottleneckChecks/' + stamp + '/' + name
        settings = project_settings.replace(
            '[application]\n', '[application]\nconfig/use_custom_user_dir=true\n'
            'config/custom_user_dir_name=' + json.dumps(custom_dir) + '\n', 1
        )
        # The global theme initializes before the editor can import a fresh font.
        if name == 'import':
            settings = '\n'.join(line for line in settings.split('\n')
                                 if not line.startswith('theme/custom_font='))
        (project / 'project.godot').write_text(settings, encoding='utf-8')
        log = output / (name + '.txt')
        command = [engine, '--path', str(project)] + arguments
        with log.open('wb') as stream:
            try:
                code = subprocess.run(command, env=env, stdout=stream, stderr=subprocess.STDOUT,
                                      timeout=timeout).returncode
            except subprocess.TimeoutExpired:
                code = -1
        text = log.read_text(encoding='utf-8', errors='replace')
        errors = [line for line in text.splitlines()
                  if ('ERROR:' in line or line.startswith('FAIL:'))
                  and 'root certificate store' not in line]
        passed = code == 0 and not errors and (not require_pass or 'PASS:' in text)
        result = dict(name=name, exit=code, passed=passed, errors=errors, log=log.name,
                      custom_user_dir=custom_dir)
        results.append(result)
        (output / 'results.json').write_text(json.dumps(dict(engine=version, platform=sys.platform,
            results=results), indent=2), encoding='utf-8')
        print(name + ': ' + ('PASS' if passed else 'FAIL') + ' (' + log.name + ')', flush=True)
        return passed

    print('Evidence and isolated project: ' + str(output), flush=True)
    if not run('import', ['--headless', '--editor', '--import', '--quit']):
        return 1
    probe = project / 'verify_user_directory.gd'
    probe.write_text('extends SceneTree\nfunc _init() -> void:\n'
                     '\tvar actual := OS.get_user_data_dir().replace("\\\\", "/")\n'
                     '\tprint("Isolated user directory: ", actual)\n'
                     '\tquit(0 if actual.ends_with("' + 'VonNeumannBottleneckChecks/' + stamp + '/user_directory") else 1)\n', encoding='utf-8')
    if not run('user_directory', ['--headless', '--script', 'res://verify_user_directory.gd']):
        return 1
    suites = sorted((project / 'tests').glob('test_*.gd'))
    for suite in suites:
        if suite.stem != 'test_recovery_game_input':
            run(suite.stem, ['--headless', '--script', 'res://tests/' + suite.name], True)
    if args.gui:
        arguments = ['--script', 'res://tests/test_recovery_game_input.gd', '--',
                     '--locale=' + args.locale, '--recovery-capture',
                     '--evidence-dir=res://.godot/game-input/']
        if args.interaction_only:
            arguments.append('--interaction-only')
        run('game_gui_' + args.locale, arguments, True, timeout=600)
    return 0 if all(result['passed'] for result in results) else 1


if __name__ == '__main__':
    raise SystemExit(main())
