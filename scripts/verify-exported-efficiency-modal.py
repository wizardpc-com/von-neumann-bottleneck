#!/usr/bin/env python3
"""Run a scoped exported efficiency focus fixture in a clone of its accepted QA profile."""
import argparse
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import time
import uuid
import zipfile

SOURCE='bb5c817bcb7e0c770fc65b41b7407e2847149a74'
BASE_SHA='f5677dc0904b53c2617f74a37015a7ad1a50aacf89edb5e731140353a644ba3d'
FIXTURE_SHA='3c4af91cbe4169adbdebcb638e5bd1fa9940369f5346431be8f8a6cf960e6cbc'
WRAPPER_SHA='b213d90b6381612e5e6d0dd6195a3a96fc066d11fe5ce348c92b2e58b06b16d7'
root=Path(__file__).resolve().parents[1]
assert hashlib.sha256((root/'scripts/verify-night-package.py').read_bytes()).hexdigest()==WRAPPER_SHA
spec=importlib.util.spec_from_file_location('original_night_audits',root/'scripts/verify-night-package.py')
audits=importlib.util.module_from_spec(spec);spec.loader.exec_module(audits)
sha=audits.sha
canonical=audits.canonical
audit_prepared_game=audits.audit_prepared_game
audit_measured_records=audits.audit_measured_records
audit_display_preferences=audits.audit_display_preferences

def inventory(folder):
    result=audits.inventory(folder)
    for path in folder.rglob('*'):
        assert not (path.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT)
        assert path.resolve().is_relative_to(folder.resolve())
    return result

def run_candidate(root,candidate,parent):
    assert candidate.is_relative_to(root/'build') and parent.is_relative_to(root/'.godot/night-package')
    parent=parent.resolve()
    assert parent.parent==root/'.godot/night-package'
    manifest=json.loads((candidate/'manifest.json').read_bytes())
    prior_path=parent/'receipt.json';strict_path=parent/'embedded-profile-reopen-validation.json'
    prior=json.loads(prior_path.read_bytes());strict=json.loads(strict_path.read_bytes())
    role=bool(manifest.get('offline_tester',False))
    expected_parent=root/'.godot/night-package'/('490b9ff9f9eb' if role else 'd196f683c01b')
    expected_receipt='55f57f5fb8fcd3e38b1aaa004a99328ccb31d58dc4e5db052edce426763d7c89' if role else '21d1d6e4de419f56f5ee1b955aaed89b7ae28f5b19b85617adeedb19df8bfc4d'
    assert parent==expected_parent and sha(prior_path)==expected_receipt
    assert candidate.name=='playtest-ModalFocus'+('Access' if role else 'Experience')+'20261018-bb5c817bcb7e'
    profile='OfflineTeammate-CreationLinks20261018' if role else 'CreationLinks20261018'
    assert prior['profile']==manifest['candidate_journey']['profile']==profile and prior['tester']==role
    assert not prior['failures'] and all(prior['checks'].values()) and strict['passed'] is True
    assert prior['creation_restart_and_feedback'].get('passed') is True if role else prior['creation_restart_and_feedback']['status'].startswith('not run')
    for key in ('source_commit','build_id'):
        assert prior[key]==manifest[key]==strict[key]
    for key in ('profile','tester','controller_sha256'):
        assert prior[key]==strict[key]
    assert strict['validator_sha256']==sha(root/'scripts/verify-embedded-profile-reopen.py')
    archive=candidate/manifest['platforms']['Windows']['zip']
    assert sha(archive)==prior['zip_sha256']==strict['zip_sha256']
    assert strict['parent_receipt_sha256']==sha(prior_path)
    raw_reopen=parent/'embedded-profile-reopen.json'
    assert sha(raw_reopen)==strict['reopen_receipt_sha256']
    reopened=json.loads(raw_reopen.read_bytes())
    assert not reopened['failures'] and all(reopened['checks'].values())
    process_path=parent/strict['process_receipt']
    assert process_path.resolve().parent==parent
    prior_process=json.loads(process_path.read_bytes())
    assert prior_process['exit']==0 and not prior_process['terminated_owned_child_reason']
    assert sha(parent/strict['process_receipt'].replace('-process.json','.log'))==prior_process['log_sha256']
    baseline=parent/'embedded-profile-post-exit-baseline.json'
    assert sha(baseline)==strict['post_exit_baseline_sha256']==reopened['post_exit_baseline_sha256']
    baseline_state=json.loads(baseline.read_bytes())['protected']['game_state']
    parent_runtime=parent/'runtime'
    source_user_data=parent_runtime/'VonNeumannBottleneckCandidates/representation'/profile
    post_exit_saves={}
    for name in ('savegame_v1.json','savegame_v1.json.bak'):
        path=source_user_data/name
        payload=json.loads(path.read_bytes());assert isinstance(payload.pop('saved_at_utc'),str)
        allowed=[reopened['protected']['game_state']] if name=='savegame_v1.json' else [reopened['protected']['game_state'],baseline_state]
        assert any(canonical(payload)==canonical(expected_state) for expected_state in allowed), 'Post-strict seed save differs: '+name
        post_exit_saves[name]={'sha256':sha(path),'typed_payload_sha256':hashlib.sha256(canonical(payload).encode()).hexdigest(),
                              'matches_reopened':canonical(payload)==canonical(reopened['protected']['game_state']),
                              'matches_pre_reopen_baseline':canonical(payload)==canonical(baseline_state)}
    records_path=source_user_data/'personal_task_records_v1.json'
    initial_best={}
    if records_path.is_file():
        records=json.loads(records_path.read_bytes())
        assert set(records)=={'schema_version','best'} and type(records['schema_version']) is int and records['schema_version']==1
        assert isinstance(records['best'],dict) and len(records['best'])<=100
        initial_best=records['best']
    probe=root/'scripts/exported-efficiency-modal-probe.gd'
    assert sha(parent/'probe.gd')==prior['controller_sha256']==strict['controller_sha256']
    original_work=prior['extended_experience']['creative_saved_work']
    assert original_work['work']['id'] and original_work['work']['recipe'] and original_work['session_sha256']
    spec=importlib.util.spec_from_file_location('measured_package_feedback',root/'scripts/verify-package-feedback.py')
    helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
    binary=parent/'unpacked/Windows/Von-Neumann-Bottleneck.exe'
    assert sha(binary)==prior['exe_sha256']==strict['exe_sha256']
    assert helper.embedded_pck_sha256(binary)==prior['embedded_pack_sha256']==strict['embedded_pack_sha256']
    expected=json.loads((binary.parent/'BUILD-MANIFEST.json').read_bytes())['files_sha256']
    assert all(sha(binary.parent/name)==digest for name,digest in expected.items())
    assert prior['source_commit']==SOURCE and sha(root/'scripts/night-package-probe.gd')==BASE_SHA
    assert sha(root/'tests/test_efficiency_fragment.gd')==FIXTURE_SHA
    assert not (binary.parent/'override.cfg').exists()
    with zipfile.ZipFile(archive) as package:
        entries=[item for item in package.infolist() if not item.is_dir()]
        zip_windows={'files':{},'directories':[]}
        directories=set()
        for item in package.infolist():
            parts=Path(item.filename).parts
            if parts[0]!='Windows':continue
            relative=Path(*parts[1:])
            if item.is_dir():
                if relative.as_posix()!='.':directories.add(relative.as_posix())
            else:
                with package.open(item) as stream:
                    digest=hashlib.sha256()
                    for block in iter(lambda:stream.read(65536),b''):digest.update(block)
                zip_windows['files'][relative.as_posix()]=digest.hexdigest()
            for parent_dir in relative.parents:
                if parent_dir.as_posix()!='.':directories.add(parent_dir.as_posix())
        zip_windows['directories']=sorted(directories)
        assert inventory(binary.parent)==zip_windows, 'Accepted Windows file/directory set is not the exact ZIP payload'
        for item in entries:
            actual=parent/'unpacked'/item.filename
            assert actual.resolve().is_relative_to((parent/'unpacked').resolve())
            digest=hashlib.sha256()
            with package.open(item) as stream:
                for block in iter(lambda:stream.read(65536),b''):digest.update(block)
            assert sha(actual)==digest.hexdigest(), 'Accepted extracted member changed: '+item.filename
        required=sum(item.file_size for item in entries)+sum(path.stat().st_size for path in parent_runtime.rglob('*') if path.is_file())+128*1024*1024
    free=shutil.disk_usage(root).free
    assert free-required>=384*1024*1024, 'Insufficient projected free space after inputs and evidence reserve'
    parent_before=inventory(parent_runtime)
    work=root/'.godot/exported-efficiency-modal'/uuid.uuid4().hex[:12];work.mkdir(parents=True)
    runtime=work/'runtime';shutil.copytree(parent_runtime,runtime)
    assert inventory(runtime)==parent_before
    temp=work/'temp';temp.mkdir()
    copied=work/'Windows';shutil.copytree(binary.parent,copied)
    binary=copied/binary.name
    assert all(sha(copied/name)==digest for name,digest in expected.items())
    assert inventory(copied)==zip_windows
    assert not (copied/'override.cfg').exists()
    copied_probe=work/'exported-efficiency-modal-probe.gd';shutil.copy2(probe,copied_probe)
    shutil.copy2(root/'scripts/night-package-probe.gd',work/'night-package-probe.gd')
    assert sha(work/'night-package-probe.gd')==BASE_SHA
    scene=work/'probe.tscn';helper.write_probe_scene(scene,copied_probe)
    user_data=runtime/'VonNeumannBottleneckCandidates/representation'/profile
    seed={'parent_work':str(parent),'parent_receipt_sha256':sha(prior_path),'strict_validation_sha256':sha(strict_path),
          'post_exit_seed':parent_before,'source_commit':prior['source_commit'],'build_id':prior['build_id'],
          'profile':profile,'tester':role,'zip_sha256':sha(archive),'exe_sha256':sha(binary),
          'embedded_pack_sha256':helper.embedded_pck_sha256(binary),'controller_sha256':sha(copied_probe),'base_controller_sha256':BASE_SHA,
          'fixture_source_sha256':FIXTURE_SHA,
          'parent_controller_sha256':prior['controller_sha256'],'initial_personal_best':initial_best,'initial_game_state':json.loads((source_user_data/'savegame_v1.json').read_bytes()),
          'initial_optional_text':{name:(source_user_data/name).read_text(encoding='utf-8') for name in ('presentation.cfg','task_navigation.cfg') if (source_user_data/name).is_file()},
          'original_saved_work':original_work,'post_strict_save_audit':post_exit_saves,
          'existing_strict_loaded_state_conversions':strict['loaded_state_conversions']}
    seed['initial_game_state'].pop('saved_at_utc')
    (work/'seed.json').write_text(json.dumps(seed,ensure_ascii=False,indent=2),encoding='utf-8')
    override=copied/'override.cfg'
    override.write_text('[application]\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)
        +'\n[display]\nwindow/size/mode=0\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720'
        +'\n[qa_night]\nphase="measured"\noutput='+json.dumps(work.as_posix(),ensure_ascii=False)+'\n',encoding='utf-8')
    env=dict(os.environ,APPDATA=str(runtime),LOCALAPPDATA=str(runtime),TEMP=str(temp),TMP=str(temp))
    log=work/'measured.log';command=[str(binary),'--log-file',str(work/'engine.log'),'--','--playtest-source=automated']
    reason='';print('Actual exported efficiency focus fixture: '+str(work),flush=True)
    try:
        with log.open('wb') as stream:
            child=subprocess.Popen(command,cwd=copied,env=env,stdout=stream,stderr=subprocess.STDOUT)
            deadline=time.monotonic()+180
            while child.poll() is None:
                text=log.read_text(encoding='utf-8',errors='replace')
                if 'SCRIPT ERROR:' in text or time.monotonic()>deadline or shutil.disk_usage(root).free<256*1024*1024:
                    reason='script_error' if 'SCRIPT ERROR:' in text else 'disk_space' if shutil.disk_usage(root).free<256*1024*1024 else 'timeout'
                    child.terminate();child.wait(timeout=15);break
                time.sleep(.2)
    finally:override.unlink(missing_ok=True)
    after=inventory(runtime)
    process={'pid':child.pid,'command':command,'environment':{key:env[key] for key in ('APPDATA','LOCALAPPDATA','TEMP','TMP')},
             'exit':child.returncode,'terminated_owned_child_reason':reason,'log_sha256':sha(log)}
    (work/'process.json').write_text(json.dumps(process,indent=2),encoding='utf-8')
    changes={name:{'before':parent_before['files'].get(name),'after':after['files'].get(name)}
             for name in parent_before['files'].keys()|after['files'].keys() if parent_before['files'].get(name)!=after['files'].get(name)}
    parent_after=inventory(parent_runtime)
    (work/'post-exit-files.json').write_text(json.dumps({'seed_sha256':sha(work/'seed.json'),'files':after,'changed_files':changes,
        'original_parent_runtime_after':parent_after,'original_parent_runtime_unchanged':parent_after==parent_before,
        'added_directories':sorted(set(after['directories'])-set(parent_before['directories'])),
        'removed_directories':sorted(set(parent_before['directories'])-set(after['directories']))},indent=2),encoding='utf-8')
    assert parent_after==parent_before, 'Supplement changed the original accepted parent runtime'
    assert sha(work/'night-package-probe.gd')==BASE_SHA and sha(copied_probe)==seed['controller_sha256']
    assert sha(prior_path)==seed['parent_receipt_sha256'] and sha(strict_path)==seed['strict_validation_sha256']
    assert all(sha(copied/name)==digest for name,digest in expected.items()) and sha(archive)==seed['zip_sha256']
    assert inventory(copied)==zip_windows
    text=log.read_text(encoding='utf-8',errors='replace')
    assert child.returncode==0 and not reason and 'ERROR:' not in text and 'PASS: Exported efficiency modal evidence' in text
    raw_path=work/'measured-evidence.json';raw=json.loads(raw_path.read_bytes())
    assert not raw['failures'] and all(raw['checks'].values())
    assert raw['check_calls']==len(raw['ordered_checks']) and all(row['passed'] is True for row in raw['ordered_checks'])
    assert [row['locale'] for row in raw['role_snapshots']]==['zh_CN','en']
    for row in raw['role_snapshots']:
        assert canonical(row['before'])==canonical(row['after'])
        assert row['before']['has_setting'] is role and canonical(row['before']['value'])==canonical(True if role else None)
    assert raw['base_controller_sha256']==BASE_SHA and raw['fixture_source_sha256']==FIXTURE_SHA
    assert raw['production_resources']=={'fragment':'res://src/ui/efficiency_fragment.gd','host':'res://src/system_lab/system_lab.gd'}
    assert raw['extended_experience']['measured_targets']['scope'].startswith('No Layout or Overlap')
    for key in ('source_commit','build_id','profile','tester','exe_sha256','controller_sha256'):assert raw[key]==seed[key]
    assert canonical(raw['protected_before']['game_state'])==canonical(reopened['protected']['game_state'])
    assert raw['parent_controller_sha256']==seed['parent_controller_sha256']
    cpu_state=audit_prepared_game(seed,raw,cpu_only=True)
    final_input=copy.deepcopy(raw)
    final_input['prepared_cpu']=raw['prepared_final']
    final_state=audit_prepared_game(seed,final_input,cpu_only=True)
    assert canonical(final_state)==canonical(cpu_state), 'Focus-only review changed prepared game payload or types'
    audit_measured_records(seed,raw);audit_display_preferences(seed,raw)
    permitted_payloads={canonical(value) for value in (seed['initial_game_state'],cpu_state,final_state)}
    for checkpoint in ('prepared_cpu','prepared_final'):
        assert set(raw[checkpoint]['disk'])=={'savegame_v1.json','savegame_v1.json.bak','hardware_workbenches_v1.json','personal_task_records_v1.json','task_navigation.cfg','presentation.cfg'}
        for name in ('savegame_v1.json','savegame_v1.json.bak'):
            payload=json.loads(raw[checkpoint]['disk'][name]['text']);assert isinstance(payload.pop('saved_at_utc'),str)
            assert canonical(payload) in permitted_payloads, 'Captured backup/main is not an explicitly evidenced legitimate state'
    assert canonical(raw['prepared_cpu'])==canonical(raw['extended_experience']['measured_cpu_prepared']), 'Pure CPU exploration changed its prepared authority snapshot'
    assert raw['original_work']['id']==original_work['work']['id'] and raw['original_work_session_sha256']==original_work['session_sha256'] and raw['creation_recovery_lock'] is False
    def protected_path(name):
        path=user_data/name.removeprefix('user://') if name.startswith('user://') else Path(name)
        assert path.resolve().is_relative_to(runtime.resolve())
        return path
    time_changes=[]
    disk=raw['prepared_final']['disk']
    mutable_names={'savegame_v1.json','savegame_v1.json.bak','hardware_workbenches_v1.json','personal_task_records_v1.json','task_navigation.cfg','presentation.cfg'}
    assert set(disk)==mutable_names
    for name,value in raw['protected_before']['protected_files'].items():
        path=protected_path(name);relative=path.relative_to(runtime).as_posix()
        expected_seed=relative in parent_before['directories'] if isinstance(value,bool) else parent_before['files'].get(relative,'absent')
        assert value==expected_seed, 'Loaded protected authority differs from exact seed: '+name
        if path.name not in mutable_names:
            actual=path.is_dir() if isinstance(value,bool) else sha(path) if path.is_file() else 'absent'
            assert actual==value, 'Preparation changed unrelated authority or writer lock: '+name
    for name,record in disk.items():
        path=user_data/name
        assert not record.get('absent',False), 'Expected prepared authority absent: '+name
        assert hashlib.sha256(record['text'].encode()).hexdigest()==record['sha256']
        if name in ('savegame_v1.json','savegame_v1.json.bak'):
            payload=json.loads(path.read_bytes());assert isinstance(payload.pop('saved_at_utc'),str)
            allowed=[]
            for saved_name in ('savegame_v1.json','savegame_v1.json.bak'):
                prior_payload=json.loads(disk[saved_name]['text']);prior_payload.pop('saved_at_utc');allowed.append(prior_payload)
            assert any(canonical(payload)==canonical(value) for value in allowed), 'Unexpected post-exit typed save change: '+name
            time_changes.append({'path':name,'prepared_sha256':record['sha256'],'after_sha256':sha(path),'payload':'exact prepared main or backup except top saved_at_utc; no numeric normalization'})
        else:assert sha(path)==record['sha256'], 'Post-exit changed prepared authority: '+name
    old_store=json.loads((source_user_data/'hardware_workbenches_v1.json').read_bytes())
    new_store=json.loads(disk['hardware_workbenches_v1.json']['text'])
    preserved=copy.deepcopy(new_store)
    old_game=old_store['namespaces']['game'];new_game=preserved['namespaces']['game']
    allowed_hardware={'half_adder','full_adder','alu','latch','register','ram','cpu','load_store'}
    assert set(new_game)==set(old_game)|allowed_hardware
    for key in allowed_hardware:
        if key in old_game:new_game[key]=old_game[key]
        else:new_game.pop(key)
    # The original Store parses old snapshots as JSON numbers and persists the
    # whole manifest with full_precision, including the untouched tutorial.
    old_expected=copy.deepcopy(old_store);store_conversions=[]
    prefix=('namespaces','game','tutorial','workbenches','default')
    boundaries=[(('schema_version',),1),
                (('components',0,'output_port_widths',0),1),
                (('components',1,'input_port_widths',0),1),
                (('components',2,'input_port_widths',0),1),
                (('components',2,'output_port_widths',0),1)]
    boundaries += [(('wires',index,key),0) for index in (0,1) for key in ('color_index','from_port','to_port')]
    for suffix,known_value in boundaries:
        pointer=prefix+suffix;expected_node=old_expected;actual_node=preserved
        for part in pointer[:-1]:expected_node=expected_node[part];actual_node=actual_node[part]
        key=pointer[-1];before=expected_node[key];after_value=actual_node[key]
        assert type(before) in (int,float) and before==known_value
        if type(before) is int:
            predicted=float(before)
            assert int(predicted)==before and type(after_value) is float and canonical(after_value)==canonical(predicted)
            expected_node[key]=predicted
            store_conversions.append({'path':'/'+('/'.join(str(part) for part in pointer)),
                                      'from_type':'int','to_type':'float','from':before,'to':predicted,
                                      'reason':'original CircuitWorkbenchStore JSON load / full_precision whole-manifest save'})
        else:assert canonical(after_value)==canonical(before)
    assert canonical(preserved)==canonical(old_expected), 'Unrelated original hardware workbench changed'
    permitted_files={str((user_data/name).relative_to(runtime).as_posix()) for name in mutable_names}
    frame_dir=(user_data/'efficiency-fragment-captures').relative_to(runtime).as_posix()
    suffix='tester' if role else 'ordinary'
    expected_frames={locale+'-modal-'+phase+'.png' for locale in ('zh_CN','en') for phase in ('positive','negative')}
    expected_frames|={locale+'-exported-'+suffix+'-feedback.png' for locale in ('zh_CN','en')}
    assert {path.name for path in (runtime/frame_dir).iterdir()}==expected_frames
    user_prefix=user_data.relative_to(runtime).as_posix()+'/'
    def auxiliary(name):
        if not name.startswith(user_prefix):return False
        relative=Path(name[len(user_prefix):])
        return (name==frame_dir or (relative.parent.as_posix()=='efficiency-fragment-captures' and relative.name in expected_frames)
                or relative.parts[0] in {'logs','shader_cache','playtest_data','offline_playtest'}
                or relative.as_posix()=='feedback_drafts_v1.json')
    assert all(name in permitted_files or auxiliary(name) for name in changes), 'Unexpected non-feedback profile file change'
    changed_directories=set(after['directories'])^set(parent_before['directories'])
    assert all(auxiliary(name) for name in changed_directories), 'Unexpected non-feedback profile directory or writer lock'
    for frame in raw['extended_experience'].get('measured_frames',[]):
        path=work/frame['file'];assert path.resolve().is_relative_to(work.resolve()) and sha(path)==frame['sha256']
    validation={'passed':True,**{key:seed[key] for key in ('source_commit','build_id','profile','tester','zip_sha256','exe_sha256','embedded_pack_sha256','controller_sha256')},
        'parent_receipt_sha256':seed['parent_receipt_sha256'],'strict_validation_sha256':seed['strict_validation_sha256'],
        'parent_controller_sha256':seed['parent_controller_sha256'],'supplement_controller_sha256':seed['controller_sha256'],
        'seed_sha256':sha(work/'seed.json'),'receipt_sha256':sha(raw_path),'process_sha256':sha(work/'process.json'),
        'post_exit_files_sha256':sha(work/'post-exit-files.json'),'post_exit_save_time_or_backup_rotation':time_changes,
        'original_parent_runtime_unchanged':True,'hardware_store_loaded_codec_conversions':store_conversions,
        'validator_sha256':sha(Path(__file__)),
        'base_controller_sha256':BASE_SHA,'fixture_source_sha256':FIXTURE_SHA,'check_calls':raw['check_calls'],
        'space_preflight':{'free_bytes':free,'input_and_reserve_bytes':required,'projected_remaining_bytes':free-required,'reserve_bytes':128*1024*1024,'floor_bytes':256*1024*1024},
        'images':{str(path.relative_to(work)):{'sha256':sha(path),'bytes':path.stat().st_size} for path in sorted(work.rglob('*.png'))},
        'evidence_grade':'actual exported game-mode efficiency modal and original-role F8 fixture; legal controller preparation, not whole canonical suite or native input'}
    (work/'validation.json').write_text(json.dumps(validation,ensure_ascii=False,indent=2),encoding='utf-8')
    print('PASS: Exported efficiency modal and original-parent protection '+str(work),flush=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate',type=Path,required=True)
    parser.add_argument('--from-parent',type=Path,required=True)
    args=parser.parse_args()
    run_candidate(root,args.candidate.resolve(),args.from_parent.resolve())

if __name__=='__main__':main()
