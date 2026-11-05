#!/usr/bin/env python3
"""Read-only independent verification of Round10 captured evidence."""
from pathlib import Path
import gzip
import hashlib
import importlib.util
import json
import re
import statistics
import sys

sys.dont_write_bytecode = True
ROOT = Path("/Users/yrq/Documents/冯诺伊曼瓶颈")
DEST = Path("/private/tmp/vnb-round10-evidence-verify.json")
issues = []


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, message):
    if not ok:
        issues.append(message)


def unique(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate key: " + key)
        result[key] = value
    return result


def decode(data):
    return json.loads(data, object_pairs_hook=unique,
                      parse_constant=lambda s: (_ for _ in ()).throw(ValueError(s)))


decoder = json.JSONDecoder()


def skip(text, pos):
    while text[pos].isspace():
        pos += 1
    return pos


def members(text, pos):
    """Return actual value spans without reserializing Godot JSON."""
    assert text[pos] == "{"
    pos = skip(text, pos + 1)
    result = {}
    while text[pos] != "}":
        key, pos = decoder.raw_decode(text, pos)
        pos = skip(text, pos)
        assert text[pos] == ":"
        start = skip(text, pos + 1)
        _, end = decoder.raw_decode(text, start)
        result[key] = (start, end)
        pos = skip(text, end)
        if text[pos] == ",":
            pos = skip(text, pos + 1)
        else:
            assert text[pos] == "}"
    return result


def elements(text, pos):
    assert text[pos] == "["
    pos = skip(text, pos + 1)
    result = []
    while text[pos] != "]":
        _, end = decoder.raw_decode(text, pos)
        result.append((pos, end))
        pos = skip(text, end)
        if text[pos] == ",":
            pos = skip(text, pos + 1)
        else:
            assert text[pos] == "]"
    return result


DIAGNOSTIC = re.compile(r"SCRIPT ERROR|ERROR:|Parse Error|WARNING:")
benchmark_rows = []
sealed_runs = {}
for run in sorted((ROOT / ".godot/circuit-recovery-benchmarks").iterdir()):
    invocations = decode((run / "invocations.json").read_bytes())
    require(len(invocations) == 1, f"{run.name}: unexpected invocation count")
    inv = invocations[0]
    raw = gzip.decompress((run / inv["output"]).read_bytes())
    value = decode(raw)
    sealed = decode(gzip.decompress((run / inv["sealed_output"]).read_bytes()))
    log = (run / inv["log"]).read_bytes()
    diagnostics = [line for line in log.decode().splitlines() if DIAGNOSTIC.search(line)]
    actual_process = {
        "returncode": inv["returncode"], "diagnostics": diagnostics,
        "log_sha256": sha(log), "raw_sha256": sha(raw),
    }
    require(sha(raw) == inv["raw_sha256"], f"{run.name}: raw hash")
    require(len(raw) == inv["raw_bytes"], f"{run.name}: raw bytes")
    require((run / inv["output"]).stat().st_size == inv["compressed_bytes"],
            f"{run.name}: compressed bytes")
    require(diagnostics == inv["diagnostics"], f"{run.name}: invocation diagnostics")
    require(sealed == {**value, "process": actual_process}, f"{run.name}: sealed content")
    require(value["failures"] == inv["failures"], f"{run.name}: failures")
    require("VonNeumannBottleneckChecks/round10/" in inv["profile"],
            f"{run.name}: profile")
    text = raw.decode()
    root_spans = members(text, skip(text, 0))
    case_spans = elements(text, root_spans["cases"][0])
    require(len(case_spans) == len(value["cases"]), f"{run.name}: case count")
    snapshots = []
    for case, case_span in zip(value["cases"], case_spans):
        spans = members(text, case_span[0])
        start, end = spans["snapshot"]
        snapshot_bytes = text[start:end].encode()
        require(sha(snapshot_bytes) == case["snapshot_sha256"],
                f"{run.name}/{case['id']}: original snapshot hash")
        require(len(snapshot_bytes) == case["snapshot_bytes"],
                f"{run.name}/{case['id']}: original snapshot bytes")
        per_call = [n / case["iterations"] for n in case["durations_us"]]
        require(per_call == case["per_call_us"], f"{run.name}/{case['id']}: per-call timings")
        require(statistics.median(per_call) == case["median_us"],
                f"{run.name}/{case['id']}: median")
        require(min(per_call) == case["min_us"] and max(per_call) == case["max_us"],
                f"{run.name}/{case['id']}: range")
        snapshots.append({"id": case["id"], "bytes": len(snapshot_bytes),
                          "sha256": sha(snapshot_bytes)})
    benchmark_rows.append({
        "run": run.name, "returncode": inv["returncode"],
        "failures": len(value["failures"]), "diagnostics": len(diagnostics),
        "raw_sha256": sha(raw), "log_sha256": sha(log), "snapshots": snapshots,
    })
    sealed_runs[run.name] = sealed

spec = importlib.util.spec_from_file_location(
    "round10_compare", ROOT / "scripts/benchmarks/computation/compare.py")
compare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compare)
comparison = compare.compare(
    sealed_runs["20261105T111531Z-reference-valid"],
    sealed_runs["20261105T112706Z-candidate-valid"])
recorded = decode((ROOT / ".godot/collaboration/round10-valid-comparison.json").read_bytes())
require(comparison == recorded, "Reproduced valid comparison differs from saved result")
require(comparison["passed"] and len(comparison["cases"]) == 11,
        "Successful full-snapshot comparison did not pass exactly eleven scenarios")
recovery_comparison = compare.compare(
    sealed_runs["20261105T111710Z-reference-recovery-defect"],
    sealed_runs["20261105T112747Z-candidate-recovery"])
require(not recovery_comparison["passed"] and recovery_comparison["cases"] == [],
        "Changed/failed diagnostic was accepted for timing comparison")

qa = ROOT / ".godot/verification/20261105T112607Z-5880555a"
qa_result = decode((qa / "results.json").read_bytes())
qa_rows = []
for row in qa_result["results"]:
    log = (qa / row["log"]).read_bytes()
    text = log.decode()
    diagnostics = [line for line in text.splitlines() if DIAGNOSTIC.search(line)]
    require(row["exit"] == 0 and row["passed"] and not row["errors"],
            row["name"] + ": QA receipt failed")
    require(not diagnostics, row["name"] + ": QA log diagnostics")
    require(row["custom_user_dir"].startswith("VonNeumannBottleneckChecks/"),
            row["name"] + ": QA profile")
    markers = [line for line in text.splitlines() if line.startswith(("PASS", "FAIL"))
               or re.search(r"\b0 failed\b", line)]
    require(row["name"] in ("import", "user_directory") or bool(markers),
            row["name"] + ": no completion marker")
    qa_rows.append({"name": row["name"], "exit": row["exit"],
                    "log_sha256": sha(log), "markers": markers,
                    "diagnostics": diagnostics})

gpu_rows = []
for stamp in ["20261105T112836Z", "20261105T112914Z"]:
    directory = ROOT / ".godot/circuit-recovery-checks" / stamp
    rows = decode((directory / "results.json").read_bytes())
    for row in rows:
        log = (directory / (row["suite"] + ".log")).read_bytes()
        diagnostics = [line for line in log.decode().splitlines() if DIAGNOSTIC.search(line)]
        require(sha(log) == row["log_sha256"], stamp + ": GPU log hash")
        require(row["returncode"] == 0 and row["stopped_for"] is None
                and not diagnostics and not row["diagnostics"], stamp + ": GPU execution")
        markers = [line for line in log.decode().splitlines() if line.startswith(("PASS", "FAIL"))]
        require(any("viewport input" in line and "0 failures" in line for line in markers),
                stamp + ": GPU completion")
        gpu_rows.append({"run": stamp, "locale": row["locale"],
                         "returncode": row["returncode"], "log_sha256": sha(log),
                         "markers": markers})

binding = []
reference = ROOT / ".godot/verification/20261105T111217Z-round10-reference/project"
candidate = qa / "project"
measured = decode((ROOT / ".godot/collaboration/round10-measured-gd-sha256.json").read_bytes())
for name, digest in measured.items():
    rel = Path("scripts/benchmarks/computation") / name
    actual = {label: sha((base / rel).read_bytes())
              for label, base in [("current", ROOT), ("reference", reference), ("candidate", candidate)]}
    require(all(value == digest for value in actual.values()), str(rel) + ": harness binding")
    binding.append({"path": str(rel), **actual})
for rel in ["src/circuit/prologue_simulator.gd",
            "tests/test_prologue_failure_recovery.gd",
            "tests/test_hardware_failure_recovery.gd"]:
    actual = {label: sha((base / rel).read_bytes())
              for label, base in [("current", ROOT), ("reference", reference), ("candidate", candidate)]}
    require(actual["current"] == actual["candidate"], rel + ": current/candidate binding")
    if rel.startswith("tests/"):
        require(actual["current"] == actual["reference"], rel + ": same before/after regression")
    else:
        require(actual["reference"] == "ea22934e27dc08fcc1cc64c7158f5f028bf6a5a7150eee02b56c834bf502b371",
                rel + ": original simulator binding")
        require(actual["candidate"] == "3ed8eb32b91b9b7b00fcd9a5b8fa7c25f0095e9c561389632b448e2b51723462",
                rel + ": reviewed simulator binding")
    binding.append({"path": rel, **actual})

result = {
    "passed": not issues, "issues": issues,
    "benchmarks": benchmark_rows, "valid_comparison": comparison,
    "changed_diagnostic_comparison_rejected": not recovery_comparison["passed"],
    "qa_results": qa_rows, "gpu_results": gpu_rows, "source_binding": binding,
    "boundaries": [
        "Existing captured evidence only; no engine, native or Git operation.",
        "No timing improvement claim for changed diagnostics.",
        "GPU screenshots require separate actual visual inspection.",
        "This verification does not establish native, Windows, export or player acceptance.",
    ],
}
DEST.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({
    "passed": result["passed"], "issues": issues, "benchmark_sets": len(benchmark_rows),
    "snapshot_count": sum(len(r["snapshots"]) for r in benchmark_rows),
    "success_parity_cases": len(comparison["cases"]),
    "qa_suites": len(qa_rows) - 2, "gpu_invocations": len(gpu_rows),
    "report": str(DEST),
}, ensure_ascii=False, indent=2))
