"""Root-owned sequential invocation of the isolated Region timing diagnostic."""
import argparse
import datetime
import gzip
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
parser.add_argument("--label", required=True)
parser.add_argument("--sync-helper", action="store_true")
args = parser.parse_args()
project = args.project.resolve()
assert ROOT / ".godot" in project.parents and project.name == "project"
assert re.fullmatch(r"[A-Za-z0-9_-]+", args.label)
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
dest = ROOT / ".godot/region-client-profiles" / (stamp + "-" + args.label)
dest.mkdir(parents=True)
helper = "scripts/benchmarks/computation/region_profile.gd"
if args.sync_helper:
    shutil.copy2(ROOT / helper, project / helper)
settings = project / "project.godot"
original = settings.read_bytes()
profile = "VonNeumannBottleneckChecks/round12/profile/" + stamp + "-" + args.label
assert b"config/use_custom_user_dir=true" in original
command = [str(ENGINE), "--headless", "--path", str(project),
           "--script", "res://" + helper]
log_path = dest / "profile.log"
record = {"command": command, "profile": profile, "label": args.label}
try:
    text = re.sub(r"^config/custom_user_dir_name=.*$",
                  'config/custom_user_dir_name="' + profile + '"',
                  original.decode(), flags=re.M)
    settings.write_text(text)
    record["project_settings_sha256"] = hashlib.sha256(settings.read_bytes()).hexdigest()
    record["files"] = {p: hashlib.sha256((project / p).read_bytes()).hexdigest()
                       for p in [helper, "scripts/benchmarks/computation/snapshot.gd",
                                 "scripts/benchmarks/computation/workload_cases.gd",
                                 "experiments/representation_region/model.gd",
                                 "experiments/representation/plan_model.gd"]}
    started = time.monotonic()
    print("RUN", args.label, "LOG", log_path, flush=True)
    stop_reason = None
    with log_path.open("wb") as handle, log_path.open("rb") as reader:
        process = subprocess.Popen(command, stdout=handle, stderr=subprocess.STDOUT)
        tail = b""
        while process.poll() is None:
            chunk = tail + reader.read()
            tail = chunk[-16384:]
            if b"SCRIPT ERROR:" in chunk:
                stop_reason = "script_error"
            elif time.monotonic() - started > 300:
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
    log = log_path.read_bytes()
    record.update(returncode=code, stopped_for=stop_reason,
                  seconds=time.monotonic() - started,
                  log_sha256=hashlib.sha256(log).hexdigest())
    record["diagnostics"] = re.findall(
        r"^.*(?:SCRIPT ERROR|ERROR:|Parse Error|WARNING:).*$", log.decode(), re.M)
    if "PASS:" not in log.decode():
        record["diagnostics"].append("Missing diagnostic PASS marker")
    output = Path.home() / "Library/Application Support" / profile / "region-profile.json"
    if output.exists():
        raw = output.read_bytes()
        (dest / "profile.json.gz").write_bytes(gzip.compress(raw, mtime=0))
        parsed = json.loads(raw)
        record.update(output="profile.json.gz", raw_bytes=len(raw),
                      raw_sha256=hashlib.sha256(raw).hexdigest(),
                      failures=parsed.get("failures"))
    else:
        record["diagnostics"].append("No original profile output")
    (dest / "invocation.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
    print("RESULT", json.dumps(record, ensure_ascii=False), flush=True)
    if code or stop_reason or record["diagnostics"] or record.get("failures"):
        raise SystemExit(1)
finally:
    settings.write_bytes(original)
print("COMPLETE", dest, flush=True)
