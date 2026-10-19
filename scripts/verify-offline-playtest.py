#!/usr/bin/env python3
"""Verify an unchanged Windows offline tester export with isolated synthetic data."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import uuid


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    original = args.exe.resolve()
    manifest = json.loads((original.parent.parent / 'manifest.json').read_text(encoding='utf-8'))
    if not manifest.get('offline_tester') or manifest.get('feedback_endpoint'):
        parser.error('requires a frozen offline tester candidate with no receiver')
    stamp = uuid.uuid4().hex[:12]
    work = root / '.godot/offline-package' / stamp
    work.mkdir(parents=True)
    existing = module('package_feedback', root / 'scripts/verify-package-feedback.py')
    _, _, binary, hashes, embedded = existing.prepare_package(original, 'Windows', work)
    tool_relative = 'feedback-tools/offline-playtests.py'
    collector = binary.parent / tool_relative
    source_collector = original.parent / tool_relative
    build_manifest_path = original.parent / 'BUILD-MANIFEST.json'
    build_manifest_bytes = build_manifest_path.read_bytes()
    build_manifest = json.loads(build_manifest_bytes)
    assert build_manifest['source_commit'] == manifest['source_commit']
    collector_sha256 = hashlib.sha256(collector.read_bytes()).hexdigest()
    assert collector_sha256 == hashlib.sha256(source_collector.read_bytes()).hexdigest()
    assert collector_sha256 == build_manifest['files_sha256'][tool_relative]
    offline = module('offline_playtests', collector)
    probe = work / 'probe.gd'
    shutil.copy2(root / 'scripts/offline-playtest-probe.gd', probe)
    scene = work / 'probe.tscn'
    existing.write_probe_scene(scene, probe)
    profile = 'OfflinePlaytestQA-' + stamp
    runtime = work / 'runtime'
    runtime.mkdir()
    env = dict(os.environ, APPDATA=str(runtime), LOCALAPPDATA=str(runtime))
    override = binary.parent / 'override.cfg'
    reports = {}
    print('Isolated exported-package evidence: ' + str(work), flush=True)
    try:
        for phase in ('capture', 'reopen'):
            override.write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='
                                + json.dumps('VonNeumannBottleneckCandidates/representation/' + profile)
                                + '\nrun/main_scene=' + json.dumps(scene.as_posix(), ensure_ascii=False)
                                + '\n[candidate]\nprofile=' + json.dumps(profile)
                                + '\n[display]\nwindow/size/mode=0\nwindow/size/window_width_override=1280'
                                  '\nwindow/size/window_height_override=720\n[qa_offline]\nphase=' + json.dumps(phase)
                                + '\noutput=' + json.dumps(work.as_posix(), ensure_ascii=False) + '\n', encoding='utf-8')
            with (work / (phase + '.log')).open('wb') as stream:
                result = subprocess.run([str(binary), '--log-file', str(work / (phase + '-engine.log')), '--', '--playtest-source=automated'],
                                        cwd=binary.parent, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=180)
            log = (work / (phase + '.log')).read_text(encoding='utf-8', errors='replace')
            if result.returncode or 'ERROR:' in log or 'PASS: offline playtest ' + phase not in log:
                raise RuntimeError(phase + ' failed; inspect ' + str(work))
            reports[phase] = json.loads((work / (phase + '.json')).read_text(encoding='utf-8'))
            print(phase + ': PASS', flush=True)
    finally:
        override.unlink(missing_ok=True)
    library = work / 'library'
    imported = offline.import_bundles([work / 'captured.zip', work / 'reopened.zip'], library)
    repeated = offline.import_bundles([work / 'captured.zip'], library)
    report = offline.render_report(library, library / 'review.html')
    assert report['cases'] == 4 and report['capture_errors'] == 0
    assert repeated[0]['status'] == 'deduplicated'
    records, _ = offline.library_records(library)
    assert all(item['case']['screenshot_status'] == 'captured' for item in records)
    final_library = work / 'final-export-only'
    offline.import_bundles([work / 'reopened.zip'], final_library)
    final_report = offline.render_report(final_library, final_library / 'review.html')
    final_records, _ = offline.library_records(final_library)
    assert final_report['cases'] == 4 and final_report['sessions'] == 2
    assert sum('SYNTHETIC offline acceptance' in item['case']['note'] for item in final_records) == 3
    assert sum('SYNTHETIC second play session' in item['case']['note'] for item in final_records) == 1
    domains = {'hardware_foundations': 'hardware', 'chapter_1': 'system', 'creation': 'creation', 'service': 'service'}
    for item in final_records:
        incident = item['case']
        context_path = item['folder'] / 'files/cases' / incident['id'] / 'context.json'
        context = json.loads(context_path.read_text(encoding='utf-8'))
        assert context['build']['source_commit'] == manifest['source_commit']
        assert context['active_domain']['kind'] == domains[incident['task']['chapter_id']]
        assert context['active_domain']['state'] and context['progress']['game']
    assert hashlib.sha256(collector.read_bytes()).hexdigest() == collector_sha256
    assert hashlib.sha256(source_collector.read_bytes()).hexdigest() == collector_sha256
    assert build_manifest_path.read_bytes() == build_manifest_bytes
    receipt = {'source_commit': manifest['source_commit'], 'build_id': manifest['build_id'],
               'bundled_collector': {'path': tool_relative, 'sha256': collector_sha256,
                                     'build_manifest_sha256': hashlib.sha256(build_manifest_bytes).hexdigest()},
               'binary_hashes': hashes, 'embedded_pack_sha256': embedded, 'phases': reports,
               'imports': imported, 'dedup': repeated, 'report': report, 'final_export_alone': final_report,
               'evidence_grade': 'rendered unchanged exported binary with synthetic controller; native input separate'}
    (work / 'receipt.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2), encoding='utf-8')
    print('PASS: exported offline capture/restart/ZIP/import/report ' + str(work), flush=True)


if __name__ == '__main__':
    main()
