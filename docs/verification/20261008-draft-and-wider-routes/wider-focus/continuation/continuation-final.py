from pathlib import Path
import subprocess,json,hashlib,shutil
r=Path('/Users/ray/Documents/von-neumann-bottleneck');q=r/'.godot/verification/20261009T041504Z-b801ccad';p=q/'project';engine=r/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
files=['experiments/representation_region/region.gd','experiments/service_plan/lab.gd','tests/test_candidate_disabled_focus.gd']
for name in files:shutil.copy2(r/name,p/name)
settings=(r/'project.godot').read_text();results=[]
for suite,rendered in [('test_candidate_disabled_focus',False),('test_candidate_disabled_focus',True)]:
 name='continuation-'+suite+('-rendered' if rendered else '');custom='VonNeumannBottleneckChecks/20261009T041504Z-b801ccad/'+name
 (p/'project.godot').write_text(settings.replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(custom)+'\n',1))
 cmd=[str(engine),'--path',str(p)]+([] if rendered else ['--headless'])+['--script','res://tests/'+suite+'.gd'];log=q/(name+'.txt')
 with log.open('wb') as stream: code=subprocess.run(cmd,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
 text=log.read_text();errors=[line for line in text.splitlines() if 'ERROR:' in line or line.startswith('FAIL:')];passed=code==0 and not errors and 'PASS:' in text
 results.append(dict(name=name,command=cmd,custom_user_dir=custom,exit=code,passed=passed,errors=errors,log=log.name));print(name,'PASS' if passed else 'FAIL',flush=True)
(q/'continuation-results.json').write_text(json.dumps(dict(engine=subprocess.check_output([str(engine),'--version'],text=True).strip(),source_sha256={name:hashlib.sha256((r/name).read_bytes()).hexdigest() for name in files},results=results),indent=2)+'\n')
raise SystemExit(0 if all(x['passed'] for x in results) else 1)
