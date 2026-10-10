from pathlib import Path
import json,subprocess,sys
root=Path(__file__).resolve().parents[2]; out=Path(__file__).resolve().parent; project=root/'.godot/verification/20261008T191635Z-60214908/project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
domain=sys.argv[1]; assert domain in ['representation_region','service_plan']
restart=len(sys.argv)>2 and sys.argv[2]=='restart'; iteration=sys.argv[3] if len(sys.argv)>3 else 'v1'; primary='representation' if domain=='representation_region' else 'service'
profile='QA-Wider-20261008-'+primary+'-en-'+iteration; custom='VonNeumannBottleneckCandidates/'+primary+'/'+profile
settings=(project/'project.godot').read_text().split('\n[candidate]')[0]
lines=[('config/custom_user_dir_name='+json.dumps(custom)) if s.startswith('config/custom_user_dir_name=') else s for s in settings.splitlines()]
settings='\n'.join(lines)+'\n[candidate]\nprimary_domain='+json.dumps(primary)+'\nprofile='+json.dumps(profile)+'\njourney_enabled=true\n'
(project/'project.godot').write_text(settings)
target=Path('/Users/ray/Library/Application Support')/custom
assert restart or not target.exists(), 'First journey must use a fresh own QA candidate profile'
command=[str(engine),'--path',str(project),'--script','res://experiments/play_journeys.gd','--','--locale=en','--experiment='+domain,'--candidate-save','--candidate-journey','--evidence-dir=res://.godot/wider-'+domain+('-restart-'+iteration+'/' if restart else '-'+iteration+'/'),'--capture']
if restart:command+=['--journey-resume']
name=domain+('-restart' if restart else '')+'-'+iteration
with (out/(name+'.txt')).open('wb') as stream:
 try:code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=480).returncode
 except subprocess.TimeoutExpired:code=-1
text=(out/(name+'.txt')).read_text(errors='replace');errors=[s for s in text.splitlines() if 'ERROR:' in s or s.startswith('FAIL:')]
result={'command':command,'user_dir':custom,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in text}
(out/(name+'-results.json')).write_text(json.dumps(result,indent=2)); print(json.dumps(result,indent=2),flush=True)
