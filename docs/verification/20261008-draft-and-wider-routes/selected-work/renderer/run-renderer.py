from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[2]; out=Path(__file__).resolve().parent
project=root/'.godot/verification/20261008T195941Z-31fb40e7/project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
original=(project/'project.godot').read_text(); results=[]
for suite,flag in [('test_creation_choice_completion','--creation-capture'),('test_service_number_display','--service-number-capture')]:
 custom='VonNeumannBottleneckChecks/selected-work-20261008/renderer-'+suite+'-1280'
 assert not (Path('/Users/ray/Library/Application Support')/custom).exists(), 'Fresh own QA profile required'
 settings='\n'.join('config/custom_user_dir_name='+json.dumps(custom) if s.startswith('config/custom_user_dir_name=') else s for s in original.splitlines())+'\n'
 (project/'project.godot').write_text(settings)
 command=[str(engine),'--path',str(project),'--script','res://tests/'+suite+'.gd','--',flag,'--capture-size=1280x720']
 with (out/(suite+'-1280.txt')).open('wb') as stream:
  try:code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:code=-1
 log=(out/(suite+'-1280.txt')).read_text(errors='replace');errors=[s for s in log.splitlines() if 'ERROR:' in s or s.startswith('FAIL:')]
 result={'suite':suite,'command':command,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in log};results.append(result)
 (out/'results-1280.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(result),flush=True)
 if not result['passed']:raise SystemExit(1)
