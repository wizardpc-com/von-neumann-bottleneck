"""Root-owned Round12 evidence archive; no engine or Git mutations."""
from pathlib import Path
import hashlib
import json
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / ".godot/collaboration"
RECEIPT = ROOT / "docs/verification/20261105-region-client-reuse"
BASE = "82d6d540a8c01e8ed2a810b30a9f078fc7d35365"
BRANCH = "codex/gameplay-systems-20261104"
QA = ROOT / ".godot/verification/20261105T142756Z-4bd0e0fc/project"
REFERENCE = ROOT / ".godot/verification/20261105T130540Z-round12-reference/project"
PROFILE = "VonNeumannBottleneckChecks/round12/playable-preview-20261105"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def copy(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    assert sha(source) == sha(target)


assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip() == BASE
assert subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip() == BRANCH
for category, directory in [
    ("benchmarks", ".godot/region-client-benchmarks"),
    ("profiles", ".godot/region-client-profiles"),
    ("checks", ".godot/region-client-checks"),
]:
    for source in sorted((ROOT / directory).iterdir()):
        if source.is_dir():
            for path in sorted(source.rglob("*")):
                if path.is_file():
                    copy(path, RECEIPT / category / source.name / path.relative_to(source))
for path in sorted(QA.parent.iterdir()):
    if path.is_file() and path.suffix in {".txt", ".json"}:
        copy(path, RECEIPT / "checks/candidate-standard" / path.name)

tool_names = [
    "round12-reference.json", "round12-iterations.json",
    "round12-measured-gd-sha256.json", "round12-public-gd-sha256.json",
    "round12-public-comparison.json",
    "run-round12-checks.py", "run-round12-benchmark.py",
    "run-round12-profile.py", "finalize-round12.py",
]
for name in tool_names:
    copy(LOCAL / name, RECEIPT / "invocation-tools" / name)
for name in [
    "round12-client-test-initial.gd", "round12-region-profile-initial.gd",
    "round12-client-oracle-probe.gd", "round12-client-oracle-probe.json",
    "round12-client-oracle-differences.json",
    "round12-profile-initial-differences.json",
]:
    copy(LOCAL / name, RECEIPT / "initial-diagnostics" /
         (name + ".txt" if name.endswith(".gd") else name))
reports = {
    "client-tests": "test-implementation",
    "client-benchmarks": "benchmark-implementation",
    "client-contract-review": "contract-review",
    "client-source-review": "source-review",
    "helper-correction-review": "helper-correction-review",
    "timing-evidence-review": "timing-evidence-review",
    "visual-review": "visual-review",
    "final-doc-review": "final-doc-review",
}
for source_name, target_name in reports.items():
    path = Path("/private/tmp") / ("vnb-round12-" + source_name + ".md")
    if path.is_file():
        copy(path, RECEIPT / "reviews" / (target_name + ".md"))
    for suffix in (".json", ".py"):
        companion = path.with_suffix(suffix)
        if companion.is_file():
            copy(companion, RECEIPT / "reviews" / (target_name + suffix))
for source_name, target_name in {
    "vnb-round12-review-evidence.py": "timing-evidence-review.py",
    "vnb-round12-evidence-initial-checker-failure.json": "timing-initial-checker-failure.json",
}.items():
    source = Path("/private/tmp") / source_name
    if source.is_file():
        copy(source, RECEIPT / "reviews" / target_name)

frames = {}
for path in sorted((QA / ".godot/workbench-captures").glob("*.png")):
    raw = path.read_bytes()
    assert raw[:8] == b"\x89PNG\r\n\x1a\n"
    dimensions = list(struct.unpack(">II", raw[16:24]))
    assert dimensions == [1280, 720], path.name
    target = RECEIPT / "frames" / path.name
    copy(path, target)
    frames[path.name] = {"sha256": sha(path), "bytes": len(raw), "dimensions": dimensions}
assert len(frames) == 20
(RECEIPT / "frame-sha256.json").write_text(json.dumps(frames, indent=2) + "\n")

# Runtime is never silently synchronized after measurement; only this README changed.
nonruntime_synced = ["scripts/benchmarks/computation/README.md"]
for name in nonruntime_synced:
    copy(ROOT / name, QA / name)
source_settings = (ROOT / "project.godot").read_text()
qa_settings = (QA / "project.godot").read_text()
assert f'config/custom_user_dir_name="{PROFILE}"' in qa_settings
stripped = "\n".join(line for line in qa_settings.split("\n") if not line.startswith(
    ("config/use_custom_user_dir=", "config/custom_user_dir_name=")))
assert stripped == source_settings
inventory = subprocess.check_output(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT
).decode().split("\0")
paths = sorted({p for p in inventory if p and p.split("/")[0] in
                {"src", "experiments", "scripts", "tests", "localization"}
                and (ROOT / p).is_file()} | {"project.godot"})
files = {}
for name in paths:
    files[name] = {"source": sha(ROOT / name), "qa_playable": sha(QA / name)}
    if name != "project.godot":
        assert files[name]["source"] == files[name]["qa_playable"], name
binding = {
    "base": BASE, "branch": BRANCH, "frozen_reference": str(REFERENCE),
    "qa_playable": str(QA), "profile": PROFILE, "files": files,
    "nonruntime_synced": nonruntime_synced,
}
(RECEIPT / "source-sha256.json").write_text(
    json.dumps(binding, ensure_ascii=False, indent=2) + "\n")
launcher = ROOT / ".godot/region-clients-preview-20261105.command"
subprocess.run(["zsh", "-n", str(launcher)], check=True)
copy(launcher, RECEIPT / "invocation-tools/playable-preview.command.txt")
print(json.dumps({
    "source_entries": len(files), "frames": len(frames), "profile": PROFILE,
    "qa": str(QA), "launcher": str(launcher), "launcher_syntax": "pass",
    "region_model_sha256": sha(ROOT / "experiments/representation_region/model.gd"),
}, ensure_ascii=False, indent=2))
