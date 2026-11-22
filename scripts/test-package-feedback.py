#!/usr/bin/env python3
"""Portable package-layout and private-report smoke checks; no Godot process."""
from contextlib import closing, redirect_stdout
from datetime import datetime, timedelta, timezone
import hashlib
import importlib.util
import ipaddress
import io
import json
import os
from pathlib import Path
import plistlib
import sqlite3
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock
from urllib.parse import urlencode
import zipfile


ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location('package_feedback',ROOT/'scripts/verify-package-feedback.py')
VERIFIER=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFIER)
WINDOWS_SPEC=importlib.util.spec_from_file_location('windows_release',ROOT/'scripts/verify-release-windows.py')
WINDOWS=importlib.util.module_from_spec(WINDOWS_SPEC)
WINDOWS_SPEC.loader.exec_module(WINDOWS)
PROVISION_SPEC=importlib.util.spec_from_file_location('provision_windows',ROOT/'scripts/provision-windows-draft-assets.py')
PROVISION=importlib.util.module_from_spec(PROVISION_SPEC)
PROVISION_SPEC.loader.exec_module(PROVISION)
sys.path.insert(0,str(ROOT/'server'))
from storage import migrate


class PackageFeedbackTests(unittest.TestCase):
    def setUp(self):
        temporary=ROOT/'.godot/package-feedback-unit'
        temporary.mkdir(parents=True,exist_ok=True)
        self.workspace=tempfile.TemporaryDirectory(dir=temporary)
        self.addCleanup(self.workspace.cleanup)
        self.output=Path(self.workspace.name)/'candidate'

    def fixture(self,platform,external_pack=False,pilot=False):
        folder=self.output/platform
        folder.mkdir(parents=True)
        if platform=='Windows':
            original=folder/('Von-Neumann-Bottleneck-Test-Pilot.exe' if pilot else 'Von-Neumann-Bottleneck.exe')
            pack=original.with_suffix('.pck')
            if external_pack:
                original.write_bytes(b'windows executable');pack.write_bytes(b'GDPCwindows pack')
            else:
                payload=b'GDPCembedded windows pack'
                original.write_bytes(b'MZwindows executable'+payload+len(payload).to_bytes(8,'little')+b'GDPC')
        else:
            original=folder/'Von-Neumann-Bottleneck.app'
            binary=original/'Contents/MacOS/game'
            pack=original/'Contents/Resources/game.pck'
            binary.parent.mkdir(parents=True);pack.parent.mkdir(parents=True)
            (original/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'game'}))
            binary.write_bytes(b'mac executable');pack.write_bytes(b'mac pack')
        files={p.relative_to(folder).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
               for p in ((original,pack) if platform=='Windows' and external_pack else
                         (original,) if platform=='Windows' else (binary,pack))}
        identity={'build_id':'synthetic-build','source_commit':'a'*40,'engine':'4.7.1.stable.test'}
        if pilot:
            identity.update(player_feedback_pilot=True,edition='test',mode_locked=True,save_profile='EditionTestPilot',
                            display_version='0.6.0',test_batch='PlayerFeedbackPilot-Wave2',
                            feedback_endpoint='https://feedback.yanruiqing.com:8443/v1',
                            privacy_url='https://feedback.yanruiqing.com:8443/privacy-player.html',
                            feedback_default_source='external_player',feedback_source_batch='PlayerFeedbackPilot-Wave2')
        (folder/'BUILD-MANIFEST.json').write_text(json.dumps(identity|{'platform':platform,'files_sha256':files}))
        (self.output/'manifest.json').write_text(json.dumps(identity|{'platforms':{platform:{}}}))
        return original,pack

    def test_windows_and_mac_pack_hashes_match_manifests(self):
        for platform in ('Windows','macOS'):
            with self.subTest(platform=platform):
                original,pack=self.fixture(platform)
                manifest,package,binary,hashes,embedded=VERIFIER.prepare_package(original,platform,Path(self.workspace.name)/('qa-'+platform))
                self.assertEqual(manifest['build_id'],'synthetic-build')
                self.assertEqual(len(hashes),1 if platform=='Windows' else 2)
                self.assertTrue(binary.is_file())
                self.assertTrue(package.is_dir())
                if platform=='Windows':
                    self.assertIsNotNone(embedded)
                    original.write_bytes(original.read_bytes().replace(b'MZwindows',b'MZtampered'))
                else:
                    self.assertIsNone(embedded)
                    pack.write_bytes(b'tampered pack')
                with self.assertRaisesRegex(ValueError,'hash mismatch'):
                    VERIFIER.prepare_package(original,platform,Path(self.workspace.name)/('bad-'+platform))

    def test_windows_external_pack_and_missing_embedded_pack(self):
        original,pack=self.fixture('Windows',external_pack=True)
        _,_,_,hashes,embedded=VERIFIER.prepare_package(original,'Windows',Path(self.workspace.name)/'qa-external')
        self.assertEqual(len(hashes),2);self.assertIsNone(embedded)
        pack.unlink()
        with self.assertRaisesRegex(ValueError,'missing embedded PCK'):
            VERIFIER.prepare_package(original,'Windows',Path(self.workspace.name)/'bad-external')

    def test_package_arguments_are_exclusive(self):
        result=subprocess.run([sys.executable,str(ROOT/'scripts/verify-package-feedback.py'),
                               '--app','unused.app','--exe','unused.exe'],capture_output=True)
        self.assertEqual(result.returncode,2)

    def test_godot_scene_and_override_keep_unicode_paths_in_utf8(self):
        work=Path(self.workspace.name)/'中文 路径'
        work.mkdir()
        probe=work/'probe.gd';scene=work/'probe.tscn';override=work/'override.cfg'
        VERIFIER.write_probe_scene(scene,probe)
        VERIFIER.write_override(override,'PackageFeedback-synthetic',scene,'PackageFeedback-synthetic','offline',work)
        scene_text=scene.read_bytes().decode('utf-8')
        override_text=override.read_bytes().decode('utf-8')
        self.assertIn(probe.as_posix(),scene_text)
        self.assertIn(scene.as_posix(),override_text)
        self.assertIn(work.as_posix(),override_text)
        self.assertNotIn('\\u',scene_text+override_text)

    def test_pilot_requires_explicit_windows_gate_and_never_reuses_baked_endpoint(self):
        self.fixture('Windows',pilot=True)
        manifest=json.loads((self.output/'manifest.json').read_text())
        fake_socket=mock.MagicMock()
        fake_socket.socket.return_value.__enter__.return_value.getsockname.return_value=('127.0.0.1',28765)
        with mock.patch.object(VERIFIER,'socket',fake_socket), \
                mock.patch.object(VERIFIER,'sys',SimpleNamespace(platform='win32')):
            for platform, opt_in, candidate in [
                ('Windows',False,manifest),('macOS',True,manifest),
                ('Windows',True,dict(manifest,edition='game')),('Windows',True,dict(manifest,mode_locked=False)),
                ('Windows',True,dict(manifest,save_profile='EditionTest')),
                ('Windows',True,dict(manifest,player_feedback_pilot=False)),
            ]:
                with self.subTest(platform=platform,opt_in=opt_in,candidate=candidate):
                    with self.assertRaises(ValueError):
                        VERIFIER.acceptance_endpoint(candidate,platform,opt_in)
            fake_socket.socket.assert_not_called()
            self.assertEqual(VERIFIER.acceptance_endpoint(manifest,'Windows',True),'http://127.0.0.1:28765')
            fake_socket.socket.return_value.__enter__.return_value.bind.assert_called_once_with(('127.0.0.1',0))
        with mock.patch.object(VERIFIER,'sys',SimpleNamespace(platform='darwin')), self.assertRaises(ValueError):
            VERIFIER.acceptance_endpoint(manifest,'Windows',True)

    def test_loopback_guards_reject_remote_targets_and_preserve_legacy_localhost(self):
        legacy={'local_acceptance_only':True,'feedback_endpoint':'http://127.0.0.1:28765'}
        self.assertEqual(VERIFIER.acceptance_endpoint(legacy,'macOS',False),legacy['feedback_endpoint'])
        work=Path(self.workspace.name)
        override=work/'override.cfg'
        for endpoint in ['https://feedback.yanruiqing.com:8443/v1','http://localhost:28765',
                         'http://127.0.0.1:65536','http://127.0.0.1:28765?','http://127.0.0.1:1@external.example']:
            with self.subTest(endpoint=endpoint), self.assertRaises(ValueError):
                VERIFIER.write_override(override,'qa',work/'probe.tscn','PackageFeedback-qa','offline',work,
                                        endpoint=endpoint,pilot=True,expected_user_dir=work/'userdata')
            self.assertFalse(override.exists())

    def test_pilot_launch_uses_copy_and_removes_loopback_override_on_failure(self):
        original,_=self.fixture('Windows',pilot=True)
        original_bytes=original.read_bytes()
        work=Path(self.workspace.name)
        script_dir=work/'scripts'
        script_dir.mkdir()
        (script_dir/'package-feedback-probe.gd').write_bytes((ROOT/'scripts/package-feedback-probe.gd').read_bytes())
        fake_socket=mock.MagicMock()
        connection=fake_socket.socket.return_value.__enter__.return_value
        connection.getsockname.return_value=('127.0.0.1',28765)
        connection.connect_ex.return_value=1
        launch_paths=[]
        host_platform=sys.platform

        def fail_launch(command, **options):
            self.assertEqual(sys.platform,host_platform)
            binary=Path(command[0])
            launch_paths.append(binary)
            self.assertNotEqual(binary,original)
            self.assertEqual(binary.read_bytes(),original_bytes)
            self.assertEqual(options['cwd'],binary.parent)
            self.assertIn('--playtest-source=automated',command)
            override=(binary.parent/'override.cfg').read_text(encoding='utf-8')
            self.assertIn('feedback_endpoint="http://127.0.0.1:28765"',override)
            self.assertIn('expected_endpoint="http://127.0.0.1:28765"',override)
            self.assertIn('feedback_privacy_url=""',override)
            self.assertIn('locked_test=true',override)
            self.assertNotIn('feedback.yanruiqing.com',override)
            self.assertNotIn('EditionTestPilot',override)
            appdata=Path(options['env']['APPDATA'])
            self.assertTrue(appdata.is_dir() and appdata.is_relative_to(work/'.godot/package-feedback'))
            self.assertIn(appdata.as_posix()+'/VonNeumannBottleneckCandidates/representation/PackageFeedback-',override)
            raise subprocess.TimeoutExpired(command, options['timeout'])

        with mock.patch.object(VERIFIER,'__file__',str(script_dir/'verify-package-feedback.py')), \
                mock.patch.object(VERIFIER,'sys',SimpleNamespace(platform='win32',executable=sys.executable)), \
                mock.patch.object(VERIFIER,'socket',fake_socket), \
                mock.patch.object(sys,'argv',['verify-package-feedback.py','--exe',str(original),'--pilot-localhost']), \
                mock.patch.object(subprocess,'run',side_effect=fail_launch), mock.patch.object(subprocess,'Popen') as receiver:
            with self.assertRaises(subprocess.TimeoutExpired):
                VERIFIER.main()
            receiver.assert_not_called()
        self.assertEqual(len(launch_paths),1)
        self.assertFalse((launch_paths[0].parent/'override.cfg').exists())
        self.assertFalse((original.parent/'override.cfg').exists())
        self.assertEqual(original.read_bytes(),original_bytes)
        connection.connect_ex.assert_called_once_with(('127.0.0.1',28765))

    def test_pilot_opinion_binds_test_mode_display_version_and_automated_source(self):
        original,_=self.fixture('Windows',pilot=True)
        manifest,_,_,_,_=VERIFIER.prepare_package(original,'Windows',Path(self.workspace.name)/'qa')
        profile='PackageFeedback-synthetic'
        payload={'level_id':'G2_intent','build_version':'0.6.0','source_commit':manifest['source_commit'],
                 'test_batch':manifest['test_batch'],'source':'automated','mode':'test','source_batch':profile,
                 'sharing_mode':'opinion','note':'SYNTHETIC package acceptance: unfinished G2 controls'}
        self.assertEqual(VERIFIER.verify_opinion(payload,manifest,profile),'0.6.0')
        for key,value in [('mode','game'),('build_version',manifest['build_id']),('source','external_player'),
                          ('source_batch',manifest['test_batch']),('work','protected')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                VERIFIER.verify_opinion(dict(payload,**{key:value}),manifest,profile)
        platform_manifest=original.parent/'BUILD-MANIFEST.json'
        changed=json.loads(platform_manifest.read_text())
        changed['feedback_source_batch']='OtherBatch'
        platform_manifest.write_text(json.dumps(changed))
        with self.assertRaisesRegex(ValueError,'pilot platform manifest'):
            VERIFIER.prepare_package(original,'Windows',Path(self.workspace.name)/'tampered')

    def test_private_report_cli_writes_files_on_this_platform(self):
        database=Path(self.workspace.name)/'events.sqlite'
        output=Path(self.workspace.name)/'private-report'
        sidecar=Path(self.workspace.name)/'triage.sqlite'
        event_id='synthetic-package-feedback'
        body=json.dumps({'event_id':event_id,'kind':'feedback','payload':{
            'chapter_id':'creation','level_id':'G2_intent','task_version':'',
            'source':'automated','mode':'test','session_id':'synthetic-session',
            'visit_id':'synthetic-visit','note':'Synthetic private report test'}})
        with closing(sqlite3.connect(database)) as db, db:
            migrate(db)
            db.execute('INSERT INTO clients VALUES (?,?)',('synthetic-client','synthetic-hash'))
            db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',
                       (event_id,'synthetic-client',1,'feedback',body,hashlib.sha256(body.encode()).hexdigest()))
        command=[sys.executable,str(ROOT/'server/private_report.py'),'--database',str(database),'--triage',str(sidecar)]
        subprocess.run(command+['--set-status',event_id,'needs_review'],check=True,capture_output=True)
        subprocess.run(command+['--output',str(output)],check=True,capture_output=True)
        self.assertEqual(json.loads((output/'report.json').read_text())['received_feedback'][0]['event_id'],event_id)
        self.assertTrue((output/'report.html').is_file())


class WindowsReleaseTests(unittest.TestCase):
    def setUp(self):
        folder=tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.work=Path(folder.name)
        self.commit='a'*40
        self.tag='v0.6.1-playtest.1'

    def archive(self, role, *, changes=None, extra=None):
        profile='Edition'+role.title()
        batch=WINDOWS.FINAL_BATCHES[role] if self.tag == WINDOWS.FINAL_TAG else 'PlayersRelease1'
        build=f'vnb-{role}-release-{self.tag}-{batch}-{self.commit[:12]}'
        name=f'Von-Neumann-Bottleneck-{role.title()}.exe'
        binary=b'MZfixture executable'
        manifest={'source_commit':self.commit,'release_version':self.tag,'display_version':self.tag[1:],
                  'edition':role,'edition_name':role.title()+' Edition','build_id':build,
                  'save_profile':profile,'platform':'Windows',
                  'content_count':60,'content_version':'tasks-20261013-journey-v1','mode_locked':True,
                  'player_release':True,'save_migration':False,'engine':'4.7.1.stable.official.a13da4feb',
                  'save_directories':[f'VonNeumannBottleneckCandidates/{d}/{profile}'
                                      for d in ('representation','service')],
                  'access_policy':'earned' if role=='game' else 'all-task-entrances',
                  'test_batch':batch,'files_sha256':{name:hashlib.sha256(binary).hexdigest()}}
        if role=='game' or self.tag == WINDOWS.FINAL_TAG:
            manifest.update(community_feedback_enabled=False,feedback_default_source='external_player',feedback_source_batch=batch,
                            feedback_endpoint=WINDOWS.PUBLIC_ORIGIN+'/v1',
                            privacy_url=WINDOWS.PUBLIC_ORIGIN+'/privacy-player.html')
            if role=='game':
                manifest['public_game_feedback']=True
            else:
                manifest.update(public_test_feedback=True,offline_feedback=True)
        manifest.update(changes or {})
        path=self.work/(role+'.zip')
        with zipfile.ZipFile(path,'w') as archive:
            archive.writestr('Windows/'+name,binary)
            archive.writestr('Windows/BUILD-MANIFEST.json',json.dumps(manifest))
            if extra: archive.writestr(extra,'unexpected')
        identity={'tag':self.tag,'source_commit':self.commit,'assets':{role:{
            'name':f'Von-Neumann-Bottleneck-Windows-{build}.zip','bytes':path.stat().st_size,
            'sha256':WINDOWS.sha256(path)}}}
        return path, identity

    def test_pinned_windows_archives_preserve_two_distinct_player_profiles(self):
        for role in ('game','test'):
            with self.subTest(role=role):
                path,identity=self.archive(role)
                binary,manifest=WINDOWS.unpack(path,self.work/role,role,identity)
                self.assertEqual(binary.read_bytes(),b'MZfixture executable')
                self.assertEqual(manifest['save_profile'],'Edition'+role.title())
        self.assertNotEqual(WINDOWS.sha256(self.work/'game.zip'),WINDOWS.sha256(self.work/'test.zip'))

    def test_archive_rejects_traversal_preexisting_config_and_digest_drift(self):
        for index, member in enumerate(('Windows/../escaped.txt','Windows/override.cfg',
                                        'Windows/Von-Neumann-Bottleneck-Game.EXE')):
            path,identity=self.archive('game',extra=member)
            with self.subTest(member=member), self.assertRaisesRegex(ValueError,'ZIP'):
                WINDOWS.unpack(path,self.work/str(index),'game',identity)
        path,identity=self.archive('game')
        path.write_bytes(path.read_bytes()+b'changed')
        with self.assertRaisesRegex(ValueError,'changed after download'):
            WINDOWS.unpack(path,self.work/'altered','game',identity)

    def test_identity_rejects_repurposed_profile_and_online_test(self):
        for index,(role,changes) in enumerate((
            ('game',{'save_profile':'EditionTestPilot'}),
            ('game',{'community_feedback_enabled':True}),
            ('test',{'feedback_endpoint':'http://127.0.0.1:5555'}),
        )):
            with self.subTest(role=role,changes=changes):
                path,identity=self.archive(role,changes=changes)
                with self.assertRaises(ValueError):
                    WINDOWS.unpack(path,self.work/str(index),role,identity)

    def test_final_windows_archives_require_game_and_dual_test_contracts(self):
        self.tag=WINDOWS.FINAL_TAG
        for role in ('game','test'):
            path,identity=self.archive(role)
            _,manifest=WINDOWS.unpack(path,self.work/role,role,identity)
            self.assertEqual(manifest['test_batch'],WINDOWS.FINAL_BATCHES[role])
            self.assertEqual(manifest['save_profile'],'Edition'+role.title())
        for index, changes in enumerate((
            {'test_batch':WINDOWS.FINAL_BATCHES['game']}, {'offline_feedback':False}, {'public_test_feedback':False},
            {'public_game_feedback':False}, {'community_feedback_enabled':True},
            {'feedback_endpoint':'https://unexpected.example/v1'}, {'save_migration':True},
        )):
            with self.subTest(changes=changes):
                path,identity=self.archive('test',changes=changes)
                with self.assertRaises(ValueError):
                    WINDOWS.unpack(path,self.work/str(index),'test',identity)

    def test_published_baseline_fetch_checks_tag_and_both_download_pins(self):
        bodies={'game':b'game predecessor','test':b'test predecessor'}
        pins={role:{'name':role+'.zip','bytes':len(body),'sha256':hashlib.sha256(body).hexdigest()}
              for role,body in bodies.items()}
        baseline=WINDOWS.BASELINE | {'assets':pins}
        assets=[{'name':pin['name'],'id':index,'state':'uploaded','size':pin['bytes'],'digest':'sha256:'+pin['sha256']}
                for index,pin in enumerate(pins.values(), 1)]
        release={'id':int(baseline['release_id']),'draft':False,'tag_name':baseline['tag'],'assets':assets}
        WINDOWS.write_json(self.work/'downloads.json',{'tag':WINDOWS.FINAL_TAG,'repository':baseline['repository'],
                                                       'source_commit':self.commit})

        def api(path, accept=None, destination=None, missing_ok=False):
            if '/git/ref/' in path:
                return {'object':{'type':'commit','sha':baseline['source_commit']}}
            if destination is None:
                return release
            self.assertEqual(accept,'application/octet-stream')
            destination.write_bytes(bodies[list(pins)[int(path.rsplit('/',1)[1])-1]])

        with mock.patch.dict(os.environ,{'GH_TOKEN':'mock-runner-token'}), \
                mock.patch.object(WINDOWS,'BASELINE',baseline), mock.patch.object(WINDOWS,'gh_get',side_effect=api):
            WINDOWS.fetch_baseline(self.work)
            self.assertEqual((self.work/'baseline-test.zip').read_bytes(),bodies['test'])
            bodies['test']=b'x'*len(bodies['test'])
            with self.assertRaisesRegex(ValueError,'fixed pin'):
                WINDOWS.fetch_baseline(self.work)
            release['draft']=True
            with self.assertRaisesRegex(ValueError,'published upgrade predecessor'):
                WINDOWS.fetch_baseline(self.work)

    def test_final_feedback_delivery_checks_separate_consents_and_private_report(self):
        for role in ('game','test'):
            with self.subTest(role=role):
                folder=self.work/role
                folder.mkdir()
                database=folder/'synthetic.sqlite'
                receipt={'feedback_id':'a'*64,'automatic_ids':{'level_complete':'b'*64,'visit_summary':'c'*64},
                         'automatic_visit_id':'consented-visit','consent_control':'SharingBasic'}
                manifest={'edition':role,'display_version':WINDOWS.FINAL_TAG[1:],'source_commit':self.commit,
                          'test_batch':WINDOWS.FINAL_BATCHES[role]}
                common={'chapter_id':'hardware_foundations','level_id':'tutorial','mode':role,'source':'automated',
                        'source_batch':'HostedWindowsReleaseQA','build_version':manifest['display_version'],
                        'source_commit':self.commit,'test_batch':WINDOWS.FINAL_BATCHES[role],'session_id':'synthetic',
                        'consent_version':'sharing-2','privacy_notice_version':'2026-10-17',
                        'consent_timestamp':'2026-11-22T15:00:00Z'}
                auto=common | {'visit_id':receipt['automatic_visit_id'],'sharing_mode':'basic'}
                completion=auto | {'event':'level_complete'}
                summary=auto | {'event':'visit_summary','completed':True,'completed_during_visit':True}
                feedback=common | {'note':WINDOWS.NOTE,'sharing_mode':'opinion'}
                with closing(sqlite3.connect(database)) as db, db:
                    migrate(db)
                    for event_id,kind,payload in (
                        (receipt['feedback_id'],'feedback',feedback),
                        (receipt['automatic_ids']['level_complete'],'event',completion),
                        (receipt['automatic_ids']['visit_summary'],'event',summary),
                    ):
                        body=json.dumps({'event_id':event_id,'kind':kind,'payload':payload})
                        db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',
                                   (event_id,'synthetic-client',1,kind,body,hashlib.sha256(body.encode()).hexdigest()))
                self.assertEqual(WINDOWS.verify_delivery(database,receipt,manifest,automatic=True),
                                 {'opinions':1,'automatic_events':2})
                with self.assertRaisesRegex(ValueError,'explicit consent'):
                    WINDOWS.verify_delivery(database,receipt | {'consent_control':'SharingLocalOnly'},manifest,automatic=True)
                with self.assertRaisesRegex(ValueError,'incorrect attribution'):
                    WINDOWS.verify_delivery(database,receipt | {'automatic_visit_id':'before-consent'},manifest,automatic=True)
                with self.assertRaisesRegex(ValueError,'Unexpected or duplicate'):
                    WINDOWS.verify_delivery(database,receipt,manifest)
                with closing(sqlite3.connect(database)) as db, db:
                    db.execute("DELETE FROM events WHERE kind='feedback'")
                self.assertEqual(WINDOWS.verify_delivery(database,receipt,manifest,automatic=True,opinion=False),
                                 {'opinions':0,'automatic_events':2})

    def test_receiver_failure_diagnostics_show_only_synthetic_counts(self):
        database=self.work/'synthetic.sqlite'
        with closing(sqlite3.connect(database)) as connection, connection:
            migrate(connection)
            connection.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',
                               ('private-id','private-client',1,'event','private-body','private-hash'))
        output=io.StringIO()
        with redirect_stdout(output):
            WINDOWS.print_receiver_counts(database)
        diagnostic=output.getvalue()
        self.assertIn('"event": 1',diagnostic)
        self.assertIn('"feedback": 0',diagnostic)
        self.assertNotIn('private-',diagnostic)

    def test_startup_uses_shipped_main_scene_and_fails_without_hub(self):
        binary=self.work/'candidate.exe'
        override=self.work/'override.cfg'
        expected={'qa_dir':'qa','edition':'game'}
        launch=['Loading resource: res://src/ui/startup.tscn',
                'Loading resource: res://.godot/exported/1234/export-d00dad-prototype_hub.scn']

        def execute(command, directory, env, timeout):
            settings=override.read_text(encoding='utf-8')
            self.assertNotIn('run/main_scene',settings)
            self.assertIn('feedback_endpoint=""',settings)
            self.assertIn('--headless',command)
            return 0,'\n'.join(launch),b'',False

        with mock.patch.object(WINDOWS,'startup_process',side_effect=execute):
            WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{})
            self.assertTrue(WINDOWS.read_json(self.work/'startup.json')['hub_loaded'])
            launch.pop()
            with self.assertRaisesRegex(RuntimeError,'did not reach the laboratory'):
                WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{})
        self.assertFalse(override.exists())

    def test_disconnected_bundle_requires_attributed_case_and_inventory_bytes(self):
        case_id='c'*32
        manifest={'source_commit':self.commit,'display_version':WINDOWS.FINAL_TAG[1:]}
        prefix='cases/'+case_id+'/'
        task={'chapter_id':'hardware_foundations','level_id':'tutorial'}
        case={'note':WINDOWS.NOTE,'task':task,'screenshot_status':'headless',
              'screenshot_error':'No rendered game viewport was available.'}
        files={prefix+'case.json':json.dumps(case).encode(),prefix+'notes.jsonl':json.dumps(case).encode(),
               prefix+'context.json':json.dumps({'reported_task':task}).encode()}
        inventory=[{'path':name,'size':len(data),'sha256':hashlib.sha256(data).hexdigest()}
                   for name,data in files.items()]
        index={'format':'vnb-offline-playtest','case_count':1,'files':inventory,
               'build':{'source_commit':self.commit,'version':WINDOWS.FINAL_TAG[1:]}}

        def bundle():
            with zipfile.ZipFile(self.work/'offline-feedback.zip','w') as archive:
                archive.writestr('manifest.json',json.dumps(index))
                for name,data in files.items():
                    archive.writestr(name,data)

        bundle()
        WINDOWS.verify_offline_bundle(self.work,case_id,manifest)
        files[prefix+'screenshot.png']=b''
        inventory.append({'path':prefix+'screenshot.png','size':0,'sha256':hashlib.sha256(b'').hexdigest()})
        bundle()
        with self.assertRaisesRegex(ValueError,'headless incident context without an image'):
            WINDOWS.verify_offline_bundle(self.work,case_id,manifest)
        del files[prefix+'screenshot.png']
        inventory.pop()
        inventory[0]['sha256']='d'*64
        bundle()
        with self.assertRaisesRegex(ValueError,'inventory hash mismatch'):
            WINDOWS.verify_offline_bundle(self.work,case_id,manifest)

    def test_fresh_startup_uses_independent_profile_and_reports_runner_fallback(self):
        binary=self.work/'candidate.exe'
        expected={'qa_dir':'qa','edition':'test'}
        facts={'status':'NotSigned','signer_present':False,'interactive':True}
        launch=[]

        def start(binary, stage, profile, expected, env, *, windowed=False):
            self.assertFalse(profile.exists())
            launch.append((profile,windowed))
            return 'windowed unavailable' if windowed else 'headless reached lab'

        with mock.patch.object(WINDOWS,'windows_host_facts',return_value=facts), \
                mock.patch.object(WINDOWS,'verify_startup',side_effect=start):
            receipt=WINDOWS.verify_fresh_startup(binary,self.work/'fresh',expected)
        self.assertEqual(receipt,{'authenticode_status':'NotSigned','signer_present':False,
                                  'headless':'headless reached lab','windowed':'windowed unavailable'})
        self.assertEqual([windowed for _,windowed in launch],[False,True])
        self.assertNotEqual(launch[0][0],launch[1][0])

    def test_graphics_failure_only_falls_back_before_the_shipped_scene_load(self):
        binary=self.work/'candidate.exe'
        expected={'qa_dir':'qa','edition':'test'}
        failure='ERROR: Could not initialize OpenGL'
        with mock.patch.object(WINDOWS,'startup_process',return_value=(1,failure,b'',False)) as execute:
            result=WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{},windowed=True)
            self.assertIn('graphics initialization failed',result)
            execute.return_value=(1,failure+'\nLoading resource: res://src/ui/startup.tscn',b'',False)
            with self.assertRaisesRegex(RuntimeError,'shipped windowed startup failed'):
                WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{},windowed=True)

    def test_startup_process_collects_real_exit_and_timeout_output(self):
        code,out,err,killed=WINDOWS.startup_process(
            [sys.executable,'-c','import sys; print("out"); print("err",file=sys.stderr); sys.exit(7)'],
            self.work,os.environ,5)
        self.assertEqual((code,out.strip(),err.strip(),killed),(7,b'out',b'err',False))
        code,out,err,killed=WINDOWS.startup_process(
            [sys.executable,'-c','import time; print("started",flush=True); time.sleep(10)'],
            self.work,os.environ,1)
        self.assertTrue(killed)
        self.assertNotEqual(code,0)
        self.assertEqual(out.strip(),b'started')

    def test_startup_timeout_is_incomplete_even_after_renderer_and_hub_evidence(self):
        binary=self.work/'candidate.exe'
        expected={'qa_dir':'qa','edition':'test'}
        output=('Godot Engine v4.7.1\nOpenGL API 3.3\nLoading resource: res://src/ui/startup.tscn\n'
                'Loading resource: res://src/ui/prototype_hub.tscn')
        with mock.patch.object(WINDOWS,'startup_process',return_value=(1,output,b'',True)) as execute:
            result=WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{},windowed=True)
            self.assertIn('windowed incomplete',result)
            evidence=WINDOWS.read_json(self.work/'startup.json')
            self.assertEqual(evidence,{'exit_code':1,'timed_out':True,'startup_loaded':True,
                                       'hub_loaded':True,'renderer':'OpenGL API'})
            with self.assertRaisesRegex(RuntimeError,'headless startup timed out'):
                WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{})
            execute.return_value=(1,output,'SCRIPT ERROR: application failure',True)
            with self.assertRaisesRegex(RuntimeError,'windowed startup timed out'):
                WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{},windowed=True)
            execute.return_value=(7,output,b'',False)
            with self.assertRaisesRegex(RuntimeError,'windowed startup failed \(exit 7\)'):
                WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{},windowed=True)
            execute.return_value=(0,output,b'',False)
            self.assertEqual(WINDOWS.verify_startup(binary,self.work,self.work/'profile',expected,{},windowed=True),
                             'windowed startup and renderer initialized')

    def test_draft_binds_annotated_tag_or_exact_uncreated_tag(self):
        draft={'id':17,'draft':True,'tag_name':self.tag,'target_commitish':self.commit}
        annotated={'object':{'type':'tag','sha':'b'*40}}
        commit={'object':{'type':'commit','sha':self.commit}}
        with mock.patch.object(WINDOWS,'gh_get',side_effect=[annotated,commit]):
            WINDOWS.verify_draft('owner/repo',draft,'17',self.tag,self.commit)
        with mock.patch.object(WINDOWS,'gh_get',return_value=None):
            WINDOWS.verify_draft('owner/repo',draft,'17',self.tag,self.commit)
            with self.assertRaisesRegex(ValueError,'full frozen commit'):
                WINDOWS.verify_draft('owner/repo',dict(draft,target_commitish='main'),'17',self.tag,self.commit)
        with self.assertRaisesRegex(ValueError,'exact draft'):
            WINDOWS.verify_draft('owner/repo',dict(draft,draft=False),'17',self.tag,self.commit)

    def test_firewall_failure_prevents_launch_and_still_removes_rule(self):
        commands=[]

        def record(command, **options):
            commands.append(command)
            if 'Install' in command and 'IPv6' in command:
                raise subprocess.CalledProcessError(1,command)
            return SimpleNamespace(stdout=json.dumps(list(WINDOWS.BLOCKED_PREFIXES['IPv4'])))

        with mock.patch.object(WINDOWS.subprocess,'run',side_effect=record):
            with self.assertRaises(subprocess.CalledProcessError):
                with WINDOWS.guarded_binary(self.work/'candidate.exe','game'):
                    self.fail('A binary cannot launch after failed firewall verification')
        self.assertEqual([(c[c.index('-Operation')+1],c[c.index('-Family')+1]) for c in commands],
                         [('Install','IPv4'),('Install','IPv6'),('Remove','IPv6'),('Remove','IPv4')])
        self.assertEqual(len({c[c.index('-Rule')+1] for c in commands}),1)

    def test_firewall_filters_cover_every_nonloopback_ipv4_and_all_ipv6(self):
        v4=tuple(map(ipaddress.ip_network,WINDOWS.BLOCKED_PREFIXES['IPv4']))
        v6=tuple(map(ipaddress.ip_network,WINDOWS.BLOCKED_PREFIXES['IPv6']))
        self.assertEqual(sum(item.num_addresses for item in v4),2**32-2**24)
        self.assertTrue(all(not item.overlaps(ipaddress.ip_network('127.0.0.0/8')) for item in v4))
        self.assertEqual(sum(item.num_addresses for item in v6),2**128)
        WINDOWS.verify_firewall_coverage('IPv4',[item.with_netmask for item in v4])
        WINDOWS.verify_firewall_coverage('IPv6',['::/0'])
        with self.assertRaises(ValueError):
            WINDOWS.verify_firewall_coverage('IPv4',[str(item) for item in v4[1:]])
        with self.assertRaises(ValueError):
            WINDOWS.verify_firewall_coverage('IPv6',['::/1'])
        with self.assertRaises(ValueError):
            WINDOWS.verify_firewall_coverage('IPv4',['0.0.0.0/0'])

    def test_phase_diagnostics_keep_steps_and_errors_without_credentials(self):
        value=WINDOWS.phase_diagnostics(
            'VNB_WINDOWS_QA: fixture ready\nignored raw payload\n'
            'ERROR: https://example.test/object?sig=opaque Bearer opaque\n'
            'SCRIPT ERROR: deletion_token="opaque"')
        self.assertIn('fixture ready',value)
        self.assertIn('SCRIPT ERROR:',value)
        self.assertNotIn('opaque',value)
        self.assertNotIn('ignored raw payload',value)

    def test_timed_out_phase_prints_only_redacted_diagnostics_and_removes_override(self):
        binary=self.work/'candidate.exe'
        output=io.StringIO()
        sample=b'VNB_WINDOWS_QA: fixture entered\nERROR: https://example.test/object?sig=opaque\n'
        error=subprocess.TimeoutExpired([str(binary)],90,output=sample)
        with mock.patch.object(WINDOWS.subprocess,'run',side_effect=error), redirect_stdout(output):
            with self.assertRaisesRegex(RuntimeError,'game write timed out'):
                WINDOWS.verify_phase(binary,self.work/'probe.tscn',self.work/'profile',self.work,
                    {'qa_dir':'qa','edition':'game'},'http://127.0.0.1:12345','write',{})
        self.assertIn('fixture entered',output.getvalue())
        self.assertNotIn('opaque',output.getvalue())
        self.assertFalse((self.work/'override.cfg').exists())

    def test_game_override_uses_only_localhost_without_changing_edition_profile(self):
        path=self.work/'override.cfg'
        identity={'qa_dir':'qa/VonNeumannBottleneckCandidates/representation/EditionGame'}
        with self.assertRaises(ValueError):
            WINDOWS.write_override(path,self.work/'probe.tscn',self.work/'profile',self.work,
                                   identity,'https://feedback.example.test/v1','write')
        self.assertFalse(path.exists())
        WINDOWS.write_override(path,self.work/'probe.tscn',self.work/'profile',self.work,
                               identity,'http://127.0.0.1:12345','write')
        override=path.read_text(encoding='utf-8')
        self.assertIn('feedback_endpoint="http://127.0.0.1:12345"',override)
        self.assertIn('feedback_privacy_url=""',override)
        self.assertIn('feedback_source_batch="HostedWindowsReleaseQA"',override)
        self.assertNotIn('[candidate]',override)

    def test_private_view_override_preserves_logical_service_and_requires_loopback_transport(self):
        path=self.work/'override.cfg'
        identity={'qa_dir':'qa','display_version':WINDOWS.FINAL_TAG[1:]}
        args=(path,self.work/'probe.tscn',self.work/'profile',self.work,identity)
        for endpoint in ('',WINDOWS.PUBLIC_ORIGIN):
            with self.assertRaises(ValueError):
                WINDOWS.write_override(*args,endpoint,'private_view')
            self.assertFalse(path.exists())
        WINDOWS.write_override(*args,'http://127.0.0.1:12345','private_view')
        override=path.read_text(encoding='utf-8')
        expected=f'feedback_endpoint="{WINDOWS.PUBLIC_ORIGIN}/v1"'
        self.assertIn(expected,override)
        self.assertIn('transport_endpoint',override)
        self.assertIn('http://127.0.0.1:12345',override)

    def test_release_process_gets_disposable_paths_and_no_runner_credentials(self):
        with mock.patch.dict(os.environ, {'SYSTEMROOT':'system','GITHUB_TOKEN':'fixture','GH_TOKEN':'fixture',
                                         'APPDATA':'real-player-data','HTTPS_PROXY':'fixture'}, clear=True):
            env=WINDOWS.runner_environment(self.work/'runtime')
        self.assertEqual(env['SYSTEMROOT'],'system')
        for key in ('APPDATA','LOCALAPPDATA','USERPROFILE','TMP','TEMP'):
            self.assertTrue(Path(env[key]).is_relative_to(self.work/'runtime'))
        self.assertFalse({'GITHUB_TOKEN','GH_TOKEN','HTTPS_PROXY'} & env.keys())

    def test_capability_requires_a_read_only_unexpired_github_release_blob(self):
        expiration=(datetime.now(timezone.utc)+timedelta(minutes=15)).isoformat()
        query={'sp':'r','sr':'b','sig':'fake-opaque-secret','se':expiration}
        base='https://release-assets.githubusercontent.com/github-production-release-asset/fixture'
        valid=base+'?'+urlencode(query)
        self.assertEqual(WINDOWS.validate_capability(valid)[0].hostname,'release-assets.githubusercontent.com')
        bad=[
            valid.replace('https:','http:'),
            valid.replace('githubusercontent.com','example.com'),
            base+'?'+urlencode(dict(query,sp='rw')),
            base+'?'+urlencode(dict(query,se='2000-01-01T00:00:00Z')),
            base+'?'+urlencode(dict(query,se=(datetime.now(timezone.utc)+timedelta(days=1)).isoformat())),
        ]
        for value in bad:
            with self.assertRaisesRegex(ValueError,'short-lived GitHub') as failure:
                WINDOWS.validate_capability(value)
            self.assertNotIn('opaque-secret',str(failure.exception))

    def test_capability_fetch_binds_each_pinned_digest_without_recording_secrets(self):
        env={'GITHUB_REPOSITORY':'owner/repo','VNB_RELEASE_ID':'17','VNB_RELEASE_TAG':self.tag,
             'VNB_RELEASE_COMMIT':self.commit}
        bodies={'game':b'synthetic game archive','test':b'synthetic test archive'}
        for role,body in bodies.items():
            prefix='VNB_'+role.upper()+'_'
            env[prefix+'ASSET']=f'Von-Neumann-Bottleneck-Windows-{role}.zip'
            env[prefix+'SHA256']=hashlib.sha256(body).hexdigest()
            env[prefix+'ASSET_CAPABILITY']='fixture-opaque-'+role

        def download(value,destination):
            body=bodies[value.removeprefix('fixture-opaque-')]
            destination.write_bytes(body)
            return len(body)

        with mock.patch.dict(os.environ,env,clear=True), mock.patch.object(WINDOWS,'gh_get') as api, \
                mock.patch.object(WINDOWS,'download_capability',side_effect=download):
            WINDOWS.fetch(self.work/'receipt',capabilities=True)
        api.assert_not_called()
        receipt=(self.work/'receipt/downloads.json').read_text()
        self.assertNotIn('fixture-opaque',receipt)
        self.assertEqual(json.loads(receipt)['download_identity'],'operator-resolved capabilities')

    def test_operator_provisions_using_stdin_and_rolls_back_an_interrupted_pair(self):
        operations=[]
        def run(args, *, data=None, operation):
            operations.append((args,data))
            if args[1]=='list': return '[]'
            if args[1]=='set' and args[2]==WINDOWS.CAPABILITY_SECRETS['test']:
                raise RuntimeError('second secret interrupted')
            return ''
        with mock.patch.object(PROVISION,'gh',side_effect=run), self.assertRaises(RuntimeError):
            PROVISION.provision('owner/repo',{'game':'opaque-one','test':'opaque-two'})
        self.assertEqual([(args[1],args[2]) for args,_ in operations[1:]],
            [('set',WINDOWS.CAPABILITY_SECRETS['game']),('set',WINDOWS.CAPABILITY_SECRETS['test']),
             ('delete',WINDOWS.CAPABILITY_SECRETS['game']),('delete',WINDOWS.CAPABILITY_SECRETS['test'])])
        self.assertEqual([data for _,data in operations[1:3]],['opaque-one','opaque-two'])
        self.assertNotIn('opaque',str([args for args,_ in operations]))


if __name__=='__main__': unittest.main(verbosity=2)
