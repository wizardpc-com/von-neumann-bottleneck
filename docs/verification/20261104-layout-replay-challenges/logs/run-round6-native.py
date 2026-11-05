"""Launch the ordinary scheduling lab in an isolated QA profile for CUA."""
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]
project = root / ".godot/verification/20261105T033350Z-75462610/project"
stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
output = root / "docs/verification/20261104-layout-replay-challenges/native" / stamp
output.mkdir(parents=True)
settings_path = project / "project.godot"
previous = settings_path.read_bytes()
profile = "VonNeumannBottleneckChecks/20261104-round6/native/" + stamp
settings = (root / "project.godot").read_text().replace(
    "[application]\n",
    "[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=" + json.dumps(profile) + "\n",
    1,
)
settings = re.sub(r"^run/main_scene=.*$", 'run/main_scene="res://experiments/layout_strategy/lab.tscn"',
                  settings, count=1, flags=re.MULTILINE)
command = ["/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot",
           "--path", str(project), "--windowed", "--resolution", "1280x720",
           "--", "--locale=zh_CN"]
receipt = dict(command=command, profile=profile, project=str(project),
               status="running", native_input="pending", scene="ordinary main scene; no fixture driver")
try:
    settings_path.write_text(settings)
    (output / "project-settings.godot").write_text(settings)
    with (output / "session.log").open("w") as log:
        proc = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                start_new_session=True)
        receipt["pid"] = proc.pid
        (output / "invocation.json").write_text(json.dumps(receipt, indent=2) + "\n")
        print("Native evidence: " + str(output), flush=True)
        print("Owned PID: " + str(proc.pid), flush=True)
        try:
            code = proc.wait(timeout=600)
        except (KeyboardInterrupt, subprocess.TimeoutExpired) as error:
            receipt["stopped_by_runner"] = type(error).__name__
            if proc.poll() is None:
                proc.terminate()
            code = proc.wait(timeout=15)
    receipt["exit"] = code
    receipt["status"] = "exited"
    receipt["diagnostics"] = [line for line in (output / "session.log").read_text().splitlines()
                              if "ERROR:" in line or line.startswith("FAIL:")]
finally:
    settings_path.write_bytes(previous)
    receipt["settings_restored"] = settings_path.read_bytes() == previous
    (output / "invocation.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt, ensure_ascii=False, indent=2), flush=True)
