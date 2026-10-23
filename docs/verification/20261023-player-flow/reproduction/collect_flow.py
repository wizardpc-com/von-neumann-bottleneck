from pathlib import Path
import difflib
import hashlib
import json
import shutil
import subprocess

root = Path('E:/VNB/game')
baseline = root / '.godot/verification/20261023T101406Z-17a315ad/project'
final = root / '.godot/verification/20261023T102738Z-73e2219c/project'
out = root / 'docs/verification/20261023-player-flow'
out.mkdir(parents=True, exist_ok=True)
runtime_files = [
    'src/ui/prototype_hub.gd', 'src/hardware_foundations/hardware_foundations.gd',
    'experiments/creation/workbench.gd', 'src/system_lab/system_lab.gd',
    'src/overlap_chapter/overlap_chapter.gd', 'src/layout_chapter/layout_chapter.gd',
]
test_files = ['tests/' + name for name in [
    'test_workbench_escape.gd', 'test_creation_sample_editing.gd',
    'test_hardware_settings_input.gd', 'test_chapter_settings_input.gd',
    'fixture_settings_quit_probe.gd',
]]
filenames = set(subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'],
                                      cwd=root).decode('utf-8').split('\0')) - {''}
changed_runtime = []
unchanged = 0
for name in sorted(filenames):
    if not name.startswith(('src/', 'experiments/', 'localization/', 'assets/')) and name != 'project.godot':
        continue
    if not (root / name).is_file():
        continue
    if name == 'project.godot':
        qa_settings = (baseline / name).read_text(encoding='utf-8').splitlines()
        qa_settings = [line for line in qa_settings if not line.startswith(('config/use_custom_user_dir=', 'config/custom_user_dir_name='))]
        assert qa_settings == (root / name).read_text(encoding='utf-8').splitlines(), 'Unexpected project settings change'
        unchanged += 1
        continue
    if not (baseline / name).exists() or (root / name).read_bytes() != (baseline / name).read_bytes():
        changed_runtime.append(name)
    else:
        unchanged += 1
assert set(changed_runtime) == set(runtime_files), changed_runtime
hashes = {}
patches = []
for name in runtime_files + test_files:
    data = (root / name).read_bytes()
    hashes[name] = dict(sha256=hashlib.sha256(data).hexdigest(),
                       matches_final_qa_copy=(final / name).read_bytes() == data)
    before = (baseline / name).read_text(encoding='utf-8').splitlines(keepends=True) if (baseline / name).exists() else []
    after = data.decode('utf-8').replace('\r\n', '\n').splitlines(keepends=True)
    patches.extend(difflib.unified_diff(before, after, fromfile='before/' + name, tofile='after/' + name))
assert all(hashes[name]['matches_final_qa_copy'] for name in runtime_files)
(out / 'scope-audit.json').write_text(json.dumps(dict(runtime_changed=changed_runtime,
    unchanged_runtime_assets_localization=unchanged, files=hashes), indent=2), encoding='utf-8')
(out / 'player-flow.patch').write_text(''.join(patches), encoding='utf-8')
print(json.dumps(dict(changed_runtime=len(changed_runtime), unchanged=unchanged,
                     runtime_matches_focused=True, evidence=str(out)), indent=2))
