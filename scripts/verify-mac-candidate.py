#!/usr/bin/env python3
"""Verify an exported Mac binary with a QA-only settings override and protected player path."""
import argparse,hashlib,json,plistlib,shutil,subprocess,uuid
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--app',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];original=a.app.resolve();stamp=uuid.uuid4().hex[:12]
manifest=json.loads((original.parent/'BUILD-MANIFEST.json').read_text())
release=json.loads((original.parent.parent/'manifest.json').read_text())
expected_tasks=len(release['content_tasks'])
edition=release.get('edition','')
mode_check=('mode.edition()=="'+edition+'" and mode.edition_locked() and mode.is_test_mode()=='+str(edition=='test').lower()+' and not mode.developer_tools_enabled() and not mode.set_mode(&"'+('game' if edition=='test' else 'test')+'")' if edition else
            'not mode.is_test_mode() and not mode.developer_tools_enabled() and mode.set_mode(&"test") and mode.is_test_mode() and mode.set_mode(&"game") and not mode.is_test_mode()')
build_check=('ProjectSettings.get_setting("application/config/version")=="'+release['display_version']+'" and ProjectSettings.get_setting("application/config/build_id")=="'+manifest['build_id']+'"' if edition else
             'ProjectSettings.get_setting("application/config/version")=="'+manifest['build_id']+'"')

expected_keys=json.dumps(sorted(release['content_tasks']))
work=root/'.godot/package-qa'/stamp;work.mkdir(parents=True);app=work/original.name
shutil.copytree(original,app,symlinks=True)
info=plistlib.loads((app/'Contents/Info.plist').read_bytes());binary=app/'Contents/MacOS'/info['CFBundleExecutable']
pack=app/'Contents/Resources'/(info['CFBundleExecutable']+'.pck')
hashes={str(x.relative_to(app)):hashlib.sha256(x.read_bytes()).hexdigest() for x in [binary,pack]}
user_suffix='VonNeumannBottleneckChecks/package-'+stamp
if edition:user_suffix+='/VonNeumannBottleneckCandidates/representation/'+release['save_profile']
probe=work/'package_probe.gd';scene=work/'package_probe.tscn'
probe.write_text('''extends Node
func _ready() -> void:
	var mode: Node = get_node("/root/GameMode")
	var remote: Node = get_node("/root/RemoteFeedback")
	var store_script: Script = load("res://src/hardware_foundations/circuit_workbench_store.gd")
	var workbench_path: String = "user://package_workbench_probe.json"
	var store = store_script.new(workbench_path)
	store.ensure_default(&"game", &"probe", {"components": [], "wires": []})
	var first_write: bool = store.save_active(&"game", &"probe", {"components": [{"id": "first"}], "wires": []})
	var second_write: bool = store.save_active(&"game", &"probe", {"components": [{"id": "second"}], "wires": []})
	var reloaded = store_script.new(workbench_path)
	var persisted: Dictionary = reloaded.active_snapshot(&"game", &"probe")
	var components: Array = persisted.get("components", [])
	var repeated_workbench_save: bool = first_write and second_write and components.size() == 1 and String((components[0] as Dictionary).get("id", "")) == "second"
	var journey_keys: Array[String] = []
	var unlocked_count: int = 0
	var completed_count: int = 0
	for task: Dictionary in get_node("/root/TaskNavigation").journey_tasks():
		if task.unlocked: unlocked_count += 1
		if task.completed: completed_count += 1
	for task: Dictionary in get_node("/root/TaskNavigation").journey_tasks(): journey_keys.append(str(task.key))
	journey_keys.sort()
	var scheduling_ready: bool = true
	if EXPECTED_BOUND_PROFILE:
		var scheduling: Control = load("res://experiments/layout_strategy/lab.tscn").instantiate()
		add_child(scheduling)
		for frame: int in 8: await get_tree().process_frame
		scheduling_ready = scheduling.product_profile() and scheduling.get("_owns_quit") and scheduling.find_child("Exit", true, false) != null
		scheduling.queue_free()
		for frame: int in 8: await get_tree().process_frame
	var checks: Dictionary = {
		"isolated":OS.get_user_data_dir().ends_with("SUFFIX"),
		"candidate_profile_binding":load("res://experiments/candidate_session/context.gd").configured_journey_for(true, "representation", str(ProjectSettings.get_setting("candidate/profile", "")), OS.get_user_data_dir())==EXPECTED_BOUND_PROFILE,
		"second_act_resources":ResourceLoader.exists("res://experiments/representation_region/region.tscn") and ResourceLoader.exists("res://experiments/service_plan/lab.tscn") and ResourceLoader.exists("res://experiments/prediction/lab.tscn"),
		"creation_export_configuration":bool(ProjectSettings.get_setting("candidate/creation_enabled",false))==EXPECTED_CREATION,
		"creation_resources":not EXPECTED_CREATION or ResourceLoader.exists("res://experiments/creation/workbench.tscn"),
		"candidate_feature":OS.has_feature("free_candidate"),
		"scheduling_product_entry":scheduling_ready,
		"mode_selection":EXPECTED_MODE_CHECK,
		"edition_access":EXPECTED_ACCESS_CHECK,
		"no_precompleted_tasks":completed_count==0,
		"edition_feature":EXPECTED_FEATURE_CHECK,
		"capture_disabled":mode.capture_arguments().is_empty(),
		"developer_helper_inert":EXPECTED_DEVELOPER_CHECK,
		"creation_profile_locked":EXPECTED_CREATION_PATH_CHECK,
		"forty_tasks":get_node("/root/TaskNavigation").tasks().size()==40,
		"candidate_journey_tasks":journey_keys==EXPECTED_KEYS,
		"remote_default_off":not remote.enabled and remote.endpoint=="EXPECTED_ENDPOINT",
		"build_identity":EXPECTED_BUILD_CHECK and ProjectSettings.get_setting("application/config/build_commit")=="EXPECTED_COMMIT",
		"batch_identity":str(ProjectSettings.get_setting("application/test_batch", "unspecified"))=="EXPECTED_BATCH",
		"profile_identity":str(ProjectSettings.get_setting("candidate/profile", ""))=="EXPECTED_PROFILE",
		"system_workspace_identity":get_node("/root/SystemChapter").workspace_version()=="EXPECTED_SYSTEM",
		"locality_workspace_identity":get_node("/root/LocalityChapter").workspace_version()=="EXPECTED_LOCALITY",
		"repeated_workbench_auto_save":repeated_workbench_save,
		"tests_excluded":not ResourceLoader.exists("res://tests/test_layout_simulation.gd"),
		"server_excluded":not FileAccess.file_exists("res://server/feedback_server.py")}
	var passed: bool = true
	for value: bool in checks.values(): passed=passed and value
	print("PACKAGE_CHECKS ",JSON.stringify(checks))
	if passed:
		var file=FileAccess.open("user://package_probe_result.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(checks)); file.close()
	get_tree().quit(0 if passed else 1)
'''.replace('EXPECTED_BOUND_PROFILE',str(bool(edition)).lower()).replace('EXPECTED_DEVELOPER_CHECK','get_node("/root/DevCapture").get("_events").is_empty() and float(get_node("/root/DevCapture").get("_quit_at")) < 0.0' if edition else 'true').replace('EXPECTED_CREATION_PATH_CHECK','load("res://experiments/creation/session.gd").launch_path()=="user://creation-candidate/session.json"' if edition else 'true').replace('EXPECTED_MODE_CHECK',mode_check).replace('EXPECTED_BUILD_CHECK',build_check).replace('EXPECTED_BATCH',release.get('test_batch','unspecified')).replace('EXPECTED_PROFILE',release.get('candidate_journey',{}).get('profile','')).replace('EXPECTED_FEATURE_CHECK','OS.has_feature("'+edition+'_edition")' if edition else 'true').replace('EXPECTED_ACCESS_CHECK',('unlocked_count==60' if edition=='test' else 'unlocked_count>0 and unlocked_count<60') if edition else 'true').replace('SUFFIX',user_suffix).replace('EXPECTED_ENDPOINT',release.get('feedback_endpoint','')).replace('EXPECTED_CREATION',json.dumps(release.get('candidate_journey',{}).get('creation_enabled',False))).replace('EXPECTED_KEYS',expected_keys).replace('EXPECTED_BUILD',manifest['build_id']).replace('EXPECTED_COMMIT',manifest['source_commit']).replace('EXPECTED_SYSTEM',release['workspace_versions']['res://src/system_lab/system_level_catalog.gd']).replace('EXPECTED_LOCALITY',release['workspace_versions']['res://src/locality_chapter/locality_level_catalog.gd']))
scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="'+str(probe)+'" id="1"]\n[node name="PackageProbe" type="Node"]\nscript = ExtResource("1")\n')
settings='[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+user_suffix+'"\n'
override=binary.parent/'override.cfg';override.write_text(settings+'run/main_scene="'+str(scene)+'"\n')
# If overrides fail, deny both reads and writes to the original game's data directory.
player=Path.home()/'Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck'
protected=[player,Path.home()/'Library/Application Support/VonNeumannBottleneckCandidates']
profile=work/'protect-player.sb';profile.write_text('(version 1)\n(allow default)\n'+''.join('(deny file-read* file-write* (subpath '+json.dumps(str(path))+'))\n' for path in protected))
user_args=['--test-mode','--capture-cpu-success','--reset-local-test-state']
if release.get('candidate_journey'):user_args.append('--candidate-journey')
if edition:
    user_args += ['--creation-profile='+str(work/'forbidden-cross-profile.json'),
                  '--dev-shot='+str(work/'forbidden-dev-shot.png')+'@999',
                  '--dev-enter=tree@999','--dev-call=workspace_owners:flush_workspace@999','--dev-quit=999']
result=subprocess.run(['/usr/bin/sandbox-exec','-f',str(profile),str(binary),'--headless','--quit-after','120','--log-file',str(work/'engine.log'),'--',*user_args],cwd=work,capture_output=True,text=True,timeout=60)
output=result.stdout+result.stderr;(work/'probe.log').write_text(output)
override.write_text(settings)
if result.returncode or 'PACKAGE_CHECKS' not in output or 'false' in next((line for line in output.splitlines() if line.startswith('PACKAGE_CHECKS')),'false') or 'SCRIPT ERROR' in output or 'ERROR:' in output:raise RuntimeError('Package probe failed; see '+str(work/'probe.log'))
for name,digest in hashes.items():assert hashlib.sha256((app/name).read_bytes()).hexdigest()==digest
report={'build_id':manifest['build_id'],'source_commit':manifest['source_commit'],'passed':True,'source_app':str(original),'qa_app':str(app),'user_suffix':user_suffix,'binary_and_pack_unchanged':hashes,'qa_override_only':str(override),'public_release':False,'edition':edition or 'legacy-candidate','checks':json.loads(next(line.removeprefix('PACKAGE_CHECKS ') for line in output.splitlines() if line.startswith('PACKAGE_CHECKS ')))}
(work/'result.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS: actual Mac release binary, edition/mode policy and capture boundary, '+str(expected_tasks)+' journey tasks, repeated workbench auto-save, remote off, excluded development files, isolated user directory. '+str(work))
