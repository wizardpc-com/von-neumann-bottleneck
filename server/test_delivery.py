"""Real loopback HTTP fault/receipt tests; temporary synthetic SQLite only."""
from contextlib import contextmanager
import json
from pathlib import Path
import sqlite3
import tempfile
import threading
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.request import Request,urlopen
from feedback_server import Receiver
from community import CONTENT_MANIFESTS
from storage import backup,merge


class DeliveryTests(unittest.TestCase):
    @contextmanager
    def receiver(self,path,readonly=False,full=False):
        server=Receiver(('127.0.0.1',0),path,'')
        if readonly:
            server.db.close(); server.db=sqlite3.connect('file:'+str(path)+'?mode=ro',uri=True)
        if full:
            pages=server.db.execute('PRAGMA page_count').fetchone()[0]
            server.db.execute('PRAGMA max_page_count='+str(pages))
        # Serve on the main test thread's SQLite connection via one-request polling.
        server.timeout=3
        try: yield server
        finally: server.server_close()

    def request(self,server,method,body):
        result=[]
        def http():
            request=Request('http://127.0.0.1:'+str(server.server_port)+('/v1/data' if method=='DELETE' else '/v1/events'),
                            data=json.dumps(body).encode(),method=method,headers={'Content-Type':'application/json'})
            try:
                with urlopen(request,timeout=5) as response: result.append((response.status,json.load(response)))
            except HTTPError as error: result.append((error.code,json.load(error)))
        client=threading.Thread(target=http);client.start();server.handle_request();client.join(timeout=6)
        self.assertFalse(client.is_alive());self.assertTrue(result)
        return result[0]

    def envelope(self):
        envelope={'client_id':'synthetic-delivery-client','deletion_token':'a'*64,'records':[{
            'event_id':'synthetic-delivery-feedback','kind':'feedback','payload':{'chapter_id':'creation','level_id':'G2_intent',
            'task_version':'tasks-20261010-journey-v1','build_version':'synthetic-delivery-build','source_commit':'synthetic-commit',
            'test_batch':'synthetic-delivery','source':'automated','mode':'test','category':'bug','note':'Synthetic unfinished task'}}]}
        envelope['records'][0]['payload'].update(CONTENT_MANIFESTS['tasks-20261010-journey-v1'].get('identities',{}).get('creation/G2_intent',{}))
        return envelope

    def test_lost_confirmation_restart_dedup_delete_restore(self):
        with tempfile.TemporaryDirectory() as folder:
            live=Path(folder)/'live.sqlite';old=Path(folder)/'old.sqlite';newest=Path(folder)/'newest.sqlite';restored=Path(folder)/'restored.sqlite'
            envelope=self.envelope();deletion={k:envelope[k] for k in ('client_id','deletion_token')}
            with self.receiver(live) as server:
                first=self.request(server,'POST',envelope)
                self.assertEqual(first,(200,{'ack':['synthetic-delivery-feedback']}))
                # Client did not persist that confirmation; it retries the exact body.
                self.assertEqual(self.request(server,'POST',envelope),first)
                self.assertEqual(server.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],1)
                backup(live,old)
            with self.receiver(live) as server:
                self.assertEqual(self.request(server,'POST',envelope)[0],200)
                self.assertEqual(server.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],1)
                self.assertEqual(self.request(server,'DELETE',deletion),(200,{'deleted':True}))
                self.assertEqual(self.request(server,'POST',envelope)[0],410)
                backup(live,newest)
            backup(old,restored);merge(restored,newest)
            with self.receiver(restored) as server:
                self.assertEqual(self.request(server,'POST',envelope)[0],410)
                self.assertEqual(server.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],0)

    def test_readonly_and_disk_full_do_not_acknowledge(self):
        with tempfile.TemporaryDirectory() as folder:
            for full in (False,True):
                path=Path(folder)/('full.sqlite' if full else 'readonly.sqlite')
                with self.receiver(path,readonly=not full,full=full) as server:
                    envelope=self.envelope()
                    if full:
                        envelope['records']=[dict(envelope['records'][0],event_id='synthetic-full-event-'+str(i),
                            payload=envelope['records'][0]['payload']|{'note':'x'*240}) for i in range(32)]
                    status,body=self.request(server,'POST',envelope)
                    self.assertEqual(status,503);self.assertEqual(body,{'error':'storage_unavailable'})
                    self.assertEqual(server.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],0)
                    self.assertEqual(server.db.execute('SELECT COUNT(*) FROM clients').fetchone()[0],0,'Failed batch transaction is atomic')

    def test_capacity_retry_and_in_batch_identity_conflicts(self):
        with tempfile.TemporaryDirectory() as folder, patch('feedback_server.MAX_EVENTS',1):
            with self.receiver(Path(folder)/'capacity.sqlite') as server:
                envelope=self.envelope();record=envelope['records'][0]
                envelope['records']=[record,record]
                receipt=(200,{'ack':[record['event_id']]})
                self.assertEqual(self.request(server,'POST',envelope),receipt,'Exact in-batch retries consume one slot')
                self.assertEqual(self.request(server,'POST',envelope),receipt,'A full receiver can still confirm committed IDs')
                conflict=dict(record,payload=record['payload']|{'note':'Conflicting synthetic body'})
                envelope['records']=[record,conflict]
                self.assertEqual(self.request(server,'POST',envelope)[0],409,'Same batch conflicting content cannot pick a winner')
                envelope['records']=[conflict]
                self.assertEqual(self.request(server,'POST',envelope)[0],409,'Full receiver still rejects conflicting content')
                envelope['records']=[dict(record,event_id='synthetic-capacity-new-event')]
                self.assertEqual(self.request(server,'POST',envelope),(503,{'error':'storage_limit'}))
                self.assertEqual(server.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],1)


if __name__=='__main__':unittest.main(verbosity=2)
