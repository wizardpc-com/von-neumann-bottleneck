from pathlib import Path
import json,shutil,subprocess,sys,hashlib
root=Path(__file__).resolve().parents[2]; out=Path(__file__).resolve().parent
project=root/'.godot/verification/20261008T191152Z-41686a6a/project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
stage=sys.argv[1]; assert stage in ['layout','overlap']
mode=sys.argv[2] if len(sys.argv)>2 else ''; assert mode in ['', 'restart', 'closeout']; continuation=bool(mode)
custom='VonNeumannBottleneckChecks/wider-paths-20261008/'+stage+'-en'
settings=(project/'project.godot').read_text()
lines=settings.splitlines()
lines=[('config/custom_user_dir_name='+json.dumps(custom)) if s.startswith('config/custom_user_dir_name=') else s for s in lines]
(project/'project.godot').write_text('\n'.join(lines)+'\n')
origin=Path('/Users/ray/Library/Application Support/VonNeumannBottleneckChecks/wider-paths-20261008/core-system-locality-en')
target=Path('/Users/ray/Library/Application Support')/custom
if not continuation:
 assert not target.exists(), 'Need fresh QA branch'
 target.mkdir(parents=True)
 copied={}
 for name in ['proxy-save.json','proxy-save.json.bak','proxy-workbenches.json']:
  raw=(origin/name).read_bytes(); (target/name).write_bytes(raw); copied[name]=hashlib.sha256(raw).hexdigest()
 (out/(stage+'-copy.json')).write_text(json.dumps({'origin':str(origin),'target':str(target),'sha256':copied},indent=2))
command=[str(engine),'--path',str(project),'--script','res://scripts/proxy-'+stage+'-path.gd','--','--resume='+stage,'--locale=en','--recovery-capture','--evidence-dir=res://.godot/wider-'+stage+'/']
if mode=='restart': command+=['--'+stage+'-restart-check']
if mode=='closeout': command+=['--layout-closeout']
name=stage+('-'+mode if mode else '')
if len(sys.argv)>3: name+='-'+sys.argv[3]
with (out/(name+'.txt')).open('wb') as stream:
 try: code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=360).returncode
 except subprocess.TimeoutExpired: code=-1
log=(out/(name+'.txt')).read_text(errors='replace'); errors=[s for s in log.splitlines() if 'ERROR:' in s or s.startswith('FAIL:')]
result={'command':command,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in log}
(out/(name+'-results.json')).write_text(json.dumps(result,indent=2)); print(json.dumps(result,indent=2),flush=True)
