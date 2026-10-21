#!/usr/bin/env python3
import importlib.util,os,sys,tempfile,time,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location("verify",Path(__file__).with_name("verify-project.py"))
verify=importlib.util.module_from_spec(spec);spec.loader.exec_module(verify)
class ProcessTests(unittest.TestCase):
    def invoke(self,code,timeout=5):
        with tempfile.TemporaryDirectory() as d:
            log=Path(d)/"test.log";start=time.monotonic()
            status=verify.run_logged_process([sys.executable,'-c',code],dict(os.environ),log,timeout)
            return status,log.read_text(),time.monotonic()-start
    def test_normal(self):
        status,text,elapsed=self.invoke("print('PASS: normal')")
        self.assertEqual(status,0);self.assertIn('PASS:',text)
    def test_script_abort(self):
        status,text,elapsed=self.invoke("import time;print('SCRIPT ERROR: fixture',flush=True);time.sleep(60)")
        self.assertEqual(status,-2);self.assertIn('SCRIPT ERROR:',text);self.assertLess(elapsed,3)
    def test_timeout(self):
        status,text,elapsed=self.invoke("import time;time.sleep(60)",0.2)
        self.assertEqual(status,-1);self.assertLess(elapsed,3)
    def test_nonzero(self):
        status,text,elapsed=self.invoke("import sys;print('FAIL: fixture');sys.exit(7)")
        self.assertEqual(status,7);self.assertIn('FAIL:',text)
if __name__=='__main__':unittest.main()
