#!/usr/bin/env python3
"""Check portable candidate ZIPs and their exact packaged-file inventory."""
import contextlib
import configparser
import hashlib
import io
import importlib.util
import json
import stat
import struct
import subprocess
import sys
import tarfile
import tempfile
from unittest import mock
import zipfile
from pathlib import Path


root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('candidate_builder',root/'scripts/build-free-candidate.py')
builder=importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
template_path=root/'build'/'冯诺依曼瓶颈'/'macos.zip'
literal=builder.godot_path_literal(template_path)
assert json.loads(literal)==template_path.resolve().as_posix()
assert '\\u' not in literal and '\\\\' not in literal
assert builder.public_https_url('https://feedback.play.example.org',api_root=True)
assert builder.public_https_url('https://play.example.org/privacy')
assert builder.public_https_url('https://play.example.org:443/privacy.html')
assert builder.public_https_url('https://feedback.play.example.org:443',api_root=True)
for unsafe_privacy in ['https://play.example.org:8443/privacy.html',
                       'https://play.example.org:0443/privacy.html',
                       'https://play.example.org/privacy%20notice',
                       'https://play.example.org/privacy?notice',
                       'https://play.example.org/privacy?',
                       'https://play.example.org/privacy\n.html']:
    assert not builder.public_https_url(unsafe_privacy),unsafe_privacy
for unsafe in ['','http://feedback.play.example.org','https://127.0.0.1','https://localhost',
               'https://feedback.example','https://feedback.play.example.org:8443',
               'https://feedback.play.example.org/v1','https://feedback.play.example.org/',
               'https://feedback.play.example.org?']:
    assert not builder.public_https_url(unsafe,api_root=True),unsafe
offline_notes=(root/'distribution/OFFLINE-PLAYTEST-README.txt').read_text(encoding='utf-8')
for profile in ['OfflineTeammate','OfflineTeammate-Night20261018']:
    assert builder.offline_profile(profile),profile
    notes=builder.offline_readme(offline_notes,profile)
    assert '%APPDATA%/VonNeumannBottleneckCandidates/representation/'+profile+'/' in notes
    assert 'service/'+profile+'/' in notes
for profile in ['CloudPlaytest','OfflineTeammateOther','Other-OfflineTeammate',
                'OfflineTeammate-','OfflineTeammate-../production','OfflineTeammate-unsafe_name',
                'OfflineTeammate-'+('x'*25)]:
    assert not builder.offline_profile(profile),profile
    rejected=subprocess.run([sys.executable,str(root/'scripts/build-free-candidate.py'),'--godot','unused',
        '--offline-tester','--platform','Windows','--second-act-profile',profile,'--creation-journey'],capture_output=True)
    assert rejected.returncode!=0 and b'error:' in rejected.stderr,profile
for flags in [['--public-playtest'],['--release-version','v0.5.0-alpha.2'],['--offline-tester'],
              ['--offline-tester','--platform','Windows','--second-act-profile','CloudPlaytest','--creation-journey'],
              ['--offline-tester','--platform','Windows','--second-act-profile','OfflineTeammate','--creation-journey',
               '--feedback-endpoint','https://feedback.play.example.org']]:
    rejected=subprocess.run([sys.executable,str(root/'scripts/build-free-candidate.py'),'--godot','unused',*flags],capture_output=True)
    assert rejected.returncode!=0 and b'error:' in rejected.stderr,flags
commit='a'*40
build_id='playtest-PackageTest-'+commit[:12]
test_root=root/'.godot/candidate-packaging-tests'
test_root.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(dir=test_root) as temporary:
    frozen=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
    # The exporter is mocked: keep committed configuration/code/license inputs,
    # not hundreds of MB of unrelated verification images or cinematic media.
    # Required packaging screenshots are explicit fixtures below.
    fixture_paths=['project.godot','export_presets.cfg','scripts','src','experiments','server',
        'distribution','LICENSE','README.md','README.en.md','CHANGELOG.md',
        'assets/branding','assets/fonts/OFL-NotoSansSC.txt']
    archive=io.BytesIO(subprocess.check_output(['git','archive',frozen,*fixture_paths],cwd=root))
    # Keep the engine mocked: this exercises packaging from committed UTF-8 sources.
    with tarfile.open(fileobj=archive,mode='a') as staged:
        for path in sorted((root/'distribution').glob('EDITION-*.txt')):
            payload=path.read_bytes();entry=tarfile.TarInfo('distribution/'+path.name)
            entry.size=len(payload);staged.addfile(entry,io.BytesIO(payload))
        for name in ['lab-home.png','task-map.png','hardware.png','feedback.png']:
            payload=b'\x89PNG\r\n\x1a\n'+name.encode()
            entry=tarfile.TarInfo('docs/verification/20261019-team-closeout/screenshots/'+name)
            entry.size=len(payload);entry.mtime=1700000000;staged.addfile(entry,io.BytesIO(payload))
    fixture=Path(temporary)/'builder';(fixture/'scripts').mkdir(parents=True)
    template=fixture/'windows.exe';template.write_bytes(b'template fixture')
    revision=subprocess.check_output(['git','rev-list','--count',frozen],cwd=root,text=True)
    def frozen_output(command,**kwargs):
        if command[0]=='git':
            if command[1]=='archive':return archive.getvalue()
            return revision if command[1]=='rev-list' else frozen
        assert command==['mock-godot','--version'],command
        return '4.7.1.stable.fixture'
    def engine_run(command,**kwargs):
        assert command[0]=='mock-godot',command
        project=Path(command[command.index('--path')+1])
        (project/'project.godot').read_text(encoding='utf-8')
        (project/'export_presets.cfg').read_text(encoding='utf-8')
        if '--script' in command:
            (project/'candidate-licenses.txt').write_text('Engine licenses · 许可',encoding='utf-8')
        if '--export-release' in command:
            assert '冯' in (project/'distribution/OFFLINE-PLAYTEST-README.txt').read_text(encoding='utf-8')
            target=Path(command[-1])
            if target.suffix=='.app':
                executable=target/'Contents/MacOS'/'game'
                executable.parent.mkdir(parents=True)
                executable.write_bytes(b'Universal export fixture')
            else:target.write_bytes(b'export fixture')
        return subprocess.CompletedProcess(command,0,'fixture · 中文日志\n','')
    arguments=['build-free-candidate.py','--godot','mock-godot','--commit',frozen,
        '--platform','Windows','--windows-template',str(template),'--offline-tester',
        '--second-act-profile','OfflineTeammate-EncodingTest','--creation-journey','--test-batch','EncodingTest']
    with mock.patch.object(builder,'__file__',str(fixture/'scripts/build-free-candidate.py')), \
            mock.patch.object(sys,'argv',arguments), \
            mock.patch.object(subprocess,'check_output',side_effect=frozen_output), \
            mock.patch.object(subprocess,'run',side_effect=engine_run),contextlib.redirect_stdout(io.StringIO()):
        builder.main()
    packaged=fixture/'build'/('playtest-EncodingTest-'+frozen[:12])
    checked=subprocess.run([sys.executable,str(root/'scripts/check-candidate-identity.py'),str(packaged)],capture_output=True)
    assert checked.returncode==0,(checked.stdout+checked.stderr).decode(errors='replace')
    manifest=json.loads((packaged/'Windows/BUILD-MANIFEST.json').read_text(encoding='utf-8'))
    for name in ['lab-home.png','task-map.png','hardware.png','feedback.png']:
        assert 'screenshots/'+name in manifest['files_sha256']
    assert '许可' in (packaged/'Windows/ENGINE-LICENSES.txt').read_text(encoding='utf-8')
    assert 'OfflineTeammate-EncodingTest' in (packaged/'Windows/README.txt').read_text(encoding='utf-8')
    assert (packaged/'Windows/Von-Neumann-Bottleneck.exe').is_file(), 'Legacy candidate binary name stays unchanged'

# Exercise the real committed-source configuration and manifest path with the
# engine/exporter mocked. This is packaging-contract coverage, not native QA.
source_project_before=(root/'project.godot').read_bytes()
for case, scope_flags, expected_count in [
        ('core', [], 40),
        ('second-act', ['--second-act-profile', 'ScopeTest'], 51),
        ('creation', ['--second-act-profile', 'ScopeTest', '--creation-journey'], 60)]:
    with tempfile.TemporaryDirectory(dir=test_root) as temporary:
        fixture=Path(temporary)/'builder';(fixture/'scripts').mkdir(parents=True)
        arguments=['build-free-candidate.py', '--godot', 'mock-godot', '--commit', frozen,
                   '--platform', 'Windows', *scope_flags]
        with mock.patch.object(builder,'__file__',str(fixture/'scripts/build-free-candidate.py')), \
                mock.patch.object(sys,'argv',arguments), \
                mock.patch.object(subprocess,'check_output',side_effect=frozen_output), \
                mock.patch.object(subprocess,'run',side_effect=engine_run),contextlib.redirect_stdout(io.StringIO()):
            builder.main()
        project=next((fixture/'.godot/candidates').glob('*/project'))
        config=configparser.ConfigParser(interpolation=None)
        config.read_string('[root]\n'+(project/'project.godot').read_text(encoding='utf-8'))
        full=config.getboolean('game','full_journey',fallback=False)
        second=config.getboolean('candidate','journey_enabled',fallback=False)
        creation=config.getboolean('candidate','creation_enabled',fallback=False)
        manifest=json.loads((fixture/'build'/('free-alpha-'+frozen[:12])/'manifest.json').read_text())
        # These are the runtime feature gates used by LabFeatures/Context/Creation.
        runtime_count=40+(11 if full or second else 0)+(9 if full or creation else 0)
        expected_version='tasks-20260910-v1' if expected_count==40 else 'tasks-20261013-journey-v1'
        print('Content scope:',case,'configured=',runtime_count,'manifest=',len(manifest['content_tasks']))
        assert runtime_count==expected_count==len(manifest['content_tasks']),case
        assert manifest['content_version']==expected_version,case
        if expected_count < 60:
            assert not full, 'Partial exports must not inherit the source/F5 full-journey override'
        else:
            assert full, 'The current full candidate retains the final cinematic gate'

# Both product editions use exactly the same archived source and task manifest,
# yet differ in fixed mode/profile, native bundle ID and immutable build identity.
edition_manifests=[]
for edition, network in [('game',False),('test',False),('test',True)]:
    with tempfile.TemporaryDirectory(dir=test_root) as temporary:
        fixture=Path(temporary)/'builder';(fixture/'scripts').mkdir(parents=True)
        platforms=['macOS'] if network else ['Windows','macOS']
        arguments=['build-free-candidate.py','--godot','mock-godot','--commit',frozen,
                   '--platform','macOS' if network else 'both','--edition',edition,
                   '--release-version','v0.6.0','--test-batch','Dual'+edition.title()]
        if network:arguments.append('--network-feedback-test')
        with mock.patch.object(builder,'__file__',str(fixture/'scripts/build-free-candidate.py')), \
                mock.patch.object(sys,'argv',arguments),mock.patch.object(sys,'platform','fixture'), \
                mock.patch.object(subprocess,'check_output',side_effect=frozen_output), \
                mock.patch.object(subprocess,'run',side_effect=engine_run),contextlib.redirect_stdout(io.StringIO()):
            builder.main()
        details=builder.edition_identity(edition,'v0.6.0',frozen,'Dual'+edition.title(),network)
        packaged=fixture/'build'/details['build_id']
        checked=subprocess.run([sys.executable,str(root/'scripts/check-candidate-identity.py'),str(packaged)],capture_output=True)
        assert checked.returncode==0,(checked.stdout+checked.stderr).decode(errors='replace')
        manifest=json.loads((packaged/'manifest.json').read_text())
        if not network:edition_manifests.append(manifest)
        binary_name='Von-Neumann-Bottleneck-'+edition.title()
        assert (packaged/'Windows'/(binary_name+'.exe')).is_file()==(not network)
        assert (packaged/'macOS'/(binary_name+'.app')).is_dir()
        assert not (packaged/'Windows/Von-Neumann-Bottleneck.exe').exists()
        assert not (packaged/'macOS/Von-Neumann-Bottleneck.app').exists()
        for platform in platforms:
            notes=(packaged/platform/'README.txt').read_text(encoding='utf-8')
            assert binary_name+'.exe' in notes and binary_name+'.app' in notes
            with zipfile.ZipFile(packaged/manifest['platforms'][platform]['zip']) as package:
                expected=platform+'/'+binary_name+('.exe' if platform=='Windows' else '.app/Contents/MacOS/game')
                assert expected in package.namelist(), 'Edition name must survive final ZIP packaging'
        project=next((fixture/'.godot/candidates').glob('*/project'))
        config=configparser.ConfigParser(interpolation=None)
        config.read_string('[root]\n'+(project/'project.godot').read_text(encoding='utf-8'))
        assert json.loads(config.get('game','edition'))==edition
        assert config.getboolean('game','full_journey') and config.getboolean('candidate','creation_enabled')
        assert not config.getboolean('playtest','offline_tester',fallback=False)
        assert config.getboolean('playtest','offline_feedback',fallback=False)==(edition=='test' and not network)
        if network:
            assert manifest['network_feedback_test'] and manifest['save_profile']=='EditionTestFeedback'
            assert json.loads(config.get('application','feedback_endpoint'))==builder.NETWORK_FEEDBACK_ORIGIN+'/v1'
            assert json.loads(config.get('application','feedback_privacy_url'))==builder.NETWORK_FEEDBACK_ORIGIN+'/privacy.html'
            assert not manifest['public_release'] and not manifest['upload_default']
        assert json.loads(config.get('application','config/version'))=='0.6.0'
        assert json.loads(config.get('application','config/build_id'))==details['build_id']
        assert json.loads(config.get('application','config/build_commit'))==frozen
        assert json.loads(config.get('application','config/custom_user_dir_name'))==details['save_directories'][0]
        presets=(project/'export_presets.cfg').read_text()
        assert presets.count('custom_features="free_candidate,'+edition+'_edition"')==2
        assert 'com.wizardpc.von-neumann-bottleneck.'+edition in presets
        assert 'application/product_version="0.6.0.' in presets
        for key,value in [('save_profile','EditionWrong'),('mode_locked',False),('edition_name','Wrong'),
                          ('source_commit','0'*40),('content_count',59),('feedback_endpoint','https://example.com')]:
            changed={**manifest,key:value}
            (packaged/'manifest.json').write_text(json.dumps(changed))
            assert subprocess.run([sys.executable,str(root/'scripts/check-candidate-identity.py'),str(packaged)],capture_output=True).returncode!=0,key
        (packaged/'manifest.json').write_text(json.dumps(manifest))
assert edition_manifests[0]['source_commit']==edition_manifests[1]['source_commit']==frozen
assert edition_manifests[0]['content_tasks']==edition_manifests[1]['content_tasks']
assert set(edition_manifests[0]['save_directories']).isdisjoint(edition_manifests[1]['save_directories'])

pair_spec=importlib.util.spec_from_file_location('edition_checker',root/'scripts/check-edition-delivery.py')
pair_checker=importlib.util.module_from_spec(pair_spec);pair_spec.loader.exec_module(pair_checker)
with tempfile.TemporaryDirectory(dir=test_root) as temporary:
    pair_dirs=[Path(temporary)/name for name in ['game','test']]
    for folder,manifest in zip(pair_dirs,edition_manifests):
        folder.mkdir();(folder/'manifest.json').write_text(json.dumps(manifest))
    # Individual archive/hash verification was exercised above. Focus this check
    # on rejecting mixed commits, models/content, branding, templates and profiles.
    with mock.patch.object(pair_checker.subprocess,'run',return_value=subprocess.CompletedProcess([],0)):
        assert pair_checker.verify_pair(*pair_dirs)['passed']
        for key,value in [('source_commit','0'*40),('content_tasks',['wrong']),('branding',{}),
                          ('windows_template_sha256','wrong'),('save_directories',edition_manifests[0]['save_directories']),
                          ('platforms',{'Windows':{}})]:
            changed={**edition_manifests[1],key:value}
            (pair_dirs[1]/'manifest.json').write_text(json.dumps(changed))
            try:pair_checker.verify_pair(*pair_dirs)
            except ValueError:pass
            else:raise AssertionError('Mixed delivery accepted: '+key)

for flags in [[],['--release-version','0.6.0'],['--release-version','v0.6.0','--test-batch','X'],
              ['--release-version','v0.6.0','--test-batch','X','--commit',frozen,'--second-act-profile','CloudPlaytest'],
              ['--release-version','v0.6.0','--test-batch','X','--commit',frozen,'--offline-tester']]:
    rejected=subprocess.run([sys.executable,str(root/'scripts/build-free-candidate.py'),'--godot','unused','--edition','game',*flags],capture_output=True)
    assert rejected.returncode!=0 and b'error:' in rejected.stderr,flags

assert (root/'project.godot').read_bytes()==source_project_before, 'Exports never rewrite the source/F5 defaults'

with tempfile.TemporaryDirectory(dir=test_root) as temporary:
    output=Path(temporary)/build_id
    assert output.resolve().is_relative_to(root.resolve())
    folder=output/'macOS'
    folder.mkdir(parents=True)
    for name in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt','LICENSE.txt','FONT-LICENSE.txt','ENGINE-LICENSES.txt']:
        (folder/name).write_text('Build: '+build_id+'\nSource commit: '+commit+'\n')
    app=folder/'Von-Neumann-Bottleneck.app'/'Contents'/'MacOS'
    app.mkdir(parents=True)
    (app/'game — Edition').write_bytes(b'exported binary')
    (app.parent/'Info.plist').write_bytes(b'plist fixture')
    files={path.relative_to(folder).as_posix():hashlib.sha256(builder.packaged_bytes(path)).hexdigest()
           for path in builder.package_files(folder)}
    (folder/'BUILD-MANIFEST.json').write_text(json.dumps({'build_id':build_id,'source_commit':commit,
        'engine':'4.7.1.stable.test','platform':'macOS','files_sha256':files}))
    archive=output/('Von-Neumann-Bottleneck-macOS-'+build_id+'.zip')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as package:
        for path in builder.package_files(folder):
            builder.write_zip_entry(package,path,path.relative_to(output))
    with zipfile.ZipFile(archive) as package:
        binary=package.getinfo('macOS/Von-Neumann-Bottleneck.app/Contents/MacOS/game — Edition')
        assert binary.external_attr >> 16 & stat.S_IXUSR
    manifest={'build_id':build_id,'source_commit':commit,'test_batch':'PackageTest','public_release':False,
        'upload_default':False,'external_ready':False,'engine':'4.7.1.stable.test','platforms':{'macOS':{
        'zip':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}}}
    (output/'manifest.json').write_text(json.dumps(manifest))
    checker=[sys.executable,str(root/'scripts/check-candidate-identity.py'),str(output)]
    first=subprocess.run(checker,capture_output=True)
    assert first.returncode==0,(first.stdout+first.stderr).decode(errors='replace')
    with zipfile.ZipFile(archive) as package:
        original=[(info.filename,package.read(info),info.external_attr) for info in package.infolist()]
    class DittoInfo(zipfile.ZipInfo):
        def _encodeFilenameFlags(self):
            return getattr(self,'raw_name',self.filename.encode('utf-8')),self.flag_bits & ~0x800
    binary_name='macOS/Von-Neumann-Bottleneck.app/Contents/MacOS/game — Edition'
    apple_name='__MACOSX/macOS/Von-Neumann-Bottleneck.app/Contents/MacOS/._game — Edition'
    apple=struct.pack('>II16sHIII',0x00051607,0x00020000,b'Mac OS X',1,9,38,32)+bytes(32)
    def check_zip_case(label, extras=(), expected=True, mutate_binary=False):
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as package:
            for name,data,attrs in original:
                info=DittoInfo(name);info.external_attr=attrs
                package.writestr(info,data+b'tampered' if mutate_binary and name==binary_name else data)
            for name,data,kind in extras:
                info=zipfile.ZipInfo(name) if kind=='utf8' else DittoInfo(name)
                if kind=='invalid':info.raw_name=b'macOS/invalid-\x82'
                package.writestr(info,data)
        manifest['platforms']['macOS'].update(bytes=archive.stat().st_size,
            sha256=hashlib.sha256(archive.read_bytes()).hexdigest())
        (output/'manifest.json').write_text(json.dumps(manifest))
        result=subprocess.run(checker,capture_output=True)
        assert (result.returncode==0)==expected,(label,(result.stdout+result.stderr).decode(errors='replace'))
    check_zip_case('ditto UTF-8 without flag plus valid AppleDouble',[(apple_name,apple,'ditto')])
    frameworks='macOS/Von-Neumann-Bottleneck.app/Contents/Frameworks/'
    frameworks_metadata='__MACOSX/macOS/Von-Neumann-Bottleneck.app/Contents/._Frameworks'
    check_zip_case('standard empty Frameworks',[(frameworks,b'','ditto'),(frameworks_metadata,apple,'ditto')])
    for label,extras in [
        ('normalized collision',[(binary_name,b'duplicate','utf8')]),
        ('invalid UTF-8',[('macOS/invalid',b'x','invalid')]),
        ('traversal',[('macOS/../escape',b'x','ditto')]),
        ('backslash',[('macOS/escape\\file',b'x','ditto')]),
        ('absolute',[('/macOS/escape',b'x','ditto')]),
        ('outside inventory',[('unlisted.txt',b'x','ditto')]),
        ('unlisted directory',[('macOS/unlisted/',b'','ditto')]),
        ('metadata orphan',[(apple_name+'missing',apple,'ditto')]),
        ('metadata absent Frameworks',[(frameworks_metadata,apple,'ditto')]),
        ('metadata ordinary file',[('__MACOSX/macOS/extra.txt',apple,'ditto')]),
        ('metadata truncated',[(apple_name,apple[:30],'ditto')]),
        ('metadata magic',[(apple_name,b'bad!'+apple[4:],'ditto')]),
        ('metadata bounds',[(apple_name,apple[:34]+struct.pack('>I',9999)+apple[38:],'ditto')]),
        ('metadata unknown ID',[(apple_name,apple[:26]+struct.pack('>I',99)+apple[30:],'ditto')]),
        ('metadata overlapping entries',[(apple_name,struct.pack('>II16sH',0x00051607,0x00020000,b'Mac OS X',2)
            +struct.pack('>III',2,50,32)+struct.pack('>III',9,50,32)+bytes(32),'ditto')]),
    ]:
        check_zip_case(label,extras,expected=False)
    check_zip_case('changed product hash',expected=False,mutate_binary=True)
    check_zip_case('restore valid ditto archive')
    with zipfile.ZipFile(archive,'a') as package:
        package.writestr('macOS/extra.txt','unlisted file')
    manifest['platforms']['macOS']['bytes']=archive.stat().st_size
    manifest['platforms']['macOS']['sha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    (output/'manifest.json').write_text(json.dumps(manifest))
    assert subprocess.run(checker,capture_output=True).returncode!=0

    public_id='playtest-PublicTest-'+commit[:12]
    public_output=Path(temporary)/public_id
    windows=public_output/'Windows'
    windows.mkdir(parents=True)
    endpoint='https://feedback.play.example.org'
    privacy='https://play.example.org/privacy'
    for name in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt','LICENSE.txt','FONT-LICENSE.txt','ENGINE-LICENSES.txt']:
        note='Build: '+public_id+'\nSource commit: '+commit+'\n'
        if name in ['README.txt','KNOWN-ISSUES.txt']:note+='v0.5.0-alpha.2\n'+endpoint+'\n'+privacy+'\n'
        (windows/name).write_text(note)
    (windows/'Von-Neumann-Bottleneck.exe').write_bytes(b'exported Windows binary')
    public_files={path.relative_to(windows).as_posix():hashlib.sha256(builder.packaged_bytes(path)).hexdigest()
                  for path in builder.package_files(windows)}
    (windows/'BUILD-MANIFEST.json').write_text(json.dumps({'build_id':public_id,'source_commit':commit,
        'engine':'4.7.1.stable.test','platform':'Windows','files_sha256':public_files}))
    public_zip=public_output/('Von-Neumann-Bottleneck-Windows-'+public_id+'.zip')
    with zipfile.ZipFile(public_zip,'w',zipfile.ZIP_DEFLATED) as package:
        for path in builder.package_files(windows):builder.write_zip_entry(package,path,path.relative_to(public_output))
    public_manifest={'build_id':public_id,'source_commit':commit,'test_batch':'PublicTest','public_release':True,
        'release_version':'v0.5.0-alpha.2','privacy_url':privacy,'feedback_endpoint':endpoint,
        'feedback_default_source':'external_player','upload_default':False,'external_ready':False,
        'local_acceptance_only':False,'engine':'4.7.1.stable.test','content_version':'tasks-20261013-journey-v1',
        'content_tasks':['task-'+str(index) for index in range(60)],
        'candidate_journey':{'primary_domain':'representation','profile':'CloudPlaytest','isolated':True,
                             'production_migration':False,'creation_enabled':True},
        'platforms':{'Windows':{'zip':public_zip.name,'bytes':public_zip.stat().st_size,
                                'sha256':hashlib.sha256(public_zip.read_bytes()).hexdigest()}}}
    (public_output/'manifest.json').write_text(json.dumps(public_manifest))
    public_checker=[sys.executable,str(root/'scripts/check-candidate-identity.py'),str(public_output)]
    checked=subprocess.run(public_checker,capture_output=True)
    assert checked.returncode==0,(checked.stdout+checked.stderr).decode(errors='replace')
    for key,value in [('external_ready',True),('upload_default',True),('local_acceptance_only',True),
                      ('feedback_default_source','unknown'),('feedback_endpoint','http://127.0.0.1:8765'),
                      ('privacy_url',''),('privacy_url','https://play.example.org:8443/privacy'),
                      ('privacy_url','https://play.example.org/privacy%20notice'),
                      ('release_version','v0.5.0-alpha.1')]:
        changed=public_manifest.copy();changed[key]=value
        (public_output/'manifest.json').write_text(json.dumps(changed))
        assert subprocess.run(public_checker,capture_output=True).returncode!=0,key
    public_manifest['public_release']=False
    (public_output/'manifest.json').write_text(json.dumps(public_manifest))
    assert subprocess.run(public_checker,capture_output=True).returncode!=0
    offline_id='playtest-OfflineTest-'+commit[:12]
    offline_output=Path(temporary)/offline_id
    offline_windows=offline_output/'Windows'
    offline_windows.mkdir(parents=True)
    for name in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt','LICENSE.txt','FONT-LICENSE.txt','ENGINE-LICENSES.txt']:
        (offline_windows/name).write_text('Build: '+offline_id+'\nSource commit: '+commit+'\n'+(offline_notes if name=='README.txt' else ''),encoding='utf-8')
    (offline_windows/'Von-Neumann-Bottleneck.exe').write_bytes(b'offline tester binary')
    offline_files={path.relative_to(offline_windows).as_posix():hashlib.sha256(builder.packaged_bytes(path)).hexdigest()
                   for path in builder.package_files(offline_windows)}
    (offline_windows/'BUILD-MANIFEST.json').write_text(json.dumps({'build_id':offline_id,'source_commit':commit,
        'engine':'4.7.1.stable.test','platform':'Windows','files_sha256':offline_files}))
    offline_zip=offline_output/('Von-Neumann-Bottleneck-Windows-'+offline_id+'.zip')
    with zipfile.ZipFile(offline_zip,'w',zipfile.ZIP_DEFLATED) as package:
        for path in builder.package_files(offline_windows):
            builder.write_zip_entry(package,path,path.relative_to(offline_output))
    offline_manifest={'build_id':offline_id,'source_commit':commit,'test_batch':'OfflineTest',
        'public_release':False,'offline_tester':True,'upload_default':False,'external_ready':False,
        'local_acceptance_only':False,'feedback_endpoint':'','engine':'4.7.1.stable.test',
        'content_version':'tasks-20261013-journey-v1','content_tasks':['task-'+str(index) for index in range(60)],
        'candidate_journey':{'primary_domain':'representation','profile':'OfflineTeammate','isolated':True,
                             'production_migration':False,'creation_enabled':True},
        'platforms':{'Windows':{'zip':offline_zip.name,'bytes':offline_zip.stat().st_size,
                                'sha256':hashlib.sha256(offline_zip.read_bytes()).hexdigest()}}}
    offline_checker=[sys.executable,str(root/'scripts/check-candidate-identity.py'),str(offline_output)]
    (offline_output/'manifest.json').write_text(json.dumps(offline_manifest))
    checked=subprocess.run(offline_checker,capture_output=True)
    assert checked.returncode==0,(checked.stdout+checked.stderr).decode(errors='replace')
    for key,value in [('feedback_endpoint','https://feedback.play.example.org'),('public_release',True),
                      ('candidate_journey',{'primary_domain':'representation','profile':'CloudPlaytest',
                                            'isolated':True,'production_migration':False,'creation_enabled':True}),
                      ('local_acceptance_only',True)]:
        changed=offline_manifest.copy();changed[key]=value
        (offline_output/'manifest.json').write_text(json.dumps(changed))
        assert subprocess.run(offline_checker,capture_output=True).returncode!=0,key
    for profile in ['CloudPlaytest','OfflineTeammateOther','OfflineTeammate-',
                    'OfflineTeammate-../production','OfflineTeammate-unsafe_name','OfflineTeammate-'+('x'*25)]:
        changed=offline_manifest.copy()
        changed['candidate_journey']={**offline_manifest['candidate_journey'],'profile':profile}
        (offline_output/'manifest.json').write_text(json.dumps(changed))
        assert subprocess.run(offline_checker,capture_output=True).returncode!=0,profile
    for key,value in [('primary_domain','service'),('isolated',False),
                      ('production_migration',True),('creation_enabled',False)]:
        changed=offline_manifest.copy()
        changed['candidate_journey']={**offline_manifest['candidate_journey'],key:value}
        (offline_output/'manifest.json').write_text(json.dumps(changed))
        assert subprocess.run(offline_checker,capture_output=True).returncode!=0,key

    profile='OfflineTeammate-Night20261018'
    offline_manifest['candidate_journey']['profile']=profile
    (offline_output/'manifest.json').write_text(json.dumps(offline_manifest))
    assert subprocess.run(offline_checker,capture_output=True).returncode!=0,'Custom profile cannot retain the default README paths'
    (offline_windows/'README.txt').write_text('Build: '+offline_id+'\nSource commit: '+commit+'\n'+builder.offline_readme(offline_notes,profile),encoding='utf-8')
    offline_files={name:hashlib.sha256((offline_windows/name).read_bytes()).hexdigest() for name in offline_files}
    (offline_windows/'BUILD-MANIFEST.json').write_text(json.dumps({'build_id':offline_id,'source_commit':commit,
        'engine':'4.7.1.stable.test','platform':'Windows','files_sha256':offline_files}))
    with zipfile.ZipFile(offline_zip,'w',zipfile.ZIP_DEFLATED) as package:
        for path in builder.package_files(offline_windows):
            builder.write_zip_entry(package,path,path.relative_to(offline_output))
    offline_manifest['platforms']['Windows'].update(bytes=offline_zip.stat().st_size,
        sha256=hashlib.sha256(offline_zip.read_bytes()).hexdigest())
    (offline_output/'manifest.json').write_text(json.dumps(offline_manifest))
    checked=subprocess.run(offline_checker,capture_output=True)
    assert checked.returncode==0,(checked.stdout+checked.stderr).decode(errors='replace')
print('PASS: dual-edition same-source/profile/identity contracts; frozen UTF-8 Windows packaging, screenshot inventory, URL gates, offline/public profiles and README paths, ZIP inventory, hashes and unlisted-file rejection')
