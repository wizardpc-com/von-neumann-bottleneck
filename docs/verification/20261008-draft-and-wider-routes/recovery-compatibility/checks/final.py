import json, subprocess, pathlib, uuid
out=pathlib.Path(__file__).resolve().parent
root=out.parents[2]
project=out/'project'
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
settings=(root/'project.godot').read_text()
results=[]
def run(name,args,require=True):
    custom='VonNeumannBottleneckChecks/Recovery-'+uuid.uuid4().hex+'/'+name
    configured=settings.replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(custom)+'\n',1)
    if name=='import-retry': configured='\n'.join(l for l in configured.split('\n') if not l.startswith('theme/custom_font='))
    (project/'project.godot').write_text(configured)
    log=out/(name+'.txt')
    command=[str(engine),'--path',str(project)]+args
    with log.open('wb') as stream:
        try: code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=180).returncode
        except subprocess.TimeoutExpired: code=-1
    content=log.read_text(errors='replace')
    errors=[l for l in content.splitlines() if ('ERROR:' in l or l.startswith('FAIL:')) and 'root certificate store' not in l]
    ok=code==0 and not errors and (not require or 'PASS:' in content)
    results.append(dict(name=name,exit=code,passed=ok,errors=errors,log=log.name,command=command,custom_user_dir=custom))
    (out/'final-results.json').write_text(json.dumps(results,indent=2))
    print(name+': '+('PASS' if ok else 'FAIL'),flush=True)
    return ok
for suite in ['test_layout_preview_selection','test_workbench_interrupted_recovery','test_workbench_write_failure','test_global_save','test_save_signature_migration']:
    run('final-'+suite,['--headless','--script','res://tests/'+suite+'.gd'])
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
