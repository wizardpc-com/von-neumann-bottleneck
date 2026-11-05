"""Read-only Round10 evidence comparison after the separate host-caption patch.

Preserves the measured computation evidence and distinguishes later host source.
Never launches Godot. Final host runtime acceptance is explicitly out of scope.
"""
from pathlib import Path
import gzip
import hashlib
import importlib.util
import json
import re

ROOT = Path("/Users/yrq/Documents/冯诺伊曼瓶颈")
BASE = ROOT / ".godot/circuit-recovery-benchmarks"
OUT = Path("/private/tmp/vnb-round10-diagnostic-comparison.json")
RUNS = {
    "reference_valid": "20261105T111531Z-reference-valid",
    "candidate_valid": "20261105T112706Z-candidate-valid",
    "reference_diagnostic": "20261105T111710Z-reference-recovery-defect",
    "candidate_diagnostic": "20261105T112747Z-candidate-recovery",
}
results = {
    "passed": False, "artifacts": {}, "checks": [], "issues": [],
    "review_phase": "after-host-caption-source-change",
    "reviewer_correction": (
        "Initial checker assumed seven samples for the valid corpus; actual "
        "Round10 commands and receipts all explicitly use three. Corrected the "
        "checker to the observed three-sample contract without changing evidence.")
}


def module(name, filename):
    spec = importlib.util.spec_from_file_location(
        name, ROOT / "scripts/benchmarks/computation" / filename)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


cmp = module("round10_comparator", "compare.py")
rec = module("round10_recorder", "record.py")


def check(ok, description):
    if not ok:
        results["issues"].append(description)
        OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
        raise AssertionError(description)
    results["checks"].append(description)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_sha(path):
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def parse(raw):
    return json.loads(raw, object_pairs_hook=cmp._unique_object)


def dictionary(value):
    check(isinstance(value, dict) and set(value) == {
        "@dictionary", "key_type", "value_type"}, "Expected typed dictionary wrapper")
    pairs = value["@dictionary"]
    keys = [json.dumps(item["key"], sort_keys=True) for item in pairs]
    check(len(keys) == len(set(keys)), "Typed dictionary has no duplicate keys")
    # This accessor is only used for authored plain-string report keys.
    check(all(isinstance(item["key"], str) for item in pairs),
          "Report dictionary keys are plain strings")
    return {item["key"]: item["value"] for item in pairs}


def array(value):
    check(isinstance(value, dict) and set(value) == {
        "@array", "element_type"}, "Expected typed array wrapper")
    return value["@array"]


def same_container_metadata(left, right, payload_key, description):
    check({k: v for k, v in left.items() if k != payload_key}
          == {k: v for k, v in right.items() if k != payload_key}, description)


def changed_keys(left, right, expected, description):
    same_container_metadata(left, right, "@dictionary", description + ": wrapper types")
    before, after = dictionary(left), dictionary(right)
    check(before.keys() == after.keys(), description + ": complete key set unchanged")
    actual = {key for key in before if before[key] != after[key]}
    check(actual == set(expected), description + ": exact changed fields " + str(sorted(actual)))
    return before, after


def int_value(value):
    check(isinstance(value, dict) and set(value) == {"@int"}, "Expected exact integer")
    return int(value["@int"])


def named_value(value, name):
    check("@dictionary" in value, "Expected digital value map")
    matches = [pair["value"] for pair in value["@dictionary"]
               if pair["key"] == {"@string_name": name}]
    check(len(matches) == 1, "Exactly one signal " + name)
    digital = matches[0]
    check(digital.get("@script") == "res://src/circuit/digital_value.gd",
          "Actual DigitalValue script for " + name)
    fields = digital["fields"]
    return tuple(int_value(fields[key]) for key in ("width", "state", "value"))


def verify_original_snapshot_bytes(raw, data, role):
    position = 0
    for case in data["cases"]:
        marker = raw.find(b'"snapshot":', position)
        check(marker >= 0, role + ": original snapshot marker " + case["id"])
        first = marker + len(b'"snapshot":')
        last = first + case["snapshot_bytes"]
        check(sha(memoryview(raw)[first:last]) == case["snapshot_sha256"],
              role + ": original snapshot byte hash " + case["id"])
        suffix = (',"snapshot_bytes":' + str(case["snapshot_bytes"])
                  + ',"snapshot_sha256":"' + case["snapshot_sha256"] + '"').encode()
        check(raw[last:last + len(suffix)] == suffix,
              role + ": exact snapshot byte boundary " + case["id"])
        position = last + len(suffix)
    check(raw.find(b'"snapshot":', position) == -1, role + ": no extra snapshot")


fixed = parse((ROOT / ".godot/collaboration/round10-iterations.json").read_bytes())
preserved = {
    "py": "5e998bfd6ee39bd7b721993f92b9307b4ae91af0bb9bca59872dac55a2d5ed76",
    "json": "66b86bbb05c83c6251d56046d668b22292b8d49b47cfb3c55b0aefdfbe0e9d46",
    "md": "93ada2a15b52f7d7fe9da2bfe854052689f0ea88363d9bc3d2d9735296ee6d95",
}
for extension, expected in preserved.items():
    path = Path("/private/tmp/vnb-round10-diagnostic-measurement-phase." + extension)
    check(file_sha(path) == expected,
          "Original measurement-phase artifact preserved byte-for-byte: " + extension)
historical = parse(Path("/private/tmp/vnb-round10-diagnostic-measurement-phase.json").read_bytes())
check(historical["passed"] and not historical["issues"],
      "Original measurement-phase result passed before host change")
results["preserved_measurement_phase_artifacts"] = preserved


def load(role, failure_count, sample_count):
    folder = BASE / RUNS[role]
    invocations = parse((folder / "invocations.json").read_bytes())
    check(len(invocations) == 1 and invocations[0]["group"] == "circuit",
          role + ": one actual circuit invocation")
    invocation = invocations[0]
    raw = gzip.decompress((folder / invocation["output"]).read_bytes())
    check(len(raw) == invocation["raw_bytes"] and sha(raw) == invocation["raw_sha256"],
          role + ": exact archived raw bytes/hash")
    check((folder / invocation["output"]).stat().st_size == invocation["compressed_bytes"],
          role + ": exact compressed byte count")
    original = (Path("/Users/yrq/Library/Application Support")
                / invocation["profile"] / "computation-benchmark.json")
    check(original.stat().st_size == len(raw) and file_sha(original) == sha(raw),
          role + ": archive matches original isolated engine profile")
    log = (folder / invocation["log"]).read_bytes()
    diagnostics = [line for line in log.decode().splitlines()
                   if re.search(r"SCRIPT ERROR|ERROR:|Parse Error|WARNING:", line)]
    check(diagnostics == invocation["diagnostics"],
          role + ": complete actual log scan agrees with invocation")
    check(invocation["returncode"] == (1 if failure_count else 0)
          and len(diagnostics) == failure_count,
          role + ": expected process exit and log diagnostics")
    check(not any("SCRIPT ERROR" in line or "Parse Error" in line for line in diagnostics),
          role + ": no parser/runtime script error")
    raw_data = parse(raw)
    sealed = cmp.read(folder / invocation["sealed_output"])
    resealed = rec.seal(raw, log, invocation["returncode"])
    check(not cmp.first_difference(resealed, sealed),
          role + ": sealed receipt exactly reproduces raw+process/log")
    verify_original_snapshot_bytes(raw, raw_data, role)
    check(len(sealed["failures"]) == failure_count
          and sealed["failures"] == invocation["failures"],
          role + ": exact runner failures")
    check(sealed["samples"] == sample_count
          and "--samples=" + str(sample_count) in invocation["command"],
          role + ": actual command sample count")
    declared = {case["id"]: case for case in invocation["cases"]}
    check(set(declared) == {case["id"] for case in sealed["cases"]},
          role + ": exact scenario set")
    for case in sealed["cases"]:
        check(case["iterations"] == fixed[case["id"]]
              == declared[case["id"]]["iterations"],
              role + ": fixed iteration count " + case["id"])
        check(len(case["durations_us"]) == sample_count
              and case["snapshot_bytes"] == declared[case["id"]]["snapshot_bytes"],
              role + ": actual samples/snapshot length " + case["id"])
    results["artifacts"][role] = {
        "directory": str(folder), "profile": invocation["profile"],
        "project": invocation["command"][invocation["command"].index("--path") + 1],
        "raw_bytes": len(raw), "raw_sha256": sha(raw), "log_sha256": sha(log),
        "sealed_file_sha256": file_sha(folder / invocation["sealed_output"]),
        "scenario_count": len(sealed["cases"]), "samples": sample_count,
        "failures": failure_count, "returncode": invocation["returncode"],
    }
    return sealed, invocation


before_valid, before_valid_inv = load("reference_valid", 0, 3)
after_valid, after_valid_inv = load("candidate_valid", 0, 3)
before_bad, before_bad_inv = load("reference_diagnostic", 14, 3)
after_fixed, after_fixed_inv = load("candidate_diagnostic", 0, 3)
check(results["artifacts"] == historical["artifacts"],
      "All four benchmark artifacts retain their exact original measurement identity")


def normalized_command(command):
    normalized = list(command)
    normalized[normalized.index("--path") + 1] = "<project>"
    return ["--label=<role>" if part.startswith("--label=") else part
            for part in normalized]


check(normalized_command(before_valid_inv["command"])
      == normalized_command(after_valid_inv["command"]),
      "Valid corpus invocations differ only in project/label")
check(normalized_command(before_bad_inv["command"])
      == normalized_command(after_fixed_inv["command"]),
      "Diagnostic invocations differ only in project/label")
parity = cmp.compare(before_valid, after_valid)
check(parity["passed"] and len(parity["cases"]) == 11,
      "All eleven accepted full typed input/result/state/event scenarios are exact")
saved_parity = parse((ROOT / ".godot/collaboration/round10-valid-comparison.json").read_bytes())
check(not cmp.first_difference(parity, saved_parity),
      "Independent exact comparison reproduces root's saved comparison")
results["valid_scenario_ids"] = [case["id"] for case in before_valid["cases"]]

old_case, new_case = before_bad["cases"][0], after_fixed["cases"][0]
check(old_case["id"] == new_case["id"] == "circuit.prologue.diagnostics",
      "Same diagnostic scenario identity")
check(old_case["input"] == new_case["input"],
      "Complete diagnostic authored typed inputs are unchanged")
old_members = array(dictionary(old_case["snapshot"])["members"])
new_members = array(dictionary(new_case["snapshot"])["members"])
check(len(old_members) == len(new_members) == 12, "Exactly twelve diagnostic members")
same_container_metadata(old_case["snapshot"], new_case["snapshot"], "@dictionary",
                        "Diagnostic snapshot container types unchanged")
same_container_metadata(dictionary(old_case["snapshot"])["members"],
                        dictionary(new_case["snapshot"])["members"], "@array",
                        "Diagnostic member array types unchanged")
changed = []
unaffected = []
for old, new in zip(old_members, new_members):
    old_fields, new_fields = dictionary(old), dictionary(new)
    name = old_fields["name"]
    check(name == new_fields["name"], "Diagnostic member ordering unchanged: " + name)
    if old != new:
        changed.append(name)
    else:
        unaffected.append(name)
check(changed == ["failed_step_state_recovery"],
      "Only the explicitly scoped recovery diagnostic changed")
results["unchanged_diagnostic_members"] = unaffected
results["changed_diagnostic_members"] = changed
recovery_index = next(i for i, item in enumerate(old_members)
                      if dictionary(item)["name"] == changed[0])
old_recovery_member, new_recovery_member = (
    old_members[recovery_index], new_members[recovery_index])
old_member, new_member = changed_keys(
    old_recovery_member, new_recovery_member, {"result"}, "Recovery member")
old, new = changed_keys(old_member["result"], new_member["result"],
                       {"continued_steps", "prior_outputs", "whole_sequence"},
                       "Recovery complete workflow")
old_whole, new_whole = changed_keys(
    old["whole_sequence"], new["whole_sequence"],
    {"canonical_signature", "events", "final_result", "prior_outputs", "steps"},
    "Whole sequence")
old_steps, new_steps = array(old_whole["steps"]), array(new_whole["steps"])
check(len(old_steps) == len(new_steps) == 3, "Whole sequence still has three steps")
check(old_steps[:2] == new_steps[:2],
      "Complete successful WRITE and failed short observations are byte-structure exact")
check([dictionary(step)["passed"] for step in old_steps] == [True, False, False]
      and [dictionary(step)["passed"] for step in new_steps] == [True, False, True],
      "Only corrected HOLD changes from failed to successful")
check(old_whole["passed"] is False and new_whole["passed"] is False,
      "Overall sequence remains failed because the middle stimulus failed")
old_cont, new_cont = array(old["continued_steps"]), array(new["continued_steps"])
check(len(old_cont) == len(new_cont) == 3, "Continuation still has three step reports")
check(old_cont[0] == new_cont[0], "First incremental WRITE report is completely exact")
old_failure, new_failure = changed_keys(
    old_cont[1], new_cont[1], {"prior_outputs"}, "Incremental failed short report")
first = dictionary(new_cont[0])
check(new_failure["prior_outputs"] == first["prior_outputs"]
      == new_failure["initial_prior_outputs"],
      "Failed continuation returns exactly the incoming last-valid output carry")
check(old_failure["prior_outputs"] != new_failure["prior_outputs"],
      "Old failed carry and corrected continuation seed are concretely distinct")
old_last, new_last = changed_keys(
    old_cont[2], new_cont[2],
    {"canonical_signature", "events", "final_result", "initial_prior_outputs",
     "passed", "prior_outputs", "steps"}, "Incremental corrected HOLD")
check(new_last["initial_prior_outputs"] == new_failure["prior_outputs"]
      and new_last["initial_runtime_state"] == new_failure["runtime_state"],
      "Corrected HOLD receives retained carry and actual register state")
check(new_last["passed"] is True and old_last["passed"] is False,
      "Incremental corrected HOLD recovers without reset")
new_final = new_last["final_result"]["fields"]
check(new_final["settled"] is True and array(new_final["errors"]) == [],
      "Recovered final observation is electrically valid with no old error")
check(named_value(new_final["observed_values"], "OUT") == (4, 0, 3),
      "Recovered actual four-bit observed OUT is known three")
check(new["runtime_state"] == old["runtime_state"]
      == new_whole["runtime_state"] == new_last["runtime_state"],
      "Complete committed storage is unchanged across old/new and whole/incremental")
check(new["prior_outputs"] == new_whole["prior_outputs"]
      == new_last["prior_outputs"] == new_final["output_values"],
      "Final output carry equals actual valid final outputs across both workflows")
prefix_count = len(array(first["events"])) + len(array(new_failure["events"]))
old_events, new_events = array(old_whole["events"]), array(new_whole["events"])
check(prefix_count == 25 and old_events[:prefix_count] == new_events[:prefix_count],
      "All twenty-five pre-recovery whole-sequence events are exactly preserved")
check(len(old_events) == 31 and len(new_events) == 41,
      "Only final recovery contributes changed whole-sequence event tail: 31 to 41")
check(len(array(old_last["events"])) == 6 and len(array(new_last["events"])) == 16,
      "Corrected incremental HOLD records sixteen real events versus six stale-error events")
strict_diagnostic = cmp.compare(before_bad, after_fixed)
check(not strict_diagnostic["passed"] and not strict_diagnostic["cases"],
      "Strict benchmark comparator rejects failed reference; no diagnostic speed claim")

reference_manifest = parse((ROOT / ".godot/collaboration/round10-reference.json").read_bytes())
reference_project = Path(results["artifacts"]["reference_valid"]["project"])
candidate_project = Path(results["artifacts"]["candidate_valid"]["project"])
check(reference_project == Path(reference_manifest["project"]),
      "Benchmark reference project equals frozen base manifest")
check(results["artifacts"]["reference_diagnostic"]["project"] == str(reference_project)
      and results["artifacts"]["candidate_diagnostic"]["project"] == str(candidate_project),
      "Each runtime uses the same project for valid and diagnostic runs")
runtime_changes = []
for name, expected_hash in reference_manifest["runtime_files"].items():
    check(file_sha(reference_project / name) == expected_hash,
          "Frozen base runtime file unchanged: " + name)
    source_hash = file_sha(ROOT / name)
    check(file_sha(candidate_project / name) == source_hash,
          "Candidate runtime matches current source: " + name)
    if source_hash != expected_hash:
        runtime_changes.append(name)
check(runtime_changes == [
    "src/circuit/prologue_simulator.gd",
    "src/hardware_foundations/hardware_foundations.gd"],
    "Current source differs in simulator plus separately patched host presentation")
measured = parse((ROOT / ".godot/collaboration/round10-measured-gd-sha256.json").read_bytes())
for name, expected_hash in measured.items():
    for project in (ROOT, reference_project, candidate_project):
        check(file_sha(project / "scripts/benchmarks/computation" / name) == expected_hash,
              "Measured harness identical in source/reference/candidate: " + name)


def circuit_dependency_closure(project):
    """Conservative source closure: literal loads plus project script-class tokens.

    The only nonliteral load must be the runner's GROUPS[group]. The exact
    recorded commands select circuit, so circuit_cases.gd is its explicit seed.
    This does not claim a dynamic module-load trace or execute any host UI.
    """
    classes = {}
    for parent in ("src", "experiments", "scripts/benchmarks/computation"):
        for path in (project / parent).rglob("*.gd"):
            text = path.read_text()
            match = re.search(r"^class_name\s+(\w+)", text, re.M)
            if match:
                name = match.group(1)
                check(name not in classes, "No duplicate project script class: " + name)
                classes[name] = str(path.relative_to(project))
    seen = set()
    dynamic_loads = []
    pending = ["scripts/benchmarks/computation/runner.gd",
               "scripts/benchmarks/computation/circuit_cases.gd"]
    while pending:
        name = pending.pop()
        if name in seen:
            continue
        seen.add(name)
        text = (project / name).read_text()
        for dependency in re.findall(
                r'(?:preload|load)\s*\(\s*["\']res://([^"\']+)["\']\s*\)', text):
            if dependency.endswith(".gd"):
                pending.append(dependency)
        for script_class in set(re.findall(r"\b[A-Za-z_]\w*\b", text)) & classes.keys():
            pending.append(classes[script_class])
        for line in text.splitlines():
            if (re.search(r"(?<!pre)\bload\s*\(", line)
                    and not re.search(r'load\s*\(\s*["\']res://', line)):
                dynamic_loads.append([name, line.strip()])
    check(dynamic_loads == [[
        "scripts/benchmarks/computation/runner.gd",
        "var adapter: Script = load(GROUPS[group])"]],
        "Only dynamic load is the recorded circuit adapter selection")
    return sorted(seen)


reference_dependencies = circuit_dependency_closure(reference_project)
source_dependencies = circuit_dependency_closure(ROOT)
candidate_dependencies = circuit_dependency_closure(candidate_project)
check(reference_dependencies == source_dependencies == candidate_dependencies,
      "Circuit computation dependency closure unchanged in all three copies")
host_path = "src/hardware_foundations/hardware_foundations.gd"
simulator_path = "src/circuit/prologue_simulator.gd"
check(host_path not in source_dependencies and simulator_path in source_dependencies,
      "Selected computation closure contains simulator and excludes Hardware host")
check(historical["source_binding"]["changed_runtime_files"] == [simulator_path],
      "Original measurement phase had only the simulator runtime change")
dependency_hashes = {}
for name in source_dependencies:
    if name.startswith("scripts/benchmarks/computation/"):
        expected = measured[Path(name).name]
    elif name == simulator_path:
        expected = historical["source_binding"]["candidate_simulator_sha256"]
    else:
        expected = reference_manifest["runtime_files"][name]
    check(file_sha(ROOT / name) == file_sha(candidate_project / name) == expected,
          "Current computation dependency retains measured bytes: " + name)
    dependency_hashes[name] = expected
check(len(source_dependencies) == 28, "Exactly twenty-eight selected computation scripts")

results["source_binding"] = {
    "base": reference_manifest["base"], "runtime_file_count": len(reference_manifest["runtime_files"]),
    "current_changed_runtime_files": runtime_changes,
    "measurement_phase_changed_runtime_files": historical["source_binding"]["changed_runtime_files"],
    "identical_measured_scripts": len(measured),
    "reference_simulator_sha256": file_sha(reference_project / "src/circuit/prologue_simulator.gd"),
    "candidate_simulator_sha256": file_sha(candidate_project / "src/circuit/prologue_simulator.gd"),
    "selected_computation_dependency_count": len(source_dependencies),
    "selected_computation_dependency_sha256": dependency_hashes,
    "dependency_method": "conservative static literal-load and script-class closure",
}
results["host_presentation"] = {
    "path": host_path,
    "measurement_phase_sha256": reference_manifest["runtime_files"][host_path],
    "current_source_sha256": file_sha(ROOT / host_path),
    "current_candidate_sha256": file_sha(candidate_project / host_path),
    "candidate_directory_updated_after_computation_measurement": True,
    "excluded_from_selected_computation_dependency_closure": True,
    "new_runtime_or_visual_acceptance_by_this_checker": False,
    "acceptance_owner": "root; separate final host regression and GPU receipts",
}
results["recovery"] = {
    "old_step_pass": [True, False, False], "new_step_pass": [True, False, True],
    "overall_pass_stays_false": True, "unchanged_pre_recovery_events": prefix_count,
    "whole_events_before_after": [len(old_events), len(new_events)],
    "incremental_hold_events_before_after": [6, 16],
    "failed_incremental_changed_fields": ["prior_outputs"],
    "failed_observation_complete_preserved": True,
    "actual_recovered_output": {"width": 4, "state": "known", "value": 3},
    "storage_unchanged": True,
    "strict_failed_reference_comparison_rejected": True,
    "diagnostic_speed_claims": 0,
}
results["passed"] = True
results["check_count"] = len(results["checks"])
OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({
    "passed": True, "check_count": results["check_count"],
    "raw_bytes_verified": sum(item["raw_bytes"] for item in results["artifacts"].values()),
    "valid_scenarios_exact": len(results["valid_scenario_ids"]),
    "unaffected_diagnostics_exact": len(unaffected),
    "recovery": results["recovery"], "source_binding": results["source_binding"],
    "output": str(OUT)}, ensure_ascii=False, indent=2))
