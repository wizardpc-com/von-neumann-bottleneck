#!/usr/bin/env python3
"""Read-only Round11 typed-artifact, intentional-difference and source audit.

Never launches Godot or mutates Git. The original strict comparator is imported
unchanged. The failed historical diagnostic is inspected separately, never
rewritten into a successful benchmark receipt.
"""
import argparse
import datetime
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import statistics
import subprocess


ROOT = Path("/Users/yrq/Documents/冯诺伊曼瓶颈")
BASE = ROOT / ".godot/region-rejection-benchmarks"
OUT = Path("/private/tmp/vnb-round11-diagnostic-compare.json")
REPORT = Path("/private/tmp/vnb-round11-diagnostic-compare.md")
BASE_COMMIT = "cf27a8236db7faca56d6361cf9a44d35224b748e"
ZERO_METRICS = [
    "total_cycles", "request_cycles", "transfer_cycles", "decode_cycles",
    "consume_cycles", "stored_bytes", "traffic_bytes", "decoded_values",
    "decode_ops", "cache_hits", "cache_misses", "evictions",
    "overfetch_values", "peak_cache_bytes",
]
EMPTY_METRICS = ["outputs", "expected", "blocks", "accesses"]
TRACE_SCRIPT = "res://src/simulation/simulation_trace.gd"
results = {
    "passed": False, "checked_at_utc": datetime.datetime.now(
        datetime.timezone.utc).isoformat(), "artifacts": {}, "checks": [],
    "issues": [], "engine_executions_by_reviewer": 0, "git_mutations": 0,
    "speedup_claim": False,
    "checker_correction": {
        "initial_result": "/private/tmp/vnb-round11-diagnostic-initial-checker-failure.json",
        "reason": "Frozen QA profile insertion adds one blank line after [application].",
        "scope": "Allow only that exact source-settings formatting difference; typed evidence comparison unchanged.",
    },
}


def module(name, filename):
    spec = importlib.util.spec_from_file_location(
        name, ROOT / "scripts/benchmarks/computation" / filename)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


cmp = module("round11_exact_comparator", "compare.py")
rec = module("round11_process_recorder", "record.py")


def check(ok, description):
    if not ok:
        results["issues"].append(description)
        OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
        raise AssertionError(description)
    results["checks"].append(description)


def same(left, right):
    return not cmp.first_difference(left, right)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_sha(path):
    return sha(path.read_bytes())


def parse(raw):
    return json.loads(raw, object_pairs_hook=cmp._unique_object,
                      parse_constant=rec._invalid_constant)


def dictionary(value):
    check(type(value) is dict and set(value) == {
        "@dictionary", "key_type", "value_type"}, "Complete typed dictionary")
    pairs = value["@dictionary"]
    check(type(pairs) is list and all(
        type(pair) is dict and set(pair) == {"key", "value"}
        and type(pair["key"]) is str for pair in pairs),
        "Authored report dictionary contains complete plain-string pairs")
    check(len({pair["key"] for pair in pairs}) == len(pairs),
          "Typed dictionary has unique keys")
    return {pair["key"]: pair["value"] for pair in pairs}


def array(value):
    check(type(value) is dict and set(value) == {"@array", "element_type"}
          and type(value["@array"]) is list, "Complete typed array")
    return value["@array"]


def integer(value):
    check(type(value) is dict and set(value) == {"@int"}
          and type(value["@int"]) is str
          and re.fullmatch(r"0|-?[1-9][0-9]*", value["@int"]) is not None,
          "Canonical integer64 evidence")
    amount = int(value["@int"])
    check(-(2**63) <= amount < 2**63, "Integer evidence within signed64 domain")
    return amount


def metadata(value, payload):
    return {key: item for key, item in value.items() if key != payload}


def snapshot_bytes(raw, receipt, role):
    offset = 0
    for case in receipt["cases"]:
        marker = raw.find(b'"snapshot":', offset)
        check(marker >= 0, role + ": original snapshot property " + case["id"])
        start = marker + len(b'"snapshot":')
        end = start + case["snapshot_bytes"]
        check(sha(raw[start:end]) == case["snapshot_sha256"],
              role + ": complete original snapshot bytes/hash " + case["id"])
        check(same(parse(raw[start:end]), case["snapshot"]),
              role + ": hash-covered bytes are the complete parsed snapshot")
        tail = (',"snapshot_bytes":' + str(case["snapshot_bytes"])
                + ',"snapshot_sha256":"' + case["snapshot_sha256"] + '"').encode()
        check(raw[end:end + len(tail)] == tail,
              role + ": exact original snapshot byte boundary")
        offset = end + len(tail)
    check(raw.find(b'"snapshot":', offset) == -1, role + ": no extra snapshot")


def load_artifact(role, directory, negative=False):
    folder = directory.resolve()
    invocation_file = folder / "invocations.json"
    invocations = parse(invocation_file.read_bytes())
    check(type(invocations) is list and len(invocations) == 1
          and invocations[0]["group"] == "workload",
          role + ": one actual workload invocation")
    inv = invocations[0]
    raw_archive = folder / inv["output"]
    raw = gzip.decompress(raw_archive.read_bytes())
    check(len(raw) == inv["raw_bytes"] and sha(raw) == inv["raw_sha256"],
          role + ": original archived JSON bytes/hash")
    check(raw_archive.stat().st_size == inv["compressed_bytes"],
          role + ": compressed byte count")
    original = (Path("/Users/yrq/Library/Application Support") / inv["profile"]
                / "computation-benchmark.json")
    check(original.read_bytes() == raw,
          role + ": archive is byte-exact original isolated engine output")
    log_file = folder / inv["log"]
    log = log_file.read_bytes()
    diagnostics = [line for line in log.decode().splitlines()
                   if rec.DIAGNOSTIC.search(line)]
    check(diagnostics == inv["diagnostics"], role + ": complete log diagnostics")
    check(not any("SCRIPT ERROR" in line or "Parse Error" in line
                  or "WARNING:" in line for line in diagnostics),
          role + ": no runtime/parser/warning diagnostics")
    check(inv["returncode"] == (1 if negative else 0),
          role + ": actual expected process exit")
    receipt = parse(raw)
    sealed = cmp.read(folder / inv["sealed_output"])
    check(same(rec.seal(raw, log, inv["returncode"]), sealed),
          role + ": sealed receipt exactly reproduces original process/log/JSON")
    check(receipt["failures"] == inv["failures"],
          role + ": invocation preserves every runner failure")
    if negative:
        check(len(diagnostics) == len(receipt["failures"]) == 15
              and diagnostics == ["ERROR: " + line for line in receipt["failures"]]
              and all(line.startswith("workload_rejections: region/rejected:")
                      for line in receipt["failures"]),
              role + ": exactly15 expected residual Region diagnostics")
    else:
        check(not diagnostics and not receipt["failures"],
              role + ": successful runner and clean complete process log")
    validation = cmp.validate_receipt(sealed, role)
    check(len(validation) == (3 if negative else 0),
          role + ": strict receipt validation has only expected negative failures")
    command = inv["command"]
    check("--samples=3" in command and receipt["samples"] == 3
          and "--headless" in command
          and command[command.index("--script") + 1]
          == "res://scripts/benchmarks/computation/runner.gd",
          role + ": recorded three-sample actual engine command")
    check("--iterations-file=" + str(ROOT / ".godot/collaboration/round11-iterations.json")
          in command, role + ": intended fixed iteration manifest")
    fixed = parse((ROOT / ".godot/collaboration/round11-iterations.json").read_bytes())
    declared = {case["id"]: case for case in inv["cases"]}
    check(set(declared) == {case["id"] for case in receipt["cases"]},
          role + ": exact invocation scenario set")
    snapshot_bytes(raw, receipt, role)
    for case in receipt["cases"]:
        name = case["id"]
        check(case["iterations"] == fixed[name] == declared[name]["iterations"],
              role + ": fixed timed batch " + name)
        per_call = [duration / case["iterations"] for duration in case["durations_us"]]
        check(len(per_call) == 3 and per_call == case["per_call_us"]
              and statistics.median(per_call) == case["median_us"]
              and min(per_call) == case["min_us"] and max(per_call) == case["max_us"],
              role + ": complete samples reconcile with timing summaries")
        check(case["snapshot_bytes"] == declared[name]["snapshot_bytes"],
              role + ": invocation binds complete snapshot size")
    results["artifacts"][role] = {
        "directory": str(folder), "project": command[command.index("--path") + 1],
        "profile": inv["profile"], "command": command,
        "raw_bytes": len(raw), "raw_sha256": sha(raw),
        "original_output": str(original), "log_sha256": sha(log),
        "sealed_sha256": file_sha(folder / inv["sealed_output"]),
        "invocations_sha256": file_sha(invocation_file),
        "returncode": inv["returncode"], "failure_count": len(receipt["failures"]),
        "samples": 3,
    }
    return sealed, inv


def normalized_command(command):
    result = list(command)
    result[result.index("--path") + 1] = "<isolated-project>"
    return ["--label=<role>" if part.startswith("--label=") else part for part in result]


def inspect_valid(receipt):
    cases = {case["id"]: case for case in receipt["cases"]}
    check(set(cases) == {"representation_region_compatibility", "representation_online_clients"},
          "Exactly the two declared valid Region workloads")
    rows = array(cases["representation_region_compatibility"]["snapshot"])
    check(len(rows) == 5, "All five authored tasks present")
    trace_count = 0
    decisions = []
    for task_index, task_value in enumerate(rows):
        task = dictionary(task_value)
        check(integer(task["task"]) == task_index, "Ordered authored task identity")
        plans = array(task["plans"])
        check(len(plans) == 4, "Four intended plans per task")
        for plan_index, plan_value in enumerate(plans):
            plan = dictionary(plan_value)
            check(type(plan["accepted"]) is bool, "Actual boolean meets decision")
            traces = array(plan["traces"])
            check(len(traces) == [1, 1, 2, 2, 2][task_index],
                  "Every plan retains all task orders")
            for trace in traces:
                check(set(trace) == {"@script", "fields"}
                      and trace["@script"] == TRACE_SCRIPT
                      and trace["fields"]["passed"] is True
                      and trace["fields"]["test_name"] == "representation-region-v1",
                      "Original successful complete Region Trace object")
            trace_count += len(traces)
            decisions.append({"task": task_index, "plan_index": plan_index,
                              "accepted": plan["accepted"]})
    online = array(cases["representation_online_clients"]["snapshot"])
    check(len(online) == 2, "Two original online plan rows")
    online_traces = 0
    for value in online:
        traces = array(dictionary(value)["traces"])
        check(len(traces) == 2 and all(
            trace.get("@script") == TRACE_SCRIPT
            and trace["fields"]["passed"] is True
            and trace["fields"]["test_name"] == "representation-region-v1"
            for trace in traces), "Two original successful online Trace objects per plan")
        online_traces += len(traces)
    check(trace_count == 32 and len(decisions) == 20 and online_traces == 4,
          "32 corpus traces/20 decisions plus four existing online traces retained")
    return {"corpus_trace_count": trace_count, "corpus_meets_decisions": decisions,
            "existing_online_trace_count": online_traces,
            "existing_online_decision_count": len(online),
            "complete_trace_count": trace_count + online_traces,
            "case_snapshot_hashes": {name: case["snapshot_sha256"] for name, case in cases.items()}}


def inspect_diagnostic(old_receipt, new_receipt):
    old_case, new_case = old_receipt["cases"][0], new_receipt["cases"][0]
    check(len(old_receipt["cases"]) == len(new_receipt["cases"]) == 1
          and old_case["id"] == new_case["id"] == "workload_rejections",
          "Same single combined rejection diagnostic")
    check(same(old_case["input"], new_case["input"]),
          "Every complete authored diagnostic input unchanged")
    before_snapshot, after_snapshot = old_case["snapshot"], new_case["snapshot"]
    check(same(metadata(before_snapshot, "@dictionary"),
               metadata(after_snapshot, "@dictionary")),
          "Diagnostic outer dictionary types unchanged")
    before, after = dictionary(before_snapshot), dictionary(after_snapshot)
    check(before.keys() == after.keys(), "Complete diagnostic member set unchanged")
    changed = [key for key in before if not same(before[key], after[key])]
    check(changed == ["region"], "Only Region diagnostic changes")
    old_trace, new_trace = before["region"], after["region"]
    check(set(old_trace) == set(new_trace) == {"@script", "fields"}
          and old_trace["@script"] == new_trace["@script"] == TRACE_SCRIPT,
          "Actual Trace script identity and object schema unchanged")
    old, new = old_trace["fields"], new_trace["fields"]
    check(old.keys() == new.keys(), "Every top-level Trace field preserved")
    changed_trace = sorted(key for key in old if not same(old[key], new[key]))
    check(changed_trace == ["expected_value", "metrics", "result_value"],
          "Only metrics and two completed scalar results change")
    check(new["passed"] is False and new["test_name"] == "representation-region-v1"
          and integer(new["result_value"]) == integer(new["expected_value"]) == 0
          and integer(new["cache_capacity_lines"]) == 1
          and array(new["events"]) == [] and array(new["loop_order"]) == []
          and new["program_source"] == "",
          "Rejected result retains exact fresh Trace defaults and failed identity")
    check(same(metadata(old["metrics"], "@dictionary"),
               metadata(new["metrics"], "@dictionary")),
          "Metric dictionary container types preserved")
    old_metrics, new_metrics = dictionary(old["metrics"]), dictionary(new["metrics"])
    allowed = set(ZERO_METRICS + EMPTY_METRICS)
    check(old_metrics.keys() == new_metrics.keys() == allowed | {"error", "spec", "plan"},
          "Exact existing21-field rejection metric schema preserved")
    check(all(same(old_metrics[key], new_metrics[key]) for key in ("error", "spec", "plan"))
          and new_metrics["error"] == "preparation_machine",
          "Full typed submitted spec/plan and exact error preserved")
    numeric = {}
    for field in ZERO_METRICS:
        old_number, new_number = integer(old_metrics[field]), integer(new_metrics[field])
        check(new_number == 0, "Rejected metric is exact integer zero: " + field)
        numeric[field] = {"before": old_number, "after": new_number,
                          "changed": not same(old_metrics[field], new_metrics[field])}
    check(sum(row["changed"] for row in numeric.values()) == 9,
          "Exactly nine residual numeric fields change; five zeros stay exact")
    arrays = {}
    untyped = {"builtin": 0, "class": "", "script": ""}
    for field in EMPTY_METRICS:
        check(array(new_metrics[field]) == []
              and new_metrics[field]["element_type"] == untyped,
              "Rejected metric is a fresh empty untyped array: " + field)
        arrays[field] = {"before_length": len(array(old_metrics[field])),
                         "after_length": 0,
                         "before_element_type": old_metrics[field]["element_type"],
                         "after_element_type": new_metrics[field]["element_type"]}
        check(arrays[field]["before_length"] == 1
              and arrays[field]["before_element_type"]["builtin"]
              == {"outputs": 2, "expected": 2, "blocks": 27, "accesses": 0}[field],
              "Exact retained-evidence array length/type before correction: " + field)
    check(integer(old["result_value"]) == integer(old["expected_value"]) == 7,
          "Actual discarded complete source result was seven")
    changed_metrics = sorted(key for key in old_metrics
                             if not same(old_metrics[key], new_metrics[key]))
    check(set(changed_metrics) <= allowed,
          "No metrics beyond explicitly authorized execution fields changed")
    strict = cmp.compare(old_receipt, new_receipt)
    check(not strict["passed"] and strict["cases"] == [],
          "Unmodified strict comparator rejects failed historical diagnostic")
    return {
        "unchanged_sibling_count": len(before) - 1,
        "unchanged_siblings": sorted(set(before) - {"region"}),
        "changed_trace_fields": changed_trace,
        "changed_metric_fields": changed_metrics, "numeric_metrics": numeric,
        "empty_arrays": arrays,
        "result_value_before_after": [integer(old["result_value"]), integer(new["result_value"])],
        "expected_value_before_after": [integer(old["expected_value"]), integer(new["expected_value"])],
        "strict_comparator_rejected": True, "strict_comparator_issues": strict["issues"],
        "equal_work_timing_comparison": False,
    }


def git_blob_hashes(commit, names):
    request = "".join(commit + ":" + name + "\n" for name in names).encode()
    process = subprocess.run(["git", "cat-file", "--batch"], input=request,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             cwd=ROOT, check=True)
    data = process.stdout
    cursor = 0
    hashes = {}
    for name in names:
        boundary = data.index(b"\n", cursor)
        header = data[cursor:boundary].split()
        check(len(header) == 3 and header[1] == b"blob",
              "Frozen base contains exact Git blob: " + name)
        size = int(header[2])
        start = boundary + 1
        hashes[name] = sha(data[start:start + size])
        check(data[start + size:start + size + 1] == b"\n",
              "Complete Git blob boundary: " + name)
        cursor = start + size + 1
    check(cursor == len(data), "All requested original Git blob bytes consumed")
    return hashes


def bind_source():
    reference = parse((ROOT / ".godot/collaboration/round11-reference.json").read_bytes())
    candidate = parse((ROOT / ".godot/collaboration/round11-candidate.json").read_bytes())
    check(reference["base"] == candidate["base"] == BASE_COMMIT,
          "Frozen and candidate manifests bind the declared Round10 base")
    before, after = Path(reference["project"]), Path(candidate["project"])
    for role, project in [("reference_valid", before), ("reference_diagnostic", before),
                          ("candidate_valid", after), ("candidate_diagnostic", after)]:
        check(results["artifacts"][role]["project"] == str(project),
              role + ": measured actual project matches source manifest")
    names = sorted(reference["runtime_files"])
    git_hashes = git_blob_hashes(BASE_COMMIT, names)
    check(git_hashes == reference["runtime_files"],
          "Every frozen source-manifest hash equals its original committed Git bytes")
    changes = []
    candidate_hashes = {}
    for name in names:
        expected = git_hashes[name]
        check(file_sha(before / name) == expected, "Unchanged frozen runtime: " + name)
        current = file_sha(ROOT / name)
        check(file_sha(after / name) == current, "Candidate equals reviewed source: " + name)
        candidate_hashes[name] = current
        if current != expected:
            changes.append(name)
    check(changes == ["experiments/representation_region/README.md",
                      "experiments/representation_region/model.gd"],
          "Only scoped Region model and companion README differ in runtime manifest")
    measured = parse((ROOT / ".godot/collaboration/round11-measured-gd-sha256.json").read_bytes())
    for name, expected in measured.items():
        check(all(file_sha(project / name) == expected for project in (ROOT, before, after)),
              "Identical measured harness in all copies: " + name)
    support_names = ["scripts/benchmarks/computation/compare.py",
                     "scripts/benchmarks/computation/record.py",
                     "experiments/representation/plan_model.gd",
                     "experiments/representation/model.gd",
                     "src/simulation/simulation_trace.gd"]
    support = git_blob_hashes(BASE_COMMIT, support_names)
    for name, expected in support.items():
        check(all(file_sha(project / name) == expected for project in (ROOT, before, after)),
              "Base model/Trace/strict evidence tools remain exact: " + name)
    old_model = (before / "experiments/representation_region/model.gd").read_text()
    new_model = (after / "experiments/representation_region/model.gd").read_text()
    def base_prefix(text):
        return text.split("static func run(", 1)[1].split("\tif not spec.get(", 1)[0]
    check(base_prefix(old_model) == base_prefix(new_model)
          and "var service: Trace = Base.run(spec,plan)" in base_prefix(new_model)
          and "if not service.passed: return service" in base_prefix(new_model),
          "Exact Base delegation and error-precedence prefix preserved")
    def successful_body(text):
        return text.split("\tvar trace := Trace.new(); trace.test_name = VERSION", 1)[1].split(
            "\nstatic func ", 1)[0].strip()
    check(successful_body(old_model) == successful_body(new_model),
          "Entire valid Region computation body remains source-exact")
    source_project = (ROOT / "project.godot").read_text().splitlines()
    for label, project in [("reference", before), ("candidate", after)]:
        lines = (project / "project.godot").read_text().splitlines()
        isolation = [line for line in lines if line.startswith("config/use_custom_user_dir=")
                     or line.startswith("config/custom_user_dir_name=")]
        check(len(isolation) == 2 and "config/use_custom_user_dir=true" in isolation
              and any("VonNeumannBottleneckChecks/" in line for line in isolation),
              label + ": only explicit QA profile settings")
        expected_project = list(source_project)
        if label == "reference":
            expected_project.insert(expected_project.index("[application]") + 1, "")
        check([line for line in lines if line not in isolation] == expected_project,
              label + ": project settings otherwise exact current source")
    return {"base": BASE_COMMIT, "runtime_file_count": len(names),
            "changed_manifest_files": changes, "identical_harness_count": len(measured),
            "measured_harness_sha256": measured, "preserved_base_and_tools_sha256": support,
            "candidate_runtime_sha256": candidate_hashes,
            "project_settings_only_isolation_diff": True,
            "reference_profile_insertion_extra_blank_line": True,
            "base_error_precedence_prefix_exact": True,
            "successful_region_computation_body_exact": True}


def write_report():
    diagnostic = results["diagnostic"]
    lines = [
        "# Round11 independent complete evidence comparison", "",
        "PASS. Read-only review completed against the original process outputs, logs,",
        "sealed receipts, complete typed snapshots and frozen/current source bytes.",
        "No Godot execution, source edit or Git mutation was performed by this reviewer.", "",
        "## Successful workloads", "",
        "The unchanged strict comparator accepts both declared valid cases. Every",
        "typed input and result value is exact, including all metrics, full events,",
        "cache/codec evidence and container types:32 compatibility traces plus4",
        "existing online traces. The corpus retains20 `meets()` decisions; the",
        "existing online case retains two more. No result was flattened for parity.", "",
        "The original three-sample commands and fixed batches (compatibility1,",
        "existing online4, diagnostic1) are verified. Timing observations do not",
        "constitute a speedup claim for this correctness repair.", "",
        "## Intentional rejected-evidence difference", "",
        f"All{diagnostic['unchanged_sibling_count']} siblings of `region` are fully typed-exact.",
        "Only Region changes. Its error, failed status, identity, complete submitted",
        "spec/plan and metric key set remain exact. Nine previously nonzero metrics",
        "become integer0; the other five already-zero numeric fields stay exact.",
        "All four completed-evidence arrays become empty; result_value and",
        "expected_value change7→0. Events and all other fresh Trace defaults are",
        "unchanged. No Region-success-only field was introduced.", "",
        "| Metric | Before | After |", "| --- | ---: | ---: |",
    ]
    for field, value in diagnostic["numeric_metrics"].items():
        lines.append(f"| {field} | {value['before']} | {value['after']} |")
    lines.extend(["", "| Array | Before length/type builtin | After length/type builtin |",
                  "| --- | --- | --- |"])
    for field, value in diagnostic["empty_arrays"].items():
        lines.append(f"| {field} | {value['before_length']}/{value['before_element_type']['builtin']}"
                     f" | 0/{value['after_element_type']['builtin']} |")
    lines.extend([
        "", "Container builtin2 denotes int,27 Dictionary,0 untyped Variant.",
        "Outputs/expected change Array[int]→Array; blocks changes Array[Dictionary]→Array;",
        "accesses remains Array. These type changes are explicit parts of fresh",
        "rejection evidence. Complete diagnostic/metric dictionary wrappers and",
        "all input provenance types are preserved.", "",
        "The frozen diagnostic exits1 with exactly15 expected residual-evidence",
        "assertions, and no parser/runtime/warning errors. Candidate exits0 cleanly.",
        "The unmodified strict comparator rejects the combined diagnostic because",
        "the historical process failed. Original receipts remain unmodified; no",
        "equal-work timing ratio is produced for the changed diagnostic.", "",
        "## Artifact and source binding", "",
        "| Role | Original JSON bytes | SHA256 |", "| --- | ---: | --- |",
    ])
    for role, value in results["artifacts"].items():
        lines.append(f"| {role} | {value['raw_bytes']} | `{value['raw_sha256']}` |")
    binding = results["source_binding"]
    lines.extend([
        "", "Every archived raw JSON matches its still-present isolated engine",
        "output byte-for-byte. Snapshot hashes cover the original serialized",
        "snapshot bytes at exact boundaries. Re-sealing raw JSON plus complete",
        "log and actual returncode reproduces each sealed receipt exactly.", "",
        f"All{binding['runtime_file_count']} reference manifest hashes match their original Git blobs at",
        f"`{BASE_COMMIT}` and remain unchanged in the frozen project.",
        "Candidate runtime files match current reviewed source. Only Region model",
        "and its README differ from the frozen manifest; Base plan model, codec,",
        "Trace and general comparison/sealing tools are unchanged. All six measured",
        "harness scripts are identical across source/reference/candidate. Project",
        "settings differ only in the two explicit QA isolation entries and one",
        "additional blank line after [application] in the frozen reference.", "",
        "The initial review checker rejected that extra blank line. Its failed",
        "JSON is retained at `/private/tmp/vnb-round11-diagnostic-initial-checker-failure.json`.",
        "The checker now permits precisely that observed formatting difference;",
        "no computation artifact, model, assertion or comparator was weakened.", "",
        "The production branch still delegates Base.run before preparation-field",
        "rejection; unchanged Base implementation and complete unaffected diagnostic",
        "siblings are preserved. This artifact review does not extend the finite",
        "corpus to every malformed input or establish arbitrary alias equivalence.", "",
        "No native OS input, Windows, export, newcomer or long-session acceptance",
        "is implied. Complete machine-readable checks, source hashes, invocation",
        "commands, container metadata and strict-comparator outcomes are in",
        "`/private/tmp/vnb-round11-diagnostic-compare.json`.", "",
    ])
    REPORT.write_text("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-valid", type=Path, required=True)
    parser.add_argument("--candidate-diagnostic", type=Path, required=True)
    args = parser.parse_args()
    before, before_inv = load_artifact(
        "reference_valid", BASE / "20261105T122550Z-reference-valid")
    after, after_inv = load_artifact("candidate_valid", args.candidate_valid)
    old_bad, old_inv = load_artifact(
        "reference_diagnostic", BASE / "20261105T122734Z-reference-rejection-defect", True)
    new_bad, new_inv = load_artifact("candidate_diagnostic", args.candidate_diagnostic)
    check(normalized_command(before_inv["command"]) == normalized_command(after_inv["command"]),
          "Valid invocation differs only by isolated project and role label")
    check(normalized_command(old_inv["command"]) == normalized_command(new_inv["command"]),
          "Diagnostic invocation differs only by isolated project and role label")
    comparison = cmp.compare(before, after)
    check(comparison["passed"] and len(comparison["cases"]) == 2,
          "Unchanged strict comparator accepts both complete successful cases")
    results["valid_comparison"] = comparison
    saved = parse((ROOT / ".godot/collaboration/round11-valid-comparison.json").read_bytes())
    check(same(comparison, saved),
          "Independent strict comparison exactly reproduces root's saved result")
    results["valid_corpus"] = inspect_valid(before)
    check(same(results["valid_corpus"], inspect_valid(after)),
          "Candidate preserves the complete corpus trace/decision inventory")
    results["diagnostic"] = inspect_diagnostic(old_bad, new_bad)
    results["source_binding"] = bind_source()
    results["passed"] = True
    results["check_count"] = len(results["checks"])
    OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
    write_report()
    print(json.dumps({
        "passed": True, "checks": results["check_count"],
        "raw_bytes_verified": sum(row["raw_bytes"] for row in results["artifacts"].values()),
        "complete_valid_traces": results["valid_corpus"]["complete_trace_count"],
        "unchanged_diagnostic_siblings": results["diagnostic"]["unchanged_sibling_count"],
        "changed_metric_fields": results["diagnostic"]["changed_metric_fields"],
        "report": str(REPORT), "result": str(OUT),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
