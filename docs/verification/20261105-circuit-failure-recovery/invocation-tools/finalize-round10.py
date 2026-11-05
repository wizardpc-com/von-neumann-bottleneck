"""Archive Round10 evidence and bind the existing isolated playable project."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
RECEIPT = ROOT / "docs/verification/20261105-circuit-failure-recovery"
QA = ROOT / ".godot/verification/20261105T112607Z-5880555a/project"
REFERENCE = ROOT / ".godot/verification/20261105T111217Z-round10-reference/project"
BASE = "b765dd249cd165358dc5329480c529c76f9218bc"


def sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def copy(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    assert sha(source) == sha(target)


RECEIPT.mkdir(parents=True, exist_ok=True)
for source, target in [
    (ROOT / ".godot/circuit-recovery-checks", RECEIPT / "checks"),
    (ROOT / ".godot/circuit-recovery-benchmarks", RECEIPT / "benchmarks"),
    (QA / ".godot/hardware-recovery-captures", RECEIPT / "frames"),
]:
    shutil.copytree(source, target, dirs_exist_ok=True)
for source in QA.parent.iterdir():
    if source.is_file():
        copy(source, RECEIPT / "checks/candidate-standard" / source.name)
for source in Path("/private/tmp").glob("vnb-round10-*"):
    if source.is_file() and source.suffix in [".md", ".json", ".py"]:
        copy(source, RECEIPT / "reviews" / source.name.removeprefix("vnb-round10-"))
for name in [
    "round10-iterations.json", "round10-measured-gd-sha256.json",
    "round10-reference.json", "round10-valid-comparison.json",
    "run-round10-checks.py", "run-round10-benchmark.py", "finalize-round10.py",
]:
    copy(ROOT / ".godot/collaboration" / name, RECEIPT / "invocation-tools" / name)

names = subprocess.check_output(
    ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
    cwd=ROOT).decode().split("\0")
bound = {}
synced = []
for name in sorted(set(names) - {""}):
    if name.split("/")[0] not in ["src", "experiments", "scripts", "tests", "localization"]:
        continue
    source = ROOT / name
    if not source.is_file():
        continue
    assert not source.is_symlink(), name
    target = QA / name
    if not target.exists() or sha(source) != sha(target):
        assert source.suffix == ".md", name
        copy(source, target)
        synced.append(name)
    bound[name] = dict(source=sha(source), qa_playable=sha(target))
    assert bound[name]["source"] == bound[name]["qa_playable"], name

measured = json.loads((ROOT / ".godot/collaboration/round10-measured-gd-sha256.json").read_text())
for name, expected in measured.items():
    for project in [ROOT, QA, REFERENCE]:
        assert sha(project / "scripts/benchmarks/computation" / name) == expected

profile = "VonNeumannBottleneckChecks/round10/playable-preview-20261105"
source_settings = (ROOT / "project.godot").read_text()
settings = QA / "project.godot"
text = re.sub(r"^config/custom_user_dir_name=.*$",
              'config/custom_user_dir_name="' + profile + '"',
              settings.read_text(), flags=re.M)
assert 'config/use_custom_user_dir=true' in text
assert profile in text
without_isolation = "\n".join(line for line in text.split("\n") if not line.startswith(
    ("config/use_custom_user_dir=", "config/custom_user_dir_name=")))
assert without_isolation == source_settings
settings.write_text(text)
bound["project.godot"] = dict(
    source=sha(ROOT / "project.godot"), qa_playable=sha(settings),
    difference="Only two isolated user-directory settings; ordinary main scene retained.")
(RECEIPT / "source-sha256.json").write_text(json.dumps(dict(
    base=BASE, branch="codex/gameplay-systems-20261104",
    frozen_reference=str(REFERENCE), qa_playable=str(QA),
    profile=profile, files=bound, nonruntime_synced=synced,
), ensure_ascii=False, indent=2) + "\n")

frames = {}
for parent in [RECEIPT / "frames", RECEIPT / "diagnostics/initial-frames"]:
    for path in sorted(parent.rglob("*.png")):
        header = path.read_bytes()[:24]
        assert header[:8] == b"\x89PNG\r\n\x1a\n"
        width, height = struct.unpack(">II", header[16:24])
        assert (width, height) == (1280, 720), str(path)
        frames[str(path.relative_to(RECEIPT))] = dict(
            sha256=sha(path), bytes=path.stat().st_size, width=width, height=height)
(RECEIPT / "frame-sha256.json").write_text(json.dumps(frames, indent=2) + "\n")

launcher = ROOT / ".godot/circuit-recovery-preview-20261105.command"
launcher.write_text('#!/bin/zsh\nset -euo pipefail\ncd "' + str(QA) + '"\n'
    'exec "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot" --path "$PWD"\n')
launcher.chmod(0o755)
subprocess.run(["zsh", "-n", str(launcher)], check=True)
print(json.dumps(dict(source_files=len(bound)-1, frames=len(frames),
                     nonruntime_synced=synced, launcher=str(launcher)),
                 ensure_ascii=False, indent=2))
