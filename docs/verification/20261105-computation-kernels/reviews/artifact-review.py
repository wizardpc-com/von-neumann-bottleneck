"""Read-only independent verification of final Round9 benchmark artifacts."""
from pathlib import Path
import gc
import gzip
import hashlib
import importlib.util
import json
import re
import sys

ROOT = Path("/Users/yrq/Documents/冯诺伊曼瓶颈")
RECEIPT = ROOT / "docs/verification/20261105-computation-kernels"
BENCH = RECEIPT / "benchmarks"
ORIGINAL = ROOT / ".godot/computation-benchmarks"
OUT = Path("/private/tmp/vnb-round9-artifact-review.json")


def load_module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts/benchmarks/computation" / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


cmp = load_module("round9_compare_review", "compare.py")
rec = load_module("round9_record_review", "record.py")
results = {"checks": [], "groups": [], "artifacts": [], "issues": []}
resume_known = "--resume-known" in sys.argv
if resume_known:
    results = json.loads(OUT.read_bytes())
    assert len(results["groups"]) == 3 and len(results["artifacts"]) == 6
    assert results["issues"] == [
        "Wrong samples: 20261105T101638Z-reference-circuit-known-failure"]
    results["reviewer_correction"] = (
        "Initial checker assumed seven samples for separately rejected diagnostics; "
        "both actual diagnostic commands and receipts explicitly use three. "
        "Corrected that checker assumption; all three accepted groups already passed.")
    results["checks"] = []
    results["issues"] = []


def require(ok, message):
    if not ok:
        results["issues"].append(message)
        OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
        raise AssertionError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_digest(path):
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def read_json(path):
    return json.loads(path.read_bytes(), object_pairs_hook=cmp._unique_object)


fixed = read_json(RECEIPT / "invocation-tools/round9-iterations.json")
measured = read_json(RECEIPT / "invocation-tools/round9-measured-gd-sha256.json")
binding = read_json(RECEIPT / "source-sha256.json")
base_manifest = read_json(RECEIPT / "runtime-base-sha256.json")
reference_project = Path(binding["frozen_reference"])
candidate_project = Path(binding["qa_playable"])

for filename in ("round9-iterations.json", "round9-measured-gd-sha256.json"):
    require(file_digest(RECEIPT / "invocation-tools" / filename)
            == file_digest(ROOT / ".godot/collaboration" / filename),
            "Archived control file differs: " + filename)
for name, expected in measured.items():
    for project in (ROOT, reference_project, candidate_project):
        require(file_digest(project / "scripts/benchmarks/computation" / name) == expected,
                "Measured script mismatch: " + str(project / name))
results["checks"].append({"fixed_script_count": len(measured),
                          "three_project_script_matches": 3 * len(measured),
                          "iteration_case_count": len(fixed)})
for name, expected in base_manifest["files"].items():
    require(file_digest(reference_project / name) == expected,
            "Frozen reference runtime mismatch: " + name)
results["checks"].append({"frozen_reference_files_match_base_manifest": len(base_manifest["files"])})
for name, expected in binding["files"].items():
    require(file_digest(ROOT / name) == expected["source"],
            "Current source differs from final binding: " + name)
    require(file_digest(candidate_project / name) == expected["qa_playable"],
            "Playable QA differs from final binding: " + name)
results["checks"].append({"current_source_and_qa_bound_files": len(binding["files"]),
                          "includes_project_settings": True})
source_settings = (ROOT / "project.godot").read_text()
qa_settings = (candidate_project / "project.godot").read_text()
without_isolation = "\n".join(
    line for line in qa_settings.split("\n")
    if not line.startswith(("config/use_custom_user_dir=", "config/custom_user_dir_name=")))
require(without_isolation == source_settings, "QA settings differ beyond isolation entries")
results["checks"].append({"qa_settings_only_two_isolation_entries": True})
print("CONTROL BINDING PASSED", flush=True)


def invocation(folder, group):
    path = BENCH / folder / "invocations.json"
    require(file_digest(path) == file_digest(ORIGINAL / folder / path.name),
            "Archived invocation differs: " + folder)
    entries = read_json(path)
    matches = [entry for entry in entries if entry["group"] == group]
    require(len(matches) == 1, "Missing or duplicate invocation: " + folder + "/" + group)
    return matches[0]


def normalized_command(command):
    result = list(command)
    result[result.index("--path") + 1] = "<project>"
    return ["--label=<role>" if item.startswith("--label=") else item for item in result]


def verify_snapshot_bytes(raw, expected):
    position = 0
    for case in expected["cases"]:
        marker = raw.find(b'"snapshot":', position)
        require(marker >= 0, "No original snapshot bytes for " + case["id"])
        first = marker + len(b'"snapshot":')
        last = first + case["snapshot_bytes"]
        encoded = memoryview(raw)[first:last]
        require(digest(encoded) == case["snapshot_sha256"],
                "Original snapshot byte hash differs for " + case["id"])
        after = (',"snapshot_bytes":' + str(case["snapshot_bytes"])
                 + ',"snapshot_sha256":"' + case["snapshot_sha256"] + '"').encode()
        require(raw[last:last + len(after)] == after,
                "Original snapshot byte boundary differs for " + case["id"])
        position = last + len(after)
    require(raw.find(b'"snapshot":', position) == -1, "Extra top-level snapshot bytes")


def load_verified(folder, group, expected_failures=0, expected_samples=7):
    print("READ", folder, group, flush=True)
    inv = invocation(folder, group)
    for filename in (inv["output"], inv["log"], inv.get("sealed_output", group + ".sealed.json.gz")):
        require(file_digest(BENCH / folder / filename) == file_digest(ORIGINAL / folder / filename),
                "Archived artifact differs from original: " + folder + "/" + filename)
    compressed = (BENCH / folder / inv["output"]).read_bytes()
    require(len(compressed) == inv["compressed_bytes"], "Compressed size differs: " + folder)
    raw = gzip.decompress(compressed)
    require(len(raw) == inv["raw_bytes"], "Original JSON byte length differs: " + folder)
    raw_sha = digest(raw)
    require(raw_sha == inv["raw_sha256"], "Original raw hash differs: " + folder)
    original_json = (Path("/Users/yrq/Library/Application Support")
                     / inv["profile"] / "computation-benchmark.json")
    require(original_json.stat().st_size == len(raw)
            and file_digest(original_json) == raw_sha,
            "Isolated engine output differs from archived raw: " + folder)
    log = (BENCH / folder / inv["log"]).read_bytes()
    diagnostics = [line for line in log.decode("utf-8", errors="replace").splitlines()
                   if re.search(r"SCRIPT ERROR|ERROR:|Parse Error|WARNING:", line)]
    require(diagnostics == inv["diagnostics"], "Invocation log scan differs: " + folder)
    require(len(diagnostics) == expected_failures, "Unexpected actual log diagnostics: " + folder)
    require(inv["returncode"] == (1 if expected_failures else 0),
            "Unexpected recorded returncode: " + folder)
    expected = rec.seal(raw, log, inv["returncode"])
    verify_snapshot_bytes(raw, expected)
    raw_length = len(raw)
    del raw, compressed
    gc.collect()
    sealed = cmp.read(BENCH / folder / inv.get("sealed_output", group + ".sealed.json.gz"))
    difference = cmp.first_difference(expected, sealed)
    require(not difference, "Sealed record differs from original+process at " + folder + ": " + difference)
    require(len(sealed["failures"]) == expected_failures, "Wrong runner failure count: " + folder)
    require(sealed["samples"] == expected_samples, "Wrong samples: " + folder)
    require("--samples=" + str(expected_samples) in inv["command"], "Command samples differ: " + folder)
    require("--benchmark-group=" + group in inv["command"], "Command group differs: " + folder)
    declared = {entry["id"]: entry for entry in inv["cases"]}
    require(set(declared) == {case["id"] for case in sealed["cases"]},
            "Invocation case set differs from original output: " + folder)
    for case in sealed["cases"]:
        require(case["iterations"] == fixed[case["id"]]
                == declared[case["id"]]["iterations"],
                "Fixed batch mismatch: " + folder + "/" + case["id"])
        require(len(case["durations_us"]) == expected_samples, "Wrong actual duration count: " + case["id"])
        require(case["snapshot_bytes"] == declared[case["id"]]["snapshot_bytes"],
                "Invocation snapshot size mismatch: " + case["id"])
        require(case["median_us"] == declared[case["id"]]["median_us"],
                "Invocation median differs from original output: " + case["id"])
    data = {
        "folder": folder, "group": group, "raw_bytes": raw_length, "raw_sha256": raw_sha,
        "log_sha256": digest(log), "original_profile_raw_matches": True,
        "archive_matches_original_raw_sealed_log_invocation": True,
        "original_snapshot_byte_hashes_verified": len(sealed["cases"]),
        "sealed_exactly_preserves_original_fields": True,
        "cases": len(sealed["cases"]), "samples": sealed["samples"],
        "failures": expected_failures, "diagnostics": len(diagnostics),
    }
    results["artifacts"].append(data)
    del expected
    gc.collect()
    print("VERIFIED", folder, group, len(sealed["cases"]), "cases", flush=True)
    return sealed, inv


comparison_records = read_json(BENCH / "final-comparisons.json")
require(file_digest(BENCH / "final-comparisons.json")
        == file_digest(ORIGINAL / "final-comparisons.json"), "Final command archive differs")
comparator_hash = file_digest(ROOT / "scripts/benchmarks/computation/compare.py")
require(comparator_hash == "0a615f9e1ba14c2c89b5f6f85fa7f46be4d0f3323b47d9a52846e9defed4293e",
        "Comparator changed from final parser repair")
results["comparator_sha256"] = comparator_hash
pairs = [
    ("workload", "20261105T100056Z-reference-final", "20261105T100802Z-candidate-final", 12),
    ("memory", "20261105T100056Z-reference-final", "20261105T100802Z-candidate-final", 12),
    ("circuit", "20261105T101607Z-reference-circuit-final", "20261105T101623Z-candidate-circuit-final", 11),
]
all_ids = set()
if resume_known:
    all_ids = {case_id for group in results["groups"] for case_id in group["ratios"]}
for group, before_folder, after_folder, count in pairs:
    if resume_known:
        continue
    before, before_inv = load_verified(before_folder, group)
    after, after_inv = load_verified(after_folder, group)
    require(normalized_command(before_inv["command"]) == normalized_command(after_inv["command"]),
            "Actual invocation differs beyond project/label: " + group)
    actual = cmp.compare(before, after)
    require(actual["passed"] and len(actual["cases"]) == count, "Final comparison failed: " + group)
    saved_path = BENCH / after_folder / (group + ".comparison.json")
    require(file_digest(saved_path) == file_digest(ORIGINAL / after_folder / saved_path.name),
            "Archived comparison differs: " + group)
    require(not cmp.first_difference(actual, read_json(saved_path)),
            "Saved comparison differs from fresh complete comparison: " + group)
    command_record = [entry for entry in comparison_records if entry["group"] == group]
    require(len(command_record) == 1, "Missing comparison command: " + group)
    command_record = command_record[0]
    require(command_record["returncode"] == 0 and command_record["cases"] == count
            and command_record["comparator_sha256"] == comparator_hash,
            "Final comparison invocation binding mismatch: " + group)
    expected_inputs = [str(ORIGINAL / before_folder / (group + ".sealed.json.gz")),
                       str(ORIGINAL / after_folder / (group + ".sealed.json.gz"))]
    require(command_record["command"][3:5] == expected_inputs,
            "Comparator invocation input mismatch: " + group)
    ids = {case["id"] for case in before["cases"]}
    require(not ids & all_ids, "Duplicate case across groups")
    all_ids.update(ids)
    results["groups"].append({"group": group, "cases": count, "passed": True,
                              "fresh_comparison_matches_saved_exactly": True,
                              "actual_commands_match_except_project_and_label": True,
                              "ratios": {case["id"]: case["speed_ratio"] for case in actual["cases"]}})
    del before, after, actual
    gc.collect()
    print("COMPARISON PASSED", group, count, flush=True)

known_before, known_before_inv = load_verified(
    "20261105T101638Z-reference-circuit-known-failure", "circuit", 11, 3)
known_after, known_after_inv = load_verified(
    "20261105T101644Z-candidate-circuit-known-failure", "circuit", 11, 3)
require(normalized_command(known_before_inv["command"]) == normalized_command(known_after_inv["command"]),
        "Known-failure invocations differ beyond project/label")
require(not cmp.first_difference(known_before["cases"][0]["snapshot"], known_after["cases"][0]["snapshot"]),
        "Known-failure full snapshots changed")
require(not cmp.first_difference(known_before["cases"][0]["input"], known_after["cases"][0]["input"]),
        "Known-failure input changed")
require(known_before["failures"] == known_after["failures"], "Known failure list differs")
known_result = cmp.compare(known_before, known_after)
require(not known_result["passed"] and known_result["cases"] == [], "Known failure published timings")
saved_known = read_json(BENCH / "20261105T101644Z-candidate-circuit-known-failure/known-failure-comparison.json")
require(not cmp.first_difference(known_result, saved_known["strict_comparison"]),
        "Known-failure saved strict comparison differs")
require(len(all_ids) == 35 and "circuit.prologue.diagnostics" not in all_ids,
        "Known failure leaked into accepted corpus")
require(all_ids | {"circuit.prologue.diagnostics"} == set(fixed),
        "Combined case set does not account for all36 fixed cases")
results["known_failure"] = {
    "case": "circuit.prologue.diagnostics", "assertions_each_side": 11,
    "full_snapshot_input_failure_list_equal": True,
    "strict_comparison_rejected": True, "published_timing_cases": 0,
}
results["accepted_case_count"] = len(all_ids)
results["passed"] = not results["issues"]
OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
print("ALL ARTIFACT CHECKS PASSED", OUT, flush=True)
