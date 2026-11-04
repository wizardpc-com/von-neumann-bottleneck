"""Process-boundary recovery probe. Uses isolated profiles and an access-only fixture."""
import argparse, json, os, pathlib, subprocess, time
ROOT = pathlib.Path(__file__).resolve().parents[1]
ENGINE = 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default=ENGINE)
args = parser.parse_args()
ENGINE = args.godot
OUT = ROOT / ('.godot/d1b/process-' + time.strftime('%Y%m%d-%H%M%S'))
OUT.mkdir(parents=True, exist_ok=True)
results = []
for route in ['chapter_1/assembly', 'chapter_3/arrival', 'chapter_4/fields']:
    for scenario in ['quit', 'map', 'lab', 'close', 'early', 'late']:
        folder = OUT / (route.replace('/', '-') + '-' + scenario)
        folder.mkdir(exist_ok=True)
        env = dict(os.environ, APPDATA=str(folder / 'profile'), LOCALAPPDATA=str(folder / 'profile'))
        ready = folder / 'ready'
        command = [ENGINE, '--headless', '--path', str(ROOT), '--script', 'res://tests/recovery/process_recovery_probe.gd', '--', '--route=' + route, '--scenario=' + scenario, '--ready=' + str(ready)]
        with (folder / 'edit.log').open('w', encoding='utf-8') as stream:
            child = subprocess.Popen(command + ['--phase=edit'], env=env, stdout=stream, stderr=subprocess.STDOUT)
            if scenario in ['early', 'late']:
                deadline = time.monotonic() + 25
                while not ready.exists() and child.poll() is None and time.monotonic() < deadline:
                    time.sleep(.01)
                if not ready.exists():
                    child.kill()
                    raise RuntimeError('No ready marker: ' + str(folder))
                killed = subprocess.run(['taskkill', '/F', '/PID', str(child.pid)], capture_output=True)
                (folder / 'kill.log').write_bytes(killed.stdout + killed.stderr)
                if killed.returncode: child.kill()
            child.wait(timeout=30)
        loaded = subprocess.run(command + ['--phase=load'], env=env, capture_output=True, timeout=30)
        (folder / 'load.log').write_bytes(loaded.stdout + loaded.stderr)
        restored = b'RESTORED: true' in loaded.stdout
        expected = scenario != 'early' or route.startswith('chapter_4')
        result = dict(route=route, scenario=scenario, restored=restored, expected=expected, passed=restored == expected and b'RESTORED: ' in loaded.stdout and loaded.returncode == 0 and (child.returncode == 0 if scenario not in ['early', 'late'] else child.returncode != 0), edit_exit=child.returncode, load_exit=loaded.returncode)
        results.append(result)
        print(result, flush=True)
(OUT / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')

passed = sum(item['passed'] for item in results)
print(f'Process recovery: {passed}/{len(results)} passed; evidence: {OUT}', flush=True)
raise SystemExit(0 if passed == len(results) else 1)
