#!/usr/bin/env python3
"""Portable package-layout and private-report smoke checks; no Godot process."""
from contextlib import closing
import hashlib
import importlib.util
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
import zipfile


ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location('package_feedback',ROOT/'scripts/verify-package-feedback.py')
VERIFIER=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFIER)
WINDOWS_SPEC=importlib.util.spec_from_file_location('windows_release',ROOT/'scripts/verify-release-windows.py')
WINDOWS=importlib.util.module_from_spec(WINDOWS_SPEC)
WINDOWS_SPEC.loader.exec_module(WINDOWS)
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
        batch='PlayersRelease1'
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
        if role=='game':
            manifest.update(public_game_feedback=True,community_feedback_enabled=False,
                            feedback_default_source='external_player',feedback_source_batch=batch,
                            feedback_endpoint=WINDOWS.PUBLIC_ORIGIN+'/v1',
                            privacy_url=WINDOWS.PUBLIC_ORIGIN+'/privacy-player.html')
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
            if 'Install' in command:
                raise subprocess.CalledProcessError(1,command)

        with mock.patch.object(WINDOWS.subprocess,'run',side_effect=record):
            with self.assertRaises(subprocess.CalledProcessError):
                with WINDOWS.guarded_binary(self.work/'candidate.exe'):
                    self.fail('A binary cannot launch after failed firewall verification')
        self.assertIn('Install',commands[0])
        self.assertIn('Remove',commands[1])
        self.assertEqual(commands[0][-3],commands[1][-3])

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

    def test_release_process_gets_disposable_paths_and_no_runner_credentials(self):
        with mock.patch.dict(os.environ, {'SYSTEMROOT':'system','GITHUB_TOKEN':'fixture','GH_TOKEN':'fixture',
                                         'APPDATA':'real-player-data','HTTPS_PROXY':'fixture'}, clear=True):
            env=WINDOWS.runner_environment(self.work/'runtime')
        self.assertEqual(env['SYSTEMROOT'],'system')
        for key in ('APPDATA','LOCALAPPDATA','USERPROFILE','TMP','TEMP'):
            self.assertTrue(Path(env[key]).is_relative_to(self.work/'runtime'))
        self.assertFalse({'GITHUB_TOKEN','GH_TOKEN','HTTPS_PROXY'} & env.keys())


if __name__=='__main__': unittest.main(verbosity=2)
