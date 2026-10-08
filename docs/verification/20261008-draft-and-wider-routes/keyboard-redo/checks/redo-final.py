from pathlib import Path
import json,uuid,subprocess
out=Path(__file__).resolve().parent;root=out.parents[2];project=out/'project';engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
settings=(root/'project.godot').read_text();results=[]
for name,args in [('redo-headless',['--headless']),('redo-rendered',['--windowed','--resolution','1280x720'])]:
    suffix='VonNeumannBottleneckChecks/Redo-'+uuid.uuid4().hex+'/'+name
    (project/'project.godot').write_text(settings.replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(suffix)+'\n',1))
    command=[str(engine),'--path',str(project)]+args+['--script','res://tests/test_chapter_redo_shortcuts.gd']
    log=out/(name+'.txt')
    with log.open('wb') as stream:
        try:code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=120).returncode
        except subprocess.TimeoutExpired:code=-1
    text=log.read_text(errors='replace');errors=[l for l in text.splitlines() if ('ERROR:' in l or l.startswith('FAIL:')) and 'root certificate store' not in l]
    passed=code==0 and not errors and 'PASS:' in text
    results.append(dict(name=name,passed=passed,exit=code,errors=errors,command=command,log=log.name,custom_user_dir=suffix))
    (out/'redo-final-results.json').write_text(json.dumps(results,indent=2)+'\n')
    print(name+': '+('PASS' if passed else 'FAIL'),flush=True)
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
