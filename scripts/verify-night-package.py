#!/usr/bin/env python3
"""Extract a frozen ZIP, verify embedded night configuration and actual first play."""
import argparse
import configparser
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import uuid
import zipfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inventory(folder):
    files={};directories=[]
    for path in sorted(folder.rglob('*')):
        assert not path.is_symlink(), 'QA clone must not traverse links: '+str(path)
        name=path.relative_to(folder).as_posix()
        if path.is_dir():directories.append(name)
        elif path.is_file():files[name]=sha(path)
    return {'files':files,'directories':directories}


def canonical(value):
    return json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=False)


def audit_prepared_game(seed,raw,cpu_only=False):
    initial=seed['initial_game_state'];checkpoint=raw['prepared_cpu' if cpu_only else 'prepared_final']
    final=json.loads(checkpoint['disk']['savegame_v1.json']['text'])
    final.pop('saved_at_utc');expected=copy.deepcopy(initial)
    experience=raw['extended_experience'];hardware=experience['measured_hardware_preparation']
    ids=['half_adder','full_adder','alu','latch','register','ram','cpu','load_store']
    assert [step['task'] for step in hardware['steps']]==ids
    for step in hardware['steps']:
        assert step['circuit_signature'] and step['report']['passed'] and step['report']['cases']
        assert all(item['passed'] and item['trace_signature'] for item in step['report']['cases'])
    before=initial['game']['hardware'];after=hardware['manifest']
    assert set(after)==set(before) and after['schema_version']==before['schema_version']
    assert sorted(after['completed_levels'])==sorted(set(before['completed_levels'])|set(ids))
    old={item['component_name']:item for item in before['designs']}
    new={item['component_name']:item for item in after['designs']}
    assert all(canonical(new.get(key))==canonical(value) for key,value in old.items())
    names={'HalfAdder':'half_adder','FullAdder':'full_adder','ALU1':'alu','ALU4':'alu','SRLatch':'latch','Register1':'register','Register4':'register','RAM2x4':'ram','TinyComputer':'cpu'}
    assert set(new)==set(old)|set(names)
    circuits={step['task']:step['circuit_signature'] for step in hardware['steps']}
    for name,level in names.items():
        item=new[name];assert item['source_level']==level and not item['metadata'].get('tester_reference',False)
        if name not in ('ALU4','Register4'):assert item['source_signature']==circuits[level]
        else:assert item['generated_from']==[new['ALU1' if name=='ALU4' else 'Register1']['source_signature']]
    expected['game']['hardware']=after
    system=final['game']['system'];old_system=initial['game']['system'];assert set(system)==set(old_system)
    assert system['prologue_ready'] is True and system['cpu_source_signature']==hardware['cpu_source_signature'] and system['ram_source_signature']==new['RAM2x4']['source_signature']
    cpu_names=sorted(new[name]['source_signature'] for name in ('TinyComputer','ALU4','Register4'))
    assert system['cpu_source_signature']==hashlib.sha256('|'.join(cpu_names).encode()).hexdigest()
    assert sorted(system['completed_levels'])==sorted(set(old_system['completed_levels'])|{'assembly','cpu_speed'})
    for field in ('workspaces','observations'):
        assert set(system[field])==set(old_system[field])|{'assembly','cpu_speed'}
        assert all(canonical(system[field][key])==canonical(value) for key,value in old_system[field].items() if key not in ('assembly','cpu_speed'))
    for level in ('assembly','cpu_speed'):
        workspace=system['workspaces'][level];assert workspace['applied_source']==workspace['draft_source']
        assert canonical(workspace)==canonical(experience['measured_system_workspaces'][level])
        assert set(workspace)=={'part_ids','prediction_id','draft_source','applied_source','connections','positions','version'}
        assert set(workspace['positions'])=={'CPU','BUS','RAM'} and set(workspace['part_ids'])=={'cpu','bus','ram'}
        assert len(workspace['connections'])==6 and workspace['part_ids']
        observations=system['observations'][level];assert observations
        previous=old_system['observations'].get(level,[])
        assert canonical(observations[:len(previous)])==canonical(previous)
        assert all(set(item)=={'source','parts','version','cpu','ram','checkpoint'} for item in observations)
        assert all(item['cpu']==system['cpu_source_signature'] and item['ram']==system['ram_source_signature'] and item['source']==workspace['applied_source'] for item in observations)
    pair=experience['measured_cpu_pair'];first=pair['before'];second=pair['after']
    assert first['source']==second['source']=='game' and first['all_passed'] and second['all_passed']
    assert first['program_signature']==second['program_signature'] and first['test_set_signature']==second['test_set_signature']
    assert first['part_ids']['cpu']!=second['part_ids']['cpu']
    assert {k:v for k,v in first['part_ids'].items() if k!='cpu'}=={k:v for k,v in second['part_ids'].items() if k!='cpu'}
    assert all(item['parts'] in (first['part_ids'],second['part_ids']) for item in system['observations']['cpu_speed'])
    assert all(item['parts']==experience['measured_assembly_preparation']['parts'] for item in system['observations']['assembly'])
    for field in set(system)-{'prologue_ready','cpu_source_signature','ram_source_signature','completed_levels','workspaces','observations'}:
        assert canonical(system[field])==canonical(old_system[field])
    expected['game']['system']=system
    if raw['tester'] and not cpu_only:
        layout=copy.deepcopy(initial['game']['layout']);e=experience['measured_layout_preparation']
        assert e['passed'] and not e['target_met'] and e['run_signature']
        layout['drafts']['fields']=e['draft'];expected['game']['layout']=layout
        overlap=copy.deepcopy(initial['game']['overlap'])
        for level,e in experience['measured_overlap_preparation'].items():
            assert level in ('backpressure','buffers') and e['trace_signature']
            overlap['drafts'][level]={'board':e['board'],'program':e['program']}
        expected['game']['overlap']=overlap
    elif not raw['tester']:assert experience['measured_targets']['status']=='NOT_RUN_NORMAL_LOCKED'
    assert canonical(expected)==canonical(final), 'Unexpected game field/value/type change beyond evidenced legitimate preparation'
    return final


def audit_measured_records(seed,raw):
    assert canonical(raw['initial_best'])==canonical(seed['initial_personal_best']), 'Initial autoload lost or altered original parent records'
    best=copy.deepcopy(seed['initial_personal_best'])
    for row in raw['official_events']:
        event=row['event'];payload=event['payload'];safe=row['safe']
        assert event['mode']=='game' and event['event']=='official_run'
        if not payload.get('passed',False):continue
        if payload['chapter_id']=='hardware_foundations' and 'case_count' in safe:safe=copy.deepcopy(safe);safe['passed_cases']=safe['case_count']
        key=payload['chapter_id']+'/'+payload['level_id'];prior=best.get(key,{})
        assert key in {'hardware_foundations/'+name for name in ('half_adder','full_adder','alu','latch','register','ram','cpu','load_store')}|{'chapter_1/assembly','chapter_1/cpu_speed','chapter_4/fields','chapter_3/backpressure','chapter_3/buffers'}
        if prior.get('case_set_version')!=safe.get('case_set_version','unspecified') or int(safe.get('cycles',0))<int(prior.get('cycles',9223372036854775807)):best[key]=safe
    assert canonical(raw['prepared_final']['best'])==canonical(best)
    recorded=json.loads(raw['prepared_final']['disk']['personal_task_records_v1.json']['text'])
    assert canonical(recorded)==canonical({'schema_version':1,'best':best})


def audit_display_preferences(seed,raw):
    def config(text):
        parser=configparser.ConfigParser(interpolation=None);parser.optionxform=str;parser.read_string(text)
        return {section:dict(parser.items(section)) for section in parser.sections()}
    old=config(seed['initial_optional_text'].get('presentation.cfg',''))
    new=config(raw['prepared_final']['disk']['presentation.cfg']['text'])
    geometry=raw['prepared_final']['window_geometry']
    assert new.get('window')=={'fullscreen':'true' if geometry['fullscreen'] else 'false','size':geometry['size'],'position':geometry['position']}
    assert {k:v for k,v in new.items() if k!='window'}=={k:v for k,v in old.items() if k!='window'}
    navigation=config(raw['prepared_final']['disk']['task_navigation.cfg']['text'])
    expected_navigation=config(seed['initial_optional_text'].get('task_navigation.cfg',''))
    expected_navigation.setdefault('navigation',{})['last_visited_task']=json.dumps(raw['prepared_final']['last_visited_task'],ensure_ascii=False)
    assert navigation==expected_navigation

def measured_evidence(root,candidate,parent):
    parent=parent.resolve()
    assert parent.parent==root/'.godot/night-package'
    manifest=json.loads((candidate/'manifest.json').read_bytes())
    prior_path=parent/'receipt.json';strict_path=parent/'embedded-profile-reopen-validation.json'
    prior=json.loads(prior_path.read_bytes());strict=json.loads(strict_path.read_bytes())
    role=bool(manifest.get('offline_tester',False))
    profile='OfflineTeammate-MeasuredGrowth20261018' if role else 'MeasuredGrowth20261018'
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
    probe=root/'scripts/night-package-probe.gd'
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
    parent_before=inventory(parent_runtime)
    work=root/'.godot/night-package'/('measured-'+uuid.uuid4().hex[:12]);work.mkdir()
    runtime=work/'runtime';shutil.copytree(parent_runtime,runtime)
    assert inventory(runtime)==parent_before
    temp=work/'temp';temp.mkdir()
    copied=work/'Windows';shutil.copytree(binary.parent,copied)
    binary=copied/binary.name
    assert all(sha(copied/name)==digest for name,digest in expected.items())
    assert not (copied/'override.cfg').exists()
    copied_probe=work/'probe.gd';shutil.copy2(probe,copied_probe)
    scene=work/'probe.tscn';helper.write_probe_scene(scene,copied_probe)
    user_data=runtime/'VonNeumannBottleneckCandidates/representation'/profile
    seed={'parent_work':str(parent),'parent_receipt_sha256':sha(prior_path),'strict_validation_sha256':sha(strict_path),
          'post_exit_seed':parent_before,'source_commit':prior['source_commit'],'build_id':prior['build_id'],
          'profile':profile,'tester':role,'zip_sha256':sha(archive),'exe_sha256':sha(binary),
          'embedded_pack_sha256':helper.embedded_pck_sha256(binary),'controller_sha256':sha(copied_probe),
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
    reason='';print('Measured actual exported supplement: '+str(work),flush=True)
    try:
        with log.open('wb') as stream:
            child=subprocess.Popen(command,cwd=copied,env=env,stdout=stream,stderr=subprocess.STDOUT)
            deadline=time.monotonic()+180
            while child.poll() is None:
                text=log.read_text(encoding='utf-8',errors='replace')
                if 'SCRIPT ERROR:' in text or time.monotonic()>deadline:
                    reason='script_error' if 'SCRIPT ERROR:' in text else 'timeout'
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
    assert sha(prior_path)==seed['parent_receipt_sha256'] and sha(strict_path)==seed['strict_validation_sha256']
    assert all(sha(copied/name)==digest for name,digest in expected.items()) and sha(archive)==seed['zip_sha256']
    text=log.read_text(encoding='utf-8',errors='replace')
    assert child.returncode==0 and not reason and 'ERROR:' not in text and 'PASS: Measured exported supplemental evidence' in text
    raw_path=work/'measured-evidence.json';raw=json.loads(raw_path.read_bytes())
    assert not raw['failures'] and all(raw['checks'].values())
    for key in ('source_commit','build_id','profile','tester','exe_sha256','controller_sha256'):assert raw[key]==seed[key]
    assert canonical(raw['protected_before']['game_state'])==canonical(reopened['protected']['game_state'])
    assert raw['parent_controller_sha256']==seed['parent_controller_sha256']
    cpu_state=audit_prepared_game(seed,raw,cpu_only=True)
    final_state=audit_prepared_game(seed,raw)
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
    assert canonical(preserved)==canonical(old_store), 'Unrelated original hardware workbench changed'
    permitted_files={str((user_data/name).relative_to(runtime).as_posix()) for name in mutable_names}
    def auxiliary(name):
        return bool(set(Path(name).parts)&{'logs','shader_cache','playtest_data','offline_playtest'}) or Path(name).name=='feedback_drafts_v1.json'
    assert all(name in permitted_files or auxiliary(name) for name in changes), 'Unexpected non-feedback profile file change'
    changed_directories=set(after['directories'])^set(parent_before['directories'])
    assert all(auxiliary(name) for name in changed_directories), 'Unexpected non-feedback profile directory or writer lock'
    for frame in raw['extended_experience']['measured_frames']:
        path=work/frame['file'];assert path.resolve().is_relative_to(work.resolve()) and sha(path)==frame['sha256']
    validation={'passed':True,**{key:seed[key] for key in ('source_commit','build_id','profile','tester','zip_sha256','exe_sha256','embedded_pack_sha256','controller_sha256')},
        'parent_receipt_sha256':seed['parent_receipt_sha256'],'strict_validation_sha256':seed['strict_validation_sha256'],
        'parent_controller_sha256':seed['parent_controller_sha256'],'supplement_controller_sha256':seed['controller_sha256'],
        'seed_sha256':sha(work/'seed.json'),'receipt_sha256':sha(raw_path),'process_sha256':sha(work/'process.json'),
        'post_exit_files_sha256':sha(work/'post-exit-files.json'),'post_exit_save_time_or_backup_rotation':time_changes,
        'original_parent_runtime_unchanged':True,'validator_sha256':sha(Path(__file__)),
        'evidence_grade':'exported game-mode supplemental controller in cloned QA data; legitimate reference-wired hardware preparation, separate pure-view protection; normal target Hosts NOT_RUN while locked'}
    (work/'validation.json').write_text(json.dumps(validation,ensure_ascii=False,indent=2),encoding='utf-8')
    print('PASS: Measured exported supplement and original-parent protection '+str(work),flush=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate',type=Path,required=True)
    parser.add_argument('--measured-evidence-from',type=Path,help='Supplement a successful strict-reopened parent in a separate exact runtime clone')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    candidate=args.candidate.resolve()
    subprocess.run([sys.executable,str(root/'scripts/check-candidate-identity.py'),str(candidate)],check=True)
    if args.measured_evidence_from is not None:
        measured_evidence(root,candidate,args.measured_evidence_from)
        return
    manifest=json.loads((candidate/'manifest.json').read_text(encoding='utf-8'))
    entry=manifest['platforms']['Windows']
    archive=candidate/entry['zip']
    work=root/'.godot/night-package'/uuid.uuid4().hex[:12]
    unpacked=work/'unpacked';unpacked.mkdir(parents=True)
    with zipfile.ZipFile(archive) as package:
        for item in package.infolist():
            if not (unpacked/item.filename).resolve().is_relative_to(unpacked.resolve()):
                raise ValueError('Unsafe archive path')
        package.extractall(unpacked)
    shutil.copy2(candidate/'manifest.json',unpacked/'manifest.json')
    binary=unpacked/'Windows/Von-Neumann-Bottleneck.exe'
    expected=json.loads((binary.parent/'BUILD-MANIFEST.json').read_text(encoding='utf-8'))['files_sha256']
    for name,digest in expected.items():
        if hashlib.sha256((binary.parent/name).read_bytes()).hexdigest()!=digest:
            raise ValueError('Extracted file differs: '+name)
    spec=importlib.util.spec_from_file_location('package_feedback',root/'scripts/verify-package-feedback.py')
    helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
    probe=work/'probe.gd';shutil.copy2(root/'scripts/night-package-probe.gd',probe)
    scene=work/'probe.tscn';helper.write_probe_scene(scene,probe)
    override=binary.parent/'override.cfg'
    override.write_text('[application]\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)
                        +'\n[display]\nwindow/size/mode=0\nwindow/size/window_width_override=1280'
                        +'\nwindow/size/window_height_override=720\n[qa_night]\noutput='
                        +json.dumps(work.as_posix(),ensure_ascii=False)+'\n',encoding='utf-8')
    runtime=work/'runtime';runtime.mkdir()
    env=dict(os.environ,APPDATA=str(runtime),LOCALAPPDATA=str(runtime))
    print('Actual extracted-package evidence: '+str(work),flush=True)
    try:
        with (work/'embedded.log').open('wb') as log:
            result=subprocess.run([str(binary),'--log-file',str(work/'engine.log'),'--',
                                   '--playtest-source=automated'],cwd=binary.parent,env=env,
                                  stdout=log,stderr=subprocess.STDOUT,timeout=180)
    finally:
        override.unlink(missing_ok=True)
    text=(work/'embedded.log').read_text(encoding='utf-8',errors='replace')
    if result.returncode or 'ERROR:' in text or 'PASS: night package' not in text:
        raise RuntimeError('Embedded night acceptance failed: '+str(work))
    receipt=json.loads((work/'embedded.json').read_text(encoding='utf-8'))
    assert receipt['source_commit']==manifest['source_commit'] and receipt['build_id']==manifest['build_id']
    assert receipt['profile']==manifest['candidate_journey']['profile']
    assert receipt['tester']==manifest.get('offline_tester',False)
    receipt.update(zip_sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                   exe_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
                   embedded_pack_sha256=helper.embedded_pck_sha256(binary))
    for name,digest in expected.items():
        assert hashlib.sha256((binary.parent/name).read_bytes()).hexdigest()==digest
    if manifest.get('offline_tester',False):
        existing=set((root/'.godot/offline-package').glob('*/receipt.json'))
        subprocess.run([sys.executable,str(root/'scripts/verify-offline-playtest.py'),'--exe',str(binary)],check=True,env=env)
        created=set((root/'.godot/offline-package').glob('*/receipt.json'))-existing
        if len(created)!=1:raise RuntimeError('Expected exactly one successful dependent offline receipt')
        child_path=created.pop()
        child=json.loads(child_path.read_text(encoding='utf-8'))
        assert child['source_commit']==manifest['source_commit'] and child['build_id']==manifest['build_id']
        receipt['creation_restart_and_feedback']={'passed':True,'receipt':str(child_path.relative_to(root)),
                                                  'final_export_alone':child['final_export_alone']}
    else:
        receipt['creation_restart_and_feedback']={'status':'not run on normal package; checked separately on tester package'}
    receipt['validator_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    receipt['controller_sha256']=hashlib.sha256(probe.read_bytes()).hexdigest()
    (work/'receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf-8')
    print('PASS: actual ZIP extraction, embedded configuration and first experience '+str(work),flush=True)


if __name__=='__main__':main()
