"""Synthetic stable receipt identity, private review, escaping and deletion-safe recovery."""
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from private_report import build_report, update_triage, purge_triage, triage_rows
from storage import migrate, backup, merge
from community import CONTENT_MANIFESTS


class PrivateReportTests(unittest.TestCase):
    def seed(self,path,event_id='synthetic-feedback-id',version='tasks-20261010-journey-v1',build='synthetic-build',note='<script>synthetic()</script>'):
        payload={'source':'automated','mode':'test','chapter_id':'creation','level_id':'G2_intent',
            'task_version':version,'build_version':build,'source_commit':'synthetic-commit','test_batch':'synthetic-cloud',
            'model_version':'synthetic-model','case_set_version':'synthetic-cases','session_id':'synthetic-session',
            'visit_id':'synthetic-visit','sequence':1,'category':'confusion','note':note}
        payload.update(CONTENT_MANIFESTS.get(version,{}).get('identities',{}).get('creation/G2_intent',{}))
        body=json.dumps({'event_id':event_id,'kind':'feedback','payload':payload},sort_keys=True,separators=(',',':'))
        with sqlite3.connect(path) as db:
            migrate(db); db.execute('INSERT OR IGNORE INTO clients VALUES (?,?)',('synthetic-client','synthetic-hash'))
            db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',(event_id,'synthetic-client',1,'feedback',body,hashlib.sha256(body.encode()).hexdigest()))

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

    def test_historical_model_case_mismatch_remains_visible_but_quarantined(self):
        identity=CONTENT_MANIFESTS['tasks-20261010-journey-v1'].get('identities',{}).get('creation/G2_intent',{})
        if not identity: self.skipTest('Authored identity export is not present yet')
        for field in ('model_version','case_set_version'):
            with tempfile.TemporaryDirectory() as folder:
                db=Path(folder)/'events.sqlite';self.seed(db)
                with sqlite3.connect(db) as connection:
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
            with sqlite3.connect(live) as db:
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
            alias=Path(folder)/'alias.sqlite';alias.symlink_to(database)
            for path in (database,alias):
                with self.assertRaisesRegex(ValueError,'separate'): update_triage(database,path,'synthetic-feedback-id','fixed')
                with self.assertRaisesRegex(ValueError,'separate'): purge_triage(database,path)
                with self.assertRaisesRegex(ValueError,'separate'): build_report(database,path)
            with sqlite3.connect(database) as db:
                self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0],2)
                self.assertIsNone(db.execute("SELECT name FROM sqlite_master WHERE name='actions'").fetchone())


if __name__=='__main__': unittest.main(verbosity=2)
