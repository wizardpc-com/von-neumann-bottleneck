#!/usr/bin/env python3
"""Three real processes verify incomplete drafts; imported QA project only."""
import argparse,json,re,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--project',type=Path,required=True);a=p.parse_args()
project=a.project.resolve();root=Path(__file__).resolve().parents[1]
if project==root or '.godot' not in project.parts:raise SystemExit('Use the imported isolated QA copy')
original=(project/'project.godot').read_text()
if 'config/use_custom_user_dir=true' not in original:raise SystemExit('QA userdata isolation is required')
identity='VonNeumannBottleneckChecks/workspace-process-'+str(time.time_ns())
settings=re.sub(r'config/custom_user_dir_name="[^"]+"','config/custom_user_dir_name='+json.dumps(identity),original)
out=project.parent/'workspace-process';out.mkdir(exist_ok=True)
try:
 (project/'project.godot').write_text(settings)
 for index in range(3):
  command=[a.godot,'--headless','--path',str(project),'--script','res://tests/fixture_chapter_workspace_restart.gd','--']+(['--writer'] if index==0 else [])
  result=subprocess.run(command,capture_output=True,text=True,timeout=60);text=result.stdout+result.stderr
  (out/(str(index)+'.txt')).write_text(text)
  if result.returncode or 'ERROR' in text or 'PASS:' not in text:raise RuntimeError(text)
 print('PASS: invalid drafts/applied sources/empty wiring survive writer + two fresh reader processes; no completion granted')
finally:(project/'project.godot').write_text(original)
