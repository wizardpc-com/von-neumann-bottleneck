import argparse
import importlib.util
import json
from pathlib import Path
import re
import time
import os

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('verify_project', ROOT / 'scripts/verify-project.py')
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)
p = argparse.ArgumentParser()
p.add_argument('--project', required=True)
p.add_argument('--out', required=True)
p.add_argument('--suite', action='append', required=True)
p.add_argument('--gpu', action='store_true')
p.add_argument('--flag', action='append', default=[])
a = p.parse_args()
project, out = Path(a.project).resolve(), Path(a.out).resolve()
out.mkdir(parents=True, exist_ok=True)
settings = (project / 'project.godot').read_text()
results = []
for index, suite in enumerate(a.suite):
    profile = 'VonNeumannBottleneckChecks/boundaries-' + str(time.time_ns()) + '/' + suite
    isolated = re.sub(r'config/custom_user_dir_name=.*', 'config/custom_user_dir_name=' + json.dumps(profile), settings)
    assert isolated != settings and 'config/use_custom_user_dir=true' in isolated
    (project / 'project.godot').write_text(isolated)
    command = ['/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot', '--path', str(project)]
    if not a.gpu:
        command += ['--headless']
    command += ['--script', 'res://tests/' + suite + '.gd']
    if a.flag:
        command += ['--'] + a.flag
    log = out / (suite + '.txt')
    code = verify.run_logged_process(command, dict(os.environ), log, 300)
    content = log.read_text(errors='replace')
    errors = [line for line in content.splitlines() if ('ERROR:' in line or line.startswith('FAIL:')) and 'root certificate store' not in line]
    result = dict(suite=suite, command=command, profile=profile, exit=code, passed=code == 0 and not errors and 'PASS:' in content, errors=errors, log=str(log))
    results.append(result)
    (out / 'results.json').write_text(json.dumps(results, indent=2))
    print(suite + ': ' + ('PASS' if result['passed'] else 'FAIL') + ' exit=' + str(code), flush=True)
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
