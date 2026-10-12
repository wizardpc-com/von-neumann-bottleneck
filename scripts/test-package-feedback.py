#!/usr/bin/env python3
"""Portable package-layout and private-report smoke checks; no Godot process."""
from contextlib import closing
import hashlib
import importlib.util
import json
from pathlib import Path
import plistlib
import sqlite3
import subprocess
import sys
import tempfile
import unittest


ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location('package_feedback',ROOT/'scripts/verify-package-feedback.py')
VERIFIER=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFIER)
sys.path.insert(0,str(ROOT/'server'))
from storage import migrate


class PackageFeedbackTests(unittest.TestCase):
    def setUp(self):
        temporary=ROOT/'.godot/package-feedback-unit'
        temporary.mkdir(parents=True,exist_ok=True)
        self.workspace=tempfile.TemporaryDirectory(dir=temporary)
        self.addCleanup(self.workspace.cleanup)
        self.output=Path(self.workspace.name)/'candidate'

    def fixture(self,platform,external_pack=False):
        folder=self.output/platform
        folder.mkdir(parents=True)
        if platform=='Windows':
            original=folder/'Von-Neumann-Bottleneck.exe'
            pack=original.with_suffix('.pck')
            if external_pack:
                original.write_bytes(b'windows executable');pack.write_bytes(b'GDPCwindows pack')
            else:
                payload=b'GDPCembedded windows pack'
                original.write_bytes(b'MZwindows executable'+payload+len(payload).to_bytes(8,'little')+b'GDPC')
        else:
            original=folder/'Von-Neumann-Bottleneck.app'
            binary=original/'Contents/MacOS/game'
            pack=original/'Contents/Resources/game.pck'
            binary.parent.mkdir(parents=True);pack.parent.mkdir(parents=True)
            (original/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'game'}))
            binary.write_bytes(b'mac executable');pack.write_bytes(b'mac pack')
        files={p.relative_to(folder).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
               for p in ((original,pack) if platform=='Windows' and external_pack else
                         (original,) if platform=='Windows' else (binary,pack))}
        identity={'build_id':'synthetic-build','source_commit':'a'*40,'engine':'4.7.1.stable.test'}
        (folder/'BUILD-MANIFEST.json').write_text(json.dumps(identity|{'platform':platform,'files_sha256':files}))
        (self.output/'manifest.json').write_text(json.dumps(identity|{'platforms':{platform:{}}}))
        return original,pack

    def test_windows_and_mac_pack_hashes_match_manifests(self):
        for platform in ('Windows','macOS'):
            with self.subTest(platform=platform):
                original,pack=self.fixture(platform)
                manifest,package,binary,hashes,embedded=VERIFIER.prepare_package(original,platform,Path(self.workspace.name)/('qa-'+platform))
                self.assertEqual(manifest['build_id'],'synthetic-build')
                self.assertEqual(len(hashes),1 if platform=='Windows' else 2)
                self.assertTrue(binary.is_file())
                self.assertTrue(package.is_dir())
                if platform=='Windows':
                    self.assertIsNotNone(embedded)
                    original.write_bytes(original.read_bytes().replace(b'MZwindows',b'MZtampered'))
                else:
                    self.assertIsNone(embedded)
                    pack.write_bytes(b'tampered pack')
                with self.assertRaisesRegex(ValueError,'hash mismatch'):
                    VERIFIER.prepare_package(original,platform,Path(self.workspace.name)/('bad-'+platform))

    def test_windows_external_pack_and_missing_embedded_pack(self):
        original,pack=self.fixture('Windows',external_pack=True)
        _,_,_,hashes,embedded=VERIFIER.prepare_package(original,'Windows',Path(self.workspace.name)/'qa-external')
        self.assertEqual(len(hashes),2);self.assertIsNone(embedded)
        pack.unlink()
        with self.assertRaisesRegex(ValueError,'missing embedded PCK'):
            VERIFIER.prepare_package(original,'Windows',Path(self.workspace.name)/'bad-external')

    def test_package_arguments_are_exclusive(self):
        result=subprocess.run([sys.executable,str(ROOT/'scripts/verify-package-feedback.py'),
                               '--app','unused.app','--exe','unused.exe'],capture_output=True)
        self.assertEqual(result.returncode,2)

    def test_private_report_cli_writes_files_on_this_platform(self):
        database=Path(self.workspace.name)/'events.sqlite'
        output=Path(self.workspace.name)/'private-report'
        sidecar=Path(self.workspace.name)/'triage.sqlite'
        event_id='synthetic-package-feedback'
        body=json.dumps({'event_id':event_id,'kind':'feedback','payload':{
            'chapter_id':'creation','level_id':'G2_intent','task_version':'',
            'source':'automated','mode':'test','session_id':'synthetic-session',
            'visit_id':'synthetic-visit','note':'Synthetic private report test'}})
        with closing(sqlite3.connect(database)) as db, db:
            migrate(db)
            db.execute('INSERT INTO clients VALUES (?,?)',('synthetic-client','synthetic-hash'))
            db.execute('INSERT INTO events VALUES (?,?,?,?,?,?)',
                       (event_id,'synthetic-client',1,'feedback',body,hashlib.sha256(body.encode()).hexdigest()))
        command=[sys.executable,str(ROOT/'server/private_report.py'),'--database',str(database),'--triage',str(sidecar)]
        subprocess.run(command+['--set-status',event_id,'needs_review'],check=True,capture_output=True)
        subprocess.run(command+['--output',str(output)],check=True,capture_output=True)
        self.assertEqual(json.loads((output/'report.json').read_text())['received_feedback'][0]['event_id'],event_id)
        self.assertTrue((output/'report.html').is_file())


if __name__=='__main__': unittest.main(verbosity=2)
