"""Exercise named notebook restart, contention and explicit crash-owner recovery."""
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parents[2]
project = root / ".godot/verification/20261105T021829Z-18f99d78/project"
output = root / "docs/verification/20261104-layout-notebook/process"
output.mkdir(parents=True, exist_ok=True)
settings = project / "project.godot"
original = settings.read_bytes()
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
profile = "VonNeumannBottleneckChecks/layout_strategy/process-" + stamp
data = Path("/Users/yrq/Library/Application Support") / profile
assert not data.exists()
source = (root / "project.godot").read_text()
engine = "/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot"
spec = importlib.util.spec_from_file_location("verifier", root / "scripts/verify-project.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
results = []
held = None
held_stream = None

def configure(value):
    settings.write_text(source.replace("[application]\n", "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=" + json.dumps(value) + "\n", 1))

def command(phase):
    return [engine,"--headless","--path",str(project),"--script","res://tests/recovery/layout_notebook_process_probe.gd","--","--notebook-phase="+phase]

def run(phase, selected_profile=profile):
    repeat = sum(item["phase"] == phase for item in results)
    log = output / (phase+("-"+str(repeat+1) if repeat else "")+".log")
    args = command(phase)
    code = verifier.run_logged_process(args, dict(os.environ), log, 60)
    text = log.read_text(errors="replace")
    passed = code == 0 and "PASS:" in text and "ERROR:" not in text and "FAIL:" not in text
    results.append(dict(phase=phase,code=code,passed=passed,profile=selected_profile,command=args,log=log.name))
    print(phase+": "+("PASS" if passed else "FAIL"),flush=True)
    if not passed: raise RuntimeError(text)

try:
    configure(profile)
    run("seed")
    committed = (data / "layout_strategy_notebook_v1.json").read_bytes()
    run("reopen")
    assert (data / "layout_strategy_notebook_v1.json").read_bytes() == committed
    held_stream = (output / "hold.log").open("wb")
    held = subprocess.Popen(command("hold"),stdout=held_stream,stderr=subprocess.STDOUT)
    deadline = time.monotonic()+20
    while not (data/"writer-ready.json").exists() and held.poll() is None and time.monotonic()<deadline:
        time.sleep(0.1)
    assert (data/"writer-ready.json").exists() and held.poll() is None, "writer did not acquire lease"
    marker = json.loads((data/"writer-ready.json").read_text())
    assert marker["pid"] == held.pid
    run("contend")
    assert (data / "layout_strategy_notebook_v1.json").read_bytes() == committed
    held.kill() # Only the owned, PID-verified test child; simulate interrupted owner.
    code = held.wait(timeout=10)
    results.append(dict(phase="owned-writer-crash",code=code,passed=code == -9,pid=held.pid,profile=profile,command=command("hold"),log="hold.log",intent="deliberate SIGKILL after live contention check"))
    assert code == -9
    held = None
    held_stream.close(); held_stream = None
    run("recover")
    recovered = (data / "layout_strategy_notebook_v1.json").read_bytes()
    assert recovered != committed
    assert json.loads(recovered)["states"]["scan_serial"]["goal"]["first_limit"] == 558
    committed = recovered
    run("reopen")
    assert (data / "layout_strategy_notebook_v1.json").read_bytes() == committed
    configure(profile+"-other")
    run("empty",profile+"-other")
finally:
    if held is not None and held.poll() is None:
        held.terminate()
        try: held.wait(timeout=5)
        except subprocess.TimeoutExpired:
            held.kill(); held.wait()
    if held_stream is not None: held_stream.close()
    settings.write_bytes(original)
    (output/"results.json").write_text(json.dumps(results,indent=2))
assert settings.read_bytes() == original
assert len(results) == 7 and all(item["passed"] for item in results)
print("PASS: real notebook restart, live writer exclusion, killed-owner recovery and profile separation")
