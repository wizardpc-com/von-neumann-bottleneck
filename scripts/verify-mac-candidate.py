#!/usr/bin/env python3
"""Verify an exported Mac binary with a QA-only settings override and protected player path."""
import argparse,hashlib,json,plistlib,shutil,subprocess,uuid
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--app',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];original=a.app.resolve();stamp=uuid.uuid4().hex[:12]
manifest=json.loads((original.parent/'BUILD-MANIFEST.json').read_text())
work=root/'.godot/package-qa'/stamp;work.mkdir(parents=True);app=work/original.name
shutil.copytree(original,app,symlinks=True)
info=plistlib.loads((app/'Contents/Info.plist').read_bytes());binary=app/'Contents/MacOS'/info['CFBundleExecutable']
pack=app/'Contents/Resources'/(info['CFBundleExecutable']+'.pck')
hashes={str(x.relative_to(app)):hashlib.sha256(x.read_bytes()).hexdigest() for x in [binary,pack]}
user_suffix='VonNeumannBottleneckChecks/package-'+stamp
probe=work/'package_probe.gd';scene=work/'package_probe.tscn'
probe.write_text('''extends Node
func _ready() -> void:
	var mode: Node = get_node("/root/GameMode")
	var remote: Node = get_node("/root/RemoteFeedback")
	var checks: Dictionary = {
		"isolated":OS.get_user_data_dir().ends_with("SUFFIX"),
		"candidate_feature":OS.has_feature("free_candidate"),
		"game_only":not mode.is_test_mode() and not mode.developer_tools_enabled() and not mode.set_mode(&"test"),
		"capture_disabled":mode.capture_arguments().is_empty(),
		"forty_tasks":get_node("/root/TaskNavigation").tasks().size()==40,
		"remote_default_off":not remote.enabled and remote.endpoint.is_empty(),
		"build_identity":ProjectSettings.get_setting("application/config/version")=="EXPECTED_BUILD" and ProjectSettings.get_setting("application/config/build_commit")=="EXPECTED_COMMIT",
		"tests_excluded":not ResourceLoader.exists("res://tests/test_layout_simulation.gd"),
		"server_excluded":not FileAccess.file_exists("res://server/feedback_server.py")}
	var passed: bool = true
	for value: bool in checks.values(): passed=passed and value
	print("PACKAGE_CHECKS ",JSON.stringify(checks))
	if passed:
		var file=FileAccess.open("user://package_probe_result.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(checks)); file.close()
	get_tree().quit(0 if passed else 1)
'''.replace('SUFFIX',user_suffix).replace('EXPECTED_BUILD',manifest['build_id']).replace('EXPECTED_COMMIT',manifest['source_commit']))
scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="'+str(probe)+'" id="1"]\n[node name="PackageProbe" type="Node"]\nscript = ExtResource("1")\n')
settings='[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+user_suffix+'"\n'
override=binary.parent/'override.cfg';override.write_text(settings+'run/main_scene="'+str(scene)+'"\n')
# If overrides fail, deny both reads and writes to the original game's data directory.
player=Path.home()/'Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck'
profile=work/'protect-player.sb';profile.write_text('(version 1)\n(allow default)\n(deny file-read* file-write* (subpath "'+str(player)+'"))\n')
result=subprocess.run(['/usr/bin/sandbox-exec','-f',str(profile),str(binary),'--headless','--quit-after','120','--log-file',str(work/'engine.log'),'--','--test-mode','--capture-cpu-success','--reset-local-test-state'],cwd=work,capture_output=True,text=True,timeout=60)
output=result.stdout+result.stderr;(work/'probe.log').write_text(output)
override.write_text(settings)
if result.returncode or 'PACKAGE_CHECKS' not in output or 'false' in next((line for line in output.splitlines() if line.startswith('PACKAGE_CHECKS')),'false') or 'SCRIPT ERROR' in output:raise RuntimeError('Package probe failed; see '+str(work/'probe.log'))
for name,digest in hashes.items():assert hashlib.sha256((app/name).read_bytes()).hexdigest()==digest
report={'build_id':manifest['build_id'],'source_commit':manifest['source_commit'],'passed':True,'source_app':str(original),'qa_app':str(app),'user_suffix':user_suffix,'binary_and_pack_unchanged':hashes,'qa_override_only':str(override),'public_release':False}
(work/'result.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS: actual Mac release binary, Game-only/capture boundary, forty tasks, remote off, excluded development files, isolated user directory. '+str(work))
