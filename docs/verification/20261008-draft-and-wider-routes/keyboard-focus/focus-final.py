import pathlib, shutil, subprocess, json, hashlib
root=pathlib.Path('/Users/ray/Documents/von-neumann-bottleneck')
out=root/'.godot/verification/20261009T035259Z-0e5feebf'
project=out/'project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
files=['experiments/creation/workbench.gd','tests/test_creation_draft_undo.gd','tests/test_creation_keyboard_focus.gd']
for f in files: shutil.copy2(root/f,project/f)
settings=(root/'project.godot').read_text()
results=[]
for suite,rendered in [('test_creation_draft_undo',False),('test_creation_keyboard_focus',False),('test_creation_keyboard_focus',True)]:
    name='final-'+suite+('-rendered' if rendered else '')
    custom='VonNeumannBottleneckChecks/20261009T035259Z-0e5feebf/'+name
    (project/'project.godot').write_text(settings.replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(custom)+'\n',1))
    cmd=[str(engine),'--path',str(project)]+([] if rendered else ['--headless'])+['--script','res://tests/'+suite+'.gd']
    log=out/(name+'.txt')
    with log.open('wb') as stream: code=subprocess.run(cmd,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
    content=log.read_text()
    errors=[l for l in content.splitlines() if 'ERROR:' in l or l.startswith('FAIL:')]
    passed=code==0 and not errors and 'PASS:' in content
    results.append(dict(name=name,command=cmd,custom_user_dir=custom,exit=code,passed=passed,errors=errors,log=log.name))
    print(name, 'PASS' if passed else 'FAIL',flush=True)
(out/'final-results.json').write_text(json.dumps(dict(engine=subprocess.check_output([str(engine),'--version'],text=True).strip(),source_sha256={f:hashlib.sha256((root/f).read_bytes()).hexdigest() for f in files},results=results),indent=2)+'\n')
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
