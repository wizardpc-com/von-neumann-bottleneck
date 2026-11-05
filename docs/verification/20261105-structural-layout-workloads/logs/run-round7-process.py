"""Actual v1/v2 restart, source/destination writer recovery and old-runtime rollback."""
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

root = Path(__file__).resolve().parents[2]
current = root / ".godot/verification/20261105T051242Z-1f038f6c/project"
legacy = root / ".godot/verification/20261105T033350Z-75462610/project"
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
output = root / "docs/verification/20261105-structural-layout-workloads/process" / stamp
output.mkdir(parents=True)
profile = "VonNeumannBottleneckChecks/layout_strategy/structure-upgrade-process-" + stamp
data = Path("/Users/yrq/Library/Application Support") / profile
assert not data.exists()
settings = {p: (p / "project.godot").read_bytes() for p in [current, legacy]}
engine = "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot"
base = "e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8"
script = "tests/recovery/layout_structure_process_probe.gd"
source_settings = (root / "project.godot").read_text()
spec = importlib.util.spec_from_file_location("verifier", root / "scripts/verify-project.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
results = []
held = None
held_stream = None
held_command = None
bindings = {}


def configure(project, selected_profile):
    text = source_settings.replace(
        "[application]\n",
        "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="
        + json.dumps(selected_profile) + "\n", 1)
    (project / "project.godot").write_text(text)


def command(project, phase):
    return [engine, "--headless", "--path", str(project), "--script",
            "res://" + script, "--", "--structure-phase=" + phase]


def run(project, phase, selected_profile=profile):
    repeat = sum(item["phase"] == phase for item in results)
    log = output / (phase + ("-" + str(repeat + 1) if repeat else "") + ".log")
    args = command(project, phase)
    code = verifier.run_logged_process(args, dict(os.environ), log, 60)
    text = log.read_text(errors="replace")
    passed = code == 0 and "PASS:" in text and "ERROR:" not in text and "FAIL:" not in text
    results.append(dict(phase=phase, code=code, passed=passed,
                        runtime="legacy-e1e27db" if project == legacy else "current",
                        profile=selected_profile, command=args, log=log.name))
    print(phase + ": " + ("PASS" if passed else "FAIL"), flush=True)
    if not passed:
        raise RuntimeError(text)


def hold(project, phase):
    global held, held_stream, held_command
    marker_path = data / "structure-writer-ready.json"
    if marker_path.exists():
        marker_path.unlink()
    held_command = command(project, phase)
    held_stream = (output / (phase + ".log")).open("wb")
    held = subprocess.Popen(held_command, stdout=held_stream, stderr=subprocess.STDOUT)
    deadline = time.monotonic() + 20
    while not marker_path.exists() and held.poll() is None and time.monotonic() < deadline:
        time.sleep(0.1)
    assert marker_path.exists() and held.poll() is None, "writer did not acquire lease"
    marker = json.loads(marker_path.read_text())
    assert marker["pid"] == held.pid
    actual = subprocess.check_output(["ps", "-p", str(held.pid), "-o", "command="], text=True).strip()
    assert str(project) in actual and "--structure-phase=" + phase in actual
    print(phase + ": live owned lease acquired", flush=True)


def stop_owned(phase):
    global held, held_stream
    assert held is not None and held.poll() is None
    pid = held.pid
    held.kill()
    code = held.wait(timeout=10)
    results.append(dict(phase=phase + "-owned-crash", code=code, passed=code == -9,
                        pid=pid, profile=profile, command=held_command,
                        log=phase + ".log", intent="deliberate SIGKILL after live-owner rejection"))
    assert code == -9
    held = None
    held_stream.close()
    held_stream = None


try:
    # Freeze the entire old runtime code against its actual commit before reuse.
    names = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", base,
                                     "experiments", "src", "autoloads"], cwd=root, text=True).splitlines()
    for name in names:
        if not name.endswith((".gd", ".tscn", ".tres", ".gdshader")):
            continue
        expected = subprocess.check_output(["git", "show", base + ":" + name], cwd=root)
        actual = (legacy / name).read_bytes()
        assert actual == expected, "Frozen rollback source changed: " + name
        bindings[name] = hashlib.sha256(actual).hexdigest()
    assert len(bindings) > 100
    for project in [current, legacy]:
        target = project / script
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / script, target)
        configure(project, profile)
    fixture = json.loads((root / "tests/fixtures/layout_strategy/legacy-scheduling-v1.json").read_text())
    data.mkdir(parents=True)
    old_book = data / "layout_strategy_notebook_v1.json"
    old_targets = data / "layout_strategy_challenges_v1.json"
    old_book.write_text(fixture["notebook_v1"])
    old_targets.write_text(fixture["targets_v1"])
    originals = {path: path.read_bytes() for path in [old_book, old_targets]}
    run(legacy, "old-seed-read")
    run(current, "new-read")
    hold(legacy, "old-hold-target")
    run(current, "contend-source")
    stop_owned("old-hold-target")
    run(current, "recover-source")
    hold(current, "hold-current-book")
    run(current, "contend-destination")
    stop_owned("hold-current-book")
    run(current, "recover-destination")
    run(current, "new-reopen")
    run(legacy, "old-rollback-read")
    assert all(path.read_bytes() == original for path, original in originals.items())
    new_paths = [data / "layout_strategy_notebook_v2.json", data / "layout_strategy_challenges_v2.json"]
    new_bytes = {path: path.read_bytes() for path in new_paths}
    run(legacy, "old-rollback-edit")
    assert all(path.read_bytes() != original for path, original in originals.items())
    assert all(path.read_bytes() == expected for path, expected in new_bytes.items())
    run(legacy, "old-edited-reopen")
    run(current, "new-reopen")
    assert all(path.read_bytes() == expected for path, expected in new_bytes.items())
    configure(current, profile + "-other")
    run(current, "empty", profile + "-other")
    for path in [old_book, old_targets] + new_paths:
        shutil.copy2(path, output / path.name)
    for name in ["expected-v1.json", "expected-v1-edited.json", "expected-v2.json"]:
        shutil.copy2(data / name, output / name)
finally:
    if held is not None and held.poll() is None:
        held.terminate()
        try:
            held.wait(timeout=5)
        except subprocess.TimeoutExpired:
            held.kill()
            held.wait()
    if held_stream is not None:
        held_stream.close()
    for project, original in settings.items():
        (project / "project.godot").write_bytes(original)
    (output / "results.json").write_text(json.dumps(results, indent=2))
    (output / "old-runtime-source.json").write_text(json.dumps(
        dict(base=base, project=str(legacy), sha256=bindings), indent=2))
assert all((p / "project.godot").read_bytes() == original for p, original in settings.items())
assert len(results) == 14 and all(item["passed"] for item in results)
print("PASS: actual source/destination contention, stopped-owner recovery, restart and frozen-runtime rollback")
print("Evidence: " + str(output))
