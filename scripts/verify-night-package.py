#!/usr/bin/env python3
"""Extract a frozen ZIP, verify embedded night configuration and actual first play."""
import argparse
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
    probe=root/'scripts/night-package-probe.gd'
    assert sha(probe)==prior['controller_sha256']==strict['controller_sha256']
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
          'original_saved_work':original_work,'post_strict_save_audit':post_exit_saves,
          'existing_strict_loaded_state_conversions':strict['loaded_state_conversions']}
    (work/'seed.json').write_text(json.dumps(seed,ensure_ascii=False,indent=2),encoding='utf-8')
    override=copied/'override.cfg'
    override.write_text('[application]\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)
        +'\n[display]\nwindow/size/mode=0\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720'
        +'\n[qa_night]\nphase="measured"\noutput='+json.dumps(work.as_posix(),ensure_ascii=False)+'\n',encoding='utf-8')
    env=dict(os.environ,APPDATA=str(runtime),LOCALAPPDATA=str(runtime),TEMP=str(temp),TMP=str(temp))
    log=work/'measured.log';command=[str(binary),'--log-file',str(work/'engine.log'),'--','--playtest-source=automated','--capture-size=1280x720']
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
    assert canonical(raw['protected_before'])==canonical(raw['protected_after'])
    assert canonical(raw['protected_before']['game_state'])==canonical(reopened['protected']['game_state'])
    assert raw['original_work']['id']==original_work['work']['id'] and raw['original_work_session_sha256']==original_work['session_sha256'] and raw['creation_recovery_lock'] is False
    def protected_path(name):
        path=user_data/name.removeprefix('user://') if name.startswith('user://') else Path(name)
        assert path.resolve().is_relative_to(runtime.resolve())
        return path
    time_changes=[]
    for name,value in raw['protected_before']['protected_files'].items():
        path=protected_path(name)
        relative=path.relative_to(runtime).as_posix()
        seed_value=relative in parent_before['directories'] if isinstance(value,bool) else parent_before['files'].get(relative,'absent')
        if name not in ('user://savegame_v1.json','user://savegame_v1.json.bak'):
            assert value==seed_value, 'Loaded protected authority differs from exact seed: '+name
        if name in ('user://savegame_v1.json','user://savegame_v1.json.bak'):
            payload=json.loads(path.read_bytes());assert isinstance(payload.pop('saved_at_utc'),str)
            seed_payloads=[]
            for suffix in ('savegame_v1.json','savegame_v1.json.bak'):
                seed_path=parent_runtime/path.relative_to(runtime).parent/suffix
                if seed_path.is_file():
                    old=json.loads(seed_path.read_bytes());old.pop('saved_at_utc');seed_payloads.append(old)
            assert any(canonical(payload)==canonical(old) for old in seed_payloads), 'Unexpected post-exit typed save change: '+name
            time_changes.append({'path':name,'before_sha256':value,'after_sha256':sha(path),'payload':'exact prior main or backup except top saved_at_utc; no numeric normalization'})
        else:
            actual=path.is_dir() if isinstance(value,bool) else sha(path) if path.is_file() else 'absent'
            assert actual==value, 'Supplement changed protected payload or lock: '+name
    permitted_save_files={str((user_data/name).relative_to(runtime).as_posix()) for name in ('savegame_v1.json','savegame_v1.json.bak')}
    def auxiliary(name):
        return bool(set(Path(name).parts)&{'logs','shader_cache','playtest_data','offline_playtest'}) or Path(name).name=='feedback_drafts_v1.json'
    assert all(name in permitted_save_files or auxiliary(name) for name in changes), 'Unexpected non-feedback profile file change'
    changed_directories=set(after['directories'])^set(parent_before['directories'])
    assert all(auxiliary(name) for name in changed_directories), 'Unexpected non-feedback profile directory or writer lock'
    for frame in raw['extended_experience']['measured_frames']:
        path=work/frame['file'];assert path.resolve().is_relative_to(work.resolve()) and sha(path)==frame['sha256']
    validation={'passed':True,**{key:seed[key] for key in ('source_commit','build_id','profile','tester','zip_sha256','exe_sha256','embedded_pack_sha256','controller_sha256')},
        'parent_receipt_sha256':seed['parent_receipt_sha256'],'strict_validation_sha256':seed['strict_validation_sha256'],
        'seed_sha256':sha(work/'seed.json'),'receipt_sha256':sha(raw_path),'process_sha256':sha(work/'process.json'),
        'post_exit_files_sha256':sha(work/'post-exit-files.json'),'post_exit_save_time_or_backup_rotation':time_changes,
        'original_parent_runtime_unchanged':True,'validator_sha256':sha(Path(__file__)),
        'evidence_grade':'exported supplemental controller in cloned post-exit QA data; reference CPU and failed target plans are not natural earned player history'}
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
