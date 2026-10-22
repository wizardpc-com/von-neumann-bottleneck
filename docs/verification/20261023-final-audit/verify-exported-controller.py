from pathlib import Path
import hashlib, importlib.util, json, os, re, shutil, subprocess, time, zipfile

root = Path(__file__).resolve().parents[1]
candidate = root / 'build/playtest-FinalAudit20261023-1479c452bd1d'
manifest = json.loads((candidate / 'manifest.json').read_text(encoding='utf-8'))
work = root / '.godot/package-qa/final-audit-20261023-1479c45'
work.mkdir(parents=True, exist_ok=False)
archive = candidate / manifest['platforms']['Windows']['zip']
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(archive) == manifest['platforms']['Windows']['sha256']
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    names = package.namelist()
    for name in names:
        target = (work / name).resolve()
        assert target.is_relative_to(work.resolve()), name
    package.extractall(work)
binary = work / 'Windows/Von-Neumann-Bottleneck.exe'
original_hash = sha(binary)
assert original_hash == sha(candidate / 'Windows/Von-Neumann-Bottleneck.exe')
spec = importlib.util.spec_from_file_location('package_structure', root / 'scripts/package-verified-playtest.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
structure = module.inspect_executable(binary)
assert structure['pe_architecture'] == 'x86_64'
assert len(manifest['content_tasks']) == 60
assert manifest['feedback_endpoint'] == ''
assert not manifest.get('offline_tester', False)
assert not any(any(part in name.lower() for part in ['savegame', 'hardware_workbench', 'cinematics.cfg', '/tests/', 'override.cfg']) for name in names)
env = dict(os.environ)
for key in ['APPDATA','LOCALAPPDATA','TEMP','TMP']:
    directory = work / 'runtime' / key
    directory.mkdir(parents=True)
    env[key] = str(directory)
results = []
for suite in ['test_mode_access', 'test_cinematics', 'test_lab_terminal_routing']:
    suffix = 'VonNeumannBottleneckChecks/package-final-audit-' + suite
    override = binary.parent / 'override.cfg'
    probe = work / (suite + '.gd')
    source = (root / 'tests' / (suite + '.gd')).read_text(encoding='utf-8')
    source = source.replace('extends SceneTree', 'extends Node').replace('func _init()', 'func _ready()')
    source = source.replace('ProjectSettings.get_setting("application/run/main_scene")', '"res://src/ui/startup.tscn"')
    for symbol in ['root','paused','process_frame','current_scene']:
        source = re.sub(r'\b' + symbol + r'\b', 'get_tree().' + symbol, source)
    for method in ['quit','change_scene_to_file','get_nodes_in_group','create_timer']:
        source = re.sub(r'(?<![.\w])' + method + r'\(', 'get_tree().' + method + '(', source)
    probe.write_text(source, encoding='utf-8')
    bootstrap = work / 'bootstrap.gd'
    bootstrap.write_text('extends Node\nfunc _ready() -> void:\n\tcall_deferred("_start")\nfunc _start() -> void:\n\tget_tree().current_scene = null\n\tget_tree().root.add_child(load(' + json.dumps(probe.as_posix()) + ').new())\n\tqueue_free()\n', encoding='utf-8')
    scene = work / 'bootstrap.tscn'
    scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path=' + json.dumps(bootstrap.as_posix()) + ' id="1"]\n[node name="PackageProbe" type="Node"]\nscript = ExtResource("1")\n', encoding='utf-8')
    override.write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=' + json.dumps(suffix) + '\nrun/main_scene=' + json.dumps(scene.as_posix()) + '\n', encoding='utf-8')
    log = work / (suite + '.txt')
    with log.open('w', encoding='utf-8') as stream:
        process = subprocess.Popen([str(binary), '--headless'], cwd=binary.parent,
                                   env=env, stdout=stream, stderr=subprocess.STDOUT)
        (work / 'child.json').write_text(json.dumps({'pid':process.pid,'binary':str(binary),'suite':suite}), encoding='utf-8')
        deadline = time.monotonic() + 150
        while process.poll() is None:
            text = log.read_text(encoding='utf-8', errors='replace')
            if 'ERROR:' in text or time.monotonic() > deadline:
                process.kill()
                process.wait()
                break
            time.sleep(0.1)
    output = log.read_text(encoding='utf-8', errors='replace')
    assert process.returncode == 0 and 'PASS:' in output and 'ERROR:' not in output, output
    if suite == 'test_mode_access':
        assert 'free_candidate=true' in output, output
    assert sha(binary) == original_hash
    results.append({'suite':suite, 'passed':True, 'output':log.name, 'qa_profile':suffix})
    print(suite + ': PASS on actual exported Windows executable', flush=True)
override.unlink()
assert sha(archive) == manifest['platforms']['Windows']['sha256']
receipt = {'source_commit':manifest['source_commit'], 'build_id':manifest['build_id'],
           'zip_sha256':sha(archive), 'zip_bytes':archive.stat().st_size,
           'executable':structure, 'actual_exported_tests':results,
           'zip_inventory':names, 'qa_only_override_removed':True,
           'candidate_and_archive_unchanged':True, 'native_graphics_audio_verified':False}
(work / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
print('PASS: exact archive and embedded PCK, mode selection and both CGs; ' + str(work), flush=True)
