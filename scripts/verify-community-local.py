#!/usr/bin/env python3
"""Synthetic local client/server lifecycle; no public traffic or player directories."""
import argparse
import json
from pathlib import Path
import re
import socket
import sqlite3
import subprocess
import sys
import time
import uuid
from urllib.parse import urlencode
from urllib.request import urlopen

p=argparse.ArgumentParser();p.add_argument('--godot',required=True);p.add_argument('--project',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];project=a.project.resolve()
if not project.is_relative_to(root/'.godot'):p.error('requires imported isolated copy under .godot')
output=root/'.godot/community-integration'/str(uuid.uuid4());output.mkdir(parents=True)
settings=project/'project.godot';original=settings.read_text()
settings.write_text(re.sub(r'config/custom_user_dir_name="[^"]+"','config/custom_user_dir_name="VonNeumannBottleneckChecks/community-'+output.name+'"',original))
with socket.socket() as reservation:
    reservation.bind(('127.0.0.1',0));port=reservation.getsockname()[1]
url='http://127.0.0.1:'+str(port);server=None;results={}
def start():
    process=subprocess.Popen([sys.executable,str(root/'server/feedback_server.py'),'--database',str(output/'feedback.sqlite'),'--port',str(port)],stdout=subprocess.PIPE,text=True)
    assert process.stdout.readline().startswith('Feedback receiver:')
    return process
def get(path):
    with urlopen(url+path,timeout=5) as response:return json.load(response)
try:
    for phase in ['queue','resume','delete_offline','delete_resume']:
        if phase in ['resume','delete_resume']:server=start()
        if phase=='delete_offline':server.terminate();server.wait(timeout=5);server=None
        started=time.monotonic()
        result=subprocess.run([a.godot,'--headless','--path',str(project),'--script','tests/community_network_probe.gd','--','--receiver='+url+'/v1','--phase='+phase],capture_output=True,text=True,timeout=45)
        (output/(phase+'.txt')).write_text(result.stdout+result.stderr)
        assert result.returncode==0 and 'PASS:' in result.stdout and 'SCRIPT ERROR' not in result.stderr,(phase,output)
        results[phase]={'passed':True,'seconds':round(time.monotonic()-started,3)}
        if phase=='resume':
            with sqlite3.connect(output/'feedback.sqlite') as db:
                counts=dict(db.execute('SELECT kind,count(*) FROM events GROUP BY kind'));assert counts=={'event':1,'feedback':1,'score':1},counts
                for (body,) in db.execute('SELECT body FROM events'):
                    payload=json.loads(body)['payload']
                    assert payload['source']=='automated' and payload['consent_version']=='sharing-2'
            community=get('/v1/community/tasks?source=automated&mode=test')['tasks']['chapter_4/mixed']
            assert community['starts']==1 and community['completions']==1 and community['small_sample']
            rules=json.loads((root/'server/community_rules.json').read_text())['boards']['chapter_4/mixed']
            query=urlencode({'level_id':'chapter_4/mixed',**{k:rules[k] for k in ['ruleset_version','model_version','case_set_version']},'source':'automated','mode':'test'})
            board=get('/v1/leaderboards?'+query);assert len(board['rows'])==1 and not board['verified']
            results['community']=community;results['board']=board
    with sqlite3.connect(output/'feedback.sqlite') as db:
        assert db.execute('SELECT COUNT(*) FROM events').fetchone()[0]==0
        assert db.execute('SELECT COUNT(*) FROM tombstones').fetchone()[0]==1
    (output/'result.json').write_text(json.dumps(results,indent=2,ensure_ascii=False))
    print('PASS: summary/opinion/score offline queue, restart, exact retransmission, community reads, withdrawal, durable deletion; '+str(output))
finally:
    if server:server.terminate();server.wait(timeout=5)
    settings.write_text(original)
