"""Verify the optional target survives one real engine restart, in a new QA profile."""
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[2]
project = root / ".godot/verification/20261104T210749Z-5839019c/project"
output = root / "docs/verification/20261104-portable-challenges/process"
output.mkdir(parents=True, exist_ok=True)
settings = project / "project.godot"
original = settings.read_bytes()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
profile = "VonNeumannBottleneckChecks/20261104-round3/process-"+stamp
data_path = Path("/Users/yrq/Library/Application Support") / profile
assert not data_path.exists()
source = (root / "project.godot").read_text(encoding="utf-8")
probe = root / ".godot/collaboration/challenge-process-probe.gd"
shutil.copy2(probe, output / "challenge-process-probe.gd")
spec = importlib.util.spec_from_file_location("verifier", root / "scripts/verify-project.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
results = []
try:
    settings.write_text(source.replace(
        "[application]\n",
        "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="+json.dumps(profile)+"\n",
        1), encoding="utf-8")
    persisted = None
    for phase in ["seed","reopen"]:
        command = ["/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot",
                   "--headless","--path",str(project),"--script",str(probe),"--","--"+phase]
        log = output / (phase+".log")
        code = verifier.run_logged_process(command, dict(os.environ), log, 60)
        text = log.read_text(encoding="utf-8")
        passed = code == 0 and "PASS:" in text and "ERROR:" not in text and "FAIL:" not in text
        if passed:
            current = (data_path / "layout_challenges_v1.json").read_bytes()
            if phase == "seed":
                persisted = current
            else:
                passed = current == persisted
        results.append(dict(phase=phase, code=code, passed=passed, command=command, profile=profile, log=log.name))
        print(phase+": "+("PASS" if passed else "FAIL"), flush=True)
        if not passed:
            break
finally:
    settings.write_bytes(original)
(output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
assert settings.read_bytes() == original
raise SystemExit(0 if len(results) == 2 and all(result["passed"] for result in results) else 1)
