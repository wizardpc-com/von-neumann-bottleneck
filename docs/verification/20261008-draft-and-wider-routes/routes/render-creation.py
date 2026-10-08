from pathlib import Path
import subprocess,json,sys
root=Path(__file__).resolve().parents[2]; out=Path(__file__).resolve().parent; project=root/'.godot/verification/20261008T191635Z-60214908/project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
iteration=sys.argv[1]; assert iteration in ['v2','v3','v4','v5','v6']
original=(project/'project.godot').read_text().split('\n[candidate]')[0]; results=[]
suites=['test_creation_workbench','test_creation_measured_closure','test_creation_draft_undo','test_creation_causal_panel']
if len(sys.argv)>2 and sys.argv[2]=='after-workbench':suites=suites[1:]
for suite in suites:
 custom='VonNeumannBottleneckChecks/wider-paths-20261008/renderer-'+suite+'-'+iteration
 target=Path('/Users/ray/Library/Application Support')/custom
 assert not target.exists(), 'Each renderer attempt needs a fresh own QA profile'
 lines=[('config/custom_user_dir_name='+json.dumps(custom)) if s.startswith('config/custom_user_dir_name=') else s for s in original.splitlines()]
 (project/'project.godot').write_text('\n'.join(lines)+'\n')
 command=[str(engine),'--path',str(project),'--script','res://tests/'+suite+'.gd','--','--creation-contract-capture']
 if suite=='test_creation_workbench':command+=['--creation-capture']
 with (out/(suite+'-render-'+iteration+'.txt')).open('wb') as stream:
  try:code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:code=-1
 text=(out/(suite+'-render-'+iteration+'.txt')).read_text(errors='replace'); errors=[s for s in text.splitlines() if 'ERROR:' in s or s.startswith('FAIL:')]
 result={'suite':suite,'command':command,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in text};results.append(result)
 (out/('creation-render-'+iteration+'-results.json')).write_text(json.dumps(results,indent=2));print(json.dumps(result),flush=True)
 if not result['passed']:break
