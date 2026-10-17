#!/usr/bin/env python3
"""Synthetic offline export checks; no player data or network required."""
import hashlib
import importlib.util
import json
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import warnings
import zipfile


SCRIPT = Path(__file__).with_name('offline-playtests.py')
TEST_TMP = SCRIPT.resolve().parents[1] / '.godot' / 'offline-import-tests'
TEST_TMP.mkdir(parents=True, exist_ok=True)
spec = importlib.util.spec_from_file_location('offline_playtests', SCRIPT)
offline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(offline)
PNG = bytes.fromhex('89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489'
                    '0000000b49444154789c636000020000050001a5f645400000000049454e44ae426082')


def encoded(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True).encode('utf-8')


def fixture(path, bundle_id='a' * 32, case_id='1' * 32, note='中文 note', revision=1,
            updated='2026-10-17T11:00:00Z', extra=None, manifest_edit=None, case_edit=None, zip_extras=None):
    case = {'id': case_id, 'captured_at_utc': '2026-10-17T10:00:00Z',
            'updated_at_utc': updated, 'category': '卡顿 / Lag', 'note': note,
            'task': {'chapter_id': 'chapter_1', 'level_id': 'selector_4'},
            'screenshot_status': 'captured', 'screenshot_error': '',
            'status': 'reported', 'revision': revision}
    if case_edit:
        case_edit(case)
    prefix = 'cases/' + case_id + '/'
    files = {prefix + 'case.json': encoded(case), prefix + 'context.json': encoded({'scene': '工作台'}),
             prefix + 'screenshot.png': PNG}
    files.update(extra or {})
    manifest = {'format': 'vnb-offline-playtest', 'version': 1, 'bundle_id': bundle_id,
                'created_at_utc': '2026-10-17T12:00:00Z',
                'build': {'version': 'test', 'source_commit': 'f' * 40, 'engine': 'Godot 4.7.1',
                          'platform': 'Windows', 'offline_tester': True},
                'files': [{'path': name, 'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
                          for name, data in files.items()]}
    if manifest_edit:
        manifest_edit(manifest)
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', message='Duplicate name:', category=UserWarning)
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as archive:
            for name, data in files.items():
                archive.writestr(name, data)
            for name, data in zip_extras or []:
                archive.writestr(name, data)
            archive.writestr('manifest.json', encoded(manifest))
    return manifest


class OfflinePlaytestsTests(unittest.TestCase):
    def test_raw_preservation_dedupe_and_conflicting_id(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            first = root / 'first.zip'; fixture(first)
            original = first.read_bytes()
            self.assertEqual(offline.import_bundles([first], library)[0]['status'], 'imported')
            self.assertEqual((library / 'bundles' / ('a' * 32) / 'original.zip').read_bytes(), original)
            with self.assertRaisesRegex(ValueError, 'outside archived bundles'):
                offline.render_report(library, library / 'bundles' / ('a' * 32) / 'original.zip')
            self.assertEqual((library / 'bundles' / ('a' * 32) / 'original.zip').read_bytes(), original)
            self.assertEqual(offline.import_bundles([first], library)[0]['status'], 'deduplicated')
            conflicting = root / 'conflicting.zip'; fixture(conflicting, note='changed')
            with self.assertRaisesRegex(offline.InvalidBundle, 'conflicting bundle_id'):
                offline.import_bundles([conflicting], library)
            self.assertEqual((library / 'bundles' / ('a' * 32) / 'original.zip').read_bytes(), original)

    def test_corruption_traversal_duplicate_manifest_coverage_and_size_limit(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            cases = [
                ('hash', {'manifest_edit': lambda m: m['files'][0].update(sha256='0' * 64)}, 'hash or size mismatch'),
                ('traversal', {'zip_extras': [('../escape.txt', b'escape')]}, 'unsafe ZIP path'),
                ('duplicate', {'zip_extras': [('manifest.json', b'{}')]}, 'duplicate ZIP path'),
                ('unlisted', {'zip_extras': [('extra.txt', b'not manifested')]}, 'manifest does not cover'),
            ]
            symlink = zipfile.ZipInfo('link.txt')
            symlink.create_system = 3
            symlink.external_attr = (stat.S_IFLNK | 0o777) << 16
            cases.append(('symlink', {'zip_extras': [(symlink, b'../target')]}, 'non-regular ZIP entry'))
            for name, kwargs, error in cases:
                path = root / (name + '.zip'); fixture(path, **kwargs)
                with self.subTest(name=name), self.assertRaisesRegex(offline.InvalidBundle, error):
                    offline.import_bundles([path], library)
            oversized = root / 'oversized.zip'; fixture(oversized, extra={'logs/big.txt': b'x' * 40})
            with mock.patch.object(offline, 'MAX_FILE', 32):
                with self.assertRaisesRegex(offline.InvalidBundle, 'file limit'):
                    offline.import_bundles([oversized], library)
            self.assertEqual(list((library / 'bundles').iterdir()), [])
            self.assertFalse((root / 'escape.txt').exists())

    def test_batch_validation_is_all_or_nothing(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            good = root / 'good.zip'; fixture(good)
            bad = root / 'bad.zip'; fixture(bad, bundle_id='b' * 32,
                                          manifest_edit=lambda m: m['files'][1].update(size=999))
            with self.assertRaises(offline.InvalidBundle):
                offline.import_bundles([good, bad], library)
            self.assertEqual(list((library / 'bundles').iterdir()), [])

    def test_large_context_and_godot_compatible_zip_mode(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            source = root / 'source.zip'
            context = encoded({'trace': 'x' * (3 * 1024 * 1024)})
            path = 'cases/' + '1' * 32 + '/context.json'
            fixture(source, extra={path: context})
            godot_style = root / 'godot-style.zip'
            with zipfile.ZipFile(source) as original, zipfile.ZipFile(godot_style, 'w') as copy:
                for name in original.namelist():
                    info = zipfile.ZipInfo(name)
                    info.create_system = 0
                    info.external_attr = 0
                    copy.writestr(info, original.read(name))
            with zipfile.ZipFile(godot_style) as archive:
                self.assertTrue(all((info.external_attr >> 16) & 0o170000 == 0 for info in archive.infolist()))
            self.assertEqual(offline.import_bundles([godot_style], library)[0]['status'], 'imported')
            self.assertEqual((library / 'bundles' / ('a' * 32) / 'files' / path).read_bytes(), context)

    def test_large_materialized_note_matches_producer_limit(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); bundle = root / 'large-note.zip'
            fixture(bundle, note='意见 ' + 'x' * (3 * 1024 * 1024))
            self.assertEqual(offline.import_bundles([bundle], root / 'library')[0]['status'], 'imported')
            case = root / 'library' / 'bundles' / ('a' * 32) / 'files' / 'cases' / ('1' * 32) / 'case.json'
            self.assertGreater(case.stat().st_size, 2 * 1024 * 1024)

    def test_context_and_metadata_shapes_are_checked(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            context_path = 'cases/' + '1' * 32 + '/context.json'
            bad = [
                ('context-list', {'extra': {context_path: encoded(['not an object'])}}, 'invalid case metadata'),
                ('missing-update', {'case_edit': lambda c: c.pop('updated_at_utc')}, 'must be a UTC timestamp'),
                ('missing-error', {'case_edit': lambda c: c.pop('screenshot_error')}, 'invalid case metadata'),
                ('missing-build', {'manifest_edit': lambda m: m['build'].pop('engine')}, 'invalid build identity'),
            ]
            for name, kwargs, error in bad:
                bundle = root / (name + '.zip'); fixture(bundle, **kwargs)
                with self.subTest(name=name), self.assertRaisesRegex(offline.InvalidBundle, error):
                    offline.import_bundles([bundle], library)
            self.assertEqual(list((library / 'bundles').iterdir()), [])

    def test_revisions_multiplayer_html_escaping_and_links(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            first = root / 'first.zip'; fixture(first, note='first <script>alert(1)</script>', revision=1,
                                               extra={'evidence/log.txt': b'private log'})
            second = root / 'second.zip'; fixture(second, bundle_id='b' * 32,
                                                 note='second & final', revision=2,
                                                 updated='2026-10-17T10:30:00Z')
            third = root / 'third.zip'; fixture(third, bundle_id='c' * 32, case_id='2' * 32,
                                               note='other tester', revision=1)
            offline.import_bundles([first, second, third], library)
            report = root / 'review.html'
            result = offline.render_report(library, report)
            page = report.read_text(encoding='utf-8')
            self.assertEqual(result, {'bundles': 3, 'cases': 2, 'revisions': 3, 'capture_errors': 0,
                                      'sessions': 0, 'ignored_session_lines': 0})
            self.assertIn('second &amp; final', page)
            self.assertIn('first &lt;script&gt;alert(1)&lt;/script&gt;', page)
            self.assertNotIn('<script>alert(1)</script>', page)
            self.assertIn('卡顿 / Lag', page)
            self.assertIn('History (1)', page)
            self.assertIn('original.zip', page)
            self.assertIn('context.json', page)
            self.assertIn('screenshot.png', page)
            self.assertIn('analysis/report.html', page)
            self.assertIn('chapter_1/selector_4', page)
            self.assertIn('test · ffffffffffff · Windows', page)
            self.assertNotIn('offline_tester&quot;:true', page)
            self.assertTrue((library / 'bundles' / ('a' * 32) / 'files' / 'evidence' / 'log.txt').exists())
            self.assertLess(page.index('second &amp; final'), page.index('first &lt;script&gt;'))
            cli = subprocess.run([sys.executable, str(SCRIPT), 'report', '--library', str(library),
                                  '--output', str(root / 'cli-report.html')], capture_output=True, text=True, check=True)
            self.assertEqual(json.loads(cli.stdout)['revisions'], 3)
            self.assertTrue((root / 'cli-report.html').is_file())

    def test_archived_sessions_reuse_reducer_and_label_incomplete_logs(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); library = root / 'library'
            def event(sequence, name, visit='', session='s1', source='external_player', build='b1',
                      chapter='chapter_1', level='selector_4', **payload):
                return {'schema_version': 2, 'session_id': session, 'sequence': sequence,
                        'source': source, 'mode': 'game', 'build_version': build,
                        'task_version': 'tasks-v1', 'model_version': 'model-v1',
                        'case_set_version': 'cases-v1', 'visit_id': visit,
                        'event': name, 'payload': {'chapter_id': chapter, 'level_id': level, **payload}}
            first_events = [event(1, 'session_start'), event(2, 'level_start', 'visit-1'),
                            event(3, 'visit_time', 'visit-1', kind='foreground', duration_ms=1200),
                            event(4, 'level_exit', 'visit-1', reason='back'),
                            event(5, 'level_start', 'visit-2')]
            lines = b''.join(encoded(item) + b'\n' for item in first_events)
            raw = lines + b'not-json\n' + encoded({'payload': []}) + b'\n' + encoded(
                event(6, 'visit_time', 'visit-2', kind='foreground', duration_ms='bad')) + b'\n'
            one = root / 'one.zip'; fixture(one, extra={'sessions/session_s1.jsonl': raw})
            two = root / 'two.zip'; fixture(two, bundle_id='b' * 32,
                                          extra={'sessions/session_s1.jsonl': lines})
            second_events = [event(1, 'level_start', 'visit-3', session='s2', source='developer',
                                   build='b2', chapter='chapter_2', level='locality'),
                             event(2, 'visit_summary', 'visit-3', session='s2', source='developer',
                                   build='b2', chapter='chapter_2', level='locality',
                                   foreground_ms=2000, completed=True, reason='complete')]
            three = root / 'three.zip'; fixture(three, bundle_id='c' * 32, case_id='2' * 32,
                                              extra={'sessions/session_s2.jsonl': b''.join(
                                                  encoded(item) + b'\n' for item in second_events)})
            offline.import_bundles([one, two, three], library)
            output = root / 'review.html'
            summary = offline.render_report(library, output)
            analysis = json.loads((root / 'analysis' / 'report.json').read_text(encoding='utf-8'))
            stats = analysis['offline_archive']
            self.assertEqual(summary['sessions'], 2)
            self.assertEqual(stats['session_files'], 3)
            self.assertEqual(stats['duplicate_event_lines'], 5)
            self.assertEqual(stats['invalid_json_lines'], 1)
            self.assertEqual(stats['invalid_event_lines'], 2)
            self.assertEqual(stats['ignored_lines_total'], 8)
            self.assertEqual(stats['incomplete_active_visits'], 1)
            self.assertEqual(stats['unknown_duration_visits'], 1)
            self.assertEqual({row['source'] for row in analysis['tasks']}, {'external_player', 'developer'})
            self.assertEqual({row['build_version'] for row in analysis['tasks']}, {'b1', 'b2'})
            self.assertIsNone(next(row for row in analysis['visits'] if row['visit_id'] == 'visit-2')['foreground_ms'])
            self.assertIn('Incomplete active visits: 1', (root / 'analysis' / 'report.html').read_text(encoding='utf-8'))
            self.assertIn('analysis/report.html', output.read_text(encoding='utf-8'))
            self.assertEqual((library / 'bundles' / ('a' * 32) / 'files' / 'sessions' / 'session_s1.jsonl').read_bytes(), raw)

    def test_cli_rejects_invalid_zip_without_report_or_archive(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as folder:
            root = Path(folder); path = root / 'invalid.zip'
            fixture(path, manifest_edit=lambda m: m.update(format='wrong'))
            result = subprocess.run([sys.executable, str(SCRIPT), 'import', str(path), '--library', str(root / 'lib')],
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('invalid manifest', result.stderr)
            self.assertEqual(list((root / 'lib' / 'bundles').iterdir()), [])


if __name__ == '__main__':
    unittest.main(verbosity=2)
