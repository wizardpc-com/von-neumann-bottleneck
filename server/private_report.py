#!/usr/bin/env python3
"""Operator-only local report; keep output private, never serve the SQLite file."""
import argparse,importlib.util,json,sqlite3
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--database',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
spec=importlib.util.spec_from_file_location('report',Path(__file__).resolve().parents[1]/'scripts/report-playtests.py');report=importlib.util.module_from_spec(spec);spec.loader.exec_module(report)
with sqlite3.connect('file:'+str(a.database.resolve())+'?mode=ro',uri=True) as db:
    rows=db.execute('SELECT id,client_id,received,body FROM events ORDER BY received,id').fetchall()
events=[]
for sequence,(event_id,client,received,body) in enumerate(rows,1):
    record=json.loads(body);payload=record['payload'];session=client+':'+payload.get('session_id','unknown')
    # Prefix visits too: absent IDs remain unknown, and installations are not called people.
    visit=client+':'+payload['visit_id'] if payload.get('visit_id') else ''
    events.append(payload | {'schema_version':2,'session_id':session,'sequence':int(payload.get('sequence',sequence)),'visit_id':visit,'source':payload.get('source','unknown'),'mode':payload.get('mode','unknown'),'event':'level_feedback' if record['kind']=='feedback' else payload.get('event','unknown'),'payload':payload|{'visit_id':visit}})
result=report.summarize([{'events':events}]);a.output.mkdir(parents=True,exist_ok=True)
(a.output/'report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
(a.output/'report.html').write_text(report.render(result))
print('Private report written locally. Upload receipt counts do not establish players or retention.')
