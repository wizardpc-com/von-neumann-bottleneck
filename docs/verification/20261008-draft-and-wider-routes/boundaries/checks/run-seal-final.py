from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[3];out=Path(__file__).resolve().parent;project=out/'project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot';original=(project/'project.godot').read_text();report=[]
runs=[('seal-final','test_hardware_seal_navigation',[],True)]
for name,suite,flags,headless in runs:
 custom='VonNeumannBottleneckChecks/20261008T203804Z-29b9b749/'+name
 assert not (Path('/Users/ray/Library/Application Support')/custom).exists()
 settings='\n'.join('config/custom_user_dir_name='+json.dumps(custom) if s.startswith('config/custom_user_dir_name=') else s for s in original.splitlines())+'\n';(project/'project.godot').write_text(settings)
 command=[str(engine)]+(['--headless'] if headless else [])+['--path',str(project),'--script','res://tests/'+suite+'.gd']+(['--']+flags if flags else [])
 with (out/(name+'.txt')).open('wb') as stream:
  try:code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:code=-1
 body=(out/(name+'.txt')).read_text(errors='replace');errors=[s for s in body.splitlines() if 'ERROR:' in s or s.startswith('FAIL:')]
 result={'name':name,'suite':suite,'command':command,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in body};report.append(result)
 (out/'results-seal-final.json').write_text(json.dumps(report,indent=2)+'\n');print(name+': '+('PASS' if result['passed'] else 'FAIL'),flush=True)
 if not result['passed']:raise SystemExit(1)
