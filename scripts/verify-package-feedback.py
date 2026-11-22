#!/usr/bin/env python3
"""Synthetic local acceptance through an unchanged exported binary and pack.

Creates private isolated QA data, performs offline/restart/HTTP/SQLite/report/
triage/delete/restore checks. A localhost result never establishes remote release.
"""
import argparse
from contextlib import closing
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import socket
import sqlite3
import subprocess
import sys
import time
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener
from urllib.error import HTTPError
import uuid


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def loopback_port(endpoint):
    match = re.fullmatch(r'http://127\.0\.0\.1:([1-9][0-9]{0,4})(?:/v1)?', endpoint or '')
    if not match or int(match[1]) > 65535:
        raise ValueError('Expected a numeric IPv4 localhost HTTP endpoint')
    return int(match[1])


def acceptance_endpoint(manifest, platform, pilot):
    if pilot:
        if (platform != 'Windows' or sys.platform != 'win32' or manifest.get('player_feedback_pilot') is not True
                or manifest.get('edition') != 'test' or manifest.get('mode_locked') is not True
                or manifest.get('save_profile') != 'EditionTestPilot' or manifest.get('local_acceptance_only')):
            raise ValueError('--pilot-localhost requires a frozen locked Test Pilot EXE on Windows')
        with socket.socket() as fixture:
            fixture.bind(('127.0.0.1', 0))
            return f'http://127.0.0.1:{fixture.getsockname()[1]}'
    if not manifest.get('local_acceptance_only') or manifest.get('player_feedback_pilot'):
        raise ValueError('requires the explicitly labelled localhost acceptance build or --pilot-localhost')
    endpoint = manifest.get('feedback_endpoint', '')
    loopback_port(endpoint)
    return endpoint


def verify_opinion(payload, manifest, pilot_profile=None):
    build_version=manifest['display_version'] if pilot_profile else manifest['build_id']
    expected={'level_id':'G2_intent','build_version':build_version,'source_commit':manifest['source_commit'],
              'test_batch':manifest['test_batch'],'source':'automated','mode':'test' if pilot_profile else 'game',
              'sharing_mode':'opinion','note':'SYNTHETIC package acceptance: unfinished G2 controls'}
    if pilot_profile:
        expected['source_batch']=pilot_profile
    if any(payload.get(key)!=value for key,value in expected.items()):
        raise ValueError('Local receipt did not match the synthetic opinion and frozen build identity')
    if {'program_source','examples','output','intent','work'} & payload.keys():
        raise ValueError('Local receipt contained protected work content')
    return build_version


def embedded_pck_sha256(binary):
    size=binary.stat().st_size
    with binary.open('rb') as file:
        if size<20: raise ValueError('missing embedded PCK')
        file.seek(-12,2)
        footer=file.read(12)
        length=int.from_bytes(footer[:8],'little')
        start=size-12-length
        if footer[8:]!=b'GDPC' or length<4 or start<0: raise ValueError('missing embedded PCK')
        file.seek(start)
        if file.read(4)!=b'GDPC': raise ValueError('invalid embedded PCK')
        file.seek(start)
        digest=hashlib.sha256()
        remaining=length
        while remaining:
            block=file.read(min(65536,remaining))
            if not block: raise ValueError('truncated embedded PCK')
            digest.update(block)
            remaining-=len(block)
        return digest.hexdigest()


def prepare_package(original, platform, work):
    if platform=='macOS':
        if not original.is_dir() or original.suffix!='.app': raise ValueError('expected an exported .app')
        package=work/original.name
        shutil.copytree(original,package,symlinks=True)
        info=plistlib.loads((package/'Contents/Info.plist').read_bytes())
        binary=package/'Contents/MacOS'/info['CFBundleExecutable']
        pack=package/'Contents/Resources'/(info['CFBundleExecutable']+'.pck')
        if not pack.is_file(): raise ValueError('missing exported Mac PCK')
    else:
        if not original.is_file() or original.suffix.lower()!='.exe': raise ValueError('expected an exported .exe')
        package=work/original.parent.name
        shutil.copytree(original.parent,package)
        binary=package/original.name
        pack=binary.with_suffix('.pck')
    manifest=json.loads((original.parent.parent/'manifest.json').read_text(encoding='utf-8'))
    platform_manifest=json.loads((original.parent/'BUILD-MANIFEST.json').read_text(encoding='utf-8'))
    if (binary.parent/'override.cfg').exists(): raise ValueError('source package already has a settings override')
    if (platform_manifest['platform']!=platform or platform_manifest['build_id']!=manifest['build_id']
            or platform_manifest['source_commit']!=manifest['source_commit'] or platform_manifest['engine']!=manifest['engine']
            or platform not in manifest['platforms']):
        raise ValueError('package manifest identity mismatch')
    if manifest.get('player_feedback_pilot') and any(
            platform_manifest.get(key)!=manifest[key] for key in ('player_feedback_pilot','edition','mode_locked',
                'save_profile','display_version','test_batch','feedback_endpoint','privacy_url','feedback_default_source',
                'feedback_source_batch')):
        raise ValueError('pilot platform manifest does not match the frozen build')
    source_folder=original if platform=='macOS' else original.parent
    hashes={}
    embedded_pack=None
    if platform=='Windows' and not pack.exists(): embedded_pack=embedded_pck_sha256(binary)
    for path in (binary,pack) if pack.exists() else (binary,):
        name=path.relative_to(package).as_posix()
        manifest_name=original.name+'/'+name if platform=='macOS' else name
        source=source_folder/name
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        if digest!=platform_manifest['files_sha256'].get(manifest_name) or digest!=hashlib.sha256(source.read_bytes()).hexdigest():
            raise ValueError('exported binary/pack hash mismatch: '+name)
        hashes[name]=digest
    return manifest,package,binary,hashes,embedded_pack


def write_probe_scene(scene,probe):
    scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path='
                     +json.dumps(probe.as_posix(),ensure_ascii=False)+' id="1"]\n'
                     '[node name="PackageFeedbackProbe" type="Node"]\nscript=ExtResource("1")\n',encoding='utf-8')


def write_override(override,user_dir,scene,qa_profile,phase,work,*,endpoint=None,pilot=False,expected_user_dir=None):
    config = ('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='
              +json.dumps(user_dir)+'\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)+'\n')
    if endpoint is not None:
        loopback_port(endpoint)
    if pilot:
        if endpoint is None or expected_user_dir is None:
            raise ValueError('Pilot override requires a loopback endpoint and isolated Windows user directory')
        config += ('feedback_endpoint='+json.dumps(endpoint)+'\nfeedback_privacy_url=""\n'
                   'feedback_source_batch='+json.dumps(qa_profile)+'\n')
    config += ('\n[candidate]\nprofile='+json.dumps(qa_profile)+'\n[qa_feedback]\nphase='
               +json.dumps(phase)+'\noutput='+json.dumps(work.as_posix(),ensure_ascii=False)+'\n')
    if endpoint is not None:
        config += 'expected_endpoint='+json.dumps(endpoint)+'\nlocked_test='+str(pilot).lower()+'\n'
    if expected_user_dir is not None:
        config += 'expected_user_dir='+json.dumps(expected_user_dir.as_posix(),ensure_ascii=False)+'\n'
    override.write_text(config,encoding='utf-8')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    package_arg=parser.add_mutually_exclusive_group(required=True)
    package_arg.add_argument('--app',type=Path)
    package_arg.add_argument('--exe',type=Path)
    parser.add_argument('--pilot-localhost',action='store_true',
                        help='Exercise a frozen Windows Test Pilot with synthetic feedback to a localhost fixture only')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    original=(args.app or args.exe).resolve()
    platform='macOS' if args.app else 'Windows'
    manifest=json.loads((original.parent.parent/'manifest.json').read_text(encoding='utf-8'))
    try:
        endpoint=acceptance_endpoint(manifest,platform,args.pilot_localhost)
    except ValueError as error:
        parser.error(str(error))
    port=loopback_port(endpoint)
    api_root=endpoint.removesuffix('/v1')+'/v1'
    local_http=build_opener(ProxyHandler({}),NoRedirect())
    stamp=uuid.uuid4().hex[:12]
    work=root/'.godot/package-feedback'/stamp
    work.mkdir(parents=True,mode=0o700)
    manifest,package,binary,hashes,embedded_pack=prepare_package(original,platform,work)
    probe=work/'probe.gd'; shutil.copy2(root/'scripts/package-feedback-probe.gd',probe)
    scene=work/'probe.tscn'
    write_probe_scene(scene,probe)
    override=binary.parent/'override.cfg'
    qa_profile='PackageFeedback-'+stamp
    user_dir='VonNeumannBottleneckCandidates/representation/'+qa_profile
    environment=os.environ.copy()
    expected_user_dir=None
    if platform=='macOS':
        protect=work/'protect-player.sb'
        player=Path.home()/'Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck'
        protect.write_text('(version 1)\n(allow default)\n(deny file-read* file-write* (subpath '+json.dumps(str(player))+'))\n',encoding='utf-8')
        launcher=['/usr/bin/sandbox-exec','-f',str(protect),str(binary)]
    else:
        runtime=work/'runtime'
        for directory in (runtime/'Roaming',runtime/'Local',runtime/'Profile'): directory.mkdir(parents=True)
        environment.update(APPDATA=str(runtime/'Roaming'),LOCALAPPDATA=str(runtime/'Local'),USERPROFILE=str(runtime/'Profile'))
        expected_user_dir=runtime/'Roaming'/user_dir
        launcher=[str(binary)]
    def phase(name):
        engine_log=work/(name+'-engine.log')
        write_override(override,user_dir,scene,qa_profile,name,work,endpoint=endpoint,
                       pilot=args.pilot_localhost,expected_user_dir=expected_user_dir)
        try:
            result=subprocess.run([*launcher,'--headless','--log-file',str(engine_log),'--',
                                   '--enable-playtest-telemetry','--enable-playtest-feedback','--playtest-source=automated'],
                                  cwd=binary.parent if platform=='Windows' else work,capture_output=True,
                                  text=True,encoding='utf-8',errors='replace',env=environment,timeout=60)
        finally:
            override.unlink(missing_ok=True)
        text=result.stdout+result.stderr; (work/(name+'.log')).write_text(text,encoding='utf-8')
        if engine_log.is_file():
            text+='\n'+engine_log.read_text(encoding='utf-8',errors='replace')
        if result.returncode or 'SCRIPT ERROR' in text or 'ERROR:' in text or 'PASS: actual package feedback '+name not in text:
            raise RuntimeError(name+' failed; inspect logs in '+str(work))
        report=json.loads((work/(name+'.json')).read_text(encoding='utf-8'))
        assert report['passed']
        if expected_user_dir is not None and Path(report['user_data_dir']).resolve() != expected_user_dir.resolve():
            raise RuntimeError('exported Windows package did not use isolated QA userdata')
        print(name+': PASS',flush=True)
        return report
    # Never stop an existing service to manufacture an offline test.
    with socket.socket() as check:
        if check.connect_ex(('127.0.0.1',port))==0:raise ValueError('acceptance port already in use')
    offline=phase('offline')
    if platform=='Windows' and not Path(offline['work_path']).resolve().is_relative_to((work/'runtime').resolve()):
        raise RuntimeError('exported Windows package wrote outside isolated QA userdata')
    database=work/'feedback.sqlite'
    server_log=(work/'receiver.log').open('w')
    receiver=subprocess.Popen([sys.executable,str(root/'server/feedback_server.py'),'--host','127.0.0.1','--port',str(port),'--database',str(database)],stdout=server_log,stderr=subprocess.STDOUT)
    try:
        for attempt in range(100):
            if receiver.poll() is not None:raise RuntimeError('localhost fixture exited during startup')
            try:
                with local_http.open(api_root+'/health',timeout=1) as response:
                    if response.status==200:break
            except OSError:time.sleep(.1)
        else:raise RuntimeError('receiver startup failed')
        online=phase('online')
        event_id=offline['feedback_id']
        with closing(sqlite3.connect(database)) as db:
            rows=db.execute('SELECT body FROM events WHERE id=?',(event_id,)).fetchall()
        assert len(rows)==1
        received=json.loads(rows[0][0])
        build_version=verify_opinion(received['payload'],manifest,qa_profile if args.pilot_localhost else None)
        # A network repeat of the original authorized bytes must acknowledge one row.
        body=json.dumps({'client_id':offline['client_id'],'deletion_token':offline['deletion_token'],'records':[offline['record']]}).encode()
        with local_http.open(Request(api_root+'/events',body,{'Content-Type':'application/json'}),timeout=5) as response:
            assert event_id in json.load(response)['ack']
        with closing(sqlite3.connect(database)) as db:assert db.execute('SELECT COUNT(*) FROM events WHERE id=?',(event_id,)).fetchone()[0]==1
        triage=work/'private-triage.sqlite'; private=work/'private-report'
        command=[sys.executable,str(root/'server/private_report.py'),'--database',str(database),'--triage',str(triage)]
        subprocess.run(command+['--set-status',event_id,'needs_retest','--fix-build',manifest['build_id'],'--review-note','Synthetic loop receipt; no player data.'],check=True,capture_output=True)
        subprocess.run(command+['--output',str(private)],check=True,capture_output=True)
        report=json.loads((private/'report.json').read_text(encoding='utf-8'))
        row=next(row for row in report['received_feedback'] if row['event_id']==event_id)
        assert row['task']=='creation/G2_intent' and row['build_version']==build_version and row['triage']['status']=='needs_retest'
        sys.path.insert(0,str(root/'server')); import storage
        old=work/'before-delete.sqlite'; storage.backup(database,old)
        phase('delete')
        subprocess.run(command+['--purge-triage','--output',str(private)],check=True,capture_output=True)
        assert not json.loads((private/'report.json').read_text(encoding='utf-8'))['received_feedback']
        restored=work/'restored.sqlite'; storage.backup(old,restored); storage.merge(restored,database)
        with closing(sqlite3.connect(restored)) as db:
            assert db.execute('SELECT COUNT(*) FROM events WHERE id=?',(event_id,)).fetchone()[0]==0
            assert db.execute('SELECT COUNT(*) FROM tombstones').fetchone()[0]==1
        try:local_http.open(Request(api_root+'/events',body,{'Content-Type':'application/json'}),timeout=5)
        except HTTPError as error:
            with error: assert error.code==410
        else:raise AssertionError('deleted identity was accepted')
        for name,digest in hashes.items():assert hashlib.sha256((package/name).read_bytes()).hexdigest()==digest
        if embedded_pack is not None: assert embedded_pck_sha256(binary)==embedded_pack
        receipt={'passed':True,'scope':'local exported-package HTTP acceptance; VPS/HTTPS external NOT_RUN',
                 'build_id':manifest['build_id'],'source_commit':manifest['source_commit'],'test_batch':manifest['test_batch'],
                 'feedback_id':event_id,'task':row['task'],'triage_status':row['triage']['status'],
                 'duplicate_rows':1,'deleted_after_restore':True,'binary_and_pack_unchanged':hashes,
                 'embedded_pck_sha256':embedded_pack,
                 'qa_overrides':'main scene, stable isolated QA profile, synthetic phase/output; endpoint/build/content unchanged',
                 'platform':platform,'source_package':str(original),
                 'synthetic_controller_sha256':hashlib.sha256(probe.read_bytes()).hexdigest(),
                 'private_report':str(private/'report.html'),'qa_data':str(work)}
        if args.pilot_localhost:
            receipt.update(qa_overrides='main scene, isolated Windows QA user directory/profile, loopback endpoint, synthetic phase/output and source batch',
                           locked_test_pilot=True, fixture_endpoint=endpoint, feedback_source='automated')
        (work/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
        print('PASS: package → HTTP → committed SQLite → same-ID private report/triage → delete/restore. '+str(work))
    finally:
        receiver.terminate();receiver.wait(timeout=10);server_log.close()
    return 0


if __name__=='__main__':raise SystemExit(main())
