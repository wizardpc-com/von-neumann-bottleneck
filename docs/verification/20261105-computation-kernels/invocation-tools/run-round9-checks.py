#!/usr/bin/env python3
import argparse
import datetime
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
parser.add_argument("--script", action="append", default=[])
parser.add_argument("--sync", action="append", default=[])
parser.add_argument("--import-project", action="store_true")
parser.add_argument("--startup", action="store_true")
parser.add_argument("--gpu", action="store_true")
parser.add_argument("--capture", action="store_true")
args = parser.parse_args()
project = args.project.resolve()
assert ROOT / ".godot" in project.parents and project.name == "project"
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
dest = ROOT / ".godot/computation-checks" / stamp
dest.mkdir(parents=True)
for rel in args.sync:
    source = ROOT / rel
    assert source.is_file() and ROOT in source.resolve().parents
    (project / rel).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, project / rel)
settings = project / "project.godot"
original = settings.read_bytes()
results = []
runs = ([("import",["--editor","--import"])] if args.import_project else [])
runs += [(s,["--script",f"res://tests/{s}.gd"]) for s in args.suite]
runs += [(Path(s).stem,["--script","res://"+s]) for s in args.script]
if args.startup:
    runs.append(("startup",["--quit-after","8"]))
try:
    for label, options in runs:
        profile = f"VonNeumannBottleneckChecks/round9/checks/{stamp}/{label}"
        text = re.sub(r'^config/custom_user_dir_name=.*$', f'config/custom_user_dir_name="{profile}"', original.decode(), flags=re.M)
        settings.write_text(text)
        display = ["--windowed", "--resolution", "1280x720"] if args.gpu else ["--headless"]
        cmd = [str(ENGINE)] + display + ["--path",str(project)] + options
        if args.capture:
            cmd += ["--", "--creation-capture", "--capture-size=1280x720"]
        print("RUN",label,"LOG",dest / f"{label}.log",flush=True)
        start = time.monotonic()
        with (dest / f"{label}.log").open("wb") as handle:
            try:
                completed = subprocess.run(cmd,stdout=handle,stderr=subprocess.STDOUT,timeout=600)
                code = completed.returncode
            except subprocess.TimeoutExpired:
                code = 124
        log = (dest / f"{label}.log").read_text()
        issues = re.findall(r"^.*(?:SCRIPT ERROR|ERROR:|Parse Error|WARNING:).*$",log,re.M)
        if label not in ["startup", "import", "creation_profile"] and "PASS:" not in log:
            issues.append("Missing suite PASS marker")
        result = {"suite":label,"command":cmd,"profile":profile,"returncode":code,
                  "seconds":time.monotonic()-start,"diagnostics":issues}
        results.append(result)
        (dest / "results.json").write_text(json.dumps(results,indent=2)+"\n")
        print("RESULT",json.dumps(result),flush=True)
        if code or issues:
            raise SystemExit(1)
finally:
    settings.write_bytes(original)
print("COMPLETE",dest,flush=True)
