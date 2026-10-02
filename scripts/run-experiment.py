#!/usr/bin/env python3
"""Launch an isolated experiment without using the player's save directory."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('experiment', choices=['representation', 'intelligent_workload', 'representation_plan', 'intelligent_state'])
    parser.add_argument('--godot', required=True)
    parser.add_argument('--locale', choices=['en', 'zh_CN'], default='zh_CN')
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--replay', choices=['lab', 'proxy', 'depth'])
    args = parser.parse_args()
    engine = shutil.which(args.godot) or str(Path(args.godot).expanduser().resolve())
    if not subprocess.check_output([engine, '--version'], text=True).startswith('4.7.1.stable.'):
        parser.error('Godot 4.7.1 stable required')
    root = Path(__file__).resolve().parents[1]
    stamp = uuid.uuid4().hex[:12]
    output = root / '.godot' / 'experiments' / stamp
    project = output / 'project'
    project.mkdir(parents=True)
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root).decode().split('\0')
    for name in sorted(set(names) - {''}):
        source = root / name
        if source.is_symlink():
            raise RuntimeError('Review symbolic link: ' + name)
        if source.is_file():
            dest = project / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
    if (root / 'override.cfg').exists():
        raise RuntimeError('Review override.cfg before launch')
    settings = (project / 'project.godot').read_text()
    if 'config/custom_user_dir_name=' in settings or 'config/use_custom_user_dir=' in settings:
        raise RuntimeError('Review custom user directory settings')
    settings = settings.replace('[application]\n', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=' + json.dumps('VonNeumannBottleneckChecks/experiments/' + stamp) + '\n', 1)
    (project / 'project.godot').write_text('\n'.join(s for s in settings.split('\n') if not s.startswith('theme/custom_font=')))
    with (output / 'import.txt').open('w') as log:
        subprocess.run([engine, '--path', str(project), '--headless', '--editor', '--import', '--quit'], stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
    if 'SCRIPT ERROR:' in (output / 'import.txt').read_text():
        raise RuntimeError('Import failed: ' + str(output / 'import.txt'))
    (project / 'project.godot').write_text(settings)
    print('Isolated project: ' + str(project), flush=True)
    if args.prepare_only:
        return
    command = [engine, '--path', str(project)]
    if args.replay:
        replays = {'lab': 'play_labs.gd', 'proxy': 'evidence_proxy/driver.gd', 'depth': 'play_depth.gd'}
        command += ['--script', 'res://experiments/' + replays[args.replay]]
    else:
        scenes = {'representation_plan': 'representation/puzzle.tscn',
                  'intelligent_state': 'intelligent_workload/state_lab.tscn'}
        command += ['res://experiments/' + scenes.get(args.experiment, args.experiment + '/lab.tscn')]
    command += ['--', '--locale=' + args.locale, '--evidence-dir=' + str(output / 'captures')]
    with (output / 'session.txt').open('w') as log:
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT)
    text = (output / 'session.txt').read_text()
    print(text)
    if result.returncode or 'ERROR:' in text or 'FAIL:' in text:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
