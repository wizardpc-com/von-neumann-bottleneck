from pathlib import Path
import subprocess,json
root=Path(__file__).resolve().parents[3];out=Path(__file__).resolve().parent; project=out/'project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
original=(project/'project.godot').read_text(); report=json.loads((out/'results.json').read_text())
for suite in ['test_creation_edit_controls','test_creation_profile_navigation','test_creation_navigation','test_creation_writer_retry_ui','test_creation_draft_undo','test_creation_choice_completion','test_representation_closure_navigation']:
 custom='VonNeumannBottleneckChecks/20261008T201936Z-d695aae7/'+suite
 assert not (Path('/Users/ray/Library/Application Support')/custom).exists()
 settings='\n'.join('config/custom_user_dir_name='+json.dumps(custom) if s.startswith('config/custom_user_dir_name=') else s for s in original.splitlines())+'\n'
 (project/'project.godot').write_text(settings)
 command=[str(engine),'--headless','--path',str(project),'--script','res://tests/'+suite+'.gd']
 with (out/(suite+'.txt')).open('wb') as stream:
  try:code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:code=-1
 body=(out/(suite+'.txt')).read_text(errors='replace'); errors=[s for s in body.splitlines() if 'ERROR:' in s or s.startswith('FAIL:')]
 result={'name':suite,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in body,'custom_user_dir':custom,'log':suite+'.txt'}
 report['results'].append(result);(out/'results.json').write_text(json.dumps(report,indent=2)+'\n');print(suite+': '+('PASS' if result['passed'] else 'FAIL'),flush=True)
raise SystemExit(0 if all(x['passed'] for x in report['results']) else 1)
