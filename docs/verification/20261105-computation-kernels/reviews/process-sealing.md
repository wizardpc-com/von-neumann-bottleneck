# Round9 fail-closed process evidence sealing

Owner `/root/audit_scores`, 2026-11-05. Assigned scope:
`scripts/benchmarks/computation/{record.py,compare.py,test_compare.py}`.
All three files are released to root. No production files, Godot execution,
Git mutation, original raw receipt or original log was changed.

## API and integration

New `record.py` provides:

```python
seal(raw: bytes, log: bytes, returncode: int) -> dict
```

Call after the real subprocess finishes, using its original JSON bytes,
complete captured log bytes and actual integer returncode. Importing `record`
does not import the comparison module or change the caller's import paths.
The returned dictionary preserves every parsed runner field and adds:

```text
process:
  returncode: actual integer
  diagnostics: every complete line matching
               SCRIPT ERROR | ERROR: | Parse Error | WARNING:
  log_sha256: SHA-256 of complete original log bytes
  raw_sha256: SHA-256 of original runner JSON bytes
```

`seal()` does not claim a pass: unsuccessful process/log/runner outcomes remain
inspectable sealed evidence and are rejected by `compare.validate_receipt()`.
Malformed/non-object JSON, nonfinite JSON constants, duplicate object keys,
already-sealed input and incorrect API argument types raise clear exceptions.
The original byte arguments are immutable and untouched.

CLI:

```text
python3 -B scripts/benchmarks/computation/record.py RAW_JSON GODOT_LOG \
  --returncode 0 --output SEALED.json.gz
```

`.json` is also supported. The returncode argument and output are mandatory.
The CLI writes sealed failed receipts when raw JSON is parseable, then returns1
for any process diagnostics/nonzero code, runner failure or schema error.
Malformed raw JSON returns1 without writing a new receipt. It prints a compact
JSON verdict rather than a traceback. Output resolving to the original JSON or
log is rejected, including an existing hard-link alias. Failed evidence is
preserved; no timing field is transformed or recomputed by sealing.

`compare.py` now requires `process` and all four fields. It rejects missing or
malformed metadata, bool/float returncodes, nonzero returncodes, nonempty
diagnostics and invalid lowercase SHA-256 syntax. Any such failure suppresses
all timing comparison output. Distinct valid raw/log hashes between reference
and candidate are expected and allowed; host, method, inputs, full snapshots,
case sets, numeric/schema checks and fixed batch conditions remain enforced.

Old unsealed diagnostic receipts now intentionally fail comparison. Root may
retain those original files unchanged and seal a separate record from their
actual original log/returncode when needed. Sealing never reconstructs or
guesses missing process evidence.

## Fresh verification

```text
python3 -B scripts/benchmarks/computation/test_compare.py
....................
Ran 20 tests in 0.430s
OK
```

The existing15 comparison tests remain. Five additional test methods cover
complete-byte hashes/raw-field preservation, different valid receipt hashes,
matching bad logs, nonzero process exit, every missing process field,
malformed metadata/digest syntax, malformed/resealed raw input, both CLI output
formats, process/runner/schema failures, invalid JSON, source overwrite
protection and preserved original source bytes.

Additionally, read and sealed **in memory only** the actual preserved retry:

`.godot/computation-benchmarks/20261105T094215Z-reference-circuit-retry/`

The original `circuit.json.gz`, `circuit.log` and invocation returncode produced:

```json
{
  "original_runner_failures": [],
  "actual_returncode": 0,
  "captured_diagnostics": 99,
  "raw_hash_matches_invocation": true,
  "sealed_self_comparison_passed": false,
  "published_timing_cases": 0
}
```

This directly closes the observed false-pass path: matching broken outputs and
an engine exit0 cannot hide the99 actual validator errors after process sealing.
No diagnostic history file was rewritten.

Full test output inspected; `git diff --check` and explicit owned-file
whitespace/conflict-marker scans were clean. Shared worktree status inspected
and unrelated changes preserved. Root owns engine verification, final
invocation-helper integration, final corpus/source binding and durable docs.

## Released hashes

| File under `scripts/benchmarks/computation/` | SHA-256 |
|---|---|
| `record.py` | `2c441837176d8298d482722901a0d40e9fe3a551893d62a3c572ab61a99375a1` |
| `compare.py` | `1722d9f8cdaee679d35c5c5a896888f51e6b6126884978ff6e140d8bb2fcb996` |
| `test_compare.py` | `a29e1ffeac665100061441208f0e60f5d1b819fb4aaad9dc51bf4077d2ac88a7` |
