"""Root-only archive/source binding for the verified Round11 candidate."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / ".godot/collaboration"
RECEIPT = ROOT / "docs/verification/20261105-region-rejection-evidence"
BASE = "cf27a8236db7faca56d6361cf9a44d35224b748e"
BRANCH = "codex/gameplay-systems-20261104"
QA = ROOT / ".godot/verification/20261105T122827Z-1645209e/project"
REFERENCE = ROOT / ".godot/verification/20261105T121412Z-round11-reference/project"
PROFILE = "VonNeumannBottleneckChecks/round11/playable-preview-20261105"
ENGINE = Path("/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip() == BASE
assert subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip() == BRANCH
for path in (ROOT / ".godot/region-rejection-benchmarks").iterdir():
    if path.is_dir():
        shutil.copytree(path, RECEIPT / "benchmarks" / path.name, dirs_exist_ok=True)
for path in (ROOT / ".godot/region-rejection-checks").iterdir():
    if path.is_dir():
        shutil.copytree(path, RECEIPT / "checks" / path.name, dirs_exist_ok=True)
for name in [
    "round11-reference.json", "round11-iterations.json",
    "round11-measured-gd-sha256.json", "round11-valid-comparison.json",
    "round11-diagnostic-strict-comparison.json",
    "run-round11-checks.py", "run-round11-benchmark.py", "finalize-round11.py",
]:
    shutil.copyfile(LOCAL / name, RECEIPT / "invocation-tools" / name)

# Only documentation changed after verification. Never silently sync runtime.
nonruntime_synced = ["scripts/benchmarks/computation/README.md"]
for name in nonruntime_synced:
    shutil.copyfile(ROOT / name, QA / name)

settings = (ROOT / "project.godot").read_text()
assert "config/use_custom_user_dir=" not in settings
settings = settings.replace(
    "[application]\n",
    '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'
    + PROFILE + '"\n',
    1,
)
(QA / "project.godot").write_text(settings)
stripped = "\n".join(line for line in settings.split("\n") if not line.startswith(
    ("config/use_custom_user_dir=", "config/custom_user_dir_name=")))
assert stripped == (ROOT / "project.godot").read_text()

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

launcher = ROOT / ".godot/region-evidence-preview-20261105.command"
launcher.write_text(
    '#!/bin/zsh\nset -euo pipefail\ncd "' + str(QA)
    + '"\nexec "' + str(ENGINE) + '" --path "$PWD"\n')
launcher.chmod(0o755)
subprocess.run(["zsh", "-n", str(launcher)], check=True)
print(json.dumps({
    "source_entries": len(files), "profile": PROFILE, "qa": str(QA),
    "launcher": str(launcher), "launcher_syntax": "pass",
    "region_model_sha256": sha(ROOT / "experiments/representation_region/model.gd"),
}, ensure_ascii=False, indent=2))
