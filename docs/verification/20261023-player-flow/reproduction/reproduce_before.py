"""Run the new checks against the preserved pre-fix runtime in a separate QA copy."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess

root = Path('E:/VNB/game')
baseline = root / '.godot/verification/20261023T101406Z-17a315ad/project'
out = root / '.godot/verification/20261023-flow-before'
project = out / 'project'
if out.exists():
    raise SystemExit('Refusing to replace an earlier reproduction')
shutil.copytree(baseline, project, ignore=shutil.ignore_patterns('.godot'))
suites = ['test_creation_sample_editing', 'test_workbench_escape',
          'test_hardware_settings_input', 'test_chapter_settings_input']
for name in suites:
    shutil.copy2(root / f'tests/{name}.gd', project / f'tests/{name}.gd')
settings = (root / 'project.godot').read_text(encoding='utf-8')
runtime = out / 'runtime'
runtime.mkdir()
env = dict(os.environ, APPDATA=str(runtime), LOCALAPPDATA=str(runtime),
           TEMP='E:/VNB/temp', TMP='E:/VNB/temp')
spec = importlib.util.spec_from_file_location('verifier', root / 'scripts/verify-project.py')
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
engine = 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
results = []
for name in ['import'] + suites:
    custom_dir = 'VonNeumannBottleneckChecks/20261023-flow-before/' + name
    content = settings.replace('[application]\n', '[application]\nconfig/use_custom_user_dir=true\n'
                              'config/custom_user_dir_name=' + json.dumps(custom_dir) + '\n', 1)
    if name == 'import':
        content = '\n'.join(line for line in content.split('\n') if not line.startswith('theme/custom_font='))
    (project / 'project.godot').write_text(content, encoding='utf-8')
    args = ['--headless', '--editor', '--import', '--quit'] if name == 'import' else [
        '--headless', '--script', f'res://tests/{name}.gd']
    code = verifier.run_logged_process([engine, '--path', str(project)] + args, env, out / f'{name}.txt', 180)
    log = (out / f'{name}.txt').read_text(encoding='utf-8', errors='replace')
    result = dict(name=name, exit=code, expected='pass' if name == 'import' else 'assertion failure',
                  script_error='SCRIPT ERROR:' in log, log=f'{name}.txt', custom_user_dir=custom_dir)
    results.append(result)
    (out / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print(json.dumps(result), flush=True)
    if name == 'import' and code != 0:
        raise SystemExit(code)
files = ['src/ui/prototype_hub.gd', 'src/hardware_foundations/hardware_foundations.gd',
         'experiments/creation/workbench.gd', 'src/system_lab/system_lab.gd',
         'src/overlap_chapter/overlap_chapter.gd', 'src/layout_chapter/layout_chapter.gd']
receipt = {p: hashlib.sha256((project / p).read_bytes()).hexdigest() for p in files}
(out / 'runtime-sha256.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
