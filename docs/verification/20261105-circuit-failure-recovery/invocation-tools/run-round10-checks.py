"""Root-only sequential checks using named Round10 QA profiles."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
ENGINE = Path("/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot")
parser = argparse.ArgumentParser()
parser.add_argument("--project", type=Path, required=True)
parser.add_argument("--suite", action="append", default=[])
parser.add_argument("--sync", action="append", default=[])
parser.add_argument("--import-project", action="store_true")
parser.add_argument("--startup", action="store_true")
parser.add_argument("--gpu", action="store_true")
parser.add_argument("--capture", action="store_true")
parser.add_argument("--locale", choices=("zh_CN", "en"), default="zh_CN")
parser.add_argument("--allow-test-failure", action="store_true")
args = parser.parse_args()
project = args.project.resolve()
assert ROOT / ".godot" in project.parents and project.name == "project"
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
dest = ROOT / ".godot/circuit-recovery-checks" / stamp
dest.mkdir(parents=True)
for rel in args.sync:
    source = ROOT / rel
    assert source.is_file() and ROOT in source.resolve().parents
    (project / rel).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, project / rel)
settings = project / "project.godot"
original = settings.read_bytes()
assert b"config/use_custom_user_dir=true" in original
runs = [("import", ["--editor", "--import", "--quit"])] if args.import_project else []
runs += [(s, ["--script", f"res://tests/{s}.gd"]) for s in args.suite]
if args.startup:
    runs.append(("startup", ["--quit-after", "8"]))
results = []
try:
    for label, options in runs:
        profile = f"VonNeumannBottleneckChecks/round10/checks/{stamp}/{label}"
        text = re.sub(r"^config/custom_user_dir_name=.*$",
                      'config/custom_user_dir_name="' + profile + '"',
                      original.decode(), flags=re.M)
        if label == "import":
            text = "\n".join(line for line in text.split("\n")
                             if not line.startswith("theme/custom_font="))
        settings.write_text(text)
        display = ["--windowed", "--resolution", "1280x720"] if args.gpu else ["--headless"]
        cmd = [str(ENGINE)] + display + ["--path", str(project)] + options
        if label not in ("import", "startup"):
            cmd += ["--", "--locale=" + args.locale]
            if args.capture:
                cmd += ["--hardware-recovery-capture", "--capture-size=1280x720"]
        log_path = dest / (label + ".log")
        start = time.monotonic()
        stop_reason = None
        print("RUN", label, "LOG", log_path, flush=True)
        with log_path.open("wb") as log, log_path.open("rb") as reader:
            process = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
            tail = b""
            while process.poll() is None:
                chunk = tail + reader.read()
                tail = chunk[-16384:]
                if b"SCRIPT ERROR:" in chunk:
                    stop_reason = "script_error"
                elif time.monotonic() - start > 300:
                    stop_reason = "timeout"
                if stop_reason:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    break
                time.sleep(0.1)
            code = process.wait()
        log = log_path.read_text()
        diagnostics = re.findall(r"^.*(?:SCRIPT ERROR|ERROR:|Parse Error|WARNING:).*$",
                                 log, re.M)
        if label not in ("import", "startup") and "PASS:" not in log:
            diagnostics.append("Missing suite PASS marker")
        result = dict(suite=label, command=cmd, profile=profile, locale=args.locale,
                      returncode=code, stopped_for=stop_reason,
                      seconds=time.monotonic() - start, diagnostics=diagnostics,
                      log_sha256=hashlib.sha256(log_path.read_bytes()).hexdigest(),
                      project_settings_sha256=hashlib.sha256(settings.read_bytes()).hexdigest())
        if label not in ("import", "startup"):
            result["script_sha256"] = hashlib.sha256(
                (project / "tests" / (label + ".gd")).read_bytes()).hexdigest()
        result["simulator_sha256"] = hashlib.sha256(
            (project / "src/circuit/prologue_simulator.gd").read_bytes()).hexdigest()
        result["hardware_host_sha256"] = hashlib.sha256(
            (project / "src/hardware_foundations/hardware_foundations.gd").read_bytes()).hexdigest()
        results.append(result)
        (dest / "results.json").write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
        print("RESULT", json.dumps(result, ensure_ascii=False), flush=True)
        if code or diagnostics or stop_reason:
            if not args.allow_test_failure or label == "import" or stop_reason:
                raise SystemExit(1)
finally:
    settings.write_bytes(original)
print("COMPLETE", dest, flush=True)
