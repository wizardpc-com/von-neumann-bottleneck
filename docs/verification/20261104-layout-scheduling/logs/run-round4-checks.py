"""Reuse the round4 QA copy; synchronize source, then run explicit suites serially."""
import argparse
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--gpu", action="store_true")
parser.add_argument("--capture", action="store_true")
parser.add_argument("--import-project", action="store_true")
parser.add_argument("suites", nargs="+")
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
output = root / ".godot/verification/20261105T005513Z-6cc70bb5"
project = output / "project"
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
batch = output / ("gpu" if args.gpu else "headless") / stamp
batch.mkdir(parents=True)
files = subprocess.check_output(
    ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=root
).decode().split("\0")
for name in sorted(set(files) - {""}):
    if name.startswith(("docs/", "distribution/")) or name == "project.godot":
        continue
    source = root / name
    if not source.is_file():
        continue
    assert not source.is_symlink(), name
    target = project / name
    if not target.exists() or target.read_bytes() != source.read_bytes():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
for suite in args.suites:
    assert suite.startswith("test_") and (project / "tests" / (suite + ".gd")).is_file(), suite
settings = (root / "project.godot").read_text()
assert "config/custom_user_dir_name=" not in settings
engine = "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot"
spec = importlib.util.spec_from_file_location("verifier", root / "scripts/verify-project.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
results = []
for suite in (["import"] if args.import_project else []) + args.suites:
    profile = f"VonNeumannBottleneckChecks/20261104-round4/{stamp}/{suite}"
    isolated = settings.replace(
        "[application]\n",
        "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=" + json.dumps(profile) + "\n",
        1)
    if suite == "import":
        isolated = "\n".join(line for line in isolated.split("\n")
                             if not line.startswith("theme/custom_font="))
    (project / "project.godot").write_text(isolated)
    command = [engine, "--path", str(project)]
    if suite == "import":
        command += ["--headless", "--editor", "--import", "--quit"]
    else:
        if not args.gpu:
            command.append("--headless")
        else:
            # Avoid racing macOS's initial native fullscreen transition.
            command += ["--windowed", "--resolution", "1280x720"]
        command += ["--script", f"res://tests/{suite}.gd"]
        if args.gpu:
            command += ["--", "--capture-size=1280x720"]
            if args.capture:
                command += ["--layout-strategy-capture", "--layout-challenge-capture", "--layout-score-capture"]
    log = batch / (suite + ".log")
    code = verifier.run_logged_process(command, dict(os.environ), log, 240)
    text = log.read_text(errors="replace")
    errors = [line for line in text.splitlines()
              if ("ERROR:" in line or line.startswith("FAIL:")) and "root certificate store" not in line]
    passed = code == 0 and not errors and (suite == "import" or "PASS:" in text)
    result = dict(suite=suite, code=code, errors=errors, command=command,
                  profile=profile, log=str(log.relative_to(output)), passed=passed)
    results.append(result)
    (batch / "results.json").write_text(json.dumps(results, indent=2))
    print(suite + ": " + ("PASS" if passed else "FAIL"), flush=True)
    for error in errors[:6]:
        print(error, flush=True)
    if suite == "import" and not passed:
        break
print("Evidence: " + str(batch))
raise SystemExit(0 if all(result["passed"] for result in results) else 1)
