#!/usr/bin/env python3
"""Actual Godot transport to loopback SQLite; only synthetic data and isolated userdata."""
import argparse,json,os,sqlite3,subprocess,tempfile,uuid,socket
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--project',type=Path,required=True);args=p.parse_args()
root=Path(__file__).resolve().parents[1];project=args.project.resolve()
if not project.is_relative_to(root/'.godot'):p.error('Use an imported isolated QA copy under .godot')
output=root/'.godot'/'feedback-integration'/str(uuid.uuid4());output.mkdir(parents=True)
settings=project/'project.godot';original=settings.read_text()
# Unique persistent user directory across the two client processes; no gameplay saves copied.
import re
settings.write_text(re.sub(r'config/custom_user_dir_name="[^"]+"','config/custom_user_dir_name="VonNeumannBottleneckChecks/feedback-'+output.name+'"',original))
server=None
with socket.socket() as reservation:
    reservation.bind(('127.0.0.1',0)); port=reservation.getsockname()[1]
url='http://127.0.0.1:'+str(port)
try:
    for phase in ('queue','resume'):
        if phase=='resume':
            server=subprocess.Popen([__import__('sys').executable,str(root/'server/feedback_server.py'),'--port',str(port),'--database',str(output/'feedback.sqlite')],stdout=subprocess.PIPE,text=True)
            assert server.stdout.readline().startswith('Feedback receiver:')
        result=subprocess.run([args.godot,'--headless','--path',str(project),'--script','tests/feedback_network_probe.gd','--','--receiver='+url,'--phase='+phase],capture_output=True,text=True,timeout=60)
        (output/(phase+'.txt')).write_text(result.stdout+result.stderr)
        if result.returncode or 'PASS:' not in result.stdout or 'SCRIPT ERROR' in result.stderr:raise RuntimeError(phase+' failed; see '+str(output))
    with sqlite3.connect(output/'feedback.sqlite') as db:
        counts=dict(db.execute('SELECT kind,count(*) FROM events GROUP BY kind'))
        assert counts=={'event':1,'feedback':1},counts
        bodies=[json.loads(x[0]) for x in db.execute('SELECT body FROM events')]
        assert all(x['payload']['source']=='automated' for x in bodies)
    (output/'result.json').write_text(json.dumps({'passed':True,'counts':counts,'receiver':'loopback only','data':'synthetic only'},indent=2))
    print('PASS: Godot cross-process queue → HTTP → SQLite; duplicate remains one row; explicit opinion while automatic sharing off. '+str(output))
finally:
    if server: server.terminate();server.wait(timeout=5)
    settings.write_text(original)
