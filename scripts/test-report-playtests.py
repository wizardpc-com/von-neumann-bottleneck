#!/usr/bin/env python3
import importlib.util
from pathlib import Path
spec=importlib.util.spec_from_file_location('report',Path(__file__).with_name('report-playtests.py'));r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
events=[]
def event(name,**payload):
 events.append({'schema_version':2,'session_id':'synthetic','sequence':len(events)+1,'visit_id':'visit-a','source':'automated','mode':'test','event':name,'payload':{'chapter_id':'hardware_foundations','level_id':'tutorial'}|payload})
event('level_start');event('modification',operation='branch',added_wires=3,removed_wires=1,explicit_wire_deletes=0)
event('modification',operation='delete_component',removed_components=1,removed_wires=2,incident_wire_removals=2)
event('player_action',action='undo');event('player_action',action='debug_run')
event('official_run',run_id='r1',passed=True,case_count=32)
for index in range(32):event('case_outcome',run_id='r1',index=index,passed=True)
event('level_feedback',fun=2,clarity=None,want_to_continue=None,revision=1)
event('level_feedback',fun=4,clarity=None,want_to_continue=3,revision=2)
report=r.summarize([{'events':events},{'events':events}]);visit=report['visits'][0];task=report['tasks'][0]
assert report['duplicate_events_ignored']==len(events)
assert visit['operations']['branch']==1 and visit['operations']['undo']==1
assert visit['quantities']['removed_components']==1 and visit['quantities']['incident_wire_removals']==2
assert visit['quantities']['explicit_wire_deletes']==0
assert len(visit['runs'])==1 and len(visit['runs'][0]['cases'])==32
assert task['ratings']['fun']=={'n':1,'N':1,'median':4} and task['ratings']['clarity']['n']==0
assert len(report['moments'])==2 and len(report['latest_task_feedback'])==1
print('PASS: transaction quantities, debug/run/cases, duplicate exports, revised opinions and missing scores')
base={'schema_version':2,'session_id':'basic','source':'external_player','mode':'game','visit_id':'one','task_version':'t1','model_version':'m1','case_set_version':'c1','build_version':'b1'}
summary={'event':'visit_summary','sequence':4,**base,'payload':{'chapter_id':'chapter_4','level_id':'mixed','foreground_ms':120000,'connections':7,'wire_deletes':2,'component_deletes':1,'debug_runs':3,'official_runs':2,'completed':True,'completed_on_entry':False,'completed_during_visit':True,'post_completion':False}}
result=r.summarize([{'events':[summary]}]);v=result['visits'][0];t=result['tasks'][0]
assert v['foreground_ms']==120000 and t['foreground_seconds']['median']==120
assert v['semantic_counters']['connections']==7 and v['semantic_counters']['wire_deletes']==2 and v['semantic_counters']['component_deletes']==1
assert v['semantic_counters']['debug_runs']==3 and t['runs']==2 and not v['runs'] and not v['timeline']
assert v['semantic_counters']['branches'] is None and v['background_ms'] is None
mixed=[{**base,'sequence':1,'event':'level_start','payload':{'chapter_id':'chapter_4','level_id':'mixed','completed':False}}, {**base,'sequence':2,'event':'visit_time','payload':{'chapter_id':'chapter_4','level_id':'mixed','kind':'foreground','duration_ms':120000}}, {**base,'sequence':3,'event':'official_run','payload':{'chapter_id':'chapter_4','level_id':'mixed','passed':True}},summary]
m=r.summarize([{'events':mixed}]);assert m['tasks'][0]['runs']==2 and m['tasks'][0]['foreground_seconds']['median']==120
for key in r.VERSION_FIELDS:
 other={**summary,key:'different','sequence':9,'visit_id':'two'}
 assert len(r.summarize([{'events':[summary,other]}])['tasks'])==2,key
old={**summary,'payload':{k:v for k,v in summary['payload'].items() if k not in ['completed_on_entry','completed_during_visit','post_completion']}}
o=r.summarize([{'events':[old]}]);assert o['visits'][0]['completed_during_visit'] is None and o['tasks'][0]['completed_started']['n']==0
print('PASS: basic summary totals, mixed-detail deduplication, unknown fields and version/cohort separation')
# One visit can learn its formal case identity later; checkpoints inherit only an unambiguous identity.
late=[{**row, 'case_set_version': ('c1' if row['event']=='official_run' else 'unspecified')} for row in mixed]
joined=r.summarize([{'events':late}]);assert len(joined['tasks'])==1 and joined['tasks'][0]['foreground_seconds']['median']==120
assert r.summarize([{'events':[{**base,'sequence':float('inf'),'event':'bad'}]}])['malformed_events_ignored']==1
print('PASS: late visit version attribution and malformed sequence isolation')
