"""Synthetic stable receipt identity, private review, escaping and deletion-safe recovery."""
import hashlib
import json
from contextlib import closing
from html.parser import HTMLParser
from pathlib import Path
import shutil
import sqlite3
import subprocess
import tempfile
import unittest
from private_report import build_report, update_triage, purge_triage, triage_rows
from storage import migrate, backup, merge
from community import CONTENT_MANIFESTS


class OpinionMarkup(HTMLParser):
    def __init__(self, rendered):
        super().__init__()
        self.in_opinions=False
        self.rows=[]
        self.other_rows=[]
        self.scripts=[]
        self.script=None
        self.feed(rendered)
        self.close()

    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if tag=='table':
            self.in_opinions=attrs.get('id')=='received-opinions'
        if tag=='tr' and 'data-source' in attrs:
            row={'dataset':{key[5:]:value for key,value in attrs.items() if key.startswith('data-')},
                 'hidden':'hidden' in attrs}
            (self.rows if self.in_opinions else self.other_rows).append(row)
        if tag=='script':
            self.script=''

    def handle_data(self, text):
        if self.script is not None:
            self.script+=text

    def handle_endtag(self, tag):
        if tag=='table':
            self.in_opinions=False
        if tag=='script':
            self.scripts.append(self.script)
            self.script=None


class PrivateReportTests(unittest.TestCase):
    wave_a='PlayerFeedbackPilot-A'
    wave_b='PlayerFeedbackPilot-B"<&'

    def seed(self,path,event_id='synthetic-feedback-id',version='tasks-20261010-journey-v1',build='synthetic-build',note='<script>synthetic()</script>',**context):
        payload={'source':'automated','mode':'test','chapter_id':'creation','level_id':'G2_intent',
            'task_version':version,'build_version':build,'source_commit':'synthetic-commit','test_batch':'synthetic-cloud',
            'model_version':'synthetic-model','case_set_version':'synthetic-cases','session_id':'synthetic-session',
            'visit_id':'synthetic-visit','sequence':1,'category':'confusion','note':note}
        payload.update(CONTENT_MANIFESTS.get(version,{}).get('identities',{}).get('creation/G2_intent',{}))
        payload.update(context)
        body=json.dumps({'event_id':event_id,'kind':'feedback','payload':payload},sort_keys=True,separators=(',',':'))
        with closing(sqlite3.connect(path)) as db, db:
            migrate(db); db.execute('INSERT OR IGNORE INTO clients VALUES (?,?)',('synthetic-client','synthetic-hash'))
            db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',(event_id,'synthetic-client',1,'feedback',body,hashlib.sha256(body.encode()).hexdigest()))

    def wave_report(self):
        folder=tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        db=Path(folder.name)/'events.sqlite'
        side=Path(folder.name)/'review.sqlite'
        player={'source':'external_player','source_batch':'different-consent-batch'}
        self.seed(db,'a-new',note='A synthetic player note',test_batch=self.wave_a,**player)
        self.seed(db,'a-fixed',test_batch=self.wave_a,**player)
        self.seed(db,'b-new',test_batch=self.wave_b,**player)
        self.seed(db,'qa-a',test_batch=self.wave_a,source_batch='QA-consent-batch')
        self.seed(db,'a-quarantine',version='unsupported-synthetic-version',test_batch=self.wave_a,**player)
        self.seed(db,'legacy',version='',note='',test_batch='',source='unknown',chapter_id='',level_id='')
        self.seed(db,'removed-opinion',test_batch='retired-wave')
        update_triage(db,side,'a-fixed','fixed','fixed-build','fixed-sha','Reviewed <synthetic>')
        update_triage(db,side,'a-quarantine','reproduced')
        update_triage(db,side,'removed-opinion','deferred',note='Removed review text')
        with closing(sqlite3.connect(db)) as conn, conn:
            conn.execute('DELETE FROM events WHERE id=?',('removed-opinion',))
        self.assertIn('removed-opinion',triage_rows(side),'The test retains the stale sidecar entry')
        return build_report(db,side)

    def test_same_receipt_task_build_and_private_review(self):
        with tempfile.TemporaryDirectory() as folder:
            db=Path(folder)/'events.sqlite'; side=Path(folder)/'review.sqlite'
            self.seed(db); self.seed(db,'synthetic-feedback-second','tasks-20261010-journey-v1','second-build')
            update_triage(db,side,'synthetic-feedback-id','needs_retest','fix-build','fix-commit','Synthetic reproduction only')
            report,rendered=build_report(db,side)
            self.assertEqual(len(report['moments']),2,'Client sequence reuse cannot hide distinct committed IDs')
            self.assertEqual(len(report['tasks']),2,'Build identities stay separate')
            receipt=next(r for r in report['received_feedback'] if r['event_id']=='synthetic-feedback-id')
            self.assertEqual((receipt['task'],receipt['build_version'],receipt['source_commit'],receipt['test_batch']),
                ('creation/G2_intent','synthetic-build','synthetic-commit','synthetic-cloud'))
            self.assertEqual(receipt['triage']['status'],'needs_retest')
            self.assertEqual(receipt['triage']['fix_commit'],'fix-commit')
            self.assertIn('synthetic-feedback-id',rendered)
            self.assertNotIn('<script>synthetic()',rendered); self.assertIn('&lt;script&gt;',rendered)
            self.assertIsNone(report['rejection_counts'])
            with self.assertRaises(ValueError): update_triage(db,side,'nonexistent-id','fixed')

    def test_unknown_and_mismatched_historical_rows_quarantined(self):
        with tempfile.TemporaryDirectory() as folder:
            db=Path(folder)/'events.sqlite'
            self.seed(db,'unknown-feedback-id','unrecognized-version')
            self.seed(db,'mixed-feedback-id','tasks-20260910-v1')
            self.seed(db,'legacy-feedback-id','')
            report,_=build_report(db)
            self.assertEqual(len(report['received_feedback']),3,'Do not silently discard received historical opinions')
            self.assertEqual(len(report['quarantined_records']),2)
            self.assertEqual({r['content_status'] for r in report['received_feedback']},
                {'unsupported_version','task_version_mismatch','legacy_unknown'})
            self.assertEqual(len(report['moments']),1,'Unknown versions cannot enter supported metrics')

    def test_hostile_stored_receipt_is_rendered_as_text_and_attributes_are_escaped(self):
        with tempfile.TemporaryDirectory() as folder:
            db=Path(folder)/'events.sqlite'
            receipt='receipt"><img src=x onerror="receiptInjected()">'
            batch='batch" onclick="batchInjected()'
            note='</pre><script>noteInjected()</script>'
            self.seed(db, receipt, note=note, test_batch=batch)
            result, rendered=build_report(db)
            self.assertEqual(result['received_feedback'][0]['event_id'], receipt)
            self.assertEqual(result['received_feedback'][0]['note'], note)
            self.assertIn('receipt&quot;&gt;&lt;img', rendered)
            self.assertNotIn('<img', rendered)
            self.assertNotIn('<script>noteInjected()', rendered)
            self.assertIn('data-batch="batch&quot; onclick=&quot;batchInjected()"', rendered)
            markup=OpinionMarkup(rendered)
            self.assertEqual(markup.rows[0]['dataset']['batch'], batch)
            self.assertFalse(any('Injected' in script for script in markup.scripts))

    def test_historical_model_case_mismatch_remains_visible_but_quarantined(self):
        identity=CONTENT_MANIFESTS['tasks-20261010-journey-v1'].get('identities',{}).get('creation/G2_intent',{})
        if not identity: self.skipTest('Authored identity export is not present yet')
        for field in ('model_version','case_set_version'):
            with tempfile.TemporaryDirectory() as folder:
                db=Path(folder)/'events.sqlite';self.seed(db)
                with closing(sqlite3.connect(db)) as connection, connection:
                    row=json.loads(connection.execute('SELECT body FROM events').fetchone()[0])
                    row['payload'][field]='historical-unknown-version';body=json.dumps(row)
                    connection.execute('UPDATE events SET body=?,digest=?',(body,hashlib.sha256(body.encode()).hexdigest()))
                report,_=build_report(db)
                self.assertEqual(report['received_feedback'][0]['content_status'],field+'_mismatch')
                self.assertEqual(len(report['quarantined_records']),1);self.assertEqual(report['moments'],[])

    def test_delete_old_backup_restore_does_not_revive_review(self):
        with tempfile.TemporaryDirectory() as folder:
            live=Path(folder)/'live.sqlite'; old=Path(folder)/'before.sqlite'; newest=Path(folder)/'deleted.sqlite'
            restored=Path(folder)/'restored.sqlite'; side=Path(folder)/'review.sqlite'
            self.seed(live); update_triage(live,side,'synthetic-feedback-id','reproduced',note='Private synthetic review')
            backup(live,old)
            with closing(sqlite3.connect(live)) as db, db:
                db.execute('INSERT INTO tombstones VALUES (?,?,?)',('synthetic-client','synthetic-hash',2))
                db.execute('DELETE FROM events WHERE client_id=?',('synthetic-client',))
                db.execute('DELETE FROM clients WHERE id=?',('synthetic-client',))
            self.assertEqual(build_report(live,side)[0]['received_feedback'],[],'Deleted feedback cannot expose review notes')
            backup(live,newest); backup(old,restored); merge(restored,newest)
            self.assertEqual(build_report(restored,side)[0]['received_feedback'],[],'Newest tombstones win before restored report generation')
            self.assertEqual(purge_triage(restored,side),1); self.assertEqual(triage_rows(side),{})
            merge(restored,old)
            self.assertEqual(build_report(restored,side)[0]['received_feedback'],[])
            self.assertEqual(purge_triage(restored,side),0,'Purge is idempotent')

    def test_triage_cannot_mutate_receiving_database(self):
        with tempfile.TemporaryDirectory() as folder:
            database=Path(folder)/'events.sqlite';self.seed(database)
            alias=Path(folder)/'alias.sqlite'
            try: alias.symlink_to(database)
            except OSError: alias=None  # Windows test environments may disallow links.
            aliases=(database,database.parent/'missing'/'..'/database.name)
            for path in aliases+((alias,) if alias else ()):
                with self.assertRaisesRegex(ValueError,'separate'): update_triage(database,path,'synthetic-feedback-id','fixed')
                with self.assertRaisesRegex(ValueError,'separate'): purge_triage(database,path)
                with self.assertRaisesRegex(ValueError,'separate'): build_report(database,path)
            with closing(sqlite3.connect(database)) as db, db:
                self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0],2)
                self.assertIsNone(db.execute("SELECT name FROM sqlite_master WHERE name='actions'").fetchone())

    def test_opinion_view_puts_review_first_and_keeps_evidence(self):
        result,rendered=self.wave_report()
        section=rendered.split('<section aria-labelledby="received-opinions-heading">')[1]
        headers=['Opinion','Task','Triage','Build batch','Receipt ID','Evidence']
        self.assertEqual(section.count('<th scope="col">'),len(headers))
        self.assertIn(''.join(f'<th scope="col">{field}</th>' for field in headers),section)
        self.assertIn('<label for="opinion-batch">Build batch</label>',section)
        self.assertIn('<label for="opinion-triage">Triage status</label>',section)
        markup=OpinionMarkup(rendered)
        self.assertEqual(len(markup.rows),len(result['received_feedback']))
        self.assertFalse(any(row['hidden'] for row in markup.rows),'The static HTML shows all opinions')
        self.assertIn('<option value="PlayerFeedbackPilot-B&quot;&lt;&amp;">',section)
        self.assertIn(self.wave_b,[row['dataset']['batch'] for row in markup.rows])
        self.assertNotIn('<option value="different-consent-batch">',section)
        self.assertIn('<option value="unknown">Unknown batch</option>',section)
        self.assertIn('No written opinion',section)
        self.assertIn('Unknown task',section)
        self.assertIn('<strong>Quarantined</strong> · unsupported_version',section)
        self.assertIn('Legacy version unknown',section)
        self.assertIn('<summary>Technical details</summary>',section)
        self.assertIn('fixed-sha',section)
        self.assertIn('Reviewed &lt;synthetic&gt;',section)
        self.assertIn('&lt;script&gt;synthetic()&lt;/script&gt;',section)
        for text in ('removed-opinion','retired-wave','Removed review text'):
            self.assertNotIn(text,rendered)
        self.assertEqual([row['event_id'] for row in result['quarantined_records']],['a-quarantine'])

    def test_empty_opinion_view_has_all_options_and_zero_count(self):
        with tempfile.TemporaryDirectory() as folder:
            database=Path(folder)/'empty.sqlite'
            with closing(sqlite3.connect(database)) as conn:
                migrate(conn)
            result,rendered=build_report(database)
        self.assertEqual(result['received_feedback'],[])
        self.assertIn('Showing 0 of 0 opinions.',rendered)
        self.assertEqual(OpinionMarkup(rendered).rows,[])
        for name in ('batch','triage'):
            self.assertIn(f'<select id="opinion-{name}"><option value="">All</option></select>',rendered)

    @unittest.skipUnless(shutil.which('node'),'Local JavaScript runtime unavailable')
    def test_emitted_opinion_filters_intersect_with_source(self):
        result,rendered=self.wave_report()
        markup=OpinionMarkup(rendered)
        for row,opinion in zip(markup.rows,result['received_feedback']):
            row['receipt']=opinion['event_id']
        fixture={'rows':markup.rows,'other':markup.other_rows,'scripts':markup.scripts,
                 'waveA':self.wave_a,'waveB':self.wave_b}
        runner=r'''
const {readFileSync} = require('node:fs');
const {runInNewContext} = require('node:vm');
const {rows, other, scripts, waveA, waveB} = JSON.parse(readFileSync(0, 'utf8'));
const controls = Object.fromEntries(['source','opinion-batch','opinion-triage','opinion-count','opinion-filters']
  .map(id => ['#' + id, {value: '', hidden: true}]));
const document = {
  querySelector: key => controls[key],
  querySelectorAll: key => ({'#received-opinions tbody tr': rows, 'tbody tr': [...other, ...rows]})[key],
};
scripts.forEach(script => runInNewContext(script, {document}));
function change(name, value) {
  const target = controls['#' + name];
  target.value = value;
  target.onchange({target});
}
const snapshots = [];
function record() {
  snapshots.push({visible: rows.filter(row => !row.hidden).map(row => row.receipt),
    count: controls['#opinion-count'].textContent,
    otherSources: [...new Set(other.filter(row => !row.hidden).map(row => row.dataset.source))].sort()});
}
record();
change('opinion-batch', waveA);
change('opinion-triage', 'needs_review');
record();
change('source', 'external_player');
record();
change('opinion-batch', waveB);
record();
change('opinion-triage', 'fixed');
record();
change('source', '');
change('opinion-batch', 'unknown');
change('opinion-triage', '');
record();
change('opinion-batch', '');
record();
console.log(JSON.stringify({snapshots, filtersVisible: !controls['#opinion-filters'].hidden}));
'''
        execution=subprocess.run(['node','-e',runner],input=json.dumps(fixture),text=True,
                                 capture_output=True,check=True)
        actual=json.loads(execution.stdout)
        self.assertTrue(actual['filtersVisible'])
        all_rows=sorted(row['event_id'] for row in result['received_feedback'])
        visible=[all_rows,['a-new','qa-a'],['a-new'],['b-new'],[],['legacy'],all_rows]
        self.assertEqual([state['visible'] for state in actual['snapshots']],visible)
        self.assertEqual([state['count'] for state in actual['snapshots']],
                         [f'Showing {len(rows)} of {len(all_rows)} opinions.' for rows in visible])
        self.assertEqual(actual['snapshots'][3]['otherSources'],['external_player'])
        self.assertEqual(actual['snapshots'][-1]['otherSources'],['automated','external_player','unknown'])


if __name__=='__main__': unittest.main(verbosity=2)
