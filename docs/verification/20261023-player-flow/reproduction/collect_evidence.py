from pathlib import Path
import json
import shutil

root = Path('E:/VNB/game')
out = root / 'docs/verification/20261023-player-flow'
runs = {
    'baseline': '20261023T101406Z-17a315ad',
    'before-initial-attempt': '20261023-flow-before',
    'before-corrected': '20261023-flow-before-corrected',
    'before-final-fixture': '20261023-flow-before-final-fixture',
    'focused': '20261023T102738Z-73e2219c',
    'final-fixture': '20261023-flow-final-fixture',
    'serial-recheck': '20261023-flow-serial-recheck',
    'gpu': '20261023-flow-gpu',
    'dialog-final': '20261023-flow-dialog-final',
    'gpu-dialog-final': '20261023-flow-gpu-dialog-final',
}
all_results = {}
for label, run in runs.items():
    source = root / '.godot/verification' / run
    target = out / label
    target.mkdir(parents=True, exist_ok=True)
    for path in source.iterdir():
        if path.is_file() and path.suffix in ('.txt', '.json'):
            shutil.copy2(path, target / path.name)
    data = json.loads((source / 'results.json').read_text(encoding='utf-8'))
    all_results[label] = data['results'] if isinstance(data, dict) else data
final_checks = {r['name']: r for r in all_results['focused'] if r['name'].startswith('test_')}
for label in ['final-fixture', 'serial-recheck', 'dialog-final']:
    final_checks.update({r['name']: r for r in all_results[label]})
assert len(final_checks) == 38 and all(r['passed'] for r in final_checks.values())
assert len(all_results['baseline']) == 228
gpu_checks = {r['name']:r for r in all_results['gpu']}
gpu_checks.update({r['name']:r for r in all_results['gpu-dialog-final']})
assert len(gpu_checks) == 3 and all(r['passed'] for r in gpu_checks.values())
baseline_failures = [r for r in all_results['baseline'] if not r['passed']]
assert all(final_checks[r['name']]['passed'] for r in baseline_failures)
for path in (root / '.godot/verification/20261023T102738Z-73e2219c/project/.godot/creation-sample-edit-captures').glob('pending-initial-*.png'):
    shutil.copy2(path, out / path.name)
assert (out / 'pending-initial-zh_CN.png').exists() and (out / 'pending-initial-en.png').exists()
for name in ['reproduce_before.py', 'replay_cases.py', 'collect_flow.py', 'collect_evidence.py',
             'test-chapter-settings-before-fixture-correction.gd', 'test-creation-before-tab-fixture-correction.gd']:
    target = out / 'reproduction'
    target.mkdir(exist_ok=True)
    shutil.copy2(Path('E:/VNB/temp/flow-audit-20261023') / name, target / name)
summary = dict(baseline_stages=228, baseline_test_suites=226,
               baseline_first_attempt_passed=sum(r['passed'] for r in all_results['baseline']),
               baseline_first_attempt_failures=baseline_failures,
               final_runtime_headless_suites=len(final_checks), final_runtime_all_passed=True,
               gpu_suites=3, gpu_all_passed=True, runtime_native_input_acceptance=False,
               runs=runs, final_suite_evidence=final_checks, final_gpu_evidence=gpu_checks)
(out / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ('final_suite_evidence', 'runs')}, indent=2))
