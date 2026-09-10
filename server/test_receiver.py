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
if __name__=='__main__':unittest.main(verbosity=2)
