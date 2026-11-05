"""Read-only final Round10 receipt/source audit. No Godot or Git mutations."""
from pathlib import Path
import hashlib
import json
import re
import struct
import subprocess
from urllib.parse import unquote, urlsplit

ROOT = Path("/Users/yrq/Documents/冯诺伊曼瓶颈")
RECEIPT = ROOT / "docs/verification/20261105-circuit-failure-recovery"
OUT = Path("/private/tmp/vnb-round10-final-static-review.json")
BASE = "b765dd249cd165358dc5329480c529c76f9218bc"
result = {
    "passed": False, "checks": [], "issues": [], "delivery_notes": [],
    "reviewer_correction": (
        "Initial checker assumed every final invocation contained a host hash. "
        "The actual headless/Chinese GPU records predate that field; English GPU "
        "and startup contain it. Preserve this distinction rather than inventing "
        "a historical hash or weakening the existing hashes.")
}


def digest(path):
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def require(ok, label):
    if not ok:
        result["issues"].append(label)
        OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        raise AssertionError(label)
    result["checks"].append(label)


def load(path):
    def unique(pairs):
        output = {}
        for key, value in pairs:
            if key in output:
                raise ValueError("Duplicate JSON key: " + key)
            output[key] = value
        return output
    return json.loads(path.read_bytes(), object_pairs_hook=unique)


def git(*arguments, input_bytes=None):
    return subprocess.check_output(["git", *arguments], cwd=ROOT, input=input_bytes)


binding = load(RECEIPT / "source-sha256.json")
qa = Path(binding["qa_playable"])
reference = Path(binding["frozen_reference"])
require(binding["base"] == BASE and binding["branch"] == "codex/gameplay-systems-20261104",
        "Source manifest base and task branch are exact")
require(git("branch", "--show-current").decode().strip() == binding["branch"],
        "Current branch remains the authorized task branch")
require(git("rev-parse", "main").decode().strip()
        == "b65a0bd3064888f41c5caeb8d7d0717d2b901658", "Protected local main unchanged")
allowed_roots = {"src", "experiments", "scripts", "tests", "localization"}
inventory = git("ls-files", "-z", "--cached", "--others", "--exclude-standard").decode().split("\0")
expected = {name for name in inventory if name
            and name.split("/")[0] in allowed_roots and (ROOT / name).is_file()}
expected.add("project.godot")
require(set(binding["files"]) == expected,
        "Manifest covers the complete current runtime/test/support inventory plus settings")
require(len(expected) == 1249, "Final binding has 1248 support files plus project settings")
for name, hashes in binding["files"].items():
    require(digest(ROOT / name) == hashes["source"], "Current source hash: " + name)
    require(digest(qa / name) == hashes["qa_playable"], "Final QA hash: " + name)
    if name != "project.godot":
        require(hashes["source"] == hashes["qa_playable"], "Source/QA equality: " + name)
qa_settings = (qa / "project.godot").read_text()
stripped = "\n".join(line for line in qa_settings.split("\n") if not line.startswith(
    ("config/use_custom_user_dir=", "config/custom_user_dir_name=")))
require(stripped == (ROOT / "project.godot").read_text(),
        "QA settings differ only by two isolated user-directory entries")
require('config/custom_user_dir_name="' + binding["profile"] + '"' in qa_settings
        and 'config/use_custom_user_dir=true' in qa_settings,
        "Final QA uses the declared isolated playable profile")

frozen = load(RECEIPT / "invocation-tools/round10-reference.json")
require(frozen["base"] == BASE and Path(frozen["project"]) == reference,
        "Frozen reference manifest identifies the same base/project")
names = list(frozen["runtime_files"])
queries = "".join(BASE + ":" + name + "\n" for name in names).encode()
objects = git("cat-file", "--batch", input_bytes=queries)
offset = 0
production_changes = []
for name in names:
    boundary = objects.index(b"\n", offset)
    header = objects[offset:boundary].decode().split()
    require(len(header) == 3 and header[1] == "blob",
            "Frozen source is an actual Git blob: " + name)
    size = int(header[2])
    content = objects[boundary + 1:boundary + 1 + size]
    require(objects[boundary + 1 + size:boundary + 2 + size] == b"\n",
            "Exact Git blob byte boundary: " + name)
    offset = boundary + 2 + size
    expected_hash = frozen["runtime_files"][name]
    require(hashlib.sha256(content).hexdigest() == expected_hash
            == digest(reference / name), "Frozen manifest/reference bind to actual base Git bytes: " + name)
    if digest(ROOT / name) != expected_hash:
        production_changes.append(name)
require(offset == len(objects), "All frozen Git blob bytes were consumed exactly")
expected_changes = ["src/circuit/prologue_simulator.gd",
                    "src/hardware_foundations/hardware_foundations.gd"]
require(production_changes == expected_changes, "Exactly the two approved production files differ")
actual_diff = git("diff", "--name-only", BASE, "--", "src", "experiments").decode().splitlines()
require(actual_diff == expected_changes, "Git production diff confirms only the two approved files")

archive_matches = []
for source, archived, prefix in [
    (ROOT / ".godot/circuit-recovery-checks", RECEIPT / "checks", "checks"),
    (ROOT / ".godot/circuit-recovery-benchmarks", RECEIPT / "benchmarks", "benchmarks"),
]:
    for path in sorted(source.rglob("*")):
        if not path.is_file():
            continue
        target = archived / path.relative_to(source)
        require(target.is_file() and digest(target) == digest(path),
                "Archived original is byte-exact: " + prefix + "/" + str(path.relative_to(source)))
        archive_matches.append(str(target.relative_to(RECEIPT)))
for source in sorted(qa.parent.iterdir()):
    if source.is_file():
        target = RECEIPT / "checks/candidate-standard" / source.name
        require(target.is_file() and digest(target) == digest(source),
                "Standard verifier artifact is exact: " + source.name)
        archive_matches.append(str(target.relative_to(RECEIPT)))
for label in ["diagnostic-comparison", "diagnostic-measurement-phase"]:
    for extension in ("md", "json", "py"):
        name = label + "." + extension
        require(digest(RECEIPT / "reviews" / name)
                == digest(Path("/private/tmp/vnb-round10-" + name)),
                "Original/follow-up review artifact preserved exactly: " + name)

attempts = []
host_hash_records = []
expected_negative = {
    ("20261105T112423Z", "test_prologue_failure_recovery"): (1, 31, None),
    ("20261105T112423Z", "test_hardware_failure_recovery"): (-15, 4, "script_error"),
    ("20261105T112522Z", "test_hardware_failure_recovery"): (1, 7, None),
    ("20261105T113442Z", "test_hardware_failure_recovery"): (1, 2, None),
}
for directory in sorted((RECEIPT / "checks").iterdir()):
    if not directory.is_dir() or directory.name == "candidate-standard":
        continue
    records = load(directory / "results.json")
    for record in records:
        name = record["suite"]
        log_path = directory / (name + ".log")
        require(digest(log_path) == record["log_sha256"],
                "Check log hash matches actual recorded invocation: " + directory.name + "/" + name)
        text = log_path.read_text()
        diagnostics = [line for line in text.splitlines()
                       if re.search(r"SCRIPT ERROR|ERROR:|Parse Error|WARNING:", line)]
        recorded = [line for line in record["diagnostics"] if line != "Missing suite PASS marker"]
        require(diagnostics == recorded, "Complete diagnostic list retained: " + directory.name + "/" + name)
        key = (directory.name, name)
        negative = key in expected_negative
        wanted = expected_negative.get(key, (0, 0, None))
        require((record["returncode"], len(diagnostics), record["stopped_for"]) == wanted,
                "Exact expected process outcome: " + directory.name + "/" + name)
        if not negative and name not in ("import", "startup"):
            require("PASS:" in text, "Actual suite PASS marker: " + directory.name + "/" + name)
        if directory.name in ("20261105T113619Z", "20261105T113852Z",
                              "20261105T114010Z", "20261105T114738Z"):
            require(record["simulator_sha256"] == digest(ROOT / expected_changes[0]),
                    "Final invocation binds current simulator: " + name)
            host_hash_recorded = "hardware_host_sha256" in record
            if host_hash_recorded:
                require(record["hardware_host_sha256"] == digest(ROOT / expected_changes[1]),
                        "Final invocation's actual host hash matches current source: " + name)
            host_hash_records.append({
                "directory": directory.name, "suite": name,
                "contemporaneous_host_hash_present": host_hash_recorded})
            if name.startswith("test_"):
                require(record["script_sha256"] == digest(ROOT / "tests" / (name + ".gd")),
                        "Final invocation binds current test: " + name)
        attempts.append({"directory": directory.name, "suite": name,
                         "returncode": record["returncode"], "diagnostics": len(diagnostics),
                         "negative": negative, "pass_lines": [
                             line for line in text.splitlines()
                             if line.startswith(("PASS:", "FAIL:"))]})
for directory_name, suite_name in expected_negative:
    require(any(item["directory"] == directory_name and item["suite"] == suite_name
                for item in attempts), "Required failed attempt retained: " + directory_name + "/" + suite_name)
require(all(item["contemporaneous_host_hash_present"] for item in host_hash_records
            if item["directory"] in ("20261105T114010Z", "20261105T114738Z")),
        "Final English GPU and startup independently record current host bytes")

standard = load(RECEIPT / "checks/candidate-standard/results.json")
require(len(standard["results"]) == 15, "Standard verifier contains import/isolation plus thirteen suites")
for row in standard["results"]:
    text = (RECEIPT / "checks/candidate-standard" / row["log"]).read_text()
    require(row["exit"] == 0 and row["passed"] and not row["errors"],
            "Standard verifier result passes: " + row["name"])
    require(not re.search(r"SCRIPT ERROR|ERROR:|Parse Error|WARNING:", text),
            "Standard verifier full log has no engine diagnostics: " + row["name"])
require("checks=308 failures=0" in
        (RECEIPT / "checks/candidate-standard/test_prologue_failure_recovery.txt").read_text(),
        "Actual candidate pure recovery result is 308/0")
for name, count in [("20261105T112836Z", 144), ("20261105T112914Z", 144),
                    ("20261105T113852Z", 158), ("20261105T114010Z", 158)]:
    text = (RECEIPT / "checks" / name / "test_hardware_failure_recovery.log").read_text()
    require("PASS: hardware failure recovery " + str(count) + " checks / 0 failures" in text,
            "Original and final GPU observation counts stay distinguishable: " + name)

frame_manifest = load(RECEIPT / "frame-sha256.json")
require(len(frame_manifest) == 12, "Six final and six diagnostic frames retained")
for name, entry in frame_manifest.items():
    path = RECEIPT / name
    header = path.read_bytes()[:24]
    require(header[:8] == b"\x89PNG\r\n\x1a\n", "Actual PNG signature: " + name)
    size = struct.unpack(">II", header[16:24])
    require(size == (entry["width"], entry["height"]) == (1280, 720)
            and path.stat().st_size == entry["bytes"] and digest(path) == entry["sha256"],
            "Exact original image dimensions/bytes/hash: " + name)
    if name.startswith("frames/"):
        require(digest(path) == digest(qa / ".godot/hardware-recovery-captures" /
                                     name.removeprefix("frames/")),
                "Final frame equals raw QA capture: " + name)

links = []
for document in sorted(RECEIPT.rglob("*.md")):
    text = re.sub(r"```.*?```", "", document.read_text(), flags=re.S)
    targets = re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", text)
    targets.extend(re.findall(r"^\[[^\]]+\]:\s+(\S+)", text, re.M))
    for target in targets:
        target = target.strip().split(' "', 1)[0]
        if target.startswith("<") and target.endswith(">"):
            target = target[1:-1]
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        path_text = unquote(parsed.path)
        path_text = re.sub(r":\d+$", "", path_text)
        resolved = (document.parent / path_text).resolve()
        require(resolved.exists(), "Local receipt link resolves: "
                + str(document.relative_to(RECEIPT)) + " -> " + target)
        links.append({"document": str(document.relative_to(RECEIPT)),
                      "target": target, "resolved": str(resolved)})

all_receipt_files = sorted(path for path in RECEIPT.rglob("*") if path.is_file())
receipt_paths = [str(path.relative_to(ROOT)) for path in all_receipt_files]
ignored_run = subprocess.run(
    ["git", "check-ignore", "--stdin", "-z"], cwd=ROOT,
    input="\0".join(receipt_paths).encode() + b"\0",
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
require(ignored_run.returncode in (0, 1), "Git ignore inspection completed read-only")
ignored = [path for path in ignored_run.stdout.decode().split("\0") if path]
if ignored:
    require(all(path.endswith(".log") for path in ignored),
            "Only raw engine logs are globally ignored in receipt")
    result["delivery_notes"].append(
        str(len(ignored)) + " raw .log files remain covered by the global *.log rule. "
        "They must be included in root's exact delivery scope with explicit force-add "
        "or a receipt-local ignore exception; this audit does not mutate the index.")
result.update({
    "passed": True,
    "bound_source_and_qa_files": len(binding["files"]),
    "frozen_git_bound_runtime_files": len(names),
    "production_changes": production_changes,
    "archived_original_files_verified": len(archive_matches),
    "archive_matches": archive_matches,
    "retained_attempts": attempts,
    "final_invocation_host_hash_bindings": host_hash_records,
    "frame_count": len(frame_manifest),
    "local_link_count": len(links),
    "local_links": links,
    "receipt_file_count_at_review": len(all_receipt_files),
    "ignored_raw_logs": ignored,
    "source_manifest_sha256": digest(RECEIPT / "source-sha256.json"),
    "check_count": len(result["checks"]),
})
OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({key: result[key] for key in (
    "passed", "check_count", "bound_source_and_qa_files", "frozen_git_bound_runtime_files",
    "production_changes", "archived_original_files_verified", "frame_count",
    "local_link_count", "receipt_file_count_at_review", "delivery_notes")}, ensure_ascii=False, indent=2))
