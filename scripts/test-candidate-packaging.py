#!/usr/bin/env python3
"""Check portable candidate ZIPs and their exact packaged-file inventory."""
import hashlib
import importlib.util
import json
import stat
import subprocess
import sys
import tempfile
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
for flags in [['--public-playtest'],['--release-version','v0.5.0-alpha.2']]:
    rejected=subprocess.run([sys.executable,str(root/'scripts/build-free-candidate.py'),'--godot','unused',*flags],capture_output=True)
    assert rejected.returncode!=0 and b'error:' in rejected.stderr,flags
commit='a'*40
build_id='playtest-PackageTest-'+commit[:12]
test_root=root/'.godot/candidate-packaging-tests'
test_root.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(dir=test_root) as temporary:
    output=Path(temporary)/build_id
    assert output.resolve().is_relative_to(root.resolve())
    folder=output/'macOS'
    folder.mkdir(parents=True)
    for name in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt','LICENSE.txt','FONT-LICENSE.txt','ENGINE-LICENSES.txt']:
        (folder/name).write_text('Build: '+build_id+'\nSource commit: '+commit+'\n')
    app=folder/'Von-Neumann-Bottleneck.app'/'Contents'/'MacOS'
    app.mkdir(parents=True)
    (app/'game').write_bytes(b'exported binary')
    files={path.relative_to(folder).as_posix():hashlib.sha256(builder.packaged_bytes(path)).hexdigest()
           for path in builder.package_files(folder)}
    (folder/'BUILD-MANIFEST.json').write_text(json.dumps({'build_id':build_id,'source_commit':commit,
        'engine':'4.7.1.stable.test','platform':'macOS','files_sha256':files}))
    archive=output/('Von-Neumann-Bottleneck-macOS-'+build_id+'.zip')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as package:
        for path in builder.package_files(folder):
            builder.write_zip_entry(package,path,path.relative_to(output))
    with zipfile.ZipFile(archive) as package:
        binary=package.getinfo('macOS/Von-Neumann-Bottleneck.app/Contents/MacOS/game')
        assert binary.external_attr >> 16 & stat.S_IXUSR
    manifest={'build_id':build_id,'source_commit':commit,'test_batch':'PackageTest','public_release':False,
        'upload_default':False,'external_ready':False,'engine':'4.7.1.stable.test','platforms':{'macOS':{
        'zip':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}}}
    (output/'manifest.json').write_text(json.dumps(manifest))
    checker=[sys.executable,str(root/'scripts/check-candidate-identity.py'),str(output)]
    first=subprocess.run(checker,capture_output=True)
    assert first.returncode==0,(first.stdout+first.stderr).decode(errors='replace')
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
print('PASS: URL gates, offline/public identities, ZIP inventory, file hashes and unlisted-file rejection')
