"""Read-only community views of bounded, client-reported evidence; no replay."""
import hashlib
import json
from pathlib import Path
from statistics import median

RULES=json.loads(Path(__file__).with_name('community_rules.json').read_text())
SCORE_METRICS=['total_cycles','prepare_cycles','query_cycles','output_cycles','ram_read_bytes','ram_write_bytes','peak_extra_bytes']
SCORE_NUMBERS={prefix+'_'+key for prefix in ['a','b'] for key in SCORE_METRICS}
LABEL='Alpha 实验性社区榜单，暂未服务端重放验证'
MIN_SAMPLE=5

def validate_score(p):
    key=p.get('chapter_id','')+'/'+p.get('level_id','')
    rule=RULES['boards'].get(key)
    if not rule or any(p.get(k)!=rule[k] for k in ['ruleset_version','model_version','case_set_version']): raise ValueError('unsupported_score_rules')
    if p.get('sharing_mode')!='score' or p.get('privacy_notice_version')!='2026-09-11' or p.get('consent_version')!='sharing-2': raise ValueError('score_consent')
    if p.get('passed_cases')!=rule['case_count'] or p.get('case_count')!=rule['case_count'] or p.get('passed') is not True: raise ValueError('incomplete_cases')
    if not isinstance(p.get('build_version'),str) or not p['build_version']: raise ValueError('build_required')
    for i,prefix in enumerate(['a','b']):
        m={key:p.get(prefix+'_'+key) for key in SCORE_METRICS}
        if any(type(x) is not int or x<0 or x>10**10 for x in m.values()): raise ValueError('score_numbers')
        if not rule['cycle_floors'][i]<=m['total_cycles']<=rule['cycle_limits'][i]: raise ValueError('score_cycles')
        if m['total_cycles']!=sum(m[k] for k in ['prepare_cycles','query_cycles','output_cycles']): raise ValueError('phase_sum')
        if not 16<=m['ram_read_bytes']<=100000 or m['ram_read_bytes']%16 or m['ram_write_bytes']<4 or m['ram_write_bytes']%4: raise ValueError('traffic')
        if m['peak_extra_bytes']>rule['scratch_limit'] or m['peak_extra_bytes']%4: raise ValueError('space')
    if p.get('total_cycles')!=p['a_total_cycles']+p['b_total_cycles']: raise ValueError('case_sum')
    return p['total_cycles']>=1000 # Very fast plausible rows are held, never called verified.

def aggregate(db, source='external_player', mode='game'):
    groups={}
    for client,body in db.execute("SELECT client_id,body FROM events WHERE kind='event' ORDER BY received,id"):
        p=json.loads(body)['payload']; key=p.get('chapter_id','')+'/'+p.get('level_id','')
        if p.get('source')!=source or p.get('mode')!=mode or p.get('task_version')!=RULES['task_version'] or key not in RULES['tasks']: continue
        if p.get('event')!='visit_summary' or not p.get('visit_id'): continue
        # Distinct visit identities, not event retries or physical edges.
        groups.setdefault(key,{})[(client,p['visit_id'])]=p
    tasks={}
    for key,visits in groups.items():
        people=len({client for client,_ in visits}); rows=list(visits.values()); enough=people>=MIN_SAMPLE
        completed=sum(p.get('completed') is True for p in rows)
        times=[p['foreground_ms'] for p in rows if not p.get('duration_unknown') and type(p.get('foreground_ms')) is int]
        hints={str(i):sum(p.get('max_hint_stage')==i for p in rows) for i in range(4)}
        strategies={s:sum(p.get('strategy')==s for p in rows) for s in ['direct','full','batch','cache','buffer','unknown']}
        tasks[key]={'starts':len(rows),'completions':completed,'sample_installations':people,
            'completion_percent':round(100*completed/len(rows),1) if enough else None,
            'median_foreground_ms':median(times) if enough and times else None,
            'hint_distribution':hints if enough else None,'strategies':strategies if enough else None,'small_sample':not enough}
    return {'api_version':1,'task_version':RULES['task_version'],'source':source,'mode':mode,
            'population':'consenting installations; visits may repeat; not all players', 'minimum_sample':MIN_SAMPLE,'tasks':tasks}

def leaderboard(db,key,rule,source='external_player',mode='game'):
    if key not in RULES['boards'] or any(rule.get(k)!=RULES['boards'][key][k] for k in ['ruleset_version','model_version','case_set_version']): raise ValueError('unsupported_board')
    best={}; held=0
    for client,body in db.execute("SELECT client_id,body FROM events WHERE kind='score'"):
        p=json.loads(body)['payload']
        if p.get('chapter_id','')+'/'+p.get('level_id','')!=key or p.get('source')!=source or p.get('mode')!=mode: continue
        if any(p.get(k)!=rule[k] for k in rule): continue
        try: visible=validate_score(p)
        except ValueError: continue
        if not visible: held+=1; continue
        if client not in best or p['total_cycles']<best[client]['total_cycles']: best[client]=p
    ordered=sorted(best.items(),key=lambda row:(row[1]['total_cycles'],row[0]))[:50]
    rows=[]
    for rank,(client,p) in enumerate(ordered,1):
        # Board-scoped alias, never installation ID, note or a cross-board identifier.
        rows.append({'rank':rank,'player':hashlib.sha256((key+json.dumps(rule,sort_keys=True)+client).encode()).hexdigest()[:10],
            'total_cycles':p['total_cycles'],'ram_read_bytes':p['a_ram_read_bytes']+p['b_ram_read_bytes'],
            'ram_write_bytes':p['a_ram_write_bytes']+p['b_ram_write_bytes'],
            'peak_extra_bytes':max(p['a_peak_extra_bytes'],p['b_peak_extra_bytes'])})
    return {'api_version':1,'label':LABEL,'verified':False,'level_id':key,**rule,'source':source,'mode':mode,'rows':rows,'held_for_review':held}
