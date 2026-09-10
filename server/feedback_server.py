#!/usr/bin/env python3
"""Bounded loopback feedback receiver. Public hosting requires a separately approved HTTPS setup."""
import argparse
import hashlib
import hmac
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import math
import os
from pathlib import Path
import re
import sqlite3
import time

TEXT = {'chapter_id':64,'level_id':64,'visit_id':100,'session_id':100,'source':24,'mode':16,
        'build_version':80,'task_version':80,'case_set_version':80,'model_version':80,'event':48,
        'action':64,'operation':64,'result_class':64,'reason':64,'strategy':24,'recipe_digest':64,'run_id':100}
NUMBERS = {'sequence','duration_ms','cycles','cost','case_count','passed_cases','total_cases','added_wires','removed_wires',
           'added_components','removed_components','explicit_wire_deletes','incident_wire_removals',
           'total_cycles','prepare_cycles','query_cycles','output_cycles','ram_read_bytes','ram_write_bytes',
           'peak_extra_bytes','required_extra_bytes','requests','fills','hits','evictions','batch','group_count','block','copy_field_count'}
BOOLS = {'passed','correct','target_met','post_completion','budget_met'}
IDENTIFIER = re.compile(r'^[a-zA-Z0-9_-]{16,100}$')
MAX_BODY = 131072
RETENTION_DAYS = 30


def validate_record(record):
    if not isinstance(record,dict) or set(record) != {'event_id','kind','payload'}:
        raise ValueError('record_fields')
    if not isinstance(record['event_id'],str) or not IDENTIFIER.fullmatch(record['event_id']):
        raise ValueError('event_id')
    if record['kind'] not in ('event','feedback') or not isinstance(record['payload'],dict):
        raise ValueError('kind')
    allowed = set(TEXT) | NUMBERS | BOOLS
    if record['kind'] == 'feedback': allowed |= {'note','fun','clarity','want_to_continue','revision'}
    for key,value in record['payload'].items():
        if key not in allowed: raise ValueError('unknown_field')
        if key in NUMBERS | {'revision','fun','clarity','want_to_continue'} and type(value) is float and math.isfinite(value) and value.is_integer():
            value=int(value); record['payload'][key]=value
        if key in TEXT:
            if not isinstance(value,str) or len(value)>TEXT[key] or any(ord(c)<32 for c in value): raise ValueError('text')
        elif key == 'note':
            if not isinstance(value,str) or len(value)>240: raise ValueError('note')
        elif key in BOOLS:
            if type(value) is not bool: raise ValueError('boolean')
        elif key in ('fun','clarity','want_to_continue'):
            if value is not None and (type(value) is not int or value not in range(1,6)): raise ValueError('rating')
        else:
            if type(value) is not int or not 0<=value<=10**10: raise ValueError('number')
    if record['payload'].get('source','unknown') not in ('unknown','external_player','developer','agent_native','automated'):
        raise ValueError('source')
    if record['payload'].get('mode','game') not in ('game','test','unknown'): raise ValueError('mode')
    if record['kind'] == 'feedback' and not any(record['payload'].get(k) for k in ('note','fun','clarity','want_to_continue')):
        raise ValueError('empty_feedback')
    return record


class Receiver(HTTPServer):
    def __init__(self,address,database,admin_token):
        super().__init__(address,Handler)
        self.admin_token=admin_token
        self.db=sqlite3.connect(database)
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.executescript('''CREATE TABLE IF NOT EXISTS clients (id TEXT PRIMARY KEY, deletion_hash TEXT NOT NULL);
          CREATE TABLE IF NOT EXISTS events (id TEXT PRIMARY KEY, client_id TEXT NOT NULL, received INTEGER NOT NULL,
          kind TEXT NOT NULL, body TEXT NOT NULL, digest TEXT NOT NULL);
          CREATE INDEX IF NOT EXISTS received_idx ON events(received);''')
        self.rates={}
        self.last_cleanup=0
        self.cleanup()
    def cleanup(self):
        now=int(time.time())
        if now-self.last_cleanup<3600: return
        with self.db:
            self.db.execute('DELETE FROM events WHERE received < ?',(now-RETENTION_DAYS*86400,))
            self.db.execute('DELETE FROM clients WHERE id NOT IN (SELECT DISTINCT client_id FROM events)')
        self.rates={k:v for k,v in self.rates.items() if time.monotonic()-v[0]<60}
        self.last_cleanup=now
    def server_close(self):
        if hasattr(self,"db"): self.db.close()
        super().server_close()


class Handler(BaseHTTPRequestHandler):
    # No IP, token, user note, URL query, or request body in access logs.
    def log_message(self,*args): pass
    def setup(self):
        super().setup()
        self.connection.settimeout(5)
    def send(self,status,body):
        raw=json.dumps(body,ensure_ascii=False,separators=(',',':')).encode()
        self.send_response(status)
        self.send_header('Content-Type','application/json; charset=utf-8')
        self.send_header('Content-Length',str(len(raw)))
        self.send_header('Cache-Control','no-store')
        self.send_header('X-Content-Type-Options','nosniff')
        self.end_headers()
        self.wfile.write(raw)
    def body(self):
        length=int(self.headers.get('Content-Length','0'))
        if length<=0 or length>MAX_BODY: raise ValueError('body_size')
        if self.headers.get('Content-Type','').split(';')[0] != 'application/json': raise ValueError('content_type')
        raw=self.rfile.read(length)
        if len(raw)!=length: raise ValueError('short_body')
        value=json.loads(raw,parse_constant=lambda _: (_ for _ in ()).throw(ValueError('nonfinite')))
        if not isinstance(value,dict): raise ValueError('object')
        return value
    def rate_ok(self):
        now=time.monotonic(); key=self.client_address[0]
        if len(self.server.rates)>=1000 and key not in self.server.rates: return False
        start,count=self.server.rates.get(key,(now,0))
        if now-start>=60: start,count=now,0
        self.server.rates[key]=(start,count+1)
        return count<120
    def do_GET(self):
        if self.path == '/health': return self.send(200,{'ok':True,'retention_days':RETENTION_DAYS})
        if self.path != '/admin/report': return self.send(404,{'error':'not_found'})
        token=self.headers.get('Authorization','')
        if not self.server.admin_token or not hmac.compare_digest(token,'Bearer '+self.server.admin_token):
            return self.send(401,{'error':'authentication_required'})
        rows=self.server.db.execute('SELECT kind,COUNT(*) FROM events GROUP BY kind').fetchall()
        return self.send(200,{'counts':dict(rows),'retention_days':RETENTION_DAYS})
    def do_POST(self):
        if self.path != '/v1/events': return self.send(404,{'error':'not_found'})
        if not self.rate_ok(): return self.send(429,{'error':'rate_limit'})
        try:
            body=self.body()
            if set(body) != {'client_id','deletion_token','records'}: raise ValueError('envelope')
            client,token=body['client_id'],body['deletion_token']
            if not isinstance(client,str) or not IDENTIFIER.fullmatch(client): raise ValueError('client')
            if not isinstance(token,str) or not re.fullmatch(r'[0-9a-f]{64}',token): raise ValueError('deletion_token')
            records=body['records']
            if not isinstance(records,list) or not 1<=len(records)<=32: raise ValueError('batch_size')
            records=[validate_record(x) for x in records]
            if len({x['event_id'] for x in records})!=len(records): raise ValueError('duplicate_in_batch')
            self.server.cleanup()
            db=self.server.db
            if db.execute('SELECT COUNT(*) FROM events').fetchone()[0]+len(records)>100000:
                return self.send(503,{'error':'storage_limit'})
            digest=hashlib.sha256(token.encode()).hexdigest()
            prior=db.execute('SELECT deletion_hash FROM clients WHERE id=?',(client,)).fetchone()
            if prior and not hmac.compare_digest(prior[0],digest): return self.send(403,{'error':'client_token'})
            prepared=[]
            for record in records:
                encoded=json.dumps(record,sort_keys=True,separators=(',',':'),ensure_ascii=False)
                record_hash=hashlib.sha256(encoded.encode()).hexdigest()
                old=db.execute('SELECT client_id,digest FROM events WHERE id=?',(record['event_id'],)).fetchone()
                if old and old!=(client,record_hash): return self.send(409,{'error':'id_conflict'})
                prepared.append((record['event_id'],client,int(time.time()),record['kind'],encoded,record_hash))
            with db:
                db.execute('INSERT OR IGNORE INTO clients VALUES (?,?)',(client,digest))
                db.executemany('INSERT OR IGNORE INTO events VALUES (?,?,?,?,?,?)',prepared)
            self.send(200,{'ack':[r['event_id'] for r in records]})
        except (ValueError,TypeError,KeyError,RecursionError,TimeoutError): self.send(400,{'error':'invalid_request'})
        except sqlite3.Error: self.send(503,{'error':'storage_unavailable'})
    def do_DELETE(self):
        if self.path != '/v1/data': return self.send(404,{'error':'not_found'})
        if not self.rate_ok(): return self.send(429,{'error':'rate_limit'})
        try:
            body=self.body();client=body.get('client_id');token=body.get('deletion_token')
            if set(body)!={'client_id','deletion_token'} or not isinstance(client,str) or not isinstance(token,str): raise ValueError()
            row=self.server.db.execute('SELECT deletion_hash FROM clients WHERE id=?',(client,)).fetchone()
            if row and not hmac.compare_digest(row[0],hashlib.sha256(token.encode()).hexdigest()): return self.send(403,{'error':'client_token'})
            with self.server.db:
                self.server.db.execute('DELETE FROM events WHERE client_id=?',(client,))
                self.server.db.execute('DELETE FROM clients WHERE id=?',(client,))
            self.send(200,{'deleted':True})
        except (ValueError,TypeError,TimeoutError): self.send(400,{'error':'invalid_request'})
        except sqlite3.Error: self.send(503,{'error':'storage_unavailable'})


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port',type=int,default=8765)
    parser.add_argument('--database',type=Path,required=True)
    args=parser.parse_args()
    args.database.parent.mkdir(parents=True,exist_ok=True)
    token=os.environ.get('VNB_FEEDBACK_ADMIN_TOKEN','')
    server=Receiver(('127.0.0.1',args.port),args.database,token)
    print(f'Feedback receiver: http://127.0.0.1:{server.server_port}; private report '+('enabled' if token else 'disabled'),flush=True)
    try: server.serve_forever()
    except KeyboardInterrupt: pass
    finally: server.server_close()
if __name__=='__main__': main()
