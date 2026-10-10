from pathlib import Path
import subprocess,json,uuid
root=Path.cwd(); qa=root/'.godot/verification/20261010T060043Z-c7662fe9/project'; engine='/Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'; base=(root/'project.godot').read_text();dest=root/'.godot/creative-renders';dest.mkdir(exist_ok=True);results=[]
for locale in ['zh_CN','en']:
 folder=dest/locale;folder.mkdir(exist_ok=True)
 profile='VonNeumannBottleneckChecks/creative-studio-'+locale+'-'+uuid.uuid4().hex[:8]
 (qa/'project.godot').write_text(base.replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(profile)+'\n',1))
 for name,script,render in [('route','scripts/verify-creative-experience.gd',True),('reopen','scripts/verify-personal-works-reopen.gd',False)]:
  cmd=[engine,'--path',str(qa),'--script','res://'+script]+(['--windowed','--resolution','1280x720'] if render else ['--headless'])+['--','--locale='+locale,'--evidence-dir='+str(folder)]
  if render:cmd+=['--capture-size=1280x720']
  r=subprocess.run(cmd,capture_output=True,text=True,timeout=180);log=r.stdout+r.stderr;(folder/(name+'.log')).write_text(log);errors=[l for l in log.splitlines() if 'ERROR:' in l or 'SCRIPT ERROR' in l or l.startswith('FAIL:')];passed=r.returncode==0 and not errors and 'PASS:' in log
  results.append({'locale':locale,'name':name,'command':cmd,'exit':r.returncode,'passed':passed,'profile':profile,'errors':errors,'log':str(folder/(name+'.log'))});(dest/'results.json').write_text(json.dumps(results,indent=2)+'\n');print(locale+' '+name+': '+str(passed)+' '+log.strip().splitlines()[-1],flush=True)
  if not passed:raise SystemExit(1)
profile='VonNeumannBottleneckChecks/creative-studio-editor-'+uuid.uuid4().hex[:8]
(qa/'project.godot').write_text(base.replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps(profile)+'\n',1))
cmd=[engine,'--path',str(qa),'--script','res://tests/test_creation_sample_editing.gd','--windowed','--resolution','1280x720','--','--creation-sample-edit-capture','--capture-size=1280x720']
r=subprocess.run(cmd,capture_output=True,text=True,timeout=180);log=r.stdout+r.stderr;(dest/'editor-render.log').write_text(log);passed=r.returncode==0 and 'ERROR:' not in log and 'FAIL:' not in log and 'PASS:' in log;results.append({'name':'bilingual-editor','command':cmd,'exit':r.returncode,'passed':passed,'log':str(dest/'editor-render.log')});(dest/'results.json').write_text(json.dumps(results,indent=2)+'\n');print('bilingual-editor: '+str(passed)+' '+log.strip().splitlines()[-1],flush=True);raise SystemExit(0 if passed else 1)
