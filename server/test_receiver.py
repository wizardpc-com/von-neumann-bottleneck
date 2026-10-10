#!/usr/bin/env python3
"""Real HTTP + SQLite contract checks; synthetic data only."""
import importlib.util
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import time
import unittest
from urllib.request import Request,urlopen
from urllib.error import HTTPError

class ReceiverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(); cls.db=Path(cls.tmp.name)/'feedback.sqlite'
        cls.process=subprocess.Popen([sys.executable,str(Path(__file__).with_name('feedback_server.py')),'--port','0','--database',str(cls.db)],stdout=subprocess.PIPE,text=True,env=__import__('os').environ|{'VNB_FEEDBACK_ADMIN_TOKEN':'synthetic-admin'})
        cls.url=cls.process.stdout.readline().split(';')[0].split('receiver: ')[1]
    @classmethod
    def tearDownClass(cls):
        cls.process.terminate();cls.process.wait(timeout=5);cls.tmp.cleanup()
    def request(self,method,path,body=None,headers=None):
        req=Request(self.url+path,data=json.dumps(body).encode() if body is not None else None,method=method,headers={'Content-Type':'application/json'}|(headers or {}))
        try:
            with urlopen(req,timeout=5) as response: return response.status,json.load(response)
        except HTTPError as e: return e.code,json.load(e)
    def envelope(self,suffix='a'):
        return {'client_id':'synthetic-client-'+suffix,'deletion_token':'a'*64,'records':[{'event_id':'synthetic-event-'+suffix,'kind':'feedback','payload':{'source':'automated','mode':'test','level_id':'fields','note':'synthetic opinion','fun':4,'clarity':None,'revision':1}}]}
    def test_contract(self):
        a=self.envelope(); self.assertEqual(self.request('POST','/v1/events',a)[0],200)
        a['records'][0]['payload']['fun']=4.0
        self.assertEqual(self.request('POST','/v1/events',a)[0],200,'JSON float roundtrip deduplicates')
        a['records'][0]['payload']['note']='different content'
        self.assertEqual(self.request('POST','/v1/events',a)[0],409)
        b=self.envelope('b');self.assertEqual(self.request('POST','/v1/events',b)[0],200)
        self.assertEqual(self.request('GET','/admin/report')[0],401)
        report=self.request('GET','/admin/report',headers={'Authorization':'Bearer synthetic-admin'})
        self.assertEqual(report[1]['counts']['feedback'],2)
        bad=self.envelope('bad');bad['records'][0]['payload']['circuit']='must not upload'
        self.assertEqual(self.request('POST','/v1/events',bad)[0],400)
        bad=self.envelope('bad');bad['records'][0]['payload']['fun']=0
        self.assertEqual(self.request('POST','/v1/events',bad)[0],400)
        bad=self.envelope('bad');bad['records']*=33
        self.assertEqual(self.request('POST','/v1/events',bad)[0],400)
        bad=self.envelope('bad');bad['records'][0]['payload']['note']='x'*140000
        self.assertEqual(self.request('POST','/v1/events',bad)[0],400)
        deletion={'client_id':a['client_id'],'deletion_token':'b'*64}
        self.assertEqual(self.request('DELETE','/v1/data',deletion)[0],403)
        deletion['deletion_token']='a'*64
        self.assertEqual(self.request('DELETE','/v1/data',deletion)[0],200)
        with sqlite3.connect(self.db) as db:
            self.assertEqual(db.execute('SELECT COUNT(*) FROM events').fetchone()[0],1)
            backup=sqlite3.connect(Path(self.tmp.name)/'backup.sqlite');db.backup(backup);backup.close()
        with sqlite3.connect(Path(self.tmp.name)/'backup.sqlite') as backup:
            self.assertEqual(backup.execute('SELECT client_id FROM events').fetchone()[0],b['client_id'])
    def test_retention(self):
        spec=importlib.util.spec_from_file_location('receiver',Path(__file__).with_name('feedback_server.py'));module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        server=module.Receiver(('127.0.0.1',0),Path(self.tmp.name)/'retention.sqlite','')
        try:
            with server.db:
                server.db.execute('INSERT INTO clients VALUES (?,?)',('expired','token'))
                server.db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',('old','expired',int(time.time())-31*86400,'event','{}','hash'))
            server.last_cleanup=0;server.cleanup()
            self.assertEqual(server.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],0)
            self.assertEqual(server.db.execute('SELECT COUNT(*) FROM clients').fetchone()[0],0)
        finally: server.server_close()
    def test_z_journey_versions_and_atomic_rejection(self):
        from community import CONTENT_MANIFESTS
        from feedback_server import validate_record
        current='tasks-20261010-journey-v1'
        self.assertIn(current,CONTENT_MANIFESTS,'Frozen current journey manifest must be present')
        def summary(task,version):
            chapter,level=task.split('/')
            record={'event_id':'synthetic-summary-'+level,'kind':'event','payload':{
                'source':'automated','mode':'test','event':'visit_summary','chapter_id':chapter,'level_id':level,
                'task_version':version,'visit_id':'synthetic-visit-'+level,'foreground_ms':100,'background_ms':0,
                'feedback_ms':0,'max_hint_stage':0,'completed':False,'completed_on_entry':False,
                'completed_during_visit':False,'build_version':'synthetic-cloud-build','source_commit':'synthetic-commit','test_batch':'synthetic-cloud'}}
            record['payload'].update(CONTENT_MANIFESTS.get(version,{}).get('identities',{}).get(task,{}))
            return record
        for version,manifest in CONTENT_MANIFESTS.items():
            for task in manifest['tasks']: validate_record(summary(task,version))
        picked={task.split('/')[0]:task for task in CONTENT_MANIFESTS[current]['tasks']}
        for domain in ('representation','service','prediction','creation'):
            envelope=self.envelope('journey-'+domain); envelope['records']=[summary(picked[domain],current)]
            self.assertEqual(self.request('POST','/v1/events',envelope)[0],200,domain)
        for category in ('confusion','control','bug','audiovisual','discovery','other'):
            envelope=self.envelope('category-'+category)
            envelope['records'][0]['payload']={'chapter_id':'creation','level_id':'G2_intent','task_version':current,
                'category':category,'source':'automated','mode':'test','build_version':'synthetic-cloud-build'}
            envelope['records'][0]['payload'].update(CONTENT_MANIFESTS[current].get('identities',{}).get('creation/G2_intent',{}))
            self.assertEqual(self.request('POST','/v1/events',envelope)[0],200,category)
        base=self.envelope('atomic-version'); good=summary(picked['creation'],current)
        for version,task,reason in [('unsupported-version',picked['creation'],'unsupported_task_version'),
                                    ('tasks-20260910-v1',picked['creation'],'summary_task'),
                                    ('',picked['creation'],'task_version_required')]:
            bad=summary(task,version); bad['event_id']='synthetic-invalid-'+reason
            base['records']=[good,bad]
            response=self.request('POST','/v1/events',base)
            self.assertEqual(response[0],400); self.assertEqual(response[1]['reason'],reason)
        with sqlite3.connect(self.db) as db:
            self.assertIsNone(db.execute('SELECT id FROM events WHERE client_id=?',(base['client_id'],)).fetchone())
        bad=self.envelope('bad-category');bad['records'][0]['payload']['category']='private-user-text'
        self.assertEqual(self.request('POST','/v1/events',bad)[1]['reason'],'category')
        report=self.request('GET','/admin/report',headers={'Authorization':'Bearer synthetic-admin'})[1]
        self.assertEqual(report['rejections_scope'],'since_process_start')
        self.assertGreaterEqual(report['rejections']['unsupported_task_version'],1)
        for field in ('model_version','case_set_version'):
            if field not in CONTENT_MANIFESTS[current].get('identities',{}).get(picked['creation'],{}): continue
            bad=self.envelope('identity-'+field);bad['records']=[summary(picked['creation'],current)]
            bad['records'][0]['payload'][field]='wrong-version'
            self.assertEqual(self.request('POST','/v1/events',bad)[1]['reason'],field)
if __name__=='__main__':unittest.main(verbosity=2)
