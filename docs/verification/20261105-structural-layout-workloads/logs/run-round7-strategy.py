"""Root-only finite new-workload research in the integrated isolated runtime."""
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[2]
project = root / ".godot/verification/20261105T051242Z-1f038f6c/project"
output = root / "docs/verification/20261105-structural-layout-workloads/strategy"
output.mkdir(parents=True, exist_ok=True)
settings = project / "project.godot"
original = settings.read_bytes()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
profile = "VonNeumannBottleneckChecks/20261105-round7/structure-probe-" + stamp
engine = "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot"
probe = root / ".godot/collaboration/round7-structure-probe.gd"
shutil.copy2(probe, project / probe.name)
shutil.copy2(probe, output / "probe.gd")
spec = importlib.util.spec_from_file_location("verifier", root / "scripts/verify-project.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
source = (root / "project.godot").read_text()
command = [engine, "--headless", "--path", str(project), "--script",
           "res://" + probe.name, "--", "--probe-output=" + str(output / "results.json")]
try:
    settings.write_text(source.replace(
        "[application]\n", "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="
        + json.dumps(profile) + "\n", 1))
    code = verifier.run_logged_process(command, dict(os.environ), output / "probe.log", 240)
    text = (output / "probe.log").read_text()
    passed = code == 0 and "PASS:" in text and "ERROR:" not in text and "FAIL:" not in text
    (output / "invocation.json").write_text(json.dumps(
        dict(command=command, profile=profile, exit=code, passed=passed), indent=2))
    print(text)
    assert passed
    report = json.loads((output / "results.json").read_text())
    assert report["candidate_count"] == 442 and not report["failures"]
finally:
    settings.write_bytes(original)
assert settings.read_bytes() == original
