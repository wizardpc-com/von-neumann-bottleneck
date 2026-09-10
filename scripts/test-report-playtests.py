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
