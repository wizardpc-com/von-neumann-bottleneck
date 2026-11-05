"""Run the read-only model probe with an isolated profile, preserving QA settings."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

root = Path(__file__).resolve().parents[2]
project = root / ".godot/verification/20261104T203308Z-530aab9a/project"
output = root / "docs/verification/20261104-portable-challenges/strategy"
output.mkdir(parents=True, exist_ok=True)
probe = root / ".godot/collaboration/round3-strategy-probe.gd"
settings = project / "project.godot"
original = settings.read_bytes()
profile = "VonNeumannBottleneckChecks/20261104-round3/strategy-sample"
assert b"VonNeumannBottleneckChecks/" in original
inputs = [
    "src/layout_chapter/layout_catalog.gd",
    "src/layout_chapter/layout_recipe.gd",
    "src/layout_chapter/layout_simulator.gd",
    "src/layout_chapter/layout_run.gd",
]
manifest = {}
for relative in inputs:
    current = (root / relative).read_bytes()
    frozen = (project / relative).read_bytes()
    assert current == frozen, relative
    manifest[relative] = hashlib.sha256(current).hexdigest()
manifest["probe"] = hashlib.sha256(probe.read_bytes()).hexdigest()
manifest["scoreboard_at_probe"] = hashlib.sha256(
    (project / "src/layout_chapter/layout_scoreboard.gd").read_bytes()
).hexdigest()
shutil.copy2(probe, output / "strategy-probe.gd")
shutil.copy2(
    project / "src/layout_chapter/layout_scoreboard.gd",
    output / "scoreboard-at-probe.gd.txt",
)
engine = "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot"
spec = importlib.util.spec_from_file_location("verifier", root / "scripts/verify-project.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
command = [engine, "--headless", "--path", str(project), "--script", str(probe), "--", "--strategy-all"]
started = time.monotonic()
try:
    modified = re.sub(
        r'^config/custom_user_dir_name=.*$',
        "config/custom_user_dir_name=" + json.dumps(profile),
        original.decode("utf-8"),
        flags=re.MULTILINE,
    )
    settings.write_text(modified, encoding="utf-8")
    code = verifier.run_logged_process(command, dict(os.environ), output / "probe.log", 300)
finally:
    settings.write_bytes(original)
assert settings.read_bytes() == original
text = (output / "probe.log").read_text(encoding="utf-8")
parsed = [
    json.loads(line.split(" ", 1)[1])
    for line in text.splitlines()
    if line.startswith("VNB_STRATEGY_RESULT ")
]
done = [
    json.loads(line.split(" ", 1)[1])
    for line in text.splitlines()
    if line.startswith("VNB_STRATEGY_DONE ")
]
result = dict(
    exit=code,
    elapsed_seconds=round(time.monotonic()-started, 3),
    command=command,
    profile=profile,
    inputs=manifest,
    settings_restored=True,
    tasks=parsed,
    completion=done,
)
(output / "results.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(dict(exit=code, tasks=len(parsed), done=done, evidence=str(output)), ensure_ascii=False))
raise SystemExit(code)
