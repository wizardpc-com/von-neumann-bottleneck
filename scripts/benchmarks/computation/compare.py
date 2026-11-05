#!/usr/bin/env python3
"""Compare complete benchmark evidence before reporting same-work timings."""
import argparse
import gzip
import json
import math
from pathlib import Path
import re
import statistics


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate benchmark receipt JSON field: " + key)
        result[key] = value
    return result


def read(path):
    data = path.read_bytes()
    if path.suffix == ".gz":
        data = gzip.decompress(data)
    return json.loads(data, object_pairs_hook=_unique_object)


def _json_issue(value, path="$", depth=0):
    """Reject lossy snapshot sentinels and non-JSON/nonfinite receipt contents."""
    if depth > 256:
        return path + ": receipt nesting exceeds the inspection bound"
    if value is None or type(value) in (bool, int, str):
        return ""
    if type(value) is float:
        return "" if math.isfinite(value) else path + ": nonfinite number"
    if type(value) is list:
        for index, item in enumerate(value):
            issue = _json_issue(item, f"{path}[{index}]", depth + 1)
            if issue:
                return issue
        return ""
    if type(value) is dict:
        if "@unsupported" in value:
            return path + ": incomplete @unsupported snapshot evidence"
        for key, item in value.items():
            if type(key) is not str:
                return path + ": receipt object key is not a string"
            issue = _json_issue(item, path + "." + key, depth + 1)
            if issue:
                return issue
        return ""
    return path + ": unsupported receipt value type"


def _positive_integer(value):
    return type(value) is int and 0 < value <= 9223372036854775807


def _positive_number(value):
    if type(value) is int:
        return _positive_integer(value)
    return type(value) is float and math.isfinite(value) and value > 0


def _nonempty_string(value):
    return type(value) is str and bool(value.strip())


def _sha256(value):
    return type(value) is str and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def _validate_process(process, name):
    if type(process) is not dict:
        return [name + ": process must contain completed subprocess evidence"]
    required = {"returncode", "diagnostics", "log_sha256", "raw_sha256"}
    missing = required - process.keys()
    if missing:
        return [name + ": missing process fields: " + ", ".join(sorted(missing))]
    issues = []
    if type(process["returncode"]) is not int or process["returncode"] != 0:
        issues.append(name + ": process did not exit successfully with integer returncode 0")
    diagnostics = process["diagnostics"]
    if type(diagnostics) is not list or not all(type(line) is str for line in diagnostics):
        issues.append(name + ": diagnostics must be an array of strings")
    elif diagnostics:
        issues.append(name + ": process log contains diagnostics: " + "; ".join(diagnostics))
    for field in ("log_sha256", "raw_sha256"):
        if not _sha256(process[field]):
            issues.append(name + ": invalid process " + field)
    return issues


def validate_receipt(result, name):
    """Require runner values and completed process evidence before comparison."""
    issues = []
    if type(result) is not dict:
        return [name + ": benchmark receipt must be an object"]
    json_issue = _json_issue(result, name)
    if json_issue:
        return [json_issue]
    required = {
        "version", "label", "engine", "os", "architecture", "display",
        "processor", "processor_count", "host_label", "execution_flags",
        "samples", "target_us", "timing_scope", "cases", "failures", "process",
    }
    missing = required - result.keys()
    if missing:
        return [name + ": missing receipt fields: " + ", ".join(sorted(missing))]
    issues.extend(_validate_process(result["process"], name + ".process"))
    if type(result["version"]) is not int or result["version"] != 1:
        issues.append(name + ": unsupported benchmark version")
    for field in ("label", "os", "architecture", "display", "processor",
                  "host_label", "timing_scope"):
        if not _nonempty_string(result[field]):
            issues.append(name + ": invalid or empty " + field)
    if type(result["engine"]) is not dict or not result["engine"]:
        issues.append(name + ": missing engine identity")
    if not _positive_integer(result["processor_count"]):
        issues.append(name + ": processor_count must be a positive integer")
    if (type(result["execution_flags"]) is not list
            or not all(type(flag) is str for flag in result["execution_flags"])):
        issues.append(name + ": execution_flags must be an array of strings")
    samples = result["samples"]
    if type(samples) is not int or samples < 3:
        issues.append(name + ": samples must be an integer of at least three")
    if not _positive_integer(result["target_us"]):
        issues.append(name + ": target_us must be a positive integer")
    failures = result["failures"]
    if type(failures) is not list or not all(type(failure) is str for failure in failures):
        issues.append(name + ": failures must be an array of strings")
    elif failures:
        issues.append(name + ": benchmark reports failures: " + "; ".join(failures))
    if type(result["cases"]) is not list or not result["cases"]:
        return issues + [name + ": cases must be a nonempty array"]
    seen = set()
    case_required = {
        "id", "subsystem", "description", "input", "iterations", "cold_us",
        "durations_us", "per_call_us", "median_us", "min_us", "max_us",
        "snapshot_bytes", "snapshot_sha256", "snapshot",
    }
    for index, case in enumerate(result["cases"]):
        location = f"{name}.cases[{index}]"
        if type(case) is not dict:
            issues.append(location + ": case must be an object")
            continue
        missing = case_required - case.keys()
        if missing:
            issues.append(location + ": missing case fields: " + ", ".join(sorted(missing)))
            continue
        for field in ("id", "subsystem", "description"):
            if not _nonempty_string(case[field]):
                issues.append(location + ": invalid or empty " + field)
        if type(case["id"]) is str:
            if case["id"] in seen:
                issues.append(location + ": duplicate case id")
            seen.add(case["id"])
        if type(case["input"]) is not dict:
            issues.append(location + ": input must contain the complete case spec")
        else:
            for field in ("id", "subsystem", "description"):
                if case["input"].get(field) != case[field]:
                    issues.append(location + ": input spec does not match case " + field)
            if type(case["input"].get("input")) is not dict:
                issues.append(location + ": input spec is missing its input dictionary")
        if not _positive_integer(case["iterations"]):
            issues.append(location + ": iterations must be a positive integer")
        if (type(case["cold_us"]) is not int
                or not 0 <= case["cold_us"] <= 9223372036854775807):
            issues.append(location + ": cold_us must be a nonnegative integer")
        durations = case["durations_us"]
        if (type(durations) is not list or len(durations) != samples
                or not all(_positive_integer(value) for value in durations)):
            issues.append(location + ": durations must be one positive integer per sample")
        per_call = case["per_call_us"]
        if (type(per_call) is not list or len(per_call) != samples
                or not all(_positive_number(value) for value in per_call)):
            issues.append(location + ": per_call_us must be finite positive sample values")
        for field in ("median_us", "min_us", "max_us"):
            if not _positive_number(case[field]):
                issues.append(location + ": invalid timing summary " + field)
        if not _positive_integer(case["snapshot_bytes"]):
            issues.append(location + ": snapshot_bytes must be a positive integer")
        digest = case["snapshot_sha256"]
        if not _sha256(digest):
            issues.append(location + ": invalid snapshot SHA-256 metadata")
        if case["snapshot"] is None:
            issues.append(location + ": null snapshot is not computation evidence")
    return issues


def first_difference(left, right, path="$"):
    if type(left) is not type(right):
        return path + " (type)"
    if isinstance(left, dict):
        if set(left) != set(right):
            return path + " (keys)"
        for key in sorted(left):
            difference = first_difference(left[key], right[key], path + "." + key)
            if difference:
                return difference
    elif isinstance(left, list):
        if len(left) != len(right):
            return path + " (length)"
        for index, (before, after) in enumerate(zip(left, right)):
            difference = first_difference(before, after, f"{path}[{index}]")
            if difference:
                return difference
    elif left != right:
        return path + " (value)"
    return ""


def _execution_method(flags):
    """A frozen source directory may differ; all other engine flags still bind."""
    normalized = []
    skip_path_value = False
    for flag in flags:
        if skip_path_value:
            normalized.append("<project-path>")
            skip_path_value = False
        elif flag == "--path":
            normalized.append(flag)
            skip_path_value = True
        elif flag.startswith("--path="):
            normalized.append("--path=<project-path>")
        else:
            normalized.append(flag)
    return normalized


def compare(reference, candidate):
    issues = validate_receipt(reference, "reference") + validate_receipt(candidate, "candidate")
    if issues:
        return {"passed": False, "issues": issues, "cases": []}
    before = {case["id"]: case for case in reference["cases"]}
    after = {case["id"]: case for case in candidate["cases"]}
    if set(before) != set(after):
        issues.append("Case sets differ; missing cases cannot establish parity")
    for field in ("engine", "os", "architecture", "display", "samples", "timing_scope",
                  "processor", "processor_count", "host_label"):
        if first_difference(reference[field], candidate[field]):
            issues.append("Timing environment or method differs: " + field)
    if _execution_method(reference["execution_flags"]) != _execution_method(candidate["execution_flags"]):
        issues.append("Timing environment or method differs: execution_flags")
    cases = []
    for key in sorted(set(before) & set(after)):
        left, right = before[key], after[key]
        parity_issue = first_difference(left["snapshot"], right["snapshot"])
        input_issue = first_difference(left["input"], right["input"])
        if parity_issue:
            issues.append(key + ": complete evidence differs at " + parity_issue)
        if input_issue:
            issues.append(key + ": workload differs at " + input_issue)
        iterations = left["iterations"]
        if iterations != right["iterations"]:
            issues.append(key + ": timing batches are not comparable")
        if not parity_issue:
            for field in ("snapshot_bytes", "snapshot_sha256"):
                if left[field] != right[field]:
                    issues.append(key + ": equal snapshots have different " + field + " metadata")
        cases.append({"id": key, "parity": not parity_issue and not input_issue,
                      "timing_comparable": False})
    # Never publish a speed ratio for incomplete, changed or differently timed work.
    if issues:
        return {"passed": False, "issues": issues, "cases": cases}
    cases = []
    for key in sorted(before):
        left, right = before[key], after[key]
        iterations = left["iterations"]
        old = [value / iterations for value in left["durations_us"]]
        new = [value / iterations for value in right["durations_us"]]
        old_median, new_median = statistics.median(old), statistics.median(new)
        cases.append(
            {
                "id": key,
                "parity": True,
                "timing_comparable": True,
                "iterations": iterations,
                "reference_median_us": old_median,
                "candidate_median_us": new_median,
                "reference_range_us": [min(old), max(old)],
                "candidate_range_us": [min(new), max(new)],
                "speed_ratio": old_median / new_median,
                "time_reduction_percent": 100 * (1 - new_median / old_median),
            }
        )
    return {"passed": True, "issues": [], "cases": cases}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        result = compare(read(args.reference), read(args.candidate))
    except (OSError, UnicodeError, ValueError, EOFError) as error:
        result = {"passed": False, "issues": ["Unable to read benchmark receipt: " + str(error)],
                  "cases": []}
    text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")
    raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
