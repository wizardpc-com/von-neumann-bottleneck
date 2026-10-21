#!/usr/bin/env python3
"""Package a fully passed isolated verifier snapshot, without modifying the checkout.
This verifies export/PE/PCK structure, not Windows execution, graphics or FPS.
Supply an official Godot 4.7.1 Windows release template already trusted/installed.
"""
import argparse,hashlib,json,os,shutil,struct,subprocess
from pathlib import Path

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for part in iter(lambda:f.read(4*1024*1024),b''):h.update(part)
    return h.hexdigest()

def inspect_executable(path):
    length=path.stat().st_size
    if length<128:raise ValueError("Truncated executable")
    with path.open('rb') as f:
        if f.read(2)!=b'MZ':raise ValueError('Missing PE executable header')
        f.seek(0x3c);offset=struct.unpack('<I',f.read(4))[0]
        if offset>length-6:raise ValueError("Invalid PE offset")
        f.seek(offset)
        if f.read(4)!=b'PE\0\0' or struct.unpack('<H',f.read(2))[0]!=0x8664:
            raise ValueError('Expected a Windows x86_64 executable')
        f.seek(-12,2);footer=f.read(12)
        size=struct.unpack('<Q',footer[:8])[0]
        if footer[8:]!=b'GDPC' or not 0<size<length-12:raise ValueError('Invalid embedded PCK footer')
        f.seek(length-size-12)
        if f.read(4)!=b'GDPC':raise ValueError('Invalid embedded PCK header')
    return {'bytes':length,'sha256':sha(path),'embedded_pack_bytes':size,'pe_architecture':'x86_64'}

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--verification',type=Path,required=True)
    ap.add_argument('--godot',type=Path,required=True)
    ap.add_argument('--template',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    args=ap.parse_args()
    verification=args.verification.resolve();source=verification/'project'
    result=json.loads((verification/'results.json').read_text())
    expected={p.stem for p in (source/'tests').glob('test_*.gd') if p.stem!='test_recovery_game_input'}
    stages={r['name']:r for r in result['results']}
    if not expected or not expected.issubset(stages) or not all(r['passed'] for r in result['results']):
        raise SystemExit('Use a completed, fully passing headless verifier run, not a partial or failed run.')
    engine=str(args.godot.resolve());template=args.template.resolve();output=args.output.resolve()
    version=subprocess.check_output([engine,'--version'],text=True).strip()
    if not version.startswith('4.7.1.stable.') or not str(result['engine']).startswith('4.7.1.stable.'):
        raise SystemExit('Godot 4.7.1 stable is required for both verification and packaging.')
    if not template.is_file():raise SystemExit('Official Windows release template is missing.')
    if output.exists():raise SystemExit('Output already exists; choose a fresh directory to preserve old packages.')
    output.mkdir(parents=True)
    project=output/'project'
    shutil.copytree(source,project,ignore=shutil.ignore_patterns('.godot'))
    settings=(project/'project.godot').read_text()
    lines=settings.splitlines()
    custom=[s for s in lines if s.startswith('config/custom_user_dir_name=')]
    if len(custom)!=1 or 'VonNeumannBottleneckChecks/' not in custom[0]:
        raise SystemExit('Unexpected user-directory configuration; review before packaging.')
    settings='\n'.join(s for s in lines if not s.startswith(('config/use_custom_user_dir=','config/custom_user_dir_name=')))+'\n'
    presets=project/'export_presets.cfg'
    content=presets.read_text()
    if 'custom_template/release=""' not in content:raise SystemExit('Review the existing custom export template before replacing it.')
    presets.write_text(content.replace('custom_template/release=""','custom_template/release='+json.dumps(str(template)),1))
    env=dict(os.environ,APPDATA=str(output/"runtime"/"appdata"),LOCALAPPDATA=str(output/"runtime"/"localappdata"))
    for key,suffix in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
        env[key]=str(output/'runtime'/suffix)
    def run(name,arguments):
        log=output/(name+'.log')
        with log.open('wb') as f:
            status=subprocess.run([engine,'--headless','--path',str(project)]+arguments,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=300).returncode
        errors=[line for line in log.read_text(errors='replace').splitlines() if 'ERROR:' in line and 'root certificate store' not in line]
        if status or errors:raise RuntimeError(f'{name} failed; retained log at {log}')
    # Match verifier bootstrap: import the font before making it the project font.
    (project/'project.godot').write_text('\n'.join(s for s in settings.splitlines() if not s.startswith('theme/custom_font='))+'\n')
    run('import-fonts',['--editor','--import','--quit'])
    (project/'project.godot').write_text(settings)
    run('import-project',['--editor','--import','--quit'])
    executable=output/'Von-Neumann-Bottleneck.exe'
    run('export',['--export-release','Windows Playtest',str(executable)])
    receipt=inspect_executable(executable)
    receipt.update(engine=version,verification_snapshot=verification.name,passed_headless_suites=len(expected),template_sha256=sha(template),native_play_verified=False,graphical_acceptance=False)
    (output/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt,indent=2))
if __name__=='__main__':main()
