#!/usr/bin/env python3
"""Merge voluntary local exports into source-separated task, visit and moment reports."""
import argparse
from collections import Counter, defaultdict
import html
import json
from pathlib import Path
from statistics import median

SOURCES = {'external_player', 'developer', 'agent_native', 'automated', 'unknown'}


def summarize(documents):
    events, duplicates, malformed = {}, 0, 0
    for document in documents:
        session = document.get('session', {})
        for event in document.get('events', []):
            if not isinstance(event, dict) or not isinstance(event.get('payload', {}), dict):
                malformed += 1
                continue
            session_id = event.get('session_id') or session.get('id')
            sequence = event.get('sequence')
            if not session_id or not isinstance(sequence, (int, float)):
                malformed += 1
                continue
            key = (session_id, int(sequence))
            if key in events:
                duplicates += 1
                continue
            copy = dict(event)
            # Old logs must remain unknown, even if merged with newer classified sessions.
            source = copy.get('source', 'unknown') if copy.get('schema_version', 1) >= 2 else 'unknown'
            copy['source'] = source if source in SOURCES else 'unknown'
            copy['session_id'] = session_id
            events[key] = copy
    visits, tasks, moments = {}, {}, []
    legacy_active = {}
    for (_, _), event in sorted(events.items()):
        payload = event.get('payload', {})
        name, source = event.get('event'), event['source']
        mode = event.get('mode', 'unknown')
        task = payload.get('task_key') or '/'.join(str(payload.get(k, '')) for k in ('chapter_id', 'level_id'))
        valid_task = task != '/' and bool(task)
        # Map and gameplay use the same public domain keys.
        task = task.replace('hardware/', 'hardware_foundations/').replace('system/', 'chapter_1/').replace('locality/', 'chapter_2/').replace('overlap/', 'chapter_3/')
        stat = tasks.setdefault((source, mode, task), {'source': source, 'mode': mode, 'task': task, 'sets': defaultdict(set), 'results': Counter(), 'foreground_ms': [], 'runs': 0}) if valid_task else None
        sid = event['session_id']
        visit_id = payload.get('visit_id') or event.get('visit_id')
        if name == 'level_start' and not visit_id:
            visit_id = f"{sid}-legacy-{event['sequence']}"
            legacy_active[sid] = visit_id
        if not visit_id and event.get('schema_version', 1) == 1:
            visit_id = legacy_active.get(sid)
        visit = None
        if visit_id:
            visit = visits.setdefault(visit_id, {'visit_id': visit_id, 'session': sid, 'source': source, 'mode': mode, 'task': task if valid_task else 'unknown', 'started': False, 'completed': False, 'exit': None, 'exit_reason': None, 'foreground_ms': 0, 'background_ms': 0, 'feedback_ms': 0, 'legacy_wall_ms': 0, 'timing': 'unknown', 'runs': [], 'hints': [], 'operations': Counter(), 'quantities': Counter(), 'timeline': [], 'interrupted_gap_unknown': False, 'retries_after_failure': 0, 'post_completion_runs': 0})
            if valid_task and name == 'level_start': visit['task'] = task
            if name not in ('visit_time', 'case_outcome'):
                visit['timeline'].append({'sequence': event['sequence'], 'event': name, 'result': payload.get('result_class'), 'action': payload.get('action'), 'phase': payload.get('phase'), 'kind': payload.get('kind')})
        if name == 'map_action' and stat:
            action = payload.get('action')
            if action == 'viewport_exposure': action = 'exposed'
            if action in ('eligible', 'exposed', 'detail_view', 'task_start'):
                stat['sets'][action].add(sid)
        elif name == 'level_start' and visit:
            visit['started'] = True
            if stat: stat['sets']['started'].add(sid)
        elif name == 'visit_time' and visit:
            kind = payload.get('kind')
            if kind in ('foreground', 'background', 'feedback'):
                visit[kind + '_ms'] += max(0, int(payload.get('duration_ms', 0)))
                visit['timing'] = 'foreground_checkpoints'
        elif name == 'official_run':
            result = payload.get('result_class', 'legacy_unknown')
            if stat:
                stat['runs'] += 1
                stat['results'][result] += 1
                if payload.get('correct', payload.get('passed', False)): stat['sets']['correct_output'].add(sid)
                if payload.get('target_met', False): stat['sets']['target_met'].add(sid)
            if visit:
                previous = visit['runs'][-1] if visit['runs'] else None
                if payload.get('post_completion', False): visit['post_completion_runs'] += 1
                elif previous and previous.get('passed') is False: visit['retries_after_failure'] += 1
                visit['runs'].append({'run_id': payload.get('run_id'), 'sequence': event['sequence'], 'passed': payload.get('passed'), 'result_class': result, 'post_completion': payload.get('post_completion', False), 'case_set_version': event.get('case_set_version', 'unknown'), 'program_digest': payload.get('program_digest'), 'metrics': {key: payload[key] for key in ('cycles', 'cost', 'passed_cases', 'total_cases') if key in payload}, 'cases': []})
        elif name == 'case_outcome' and visit:
            for run in reversed(visit['runs']):
                if run['run_id'] == payload.get('run_id'):
                    run['cases'].append(payload)
                    break
        elif name == 'level_complete':
            if stat: stat['sets']['completed'].add(sid)
            if visit:
                visit['completed'] = True
                if event.get('schema_version', 1) == 1:
                    visit['legacy_wall_ms'] += max(0, int(payload.get('duration_ms', 0)))
                    visit['timing'] = 'legacy_wall_time'
                    legacy_active.pop(sid, None)
        elif name == 'level_exit' and visit:
            visit['exit'] = payload.get('reason', 'unknown')
            visit['interrupted_gap_unknown'] = payload.get('duration_unknown', False)
            if event.get('schema_version', 1) == 1:
                visit['legacy_wall_ms'] += max(0, int(payload.get('duration_ms', 0)))
                visit['timing'] = 'legacy_wall_time'
            legacy_active.pop(sid, None)
        elif name == 'exit_reason' and visit:
            visit['exit_reason'] = payload.get('reason')
        elif name in ('hint_action', 'hint_used') and visit:
            visit['hints'].append({'stage': payload.get('stage'), 'phase': payload.get('phase', 'reveal'), 'sequence': event['sequence']})
        elif name in ('modification', 'player_action') and visit:
            visit['operations'][str(payload.get('action', payload.get('operation', payload.get('target', 'unknown'))))] += 1
            if name=='modification':
                for key in ('added_wires','removed_wires','added_components','removed_components','explicit_wire_deletes','incident_wire_removals'):
                    if type(payload.get(key)) in (int,float) and payload[key]>=0: visit['quantities'][key]+=int(payload[key])
        elif name in ('moment', 'moment_note', 'level_feedback', 'chapter_feedback', 'demo_feedback'):
            moments.append({'source': source, 'mode': mode, 'session': sid, 'visit_id': visit_id, 'sequence': event['sequence'], 'task': task, 'event': name, 'payload': payload})
    for visit in visits.values():
        stat = tasks.get((visit['source'], visit['mode'], visit['task']))
        if stat and visit['timing'] == 'foreground_checkpoints' and visit['started']:
            stat['foreground_ms'].append(visit['foreground_ms'])
    latest_feedback={}
    for item in moments:
        if item['event']=='level_feedback':
            # Unknown visits are still grouped within their session, never called unique people.
            key=(item['source'],item['mode'],item['session'],item['visit_id'],item['task'])
            latest_feedback[key]=item
    output_tasks = []
    for stat in tasks.values():
        sets = stat.pop('sets')
        durations = stat.pop('foreground_ms')
        stat['sessions'] = {key: len(sets.get(key, set())) for key in ('eligible', 'exposed', 'detail_view', 'task_start', 'started', 'correct_output', 'target_met', 'completed')}
        # Numerators use intersections; exposure can happen before eligibility.
        stat['exposed_eligible'] = {'n': len(sets['exposed'] & sets['eligible']), 'N': len(sets['eligible'])}
        stat['started_exposed'] = {'n': len(sets['started'] & sets['exposed']), 'N': len(sets['exposed'])}
        stat['completed_started'] = {'n': len(sets['completed'] & sets['started']), 'N': len(sets['started'])}
        stat['foreground_seconds'] = {'n': len(durations), 'median': round(median(durations)/1000, 2) if durations else None, 'min': min(durations)/1000 if durations else None, 'max': max(durations)/1000 if durations else None}
        opinions=[item for item in latest_feedback.values() if (item['source'],item['mode'],item['task'])==(stat['source'],stat['mode'],stat['task'])]
        stat['ratings']={}
        for key in ('fun','clarity','want_to_continue'):
            values=[item['payload'][key] for item in opinions if type(item['payload'].get(key)) in (int,float) and 1<=item['payload'][key]<=5]
            stat['ratings'][key]={'n':len(values),'N':len(opinions),'median':median(values) if values else None}
        output_tasks.append(stat)
    return {'schema_version': 1, 'input_sessions': len({key[0] for key in events}), 'deduplicated_events': len(events), 'duplicate_events_ignored': duplicates, 'malformed_events_ignored': malformed,
            'limitations': ['Session counts are not unique people. Sources are kept separate; unknown is not human.', 'Visible means drawn in the viewport, not attention. Ratios are observations, not causal funnels.', 'Unfinished visits retain observed time; interruption gaps and legacy foreground time remain unknown.', 'Failure followed by another run is a retry; successful repeats and post-completion runs are separate.', 'No survival estimate or abandonment inference is made from incomplete visits.'],
            'tasks': sorted(output_tasks, key=lambda item: (item['source'], item['mode'], item['task'])), 'visits': list(visits.values()), 'moments': moments, 'latest_task_feedback': list(latest_feedback.values())}


def render(report):
    esc = lambda value: html.escape(str(value))
    sections = []
    for title, key, columns in [('Tasks / routes', 'tasks', ['source','mode','task','sessions','completed_started','foreground_seconds','ratings','results']), ('Visits / attempts', 'visits', ['source','mode','task','completed','exit','exit_reason','foreground_ms','background_ms','feedback_ms','timing','runs','hints','operations','quantities']), ('Moments / feedback', 'moments', ['source','mode','task','visit_id','sequence','event','payload'])]:
        rows = []
        for row in report[key]:
            cells = []
            for column in columns:
                value = row.get(column)
                cells.append('<td><pre>' + esc(json.dumps(value, ensure_ascii=False, indent=2) if isinstance(value, (dict,list)) else value) + '</pre></td>')
            rows.append('<tr data-source="' + esc(row['source']) + '">' + ''.join(cells) + '</tr>')
        sections.append('<h2>' + title + '</h2><div class="scroll"><table><thead><tr>' + ''.join('<th>'+esc(c)+'</th>' for c in columns) + '</tr></thead><tbody>' + ''.join(rows) + '</tbody></table></div>')
    return '<!doctype html><meta charset="utf-8"><title>VNB local playtest report</title><style>body{font:16px system-ui;background:#0e1823;color:#e5edf5;padding:24px}h1{color:#66d6e8}select{padding:8px}.scroll{overflow:auto}table{border-collapse:collapse}td,th{padding:12px;border:1px solid #30455b;vertical-align:top}pre{font:13px ui-monospace;white-space:pre-wrap;min-width:90px;max-width:420px}li{margin:8px}</style><h1>VNB · Local playtest evidence</h1><p>Sessions: ' + str(report['input_sessions']) + ' · Events: ' + str(report['deduplicated_events']) + '</p><ul>' + ''.join('<li>'+esc(x)+'</li>' for x in report['limitations']) + '</ul><label>Source <select id="source"><option value="">All, separate rows</option>' + ''.join('<option>'+x+'</option>' for x in sorted(SOURCES)) + '</select></label>' + ''.join(sections) + '<script>document.querySelector("#source").onchange=e=>document.querySelectorAll("tbody tr").forEach(r=>r.hidden=!!e.target.value&&r.dataset.source!==e.target.value)</script>'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('exports', nargs='+', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    report = summarize([json.loads(path.read_text(encoding='utf-8')) for path in args.exports])
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output/'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    (args.output/'report.html').write_text(render(report), encoding='utf-8')
    print(f"Wrote {args.output / 'report.html'} ({report['input_sessions']} sessions)")

if __name__ == '__main__': main()
