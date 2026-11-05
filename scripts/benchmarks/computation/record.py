#!/usr/bin/env python3
"""Seal a completed Godot benchmark with its actual process/log evidence."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re


DIAGNOSTIC = re.compile(r"SCRIPT ERROR|ERROR:|Parse Error|WARNING:")


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate runner JSON field: " + key)
        result[key] = value
    return result


def _invalid_constant(value):
    raise ValueError("Nonfinite runner JSON number: " + value)


def seal(raw: bytes, log: bytes, returncode: int) -> dict:
    """Preserve runner fields and add evidence; sealing itself is not a pass.

    Call after subprocess completion with its real returncode and complete
    captured log. Malformed/resealed raw JSON raises; unsuccessful processes
    still produce inspectable sealed receipts, rejected by compare.py.
    """
    if type(raw) is not bytes or type(log) is not bytes:
        raise TypeError("Runner JSON and complete process log must be bytes")
    if type(returncode) is not int:
        raise TypeError("Process returncode must be an actual integer")
    result = json.loads(
        raw.decode("utf-8"), object_pairs_hook=_unique_object,
        parse_constant=_invalid_constant,
    )
    if type(result) is not dict:
        raise ValueError("Runner JSON must be an object")
    if "process" in result:
        raise ValueError("Seal original runner JSON, not a previously sealed receipt")
    result["process"] = {
        "returncode": returncode,
        "diagnostics": [
            line for line in log.decode("utf-8", errors="replace").splitlines()
            if DIAGNOSTIC.search(line)
        ],
        "log_sha256": hashlib.sha256(log).hexdigest(),
        "raw_sha256": hashlib.sha256(raw).hexdigest(),
    }
    return result


def main():
    # Kept inside the CLI so seal() can also be loaded independently by an
    # invocation helper without changing that helper's module search path.
    from compare import validate_receipt

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("raw", type=Path, help="Original unmodified runner JSON")
    parser.add_argument("log", type=Path, help="Complete captured process log")
    parser.add_argument("--returncode", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        for source in (args.raw, args.log):
            if (args.output.resolve() == source.resolve()
                    or (args.output.exists() and args.output.samefile(source))):
                raise ValueError("Sealed output must not overwrite original runner JSON or log")
        result = seal(args.raw.read_bytes(), args.log.read_bytes(), args.returncode)
        issues = validate_receipt(result, "sealed")
        data = (json.dumps(result, ensure_ascii=False, allow_nan=False,
                           separators=(",", ":")) + "\n").encode("utf-8")
        if args.output.suffix == ".gz":
            data = gzip.compress(data, mtime=0)
        args.output.write_bytes(data)
        summary = {
            "passed": not issues, "issues": issues, "output": str(args.output),
            "process": result["process"],
        }
    except (OSError, UnicodeError, ValueError, TypeError, RecursionError) as error:
        summary = {"passed": False, "issues": ["Unable to seal process evidence: " + str(error)]}
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if summary["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
