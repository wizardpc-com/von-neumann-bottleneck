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
import uuid
import zipfile


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate',type=Path,required=True)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    candidate=args.candidate.resolve()
    subprocess.run([sys.executable,str(root/'scripts/check-candidate-identity.py'),str(candidate)],check=True)
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
