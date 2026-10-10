from pathlib import Path
import subprocess,json,time
root=Path(__file__).resolve().parents[2]
out=Path(__file__).resolve().parent
engine=root/'.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot'
command=[str(engine),'--path',str(out/'project'),'--script','res://scripts/proxy-player-paths.gd','--','--locale=en','--recovery-capture','--evidence-dir=res://.godot/wider-play/']
with (out/'play.txt').open('wb') as stream:
 try: code=subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,timeout=1800).returncode
 except subprocess.TimeoutExpired: code=-1
log=(out/'play.txt').read_text(errors='replace')
errors=[line for line in log.splitlines() if 'ERROR:' in line or line.startswith('FAIL:')]
result={'command':command,'exit':code,'errors':errors,'passed':code==0 and not errors and 'PASS:' in log}
(out/'results.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
