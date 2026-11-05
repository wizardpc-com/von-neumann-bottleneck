"""Archive Round9 observations and bind the existing isolated playable QA."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import shutil
import statistics
import subprocess

ROOT = Path(__file__).resolve().parents[2]
RECEIPT = ROOT / "docs/verification/20261105-computation-kernels"
QA = ROOT / ".godot/verification/20261105T095516Z-05af4f51/project"
BASE = ROOT / ".godot/verification/20261105T090809Z-3273d2f7/project"
RECEIPT.mkdir(parents=True, exist_ok=True)

for folder, target in [
    (ROOT / ".godot/computation-benchmarks", RECEIPT / "benchmarks"),
    (ROOT / ".godot/computation-checks", RECEIPT / "checks"),
]:
    shutil.copytree(folder, target, dirs_exist_ok=True)
for label, project in [("reference-suites", BASE), ("candidate-suites", QA)]:
    target = RECEIPT / "checks" / label
    target.mkdir(parents=True, exist_ok=True)
    for source in project.parent.iterdir():
        if source.is_file():
            shutil.copy2(source, target / source.name)
for source in Path("/private/tmp").glob("vnb-round9-*.md"):
    target = RECEIPT / "reviews" / source.name.removeprefix("vnb-round9-")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
for name in [
    "round9-iterations.json", "round9-measured-gd-sha256.json",
    "run-round9-benchmark.py", "run-round9-checks.py",
    "round9-creation-gpu-probe.gd", "finalize-round9.py",
]:
    target = RECEIPT / "invocation-tools" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / ".godot/collaboration" / name, target)

profiles = {}
for label, stamp in [("reference", "20261105T092702Z"), ("candidate", "20261105T101819Z")]:
    source = Path.home() / (
        "Library/Application Support/VonNeumannBottleneckChecks/round9/checks/"
        + stamp + "/creation_profile/creation-profile.json")
    target = RECEIPT / "profiles" / (label + ".json")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    profiles[label] = json.loads(source.read_text())
assert profiles["reference"]["engine"] == profiles["candidate"]["engine"]
assert profiles["reference"]["processor"] == profiles["candidate"]["processor"]
profile_results = []
for before, after in zip(profiles["reference"]["cases"], profiles["candidate"]["cases"]):
    assert before["length"] == after["length"]
    for old, new in zip(before["samples"], after["samples"]):
        for field in ["predictions", "rule_reads", "events", "output_sha256", "cost"]:
            assert old[field] == new[field], (before["length"], field)
    old_times = [s["generate_us"] for s in before["samples"]]
    new_times = [s["generate_us"] for s in after["samples"]]
    profile_results.append(dict(
        length=before["length"], reference_us=old_times, candidate_us=new_times,
        reference_median_us=statistics.median(old_times),
        candidate_median_us=statistics.median(new_times),
        speed_ratio=statistics.median(old_times)/statistics.median(new_times),
        event_count=after["samples"][0]["events"], cost=after["samples"][0]["cost"],
        output_sha256=after["samples"][0]["output_sha256"],
    ))
(RECEIPT / "profiles/comparison.json").write_text(json.dumps(dict(
    scope="Diagnostic three-sample public generation; full4096 parity is separately in the workload corpus.",
    matching_output_cost_counts=True, cases=profile_results), indent=2)+"\n")

diagnostic = Path.home() / (
    "Library/Application Support/VonNeumannBottleneckChecks/round9/checks/"
    "20261105T102652Z/round9-creation-gpu-probe/failed-click.png")
(RECEIPT / "diagnostics").mkdir(exist_ok=True)
shutil.copy2(diagnostic, RECEIPT / "diagnostics/hidden-ledger-click.png")

names = subprocess.check_output(
    ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT
).decode().split("\0")
bound = {}
synced = []
for name in sorted(set(names) - {""}):
    if name.split("/")[0] not in ["src", "experiments", "scripts", "tests", "localization"]:
        continue
    source = ROOT / name
    if not source.is_file():
        continue
    assert not source.is_symlink(), name
    data = source.read_bytes()
    target = QA / name
    if not target.exists() or target.read_bytes() != data:
        assert source.suffix in [".md", ".py"], name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        synced.append(name)
    digest = hashlib.sha256(data).hexdigest()
    assert hashlib.sha256(target.read_bytes()).hexdigest() == digest
    bound[name] = dict(source=digest, qa_playable=digest)

measured = json.loads((ROOT / ".godot/collaboration/round9-measured-gd-sha256.json").read_text())
for name, digest in measured.items():
    for project in [ROOT, BASE, QA]:
        assert hashlib.sha256((project / "scripts/benchmarks/computation" / name).read_bytes()).hexdigest() == digest

profile = "VonNeumannBottleneckChecks/round9/playable-preview-20261105"
source_settings = (ROOT / "project.godot").read_text()
settings = QA / "project.godot"
text = settings.read_text()
text = re.sub(r'^config/custom_user_dir_name=.*$', 'config/custom_user_dir_name="'+profile+'"', text, flags=re.M)
settings.write_text(text)
without_isolation = "\n".join(line for line in text.split("\n") if not line.startswith(
    ("config/use_custom_user_dir=", "config/custom_user_dir_name=")))
assert without_isolation == source_settings
bound["project.godot"] = dict(
    source=hashlib.sha256(source_settings.encode()).hexdigest(),
    qa_playable=hashlib.sha256(text.encode()).hexdigest(),
    difference="Only two isolated user-directory settings; ordinary main scene retained.")
(RECEIPT / "source-sha256.json").write_text(json.dumps(dict(
    base="2748138d166855e86a5496ce60ca37a8389d4ce7",
    branch="codex/gameplay-systems-20261104", frozen_reference=str(BASE),
    qa_playable=str(QA), profile=profile, files=bound, nonruntime_synced=synced,
), ensure_ascii=False, indent=2)+"\n")

launcher = ROOT / ".godot/computation-preview-20261105.command"
launcher.write_text('#!/bin/zsh\nset -euo pipefail\ncd "'+str(QA)+'"\n'
    'exec "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot" --path "$PWD"\n')
launcher.chmod(0o755)
subprocess.run(["zsh", "-n", str(launcher)], check=True)
print(json.dumps(dict(source_files=len(bound)-1, nonruntime_synced=synced,
    launcher=str(launcher), profile_comparison=profile_results), ensure_ascii=False, indent=2))
