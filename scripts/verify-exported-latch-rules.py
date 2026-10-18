#!/usr/bin/env python3
"""Validate the fixed exported latch PCK with the same-version pinned official editor."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import struct
import subprocess
import sys
import time
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'c84cc9d67b25e6e37eebd19570a9c065f62088ae'
TEST_PATH = 'tests/test_latch_rule_example.gd'
TEST_SHA = 'b0a74fea5494c36646eae948fd72938328e7f9f30086fde1481914be64389eee'
AUDITS_SHA = 'b213d90b6381612e5e6d0dd6195a3a96fc066d11fe5ce348c92b2e58b06b16d7'
CHECKER_SHA = '6b92fb35b8d1b8a0ad4869589c589031424ec11d45db9f05251805e42f68e9a1'
PACK_HELPER_SHA = '3ada696a5718542faca9c40f730a23d37c18055d92f744f01734a4523f60acd7'
TEMPLATE_SHA = '76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07'
TASKS_SHA = 'f5fe865897ea8763b9960d838fbca4f6f3b3e6ced8fd04a22258f0f489fd11f6'
EDITOR_SHA = '323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a'
EDITOR_BYTES = 178997256
MIB = 1024 * 1024


def no_links(path):
    for item in (path, *path.parents):
        if item.exists():
            info = item.lstat()
            assert not item.is_symlink() and not getattr(info, 'st_file_attributes', 0) & 1024, str(item)


def no_project_ancestors(path):
    no_links(path)
    for parent in (path, *path.parents):
        assert not (parent / 'project.godot').exists(), 'Source project fallback: ' + str(parent)
        assert not (parent / 'override.cfg').exists(), 'Unexpected override: ' + str(parent)


def load_pinned(name, digest):
    path = ROOT / 'scripts' / name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, name
    spec = importlib.util.spec_from_file_location(name.replace('-', '_').replace('.', '_'), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def snapshot(folder, audits):
    no_links(folder)
    for path in folder.rglob('*'):
        no_links(path)
        assert path.resolve().is_relative_to(folder.resolve())
    return audits.inventory(folder)


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


def extract_exact(archive, destination, manifest, audits):
    with zipfile.ZipFile(archive) as package:
        entries = package.infolist()
        names = [item.filename for item in entries]
        assert len(names) == len(set(name.casefold() for name in names)), 'Duplicate/case-colliding ZIP member'
        for item in entries:
            name = item.filename
            path = PurePosixPath(name)
            assert '\\' not in name and not path.is_absolute() and path.parts and path.parts[0] == 'Windows'
            assert all(part not in ('.', '..') and ':' not in part for part in path.parts)
            assert name.rstrip('/') == path.as_posix(), 'Noncanonical ZIP path'
            mode = item.external_attr >> 16
            assert stat.S_IFMT(mode) in (0, stat.S_IFREG, stat.S_IFDIR), 'ZIP link or special file'
            assert not item.external_attr & 1024, 'ZIP reparse attribute'
        metadata = json.loads(package.read('Windows/BUILD-MANIFEST.json'))
        assert metadata['source_commit'] == SOURCE and metadata['build_id'] == manifest['build_id']
        assert metadata['engine'] == manifest['engine'] and metadata['platform'] == 'Windows'
        expected = {'Windows/' + name for name in metadata['files_sha256']} | {'Windows/BUILD-MANIFEST.json'}
        assert {item.filename for item in entries if not item.is_dir()} == expected
        files = {}
        directories = set()
        for item in entries:
            target = destination.joinpath(*PurePosixPath(item.filename).parts)
            assert target.resolve().is_relative_to(destination.resolve())
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with package.open(item) as src, target.open('xb') as dst:
                    shutil.copyfileobj(src, dst, 65536)
                relative = target.relative_to(destination / 'Windows').as_posix()
                files[relative] = audits.sha(target)
                if relative != 'BUILD-MANIFEST.json':
                    assert files[relative] == metadata['files_sha256'][relative]
            relative = target.relative_to(destination / 'Windows')
            for parent in ([relative] if item.is_dir() else []) + list(relative.parents):
                if parent.as_posix() != '.':
                    directories.add(parent.as_posix())
    expected_tree = {'files': files, 'directories': sorted(directories)}
    assert snapshot(destination / 'Windows', audits) == expected_tree
    assert not any(name.lower().endswith(('.gd', '.gdc', '.pck')) for name in files), 'Loose source or pack fallback'
    return expected_tree


def extract_embedded_pack(binary, destination, audits, pack):
    size = binary.stat().st_size
    with binary.open('rb') as source:
        assert size >= 20
        source.seek(-12, 2)
        footer = source.read(12)
        length = int.from_bytes(footer[:8], 'little')
        start = size - 12 - length
        assert footer[8:] == b'GDPC' and length >= 4 and start >= 0
        source.seek(start)
        assert source.read(4) == b'GDPC'
        source.seek(start)
        remaining = length
        with destination.open('xb') as target:
            while remaining:
                block = source.read(min(65536, remaining))
                assert block, 'Truncated embedded PCK'
                target.write(block)
                remaining -= len(block)
    digest = audits.sha(destination)
    assert destination.stat().st_size == length and digest == pack.embedded_pck_sha256(binary)
    return {'path': str(destination), 'bytes': length, 'sha256': digest, 'exe_offset': start}


def run_phase(work, stage, binary, editor, pck, pck_identity, test, profile, tester, audits):
    phase = work / stage
    phase.mkdir()
    runtime = phase / 'runtime'
    environment = {}
    for key, name in [('APPDATA', 'appdata'), ('LOCALAPPDATA', 'localappdata'), ('TEMP', 'temp'), ('TMP', 'temp')]:
        folder = runtime / name
        folder.mkdir(parents=True, exist_ok=True)
        environment[key] = str(folder)
    before = snapshot(runtime, audits)
    assert not before['files']
    no_project_ancestors(binary.parent)
    required = 640 if stage == 'gui' else 384
    assert shutil.disk_usage(work).free >= required * MIB, 'Insufficient phase space'
    assert editor.stat().st_size == EDITOR_BYTES and audits.sha(editor) == EDITOR_SHA
    assert pck.stat().st_size == pck_identity['bytes'] and audits.sha(pck) == pck_identity['sha256']
    command = [str(editor), '--main-pack', str(pck)] + (['--headless'] if stage == 'headless' else []) + ['--script', str(test)]
    if stage == 'gui':
        command += ['--', '--capture', '--latch-rule-capture']
    log = phase / 'stdout.log'
    child = None
    reason = ''
    started = time.monotonic()
    try:
        with log.open('wb') as stream:
            child = subprocess.Popen(command, cwd=binary.parent, env=dict(os.environ, **environment),
                                     stdout=stream, stderr=subprocess.STDOUT)
            write_json(phase / 'owned-process.json', {'pid': child.pid, 'command': command, 'environment': environment, 'status': 'RUNNING'})
            while child.poll() is None:
                text = log.read_text(encoding='utf-8', errors='replace')
                free = shutil.disk_usage(work).free
                if 'SCRIPT ERROR:' in text or free < 256 * MIB or time.monotonic() - started > 180:
                    reason = 'script_error' if 'SCRIPT ERROR:' in text else 'disk_space' if free < 256 * MIB else 'timeout'
                    child.terminate()
                    child.wait(timeout=15)
                    break
                time.sleep(.2)
    finally:
        if child is not None and child.poll() is None:
            reason = reason or 'supervisor_exception'
            child.terminate()
            child.wait(timeout=15)
        after = snapshot(runtime, audits)
        text = log.read_text(encoding='utf-8', errors='replace') if log.exists() else ''
        errors = [line for line in text.splitlines() if 'ERROR:' in line or line.startswith('FAIL:')]
        warnings = [line for line in text.splitlines() if 'WARNING:' in line]
        matches = re.findall(r'^PASS: SRLatch isolated five-step handbook \((\d+) checks\)$', text, re.MULTILINE)
        expected_checks = 336 if stage == 'gui' else 258
        editor_after = audits.sha(editor)
        pck_after = audits.sha(pck)
        carrier_unchanged = (editor.stat().st_size == EDITOR_BYTES and editor_after == EDITOR_SHA
                             and pck.stat().st_size == pck_identity['bytes'] and pck_after == pck_identity['sha256'])
        passed = (child is not None and child.returncode == 0 and not reason and not errors
                  and matches == [str(expected_checks)] and carrier_unchanged)
        result = {'stage': stage, 'pid': child.pid if child else None, 'command': command,
                  'environment': environment, 'cwd': str(binary.parent), 'exit': child.returncode if child else None,
                  'terminated_owned_child_reason': reason, 'elapsed_seconds': round(time.monotonic() - started, 3),
                  'log_sha256': audits.sha(log) if log.exists() else None, 'errors': errors, 'warnings': warnings,
                  'reported_checks': int(matches[0]) if len(matches) == 1 else None, 'passed': passed,
                  'runtime_before': before, 'runtime_after': after,
                  'editor_sha256_before': EDITOR_SHA, 'editor_sha256_after': editor_after,
                  'pck_sha256_before': pck_identity['sha256'], 'pck_sha256_after': pck_after,
                  'editor_and_extracted_pck_unchanged': carrier_unchanged}
        write_json(phase / 'owned-process.json', result)
    result['controller_passed'] = passed
    if not passed:
        write_json(phase / 'phase-result.json', result)
        return result
    try:
        user_data = runtime / 'appdata/VonNeumannBottleneckCandidates/representation' / profile
        assert user_data.is_dir(), 'PCK did not use its fixed candidate profile'
        prefix = 'appdata/VonNeumannBottleneckCandidates/'
        allowed = [prefix + domain + '/' + profile + '/' for domain in ('representation', 'service')]
        assert all(not name.startswith(prefix) or any(name.startswith(p) for p in allowed) for name in after['files'])
        main = json.loads((user_data / 'latch-rule-save.json').read_bytes())
        backup = json.loads((user_data / 'latch-rule-save.json.bak').read_bytes())
        assert isinstance(main.pop('saved_at_utc'), str) and isinstance(backup.pop('saved_at_utc'), str)
        assert audits.canonical(main) == audits.canonical(backup), 'Unknown main/backup payload difference'
        assert main['game']['hardware']['completed_levels'] == ['tutorial'] and main['game']['hardware']['designs'] == []
        creation = user_data / 'creation-candidate'
        assert not creation.exists(), 'Unexpected creation/Session/lease state'
        result.update({'profile': profile, 'tester': tester, 'user_data': str(user_data),
                       'main_sha256': audits.sha(user_data / 'latch-rule-save.json'),
                       'backup_sha256': audits.sha(user_data / 'latch-rule-save.json.bak'),
                       'main_backup_typed_equal_except_top_saved_at_utc': True, 'creation_directory_absent': True,
                       'authority_limit': 'Original in-process baseline assertions passed; no serialized pre-browse authority snapshot or existing saved work fixture.'})
        pngs = {name: digest for name, digest in after['files'].items() if name.lower().endswith('.png')}
        if stage == 'gui':
            receipt = user_data / 'latch-rule-captures/receipt.json'
            raw = json.loads(receipt.read_bytes())
            assert raw['checks'] == 336 and raw['failures'] == [] and len(raw['frames']) == 36
            expected = {f'{locale}-{width}-step-{step}.png': (width, height)
                        for locale in ('zh_CN', 'en') for width, height in ((1280, 720), (1920, 1080), (1440, 900))
                        for step in range(1, 6)}
            expected.update({f'{locale}-{width}-rules.png': (width, height)
                             for locale in ('zh_CN', 'en') for width, height in ((1280, 720), (1920, 1080), (1440, 900))})
            assert {Path(row['path']).name for row in raw['frames']} == set(expected)
            suite_pngs = {}
            for row in raw['frames']:
                path = Path(row['path'])
                assert path.resolve().parent == receipt.parent.resolve() and audits.sha(path) == row['sha256']
                with path.open('rb') as file:
                    header = file.read(24)
                assert header[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', header[16:24]) == expected[path.name]
                suite_pngs[path.relative_to(runtime).as_posix()] = row['sha256']
            assert set(suite_pngs) <= set(pngs)
            result.update({'suite_receipt_sha256': audits.sha(receipt), 'suite_pngs_sha256': suite_pngs,
                           'extra_feedback_or_incident_pngs_sha256': {name: digest for name, digest in pngs.items() if name not in suite_pngs},
                           'image_grade': 'Actual exported PCK canonical frames in the same-version official editor; not release-EXE, independently viewed or native OS evidence.'})
        else:
            assert not pngs, 'Headless phase unexpectedly captured images'
    except Exception as exc:
        result['passed'] = False
        result['data_validation_error'] = type(exc).__name__ + ': ' + str(exc)
    write_json(phase / 'phase-result.json', result)
    if result['passed']:
        write_json(phase / 'phase-validation.json', result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--godot', type=Path, required=True, help='Pinned 4.7.1 official main editor executable; console bootstrap is not accepted')
    parser.add_argument('--gui', action='store_true', help='After headless success, run one fresh-data canonical renderer phase')
    args = parser.parse_args()
    audits = load_pinned('verify-night-package.py', AUDITS_SHA)
    pack = load_pinned('verify-package-feedback.py', PACK_HELPER_SHA)
    checker = ROOT / 'scripts/check-candidate-identity.py'
    assert audits.sha(checker) == CHECKER_SHA
    editor = args.godot.absolute()
    no_links(editor)
    editor = editor.resolve()
    assert editor.stat().st_size == EDITOR_BYTES and audits.sha(editor) == EDITOR_SHA
    candidate = args.candidate.absolute()
    no_links(candidate)
    candidate = candidate.resolve()
    assert candidate.parent == ROOT / 'build'
    before = snapshot(candidate, audits)
    manifest = json.loads((candidate / 'manifest.json').read_bytes())
    tester = manifest.get('offline_tester', False)
    assert type(tester) is bool
    batch = 'LatchRulesAccess20261018' if tester else 'LatchRulesExperience20261018'
    profile = 'OfflineTeammate-CreationLinks20261018' if tester else 'CreationLinks20261018'
    identity = 'playtest-' + batch + '-' + SOURCE[:12]
    assert manifest['source_commit'] == SOURCE and manifest['build_id'] == candidate.name == identity
    assert manifest['engine'] == '4.7.1.stable.official.a13da4feb' and manifest['test_batch'] == batch
    for key in ('public_release', 'upload_default', 'external_ready', 'local_acceptance_only'):
        assert manifest[key] is False
    assert manifest['feedback_endpoint'] == '' and set(manifest['platforms']) == {'Windows'}
    assert manifest['windows_template_sha256'] == TEMPLATE_SHA
    assert manifest['content_version'] == 'tasks-20261013-journey-v1'
    assert len(manifest['content_tasks']) == len(set(manifest['content_tasks'])) == 60
    assert hashlib.sha256(audits.canonical(manifest['content_tasks']).encode()).hexdigest() == TASKS_SHA
    assert audits.canonical(manifest['candidate_journey']) == audits.canonical({
        'primary_domain': 'representation', 'profile': profile, 'isolated': True,
        'production_migration': False, 'creation_enabled': True})
    archive = candidate / manifest['platforms']['Windows']['zip']
    assert archive.parent == candidate and archive.stat().st_size == manifest['platforms']['Windows']['bytes']
    assert audits.sha(archive) == manifest['platforms']['Windows']['sha256']
    base = ROOT.parent / 'latch-rule-exported-qa'
    no_project_ancestors(base)
    with zipfile.ZipFile(archive) as package:
        extraction_bytes = sum(item.file_size for item in package.infolist())
        executable_info = package.getinfo('Windows/Von-Neumann-Bottleneck.exe')
        with package.open(executable_info) as member:
            assert executable_info.file_size >= 20
            member.seek(executable_info.file_size - 12)
            footer = member.read(12)
            pck_bytes = int.from_bytes(footer[:8], 'little')
            assert footer[8:] == b'GDPC' and 4 <= pck_bytes <= executable_info.file_size - 12
    assert shutil.disk_usage(ROOT.parent).free >= extraction_bytes + pck_bytes + (640 if args.gui else 384) * MIB
    work = base / uuid.uuid4().hex[:12]
    work.mkdir(parents=True)
    no_project_ancestors(work)
    print('Exported latch PCK / pinned editor QA: ' + str(work), flush=True)
    phases = []
    payload = None
    pck_identity = None
    error = ''
    seed = {'source_commit': SOURCE, 'build_id': identity, 'profile': profile, 'tester': tester,
            'candidate': str(candidate), 'candidate_inventory_before': before,
            'role_evidence': 'Strict manifest role and immutable exported PCK loaded by the pinned editor; the unchanged canonical test reads the PCK role for F8 but does not serialize the role setting.', 'manifest_sha256': audits.sha(candidate / 'manifest.json'),
            'zip_sha256': audits.sha(archive), 'test_sha256': TEST_SHA,
            'editor': {'path': str(editor), 'bytes': EDITOR_BYTES, 'sha256': EDITOR_SHA},
            'release_exe_executed': False, 'supervisor_sha256': audits.sha(Path(__file__)),
            'identity_checker_sha256': CHECKER_SHA, 'audits_sha256': AUDITS_SHA, 'pack_helper_sha256': PACK_HELPER_SHA}
    write_json(work / 'seed.json', seed)
    try:
        with (work / 'identity.log').open('wb') as stream:
            checked = subprocess.run([sys.executable, str(checker), str(candidate)], cwd=ROOT,
                                     stdout=stream, stderr=subprocess.STDOUT, timeout=180)
        assert checked.returncode == 0 and 'PASS:' in (work / 'identity.log').read_text(encoding='utf-8', errors='replace')
        test_bytes = subprocess.check_output(['git', 'show', SOURCE + ':' + TEST_PATH], cwd=ROOT)
        assert hashlib.sha256(test_bytes).hexdigest() == TEST_SHA
        test = work / 'test_latch_rule_example.gd'
        test.write_bytes(test_bytes)
        payload = extract_exact(archive, work / 'unpacked', manifest, audits)
        binary = work / 'unpacked/Windows/Von-Neumann-Bottleneck.exe'
        no_project_ancestors(binary.parent)
        pck = work / 'exported.pck'
        pck_identity = extract_embedded_pack(binary, pck, audits, pack)
        assert pck_identity['bytes'] == pck_bytes
        seed.update({'extracted_pck': pck_identity, 'exe_sha256': audits.sha(binary), 'embedded_pck_sha256': pack.embedded_pck_sha256(binary),
                     'windows_payload_before': payload, 'canonical_test_path': str(test),
                     'identity_log_sha256': audits.sha(work / 'identity.log')})
        write_json(work / 'seed.json', seed)
        for stage in (['headless', 'gui'] if args.gui else ['headless']):
            phase = run_phase(work, stage, binary, editor, pck, pck_identity, test, profile, tester, audits)
            phases.append(phase)
            assert phase['passed'], ('Canonical ' + stage + ' failed: '
                                     + phase.get('data_validation_error', phase['terminated_owned_child_reason']
                                                 or '; '.join(phase['errors']) or 'exit/PASS-count premise')
                                     + '; no retry or later phase')
    except Exception as exc:
        error = type(exc).__name__ + ': ' + str(exc)
    finally:
        candidate_after = snapshot(candidate, audits)
        windows_after = snapshot(work / 'unpacked/Windows', audits) if (work / 'unpacked/Windows').exists() else None
        unchanged = candidate_after == before and (payload is None or windows_after == payload)
        test_unchanged = not (work / 'test_latch_rule_example.gd').exists() or audits.sha(work / 'test_latch_rule_example.gd') == TEST_SHA
        editor_after = audits.sha(editor)
        pck_after = audits.sha(work / 'exported.pck') if (work / 'exported.pck').exists() else None
        carrier_unchanged = (editor_after == EDITOR_SHA and editor.stat().st_size == EDITOR_BYTES
                             and pck_identity is not None and pck_after == pck_identity['sha256']
                             and (work / 'exported.pck').stat().st_size == pck_identity['bytes'])
        passed = not error and unchanged and test_unchanged and carrier_unchanged and len(phases) == (2 if args.gui else 1) and all(row['passed'] for row in phases)
        result = {'passed': passed, 'scope': 'Actual exported PCK canonical latch fixture in the pinned same-version official editor; fresh QA data only, not release-EXE validation, ordinary player progression or native OS.',
                  'seed_sha256': audits.sha(work / 'seed.json'), 'source_commit': SOURCE, 'build_id': identity,
                  'headless_required': True, 'gui_requested': args.gui, 'phases': phases, 'error': error,
                  'candidate_inventory_after': candidate_after, 'windows_payload_after': windows_after,
                  'candidate_and_extracted_package_unchanged': unchanged, 'canonical_test_unchanged': test_unchanged,
                  'editor_sha256_after': editor_after, 'extracted_pck_sha256_after': pck_after,
                  'editor_and_extracted_pck_unchanged': carrier_unchanged, 'release_exe_executed': False}
        write_json(work / 'result.json', result)
        if passed:
            write_json(work / 'validation.json', result)
    print(('PASS: ' if passed else 'FAIL: ') + 'exported PCK / pinned editor canonical latch-rule scope; ' + str(work), flush=True)
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
