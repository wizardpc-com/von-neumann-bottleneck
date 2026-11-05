#!/usr/bin/env python3
"""Root-only sequential benchmark invocation with isolated QA profiles."""
import argparse
import datetime
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
ENGINE = Path("/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot")
_seal_spec = importlib.util.spec_from_file_location(
    "computation_record", ROOT / "scripts/benchmarks/computation/record.py")
_seal_module = importlib.util.module_from_spec(_seal_spec)
_seal_spec.loader.exec_module(_seal_module)

parser = argparse.ArgumentParser()
parser.add_argument("--project", type=Path, required=True)
parser.add_argument("--label", required=True)
parser.add_argument("--groups", default="circuit,memory,workload")
parser.add_argument("--iterations", type=Path)
parser.add_argument("--only", default="")
parser.add_argument("--samples", default="7")
parser.add_argument("--sync-harness", action="store_true")
args = parser.parse_args()
project = args.project.resolve()
assert ROOT / ".godot" in project.parents and project.name == "project"
assert re.fullmatch(r"[A-Za-z0-9_-]+", args.label)
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
dest = ROOT / ".godot/region-client-benchmarks" / f"{stamp}-{args.label}"
dest.mkdir(parents=True)
if args.sync_harness:
    for p in (ROOT / "scripts/benchmarks/computation").glob("*"):
        if p.is_file():
            shutil.copy2(p, project / p.relative_to(ROOT))
settings = project / "project.godot"
original = settings.read_bytes()
records = []
try:
    for group in args.groups.split(","):
        profile = f"VonNeumannBottleneckChecks/round12/{stamp}-{args.label}/{group}"
        text = original.decode()
        text = re.sub(r'^config/custom_user_dir_name=.*$', f'config/custom_user_dir_name="{profile}"', text, flags=re.M)
        assert f'config/custom_user_dir_name="{profile}"' in text
        settings.write_text(text)
        cmd = [str(ENGINE), "--headless", "--path", str(project),
               "--script", "res://scripts/benchmarks/computation/runner.gd", "--",
               "--benchmark-group=" + group, "--label=" + args.label,
               "--host-label=yrq-mac-round12", "--samples=" + args.samples]
        if args.iterations:
            cmd.append("--iterations-file=" + str(args.iterations.resolve()))
        if args.only:
            cmd.append("--only=" + args.only)
        log = dest / f"{group}.log"
        start = time.monotonic()
        print("RUN", group, "LOG", log, flush=True)
        with log.open("wb") as handle:
            completed = subprocess.run(cmd, stdout=handle, stderr=subprocess.STDOUT, timeout=900)
        output = Path.home() / "Library/Application Support" / profile / "computation-benchmark.json"
        record = {"group":group,"command":cmd,"profile":profile,"returncode":completed.returncode,
                  "seconds":time.monotonic()-start,"log":log.name}
        diagnostics = re.findall(r"^.*(?:SCRIPT ERROR|ERROR:|Parse Error|WARNING:).*$",log.read_text(),re.M)
        record["diagnostics"] = diagnostics
        if output.exists():
            raw = output.read_bytes()
            archived = dest / f"{group}.json.gz"
            archived.write_bytes(gzip.compress(raw, mtime=0))
            record.update({"output":archived.name,"raw_sha256":hashlib.sha256(raw).hexdigest(),
                           "raw_bytes":len(raw),"compressed_bytes":archived.stat().st_size})
            result = json.loads(raw)
            sealed = _seal_module.seal(raw, log.read_bytes(), completed.returncode)
            sealed_path = dest / f"{group}.sealed.json.gz"
            sealed_path.write_bytes(gzip.compress(
                (json.dumps(sealed, ensure_ascii=False, allow_nan=False,
                            separators=(",", ":")) + "\n").encode(), mtime=0))
            record["sealed_output"] = sealed_path.name
            record["failures"] = result.get("failures")
            record["cases"] = [{"id":c["id"],"iterations":c["iterations"],"median_us":c["median_us"],
                               "snapshot_bytes":c["snapshot_bytes"]} for c in result["cases"]]
        records.append(record)
        (dest / "invocations.json").write_text(json.dumps(records,ensure_ascii=False,indent=2)+"\n")
        print("RESULT", json.dumps(record,ensure_ascii=False),flush=True)
        if completed.returncode or diagnostics or record.get("failures"):
            raise SystemExit(1)
finally:
    settings.write_bytes(original)
print("COMPLETE", dest, flush=True)
