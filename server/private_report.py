#!/usr/bin/env python3
"""Private local report and ID-linked review notes; no network management API."""
import argparse
from contextlib import closing
import html
import importlib.util
import json
import os
from pathlib import Path
import sqlite3
import time
from community import CONTENT_MANIFESTS

STATUSES={'needs_review','reproduced','needs_information','fixed','needs_retest','deferred'}
IDENTITY_FIELDS=('task_version','model_version','case_set_version','build_version','source_commit','test_batch','source_batch','background_cohort')
OPINION_EVIDENCE_FIELDS=('received','mode','visit_id','content_status','ratings',
                         *(key for key in IDENTITY_FIELDS if key!='test_batch'))


def read_rows(database):
    with closing(sqlite3.connect('file:'+str(Path(database).resolve())+'?mode=ro',uri=True)) as db:
        return db.execute('SELECT id,client_id,received,body FROM events ORDER BY received,id').fetchall()


def open_triage(path):
    path=Path(path); path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    if not path.exists():
        fd=os.open(path,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600); os.close(fd)
    path.chmod(0o600)
    db=sqlite3.connect(path)
    db.execute('CREATE TABLE IF NOT EXISTS actions(event_id TEXT PRIMARY KEY,status TEXT NOT NULL,fix_build TEXT NOT NULL,fix_commit TEXT NOT NULL,note TEXT NOT NULL,updated INTEGER NOT NULL)')
    db.commit()
    return db


def triage_rows(path):
    if path is None or not Path(path).exists(): return {}
    with closing(sqlite3.connect('file:'+str(Path(path).resolve())+'?mode=ro',uri=True)) as db:
        return {r[0]:dict(zip(('status','fix_build','fix_commit','note','updated'),r[1:])) for r in db.execute('SELECT * FROM actions')}


def require_separate_sidecar(database,path):
    if path is None: return
    database,path=Path(database),Path(path)
    if database.resolve()==path.resolve() or (database.exists() and path.exists() and os.path.samefile(database,path)):
        raise ValueError('triage sidecar must be separate from receiving database')


def update_triage(database,path,event_id,status,fix_build='',fix_commit='',note=''):
    require_separate_sidecar(database,path)
    if status not in STATUSES: raise ValueError('unsupported status')
    if any(len(value)>limit or any(ord(c)<32 for c in value) for value,limit in ((fix_build,80),(fix_commit,80),(note,1000))):
        raise ValueError('review field bounds')
    current={row[0] for row in read_rows(database) if json.loads(row[3]).get('kind')=='feedback'}
    if event_id not in current: raise ValueError('feedback ID not present in current database')
    with closing(open_triage(path)) as db, db:
        db.execute('INSERT INTO actions VALUES (?,?,?,?,?,?) ON CONFLICT(event_id) DO UPDATE SET status=excluded.status,fix_build=excluded.fix_build,fix_commit=excluded.fix_commit,note=excluded.note,updated=excluded.updated',
                   (event_id,status,fix_build,fix_commit,note,int(time.time())))


def purge_triage(database,path):
    """Delete review notes for feedback absent from the current deletion-safe database."""
    require_separate_sidecar(database,path)
    current={row[0] for row in read_rows(database) if json.loads(row[3]).get('kind')=='feedback'}
    with closing(open_triage(path)) as db, db:
        stale=[r[0] for r in db.execute('SELECT event_id FROM actions') if r[0] not in current]
        db.executemany('DELETE FROM actions WHERE event_id=?',[(key,) for key in stale])
    return len(stale)


def content_status(payload):
    version=payload.get('task_version')
    if not version: return 'legacy_unknown'
    manifest=CONTENT_MANIFESTS.get(version)
    if manifest is None: return 'unsupported_version'
    task=payload.get('chapter_id','')+'/'+payload.get('level_id','')
    if task not in manifest['tasks']: return 'task_version_mismatch'
    for field,value in manifest.get('identities',{}).get(task,{}).items():
        if payload.get(field)!=value: return field+'_mismatch'
    return 'supported'


def evidence_details(label, values):
    evidence=html.escape(json.dumps(values, ensure_ascii=False, indent=2))
    return f'<details><summary>{label}</summary><pre>{evidence}</pre></details>'


def render_opinions(feedback):
    esc=html.escape
    batches=set()
    statuses={}
    rows=[]
    for row in feedback:
        batch=row['test_batch'] or 'unknown'
        status=row['triage']['status']
        status_label=status.replace('_',' ').capitalize()
        batches.add(batch)
        statuses[status]=status_label

        opinion=f'<pre>{esc(row["note"] or "No written opinion")}</pre>'
        if row['category']:
            opinion+=f'<small>Category · {esc(row["category"])}</small>'

        content=row['content_status']
        task=esc(row['task'] if row['task'].strip('/') else 'Unknown task')
        if content not in ('supported','legacy_unknown'):
            task+=f'<br><strong>Quarantined</strong> · {esc(content)}'
        elif content=='legacy_unknown':
            task+='<br><small>Legacy version unknown</small>'

        review={key:value for key,value in row['triage'].items() if key!='status' and value not in ('', None)}
        triage=esc(status_label)
        if review:
            triage+=evidence_details('Review details',review)

        evidence={key:row[key] for key in OPINION_EVIDENCE_FIELDS}
        if row['test_batch']!=batch:
            evidence['test_batch']=row['test_batch']
        batch_cell=f'{esc(batch)}<br><small>{esc(row["source"])}</small>'
        cells=(opinion,task,triage,batch_cell,f'<pre>{esc(row["event_id"])}</pre>',evidence_details('Technical details',evidence))
        rows.append(f'<tr data-source="{esc(row["source"])}" data-batch="{esc(batch)}" data-triage="{esc(status)}">'
                    + ''.join(f'<td>{cell}</td>' for cell in cells) + '</tr>')

    batches={batch:('Unknown batch' if batch=='unknown' else batch) for batch in batches}
    controls=[]
    for field,label,options in (('batch','Build batch',batches),('triage','Triage status',statuses)):
        choices=''.join(f'<option value="{esc(value)}">{esc(options[value])}</option>' for value in sorted(options))
        controls.append(f'<label for="opinion-{field}">{label}</label> '
                        f'<select id="opinion-{field}"><option value="">All</option>{choices}</select> ')

    columns=('Opinion','Task','Triage','Build batch','Receipt ID','Evidence')
    headings=''.join(f'<th scope="col">{column}</th>' for column in columns)
    total=len(rows)
    return ('<section aria-labelledby="received-opinions-heading">'
            '<h2 id="received-opinions-heading">Received opinions / private review</h2>'
            '<fieldset id="opinion-filters" hidden><legend>Filter received opinions</legend>'
            + ''.join(controls)
            + '<p>These filters also use the report’s <a href="#source">Source</a> selection.</p></fieldset>'
            + f'<p id="opinion-count" role="status">Showing {total} of {total} opinions.</p>'
            + '<div class="scroll"><table id="received-opinions" aria-labelledby="received-opinions-heading" style="overflow-wrap:anywhere">'
            + f'<thead><tr>{headings}</tr></thead><tbody>' + ''.join(rows) + '</tbody></table></div>'
            + '<p>Persistent rejection counts: unknown. Historical unsupported records are quarantined and do not enter task metrics.</p>'
            + '''</section><script>
{
  const source = document.querySelector("#source");
  const batch = document.querySelector("#opinion-batch");
  const triage = document.querySelector("#opinion-triage");
  const rows = document.querySelectorAll("#received-opinions tbody tr");
  const count = document.querySelector("#opinion-count");
  function filterOpinions() {
    let shown = 0;
    rows.forEach(row => {
      const {source: rowSource, batch: rowBatch, triage: rowTriage} = row.dataset;
      const matches = (!source.value || source.value === rowSource)
        && (!batch.value || batch.value === rowBatch)
        && (!triage.value || triage.value === rowTriage);
      row.hidden = !matches;
      if (matches) shown++;
    });
    count.textContent = `Showing ${shown} of ${rows.length} opinions.`;
  }
  const filterBySource = source.onchange;
  source.onchange = event => {
    filterBySource(event);
    filterOpinions();
  };
  batch.onchange = triage.onchange = filterOpinions;
  document.querySelector("#opinion-filters").hidden = false;
  filterOpinions();
}
</script>''')


def build_report(database,triage=None):
    require_separate_sidecar(database,triage)
    spec=importlib.util.spec_from_file_location('report',Path(__file__).resolve().parents[1]/'scripts/report-playtests.py')
    report=importlib.util.module_from_spec(spec); spec.loader.exec_module(report)
    # These release identities are private-report grouping dimensions too.
    report.VERSION_FIELDS=IDENTITY_FIELDS
    actions=triage_rows(triage); events=[]; feedback=[]; quarantined=[]
    for sequence,(event_id,client,received,body) in enumerate(read_rows(database),1):
        record=json.loads(body); payload=record['payload']; session=client+':'+payload.get('session_id','unknown')
        visit=client+':'+payload['visit_id'] if payload.get('visit_id') else ''
        status=content_status(payload)
        item={'event_id':event_id,'received':received,'task':payload.get('chapter_id','')+'/'+payload.get('level_id',''),
              'source':payload.get('source','unknown'),'mode':payload.get('mode','unknown'),'visit_id':visit,'content_status':status,
              **{key:payload.get(key,'unknown') for key in IDENTITY_FIELDS}}
        if record['kind']=='feedback':
            feedback.append(item|{'category':payload.get('category',''),'note':payload.get('note',''),
                'ratings':{key:payload.get(key) for key in ('fun','clarity','want_to_continue')},
                'triage':actions.get(event_id,{'status':'needs_review'})})
        if status not in ('supported','legacy_unknown'):
            quarantined.append(item); continue
        # Stable database IDs decide event identity, not client-carried sequence reuse.
        events.append(payload|{'schema_version':2,'session_id':session,'sequence':sequence,'event_id':event_id,
            'visit_id':visit,'source':payload.get('source','unknown'),'mode':payload.get('mode','unknown'),
            'event':'level_feedback' if record['kind']=='feedback' else payload.get('event','unknown'),'payload':payload|{'visit_id':visit}})
    result=report.summarize([{'events':events}])
    result.update(received_feedback=feedback,quarantined_records=quarantined,
                  rejection_counts=None,rejection_counts_scope='unknown: validation rejections are not stored in SQLite; private /admin/report has process-lifetime counters only')
    result['limitations'].append('Feedback IDs link review notes only while their feedback exists in the current database. Restore must merge newest tombstones before reporting; purge the private triage sidecar after deletion/retention.')
    return result,report.render(result)+render_opinions(feedback)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database',type=Path,required=True); parser.add_argument('--output',type=Path)
    parser.add_argument('--triage',type=Path)
    parser.add_argument('--set-status',nargs=2,metavar=('FEEDBACK_ID','STATUS'))
    parser.add_argument('--fix-build',default=''); parser.add_argument('--fix-commit',default=''); parser.add_argument('--review-note',default='')
    parser.add_argument('--purge-triage',action='store_true'); args=parser.parse_args()
    if (args.set_status or args.purge_triage) and args.triage is None: parser.error('--triage required for review mutations')
    if not args.output and not args.set_status and not args.purge_triage: parser.error('--output or a review action required')
    if args.set_status: update_triage(args.database,args.triage,*args.set_status,args.fix_build,args.fix_commit,args.review_note)
    if args.purge_triage: print('Purged private review records:',purge_triage(args.database,args.triage))
    if args.output:
        result,rendered=build_report(args.database,args.triage); args.output.mkdir(parents=True,exist_ok=True,mode=0o700)
        for name,content in [('report.json',json.dumps(result,ensure_ascii=False,indent=2)),('report.html',rendered)]:
            target=args.output/name
            fd=os.open(target,os.O_CREAT|os.O_TRUNC|os.O_WRONLY,0o600)
            os.fchmod(fd,0o600)
            with os.fdopen(fd,'w',encoding='utf-8') as file: file.write(content)
        print('Private report written locally. Received installations/visits are not all players.')


if __name__=='__main__': main()
