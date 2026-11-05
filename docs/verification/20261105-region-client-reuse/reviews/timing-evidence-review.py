#!/usr/bin/env python3
"""Read-only Round12 receipt audit; no engine or Git writes.

Large original snapshots are parsed one case at a time. Public comparison
passes each complete actual snapshot to the unchanged strict comparator;
the full declared case set is checked separately. Nothing is projected out
of the actual comparison or rewritten into the original receipts.
"""
import argparse
import copy
import datetime
import gc
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import statistics
import subprocess


ROOT = Path("/Users/yrq/Documents/冯诺伊曼瓶颈")
OUT = Path("/private/tmp/vnb-round12-timing-evidence-review.json")
BASE = "82d6d540a8c01e8ed2a810b30a9f078fc7d35365"
PUBLIC_REFERENCE = ROOT / ".godot/region-client-benchmarks/20261105T132834Z-reference"
PROFILE_REFERENCE = ROOT / ".godot/region-client-profiles/20261105T141917Z-reference-corrected"
TRACE = "res://src/simulation/simulation_trace.gd"
EVENT = "res://src/simulation/simulation_event.gd"
SUM_FIELDS = ("request_cycles", "transfer_cycles", "decode_cycles",
              "consume_cycles", "traffic_bytes", "decoded_values",
              "decode_ops", "cache_hits", "cache_misses", "evictions")
PROFILE_COUNTS = {"online_rle": 8, "offline_revisits": 2}
SWEEP_IDS = [f"representation_region_{family}_c{n}"
             for family in PROFILE_COUNTS for n in [1, 2, 4, 8]]
CHECKS = 0
RESULT = {"passed": False, "checked_at_utc": datetime.datetime.now(
    datetime.timezone.utc).isoformat(), "checks": 0, "issues": [],
    "artifacts": {}, "public_comparison": [], "diagnostics": {},
    "engine_runs_by_reviewer": 0, "git_mutations_by_reviewer": 0,
    "checker_correction": {
        "initial_result": "/private/tmp/vnb-round12-evidence-initial-checker-failure.json",
        "reason": "Exact source-only correction check initially omitted the added explanatory comment.",
        "scope": "Include that exact comment; all artifact, typed-value and timing assertions unchanged."}}


def module(name, filename):
    spec = importlib.util.spec_from_file_location(
        name, ROOT / "scripts/benchmarks/computation" / filename)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


cmp = module("round12_original_comparator", "compare.py")
rec = module("round12_original_recorder", "record.py")


def check(ok, message):
    global CHECKS
    CHECKS += 1
    if not ok:
        RESULT["issues"].append(message)
        raise AssertionError(message)


def sha(value):
    return hashlib.sha256(value).hexdigest()


def parse(raw):
    return json.loads(raw, object_pairs_hook=cmp._unique_object,
                      parse_constant=rec._invalid_constant)


def same(a, b):
    return not cmp.first_difference(a, b)


def decoded_key(value):
    if type(value) is str:
        return value
    check(type(value) is dict and set(value) == {"@string_name"},
          "Supported typed dictionary key")
    return value["@string_name"]


def dictionary(value):
    check(type(value) is dict and set(value) == {
        "@dictionary", "key_type", "value_type"}, "Complete typed dictionary")
    result = {}
    for pair in value["@dictionary"]:
        check(type(pair) is dict and set(pair) == {"key", "value"},
              "Complete typed dictionary pair")
        key = decoded_key(pair["key"])
        check(key not in result, "No ambiguous normalized dictionary key")
        result[key] = pair["value"]
    return result


def array(value):
    check(type(value) is dict and set(value) == {
        "@array", "element_type"}, "Complete typed array")
    return value["@array"]


def integer(value):
    check(type(value) is dict and set(value) == {"@int"}
          and type(value["@int"]) is str
          and re.fullmatch(r"0|-?[1-9][0-9]*", value["@int"]) is not None,
          "Canonical typed integer")
    result = int(value["@int"])
    check(-(2**63) <= result < 2**63, "Signed64 integer domain")
    return result


class Receipt:
    def __init__(self, raw, role):
        self.raw, self.role = raw, role
        self.spans = []
        parts, cursor = [], 0
        pattern = rb',"snapshot_bytes":(\d+),"snapshot_sha256":"([a-f0-9]{64})"'
        for index, match in enumerate(re.finditer(pattern, raw)):
            size = int(match[1])
            start, end = match.start() - size, match.start()
            check(start >= cursor and raw[start-11:start] == b'"snapshot":',
                  role + ": exact original snapshot byte boundary")
            check(sha(memoryview(raw)[start:end]) == match[2].decode(),
                  role + ": original snapshot SHA256")
            self.spans.append((start, end))
            parts.extend((raw[cursor:start],
                          json.dumps({"raw_snapshot_index": index}).encode()))
            cursor = end
        parts.append(raw[cursor:])
        self.meta = parse(b"".join(parts))
        check(len(self.spans) == len(self.meta["cases"]),
              role + ": every complete snapshot located exactly once")
        self.by_id = {}
        for index, case in enumerate(self.meta["cases"]):
            check(case["snapshot"] == {"raw_snapshot_index": index},
                  role + ": snapshot index binds to actual case")
            check(case["id"] not in self.by_id, role + ": unique case IDs")
            self.by_id[case["id"]] = index

    def snapshot_bytes(self, name):
        a, b = self.spans[self.by_id[name]]
        return memoryview(self.raw)[a:b]

    def snapshot(self, name):
        value = parse(bytes(self.snapshot_bytes(name)))
        check(not cmp._json_issue(value), self.role + ": full supported typed snapshot")
        return value

    def full_case_receipt(self, name):
        result = copy.deepcopy(self.meta)
        case = result["cases"][self.by_id[name]]
        case["snapshot"] = self.snapshot(name)
        result["cases"] = [case]
        return result


def process_artifact(folder, profile=False):
    folder = Path(folder).resolve()
    role = folder.name
    manifest_path = folder / ("invocation.json" if profile else "invocations.json")
    inv = parse(manifest_path.read_bytes())
    if not profile:
        check(type(inv) is list and len(inv) == 1, role + ": one public invocation")
        inv = inv[0]
    check(inv["returncode"] == 0 and not inv["diagnostics"]
          and not inv["failures"] and not inv.get("stopped_for"),
          role + ": actual completed successful process")
    check(inv["profile"].startswith("VonNeumannBottleneckChecks/round12/"),
          role + ": isolated actual output profile")
    log = (folder / ("profile.log" if profile else inv["log"])).read_bytes()
    diagnostics = [line for line in log.decode().splitlines()
                   if rec.DIAGNOSTIC.search(line)]
    check(diagnostics == inv["diagnostics"], role + ": full log diagnostics exact")
    marker = (b"PASS: Region diagnostic profile 8 cases, 0 failures" if profile
              else b"PASS: computation benchmark 12 cases, 0 failures")
    check(marker in log, role + ": complete successful finish marker")
    if profile:
        check(sha(log) == inv["log_sha256"], role + ": original log hash")
    raw = gzip.decompress((folder / inv["output"]).read_bytes())
    check(len(raw) == inv["raw_bytes"] and sha(raw) == inv["raw_sha256"],
          role + ": complete original receipt size/hash")
    original = Path("/Users/yrq/Library/Application Support") / inv["profile"] / (
        "region-profile.json" if profile else "computation-benchmark.json")
    check(sha(original.read_bytes()) == sha(raw),
          role + ": archive matches original isolated engine output")
    receipt = Receipt(raw, role)
    check(receipt.meta["samples"] == 7 and not receipt.meta["failures"],
          role + ": seven samples and no runner failures")
    check(receipt.meta["engine"]["string"] == "4.7.1-stable (official)"
          and receipt.meta["engine"]["hash"] == "a13da4feb8d8aefc283c3763d33a2f170a18d541",
          role + ": pinned actual engine identity")
    command = inv["command"]
    project = Path(command[command.index("--path") + 1])
    check("--headless" in command, role + ": headless command")
    if profile:
        check(receipt.meta["passed"] is True and receipt.meta["checks"] > 0,
              role + ": actual diagnostic pass and checks")
        check(receipt.meta["fixed_iterations"] == PROFILE_COUNTS,
              role + ": fixed family counts")
        check(set(receipt.by_id) == set(SWEEP_IDS), role + ": eight diagnostic cases")
        for rel, expected in inv["files"].items():
            check(sha((project / rel).read_bytes()) == expected,
                  role + ": actual bound helper/runtime file " + rel)
    else:
        sealed_raw = gzip.decompress((folder / inv["sealed_output"]).read_bytes())
        sealed = Receipt(sealed_raw, role + "/sealed")
        expected = copy.deepcopy(receipt.meta)
        expected["process"] = {
            "returncode": inv["returncode"], "diagnostics": diagnostics,
            "log_sha256": sha(log), "raw_sha256": sha(raw)}
        check(same(expected, sealed.meta), role + ": complete sealer metadata exact")
        for name in receipt.by_id:
            check(receipt.snapshot_bytes(name) == sealed.snapshot_bytes(name),
                  role + ": every sealed full snapshot preserves original bytes")
        receipt.meta["process"] = expected["process"]
        fixed = parse((ROOT / ".godot/collaboration/round12-iterations.json").read_bytes())
        check(set(receipt.by_id) == set(fixed), role + ": exact twelve public cases")
        check("--samples=7" in command, role + ": actual seven-sample command")
        for case in receipt.meta["cases"]:
            check(case["iterations"] == fixed[case["id"]], role + ": fixed public counts")
            inspect_timing(case, case["iterations"], role + "/" + case["id"])
        del sealed, sealed_raw
    RESULT["artifacts"][role] = {
        "directory": str(folder), "project": str(project),
        "raw_bytes": len(raw), "raw_sha256": sha(raw), "log_sha256": sha(log),
        "manifest_sha256": sha(manifest_path.read_bytes()),
        "returncode": inv["returncode"], "seconds": inv["seconds"],
        "samples": 7, "cases": len(receipt.meta["cases"]),
        "profile": inv["profile"], "files": inv.get("files", {})}
    return receipt, inv


def inspect_timing(row, iterations, path):
    durations = row["durations_us"]
    check(len(durations) == 7 and all(type(x) is int and x > 0 for x in durations),
          path + ": seven positive actual durations")
    per_call = [x / iterations for x in durations]
    check(per_call == row["per_call_us"]
          and statistics.median(per_call) == row["median_us"]
          and min(per_call) == row["min_us"] and max(per_call) == row["max_us"],
          path + ": exact timing summary arithmetic")


def inspect_trace(trace, expected_pass=True):
    check(type(trace) is dict and set(trace) == {"@script", "fields"}
          and trace["@script"] == TRACE, "Complete SimulationTrace identity")
    fields = trace["fields"]
    check(set(fields) == {"events", "metrics", "result_value", "expected_value",
          "passed", "cache_capacity_lines", "test_name", "loop_order",
          "program_source"}, "Every Trace script field retained")
    check(fields["passed"] is expected_pass, "Actual expected Trace status")
    metrics = dictionary(fields["metrics"])
    events = array(fields["events"])
    clock = 0
    for event in events:
        check(event["@script"] == EVENT and set(event) == {"@script", "fields"},
              "Complete actual Event object")
        ef = event["fields"]
        check(set(ef) == {"kind", "cycle", "duration", "source_device",
              "target_device", "address", "cache_line", "value", "message",
              "source_line", "route_devices", "details"},
              "Every Event script field retained")
        check(integer(ef["cycle"]) == clock and integer(ef["duration"]) >= 0,
              "Complete consecutive event time")
        clock += integer(ef["duration"])
    if events:
        check(clock == integer(metrics["total_cycles"]), "All event cycles accounted")
    return fields, metrics, events


def inspect_public_case(name, snapshot):
    if name in SWEEP_IDS:
        fields, metrics, events = inspect_trace(snapshot)
        spec = dictionary(metrics["spec"])
        clients = integer(spec["clients"])
        accesses, outputs = array(metrics["accesses"]), array(metrics["outputs"])
        addresses, data = array(spec["addresses"]), array(spec["data"])
        check(len(outputs) == len(accesses) == clients * len(addresses),
              name + ": every actual requested output/access retained")
        expected = [data[integer(address)] for _ in range(clients) for address in addresses]
        check(outputs == expected == array(metrics["expected"]),
              name + ": independent ordered source values")
        for client in range(clients):
            first = dictionary(accesses[client * len(addresses)])
            cold = dictionary(first["cache_before"])
            check(integer(first["client"]) == client and first["hit"] is False
                  and integer(cold["used_bytes"]) == 0 and array(cold["keys"]) == [],
                  name + ": independent cold client")
        return {"traces": 1, "events": len(events), "outputs": len(outputs),
                "cycles": integer(metrics["total_cycles"]),
                "traffic_bytes": integer(metrics["total_traffic_bytes"])}
    count, decisions, events = 0, 0, 0
    def visit(node):
        nonlocal count, decisions, events
        if isinstance(node, dict):
            if node.get("@script") == TRACE:
                expected_pass = node["fields"]["passed"]
                _, _, ev = inspect_trace(node, expected_pass)
                if name != "workload_rejections":
                    check(expected_pass is True, name + ": every intended success succeeded")
                count += 1
                events += len(ev)
                return
            if "@dictionary" in node:
                for pair in node["@dictionary"]:
                    if pair["key"] == "accepted":
                        check(type(pair["value"]) is bool, "Actual goal boolean")
                        decisions += 1
            for child in node.values():
                visit(child)
        elif isinstance(node, list):
            for child in node:
                visit(child)
    visit(snapshot)
    return {"traces": count, "decisions": decisions, "events": events}


def public_review(reference, candidate=None):
    coverage = {}
    if candidate:
        check(set(reference.by_id) == set(candidate.by_id), "Full public case set parity")
    for name in reference.by_id:
        left = reference.full_case_receipt(name)
        check(not cmp.validate_receipt(left, "reference/" + name),
              name + ": original strict validation with complete real snapshot")
        coverage[name] = inspect_public_case(name, left["cases"][0]["snapshot"])
        if candidate:
            right = candidate.full_case_receipt(name)
            comparison = cmp.compare(left, right)
            check(comparison["passed"] and not comparison["issues"],
                  name + ": unchanged strict comparator full typed parity")
            check(reference.snapshot_bytes(name) == candidate.snapshot_bytes(name),
                  name + ": byte-exact complete snapshot parity")
            RESULT["public_comparison"].extend(comparison["cases"])
            del right
        del left
        gc.collect()
    check(coverage["representation_region_compatibility"]["traces"] == 32
          and coverage["representation_region_compatibility"]["decisions"] == 20,
          "All32compatibility traces and20decisions retained")
    check(coverage["representation_online_clients"]["traces"] == 4,
          "Four existing online workflow traces retained")
    check(coverage["representation_partition_revisits"]["traces"] == 4,
          "Four unchanged Base control traces retained")
    RESULT["public_coverage"] = coverage


def diagnostic_review(receipt, candidate=None):
    rows = []
    if candidate:
        for field in ("engine", "os", "architecture", "display", "processor",
                      "processor_count", "samples", "fixed_iterations", "timing_scope"):
            check(same(receipt.meta[field], candidate.meta[field]),
                  "Diagnostic environment/method equal: " + field)
        check(set(receipt.by_id) == set(candidate.by_id), "Diagnostic case set parity")
    for case in receipt.meta["cases"]:
        name = case["id"]
        check(case["passed"] is True and case["samples"] == 7,
              name + ": actual complete successful diagnostic")
        iterations = PROFILE_COUNTS[case["fixture"]]
        check(case["iterations_per_sample_per_boundary"] == iterations,
              name + ": diagnostic fixed counts")
        for boundary, values in case["timings"].items():
            check(boundary in {"independent_services", "client_evidence_materialization"},
                  name + ": known separate diagnostic boundary")
            inspect_timing(values, iterations, name + "/" + boundary)
            check(type(case["cold_us"][boundary]) is int and case["cold_us"][boundary] >= 0,
                  name + ": separate actual cold timing")
        value = receipt.snapshot(name)
        evidence = dictionary(value)
        check(set(evidence) == {"template", "region", "independent_services",
              "materialized_service", "materialization_seed"}, name + ": complete evidence surfaces")
        tf, tm, te = inspect_trace(evidence["template"])
        rf, rm, revents = inspect_trace(evidence["region"])
        mf = evidence["materialized_service"]["fields"]
        clients = case["clients"]
        independent = array(evidence["independent_services"])
        check(len(independent) == clients, name + ": N actual Base result objects")
        for service in independent:
            check(same(service, evidence["template"]), name + ": full independent Base equality")
        prefix, suffix = [], []
        for event in revents:
            if "client" in dictionary(event["fields"]["details"]):
                suffix.append(event)
            else:
                check(not suffix, name + ": contiguous actual preparation prefix")
                prefix.append(event)
        expected = dict(evidence["region"])
        expected_fields = dict(rf)
        expected_fields["events"] = dict(rf["events"])
        expected_fields["events"]["@array"] = suffix
        expected["fields"] = expected_fields
        check(same(expected, evidence["materialized_service"]),
              name + ": every typed materialized field matches actual service suffix")
        prep = sum(integer(event["fields"]["duration"]) for event in prefix)
        check(prep == integer(rm["preparation_cycles"]),
              name + ": exact actual preparation offset")
        check(len(suffix) == len(te) * clients,
              name + ": complete event count across clients")
        for key in SUM_FIELDS:
            check(integer(rm[key]) == clients * integer(tm[key]),
                  name + ": current summed metric " + key)
        for key in ("overfetch_values", "peak_cache_bytes"):
            check(rm[key] == tm[key], name + ": current single-service metric " + key)
        if candidate:
            right = candidate.meta["cases"][candidate.by_id[name]]
            check(same(case["input"], right["input"]) and right["passed"] is True,
                  name + ": same complete diagnostic input and actual success")
            check(receipt.snapshot_bytes(name) == candidate.snapshot_bytes(name),
                  name + ": complete diagnostic typed evidence byte parity")
            check(right["samples"] == 7
                  and right["iterations_per_sample_per_boundary"] == iterations,
                  name + ": identical candidate sample/count declaration")
            for boundary, timing in right["timings"].items():
                inspect_timing(timing, iterations, name + "/candidate/" + boundary)
        rows.append({key: val for key, val in case.items() if key not in ("snapshot", "input")})
        del value, evidence, expected, expected_fields, independent, tf, tm, te, rf, rm, revents, mf
        gc.collect()
    RESULT["diagnostics"][receipt.role] = rows
    if candidate:
        RESULT["diagnostics"][candidate.role] = [
            {key: val for key, val in case.items() if key not in ("snapshot", "input")}
            for case in candidate.meta["cases"]]


def source_review(public_inv, profile_inv, candidate_public=None, candidate_profile=None):
    source = parse((ROOT / ".godot/collaboration/round12-reference.json").read_bytes())
    check(source["base"] == BASE and len(source["files"]) == 556,
          "Correct frozen556file base manifest")
    reference = Path(source["project"])
    paths = list(source["files"])
    batch = "".join(BASE + ":" + path + "\n" for path in paths).encode()
    blobs = subprocess.check_output(["git", "cat-file", "--batch"], input=batch, cwd=ROOT)
    cursor = 0
    for path in paths:
        end = blobs.index(b"\n", cursor)
        header = blobs[cursor:end].split()
        check(header[1] == b"blob", "Committed reference blob " + path)
        size = int(header[2])
        blob = blobs[end+1:end+1+size]
        cursor = end + size + 2
        expected = source["files"][path]
        check(sha(blob) == expected == sha((reference / path).read_bytes()),
              "Frozen reference equals committed content " + path)
    measured = parse((ROOT / ".godot/collaboration/round12-measured-gd-sha256.json").read_bytes())
    measured.pop("scripts/benchmarks/computation/region_profile.gd")
    for path, expected in measured.items():
        check(sha((ROOT / path).read_bytes()) == expected
              == sha((reference / path).read_bytes()), "Six unchanged public GDScript bytes " + path)
    helper = "scripts/benchmarks/computation/region_profile.gd"
    check(sha((ROOT / helper).read_bytes()) == profile_inv["files"][helper]
          == "229639c318054dd15af06bac08c3ff2844354f15169e205e642c8c3fe2f4a9cd",
          "Corrected diagnostic helper identity")
    initial = ROOT / ".godot/collaboration/round12-region-profile-initial.gd"
    corrected = initial.read_text().replace("seed.service_cycles = 0",
        '# Region\'s literal metric merge introduces this key as String.\n'
        '\tseed["service_cycles"] = 0')
    check(corrected == (ROOT / helper).read_text(),
          "Diagnostic correction is exactly the String key seed insertion")
    if candidate_public:
        project = Path(candidate_public["command"][candidate_public["command"].index("--path") + 1])
        for path, expected in measured.items():
            check(sha((project / path).read_bytes()) == expected,
                  "Candidate shares all six public GDScripts " + path)
    if candidate_profile:
        for path, expected in profile_inv["files"].items():
            if path == "experiments/representation_region/model.gd":
                continue
            check(candidate_profile["files"][path] == expected,
                  "Identical reference/candidate diagnostic input implementation " + path)
    RESULT["source"] = {"base": BASE, "reference_runtime_files": len(paths),
                        "public_gd_files": measured,
                        "diagnostic_helper_sha256": profile_inv["files"][helper]}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-public", type=Path)
    parser.add_argument("--candidate-profile", type=Path)
    args = parser.parse_args()
    try:
        ref, ref_inv = process_artifact(PUBLIC_REFERENCE)
        cand, cand_inv = (process_artifact(args.candidate_public)
                          if args.candidate_public else (None, None))
        public_review(ref, cand)
        del ref, cand
        gc.collect()
        profile, profile_inv = process_artifact(PROFILE_REFERENCE, True)
        other, other_inv = (process_artifact(args.candidate_profile, True)
                            if args.candidate_profile else (None, None))
        diagnostic_review(profile, other)
        del profile, other
        gc.collect()
        source_review(ref_inv, profile_inv, cand_inv, other_inv)
        RESULT["candidate_complete"] = bool(cand_inv and other_inv)
        RESULT["passed"] = True
    except Exception as error:
        if not RESULT["issues"]:
            RESULT["issues"].append(type(error).__name__ + ": " + str(error))
    finally:
        RESULT["checks"] = CHECKS
        OUT.write_text(json.dumps(RESULT, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"passed": RESULT["passed"], "checks": CHECKS,
                      "candidate_complete": RESULT.get("candidate_complete", False),
                      "issues": RESULT["issues"], "output": str(OUT)}, ensure_ascii=False))
    return 0 if RESULT["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
