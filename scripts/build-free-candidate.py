#!/usr/bin/env python3
"""Build both free candidates from one committed Git archive, never live player data."""
import argparse,datetime,hashlib,io,json,shutil,subprocess,tarfile,zipfile
from pathlib import Path

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--godot',required=True);p.add_argument('--commit',default='HEAD');a=p.parse_args()
    root=Path(__file__).resolve().parents[1]
    commit=subprocess.check_output(['git','rev-parse',a.commit],cwd=root,text=True).strip()
    engine=subprocess.check_output([a.godot,'--version'],text=True).strip()
    if not engine.startswith('4.7.1.stable.'):p.error('Godot 4.7.1 stable required')
    stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+commit[:8]
    work=root/'.godot/candidates'/stamp;project=work/'project';project.mkdir(parents=True)
    archive=subprocess.check_output(['git','archive',commit],cwd=root)
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        for member in source.getmembers():
            dest=(project/member.name).resolve()
            if not dest.is_relative_to(project.resolve()) or not (member.isfile() or member.isdir()):raise ValueError('Unsupported archive member: '+member.name)
        source.extractall(project)
    output=root/'build'/('free-alpha-'+stamp);output.mkdir(parents=True)
    original=(project/'project.godot').read_text()
    isolated=original.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="VonNeumannBottleneckChecks/build-'+stamp+'"')
    def run(name,args):
        result=subprocess.run([a.godot,'--headless','--path',str(project),*args],capture_output=True,text=True,timeout=600)
        text=result.stdout+result.stderr;(work/(name+'.log')).write_text(text)
        if result.returncode or 'SCRIPT ERROR' in text or 'ERROR:' in text:raise RuntimeError(name+' failed: '+str(work/(name+'.log')))
        print(name+': PASS',flush=True)
    (project/'project.godot').write_text('\n'.join(line for line in isolated.splitlines() if not line.startswith('theme/custom_font='))+'\n')
    run('import',['--editor','--import','--quit'])
    (project/'project.godot').write_text(isolated)
    # Read the exact engine's bundled licensing data, not a guessed dependency list.
    probe=project/'candidate_license_probe.gd'
    probe.write_text('extends SceneTree\nfunc _init() -> void:\n\tvar f=FileAccess.open("res://candidate-licenses.txt",FileAccess.WRITE)\n\tf.store_string(Engine.get_license_text()+"\\n\\n"+JSON.stringify(Engine.get_copyright_info(),"\\t")+"\\n\\n"+JSON.stringify(Engine.get_license_info(),"\\t"))\n\tf.close()\n\tquit()\n')
    run('licenses',['--script','res://candidate_license_probe.gd']);probe.unlink()
    (project/'project.godot').write_text(original)
    # Exporters themselves do not start the game. Native QA uses a separate override.
    manifest={'source_commit':commit,'engine':engine,'created_utc':stamp,'public_release':False,'upload_default':False,'platforms':{}}
    for platform,preset,binary in [('macOS','macOS Free Candidate','Von-Neumann-Bottleneck.app'),('Windows','Windows Playtest','Von-Neumann-Bottleneck.exe')]:
        folder=output/platform;folder.mkdir()
        run('export-'+platform,['--export-release',preset,str(folder/binary)])
        for src,name in [('distribution/PLAYTEST-README.txt','README.txt'),('distribution/KNOWN-ISSUES.txt','KNOWN-ISSUES.txt'),('distribution/CHANGELOG.txt','CHANGELOG.txt'),('LICENSE','LICENSE.txt'),('assets/fonts/OFL-NotoSansSC.txt','FONT-LICENSE.txt'),('candidate-licenses.txt','ENGINE-LICENSES.txt')]:shutil.copy2(project/src,folder/name)
        files={str(f.relative_to(folder)):hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(folder.rglob('*')) if f.is_file()}
        platform_manifest={'source_commit':commit,'engine':engine,'platform':platform,'native_validation':'See verification record; export is not native acceptance','files_sha256':files}
        (folder/'BUILD-MANIFEST.json').write_text(json.dumps(platform_manifest,indent=2)+'\n')
        zip_path=output/('Von-Neumann-Bottleneck-'+platform+'-'+commit[:8]+'.zip')
        if platform=='macOS':subprocess.run(['/usr/bin/ditto','-c','-k','--sequesterRsrc','--keepParent',str(folder),str(zip_path)],check=True)
        else:
            with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
                for f in sorted(folder.rglob('*')):
                    if f.is_file():z.write(f,f.relative_to(output))
        with zipfile.ZipFile(zip_path) as z:assert z.testzip() is None
        manifest['platforms'][platform]={'zip':zip_path.name,'bytes':zip_path.stat().st_size,'sha256':hashlib.sha256(zip_path.read_bytes()).hexdigest()}
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Candidates: '+str(output))
if __name__=='__main__':main()
