"""Supplement a successful actual-package receipt in the same isolated embedded namespace."""
import argparse,hashlib,importlib.util,json,os,subprocess,time,uuid
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--work',type=Path,required=True);p.add_argument('--candidate',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];work=a.work.resolve();candidate=a.candidate.resolve()
assert work.parent==root/'.godot/night-package'
prior_path=work/'receipt.json';prior_bytes=prior_path.read_bytes();prior=json.loads(prior_bytes)
manifest=json.loads((candidate/'manifest.json').read_bytes());role=bool(manifest.get('offline_tester',False))
assert prior['source_commit']==manifest['source_commit'] and prior['build_id']==manifest['build_id']
assert prior['profile']==manifest['candidate_journey']['profile']
assert prior['profile'] in (('OfflineTeammate-FullJourney20261018','OfflineTeammate-Creative20261018') if role else ('FullJourney20261018','Creative20261018'))
assert prior['tester']==role and not prior['failures'] and all(prior['checks'].values())
assert prior['creation_restart_and_feedback'].get('passed') is True if role else prior['creation_restart_and_feedback']['status'].startswith('not run')
binary=work/'unpacked/Windows/Von-Neumann-Bottleneck.exe';probe=work/'probe.gd';scene=work/'probe.tscn';runtime=work/'runtime'
assert runtime.is_dir() and binary.is_file()
hash_file=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
assert hash_file(binary)==prior['exe_sha256'] and hash_file(probe)==prior['controller_sha256']
spec=importlib.util.spec_from_file_location('package_feedback',root/'scripts/verify-package-feedback.py');helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
assert helper.embedded_pck_sha256(binary)==prior['embedded_pack_sha256']
assert hash_file(candidate/manifest['platforms']['Windows']['zip'])==prior['zip_sha256']
expected=json.loads((binary.parent/'BUILD-MANIFEST.json').read_bytes())['files_sha256']
assert all(hash_file(binary.parent/name)==digest for name,digest in expected.items())
override=binary.parent/'override.cfg';assert not override.exists()
raw_receipt=work/'embedded-profile-reopen.json';validation=work/'embedded-profile-reopen-validation.json'
baseline_path=work/'embedded-profile-post-exit-baseline.json'
assert not raw_receipt.exists() and not validation.exists() and not baseline_path.exists()
user_data=runtime/'VonNeumannBottleneckCandidates/representation'/prior['profile']
protected=prior['restart_protected'];disk={}
for name,expected_value in protected['protected_files'].items():
 path=(user_data/name.removeprefix('user://')) if name.startswith('user://') else Path(name)
 assert path.resolve().is_relative_to(runtime.resolve())
 actual=path.is_dir() if isinstance(expected_value,bool) else (hash_file(path) if path.is_file() else 'absent')
 if name in ('user://savegame_v1.json','user://savegame_v1.json.bak'):
  assert path.is_file()
  payload=json.loads(path.read_bytes());assert isinstance(payload.get('saved_at_utc'),str)
  payload.pop('saved_at_utc')
  assert json.dumps(payload,sort_keys=True,separators=(',',':'),ensure_ascii=False)==json.dumps(protected['game_state'],sort_keys=True,separators=(',',':'),ensure_ascii=False), 'Post-exit game payload differs: '+name
 else:assert actual==expected_value, 'Post-exit protected authority differs: '+name
 disk[name]=actual
baseline={'parent_receipt_sha256':hashlib.sha256(prior_bytes).hexdigest(),
          'source_commit':prior['source_commit'],'build_id':prior['build_id'],
          'profile':prior['profile'],'tester':role,'controller_sha256':prior['controller_sha256'],
          'protected':{'game_state':protected['game_state'],'protected_files':disk}}
baseline_path.write_text(json.dumps(baseline,ensure_ascii=False,indent=2),encoding='utf-8')
baseline_bytes=baseline_path.read_bytes()
override.write_text('[application]\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)+'\n[display]\nwindow/size/mode=0\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n[qa_night]\nphase="reopen"\noutput='+json.dumps(work.as_posix(),ensure_ascii=False)+'\n',encoding='utf-8')
attempt=uuid.uuid4().hex[:8]
engine_log=work/('embedded-profile-reopen-'+attempt+'-engine.log')
command=[str(binary),'--log-file',str(engine_log),'--','--playtest-source=automated']
log=work/('embedded-profile-reopen-'+attempt+'.log');assert not log.exists() and not engine_log.exists();reason='';print('Embedded namespace restart: '+str(work),flush=True)
try:
 with log.open('wb') as stream:
  child=subprocess.Popen(command,cwd=binary.parent,env=dict(os.environ,APPDATA=str(runtime),LOCALAPPDATA=str(runtime)),stdout=stream,stderr=subprocess.STDOUT)
  print('Owned restart PID '+str(child.pid),flush=True);deadline=time.monotonic()+180
  while child.poll() is None:
   text=log.read_text(encoding='utf-8',errors='replace')
   if 'SCRIPT ERROR:' in text or time.monotonic()>deadline:
    reason='script_error' if 'SCRIPT ERROR:' in text else 'timeout';child.terminate();child.wait(timeout=15);break
   time.sleep(.2)
finally:override.unlink(missing_ok=True)
text=log.read_text(encoding='utf-8',errors='replace')
(work/('embedded-profile-reopen-'+attempt+'-process.json')).write_text(json.dumps({'pid':child.pid,'command':command,'APPDATA':str(runtime),'exit':child.returncode,'terminated_owned_child_reason':reason,'log_sha256':hash_file(log)},indent=2),encoding='utf-8')
assert child.returncode==0 and not reason and 'ERROR:' not in text and 'PASS: embedded profile independent restart' in text
receipt=json.loads(raw_receipt.read_bytes());assert not receipt['failures'] and all(receipt['checks'].values())
assert receipt['parent_receipt_sha256']==hashlib.sha256(prior_bytes).hexdigest() and prior_path.read_bytes()==prior_bytes
for key in ('profile','tester','source_commit','build_id','exe_sha256','controller_sha256'):assert receipt[key]==prior[key]
expected_loaded_protected=json.loads(json.dumps(baseline['protected']))
loaded_state_conversions=[]
if role:
 # ChapterWorkspace reload encodes integral Vector2 coordinates as integers.
 positions=expected_loaded_protected['game_state']['game']['system']['workspaces']['cpu_speed']['positions']
 for device in ('CPU','BUS','RAM'):
  for index in (0,1):
   value=positions[device][index]
   if type(value) is float and value.is_integer():
    positions[device][index]=int(value)
    loaded_state_conversions.append({'path':'/game_state/game/system/workspaces/cpu_speed/positions/'+device+'/'+str(index),'from':value,'to':int(value)})
assert json.dumps(receipt['protected'],sort_keys=True,separators=(',',':'),ensure_ascii=False)==json.dumps(expected_loaded_protected,sort_keys=True,separators=(',',':'),ensure_ascii=False)
assert baseline_path.read_bytes()==baseline_bytes and receipt['post_exit_baseline_sha256']==hashlib.sha256(baseline_bytes).hexdigest()
assert all(hash_file(binary.parent/name)==digest for name,digest in expected.items())
assert helper.embedded_pck_sha256(binary)==prior['embedded_pack_sha256']
validation.write_text(json.dumps({'passed':True,'evidence_grade':'actual embedded namespace across independent exported processes; rendered controller, not native OS input','source_commit':manifest['source_commit'],'build_id':manifest['build_id'],'profile':prior['profile'],'tester':role,'zip_sha256':prior['zip_sha256'],'exe_sha256':prior['exe_sha256'],'embedded_pack_sha256':prior['embedded_pack_sha256'],'controller_sha256':prior['controller_sha256'],'parent_receipt_sha256':hashlib.sha256(prior_bytes).hexdigest(),'post_exit_baseline_sha256':hashlib.sha256(baseline_bytes).hexdigest(),'loaded_state_conversions':loaded_state_conversions,'loaded_state_comparison':'canonical JSON exact after only the recorded tester CPU workspace coordinate conversions; all protected file hashes exact','reopen_receipt_sha256':hash_file(raw_receipt),'process_receipt':'embedded-profile-reopen-'+attempt+'-process.json','validator_sha256':hash_file(Path(__file__))},indent=2),encoding='utf-8')
print('PASS: same embedded namespace saved tutorial and workbench reopened '+str(validation),flush=True)
