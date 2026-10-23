"""Replay focused QA scripts in a prepared copy with fresh isolated profiles."""
from pathlib import Path
import argparse
import importlib.util
import json
import os

parser = argparse.ArgumentParser()
parser.add_argument('--project', required=True)
parser.add_argument('--out', required=True)
parser.add_argument('--suite', action='append', required=True)
parser.add_argument('--gui', action='store_true')
args = parser.parse_args()
root = Path('E:/VNB/game')
project, out = Path(args.project), Path(args.out)
out.mkdir(parents=True, exist_ok=False)
runtime = out / 'runtime'
runtime.mkdir()
env = dict(os.environ, APPDATA=str(runtime), LOCALAPPDATA=str(runtime),
           TEMP='E:/VNB/temp', TMP='E:/VNB/temp')
spec = importlib.util.spec_from_file_location('verifier', root / 'scripts/verify-project.py')
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
settings = (root / 'project.godot').read_text(encoding='utf-8')
old_settings = (project / 'project.godot').read_bytes()
engine = 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
results = []
try:
    for name in args.suite:
        custom_dir = 'VonNeumannBottleneckChecks/' + out.name + '/' + name
        content = settings.replace('[application]\n', '[application]\nconfig/use_custom_user_dir=true\n'
                                  'config/custom_user_dir_name=' + json.dumps(custom_dir) + '\n', 1)
        (project / 'project.godot').write_text(content, encoding='utf-8')
        if args.gui:
            profile = runtime / custom_dir
            profile.mkdir(parents=True, exist_ok=False)
            (profile / 'presentation.cfg').write_text(
                '[audio]\nenabled=false\nvolume=0.0\n[ambience]\nenabled=false\nvolume=0.0\n'
                '[window]\nfullscreen=false\nsize=Vector2i(1280, 720)\nposition=Vector2i(40, 40)\n',
                encoding='utf-8')
        command = [engine, '--path', str(project)]
        if not args.gui:
            command += ['--headless']
        else:
            command += ['--rendering-method', 'gl_compatibility', '--windowed', '--resolution', '1280x720']
        command += ['--script', f'res://tests/{name}.gd']
        if args.gui and name == 'test_creation_sample_editing':
            command += ['--', '--creation-sample-edit-capture']
        code = verifier.run_logged_process(command, env, out / f'{name}.txt', 240)
        log = (out / f'{name}.txt').read_text(encoding='utf-8', errors='replace')
        errors = [line for line in log.splitlines() if ('ERROR:' in line or line.startswith('FAIL:'))
                  and 'root certificate store' not in line]
        result = dict(name=name, exit=code, passed=code == 0 and not errors and 'PASS:' in log,
                      errors=errors, custom_user_dir=custom_dir)
        results.append(result)
        (out / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
        print(json.dumps(result), flush=True)
finally:
    (project / 'project.godot').write_bytes(old_settings)
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
