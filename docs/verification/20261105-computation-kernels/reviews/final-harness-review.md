# Round9 final independent harness review

Reviewer: `/root/audit_scores`, 2026-11-05. Scope is the final read-only
assignment in `.godot/collaboration/round9-audit.md`.

This review read the five current harness files and prior review reports.
No source/test edits, engine execution, Git mutation, unit-test execution or
large receipt parsing occurred during root's active timing runs. The only
written file is this report. Root retains all implementation ownership.

## Verdict

The concrete earlier false-pass path is closed in the current tool chain:
an exit-zero run with captured script errors cannot pass after `record.seal`
adds its complete process-log diagnostics and `compare.validate_receipt`
requires them to be empty. Unsupported snapshots, schema omissions, bad
numeric timing values, differing workloads, differing complete captured
values, differing batch counts, and differing declared environments all
prevent timing ratios from being published.

One new, bounded input-parser gap remains below. It does not show that the
normal producer's current receipts or measured timings are invalid.
Final reference/candidate acceptance and source/invocation binding remain
root's separate verification work; this report is not a new acceptance run.

## F1 — P2: comparator loading silently accepts duplicate JSON fields

`scripts/benchmarks/computation/compare.py:12–16` reads both plain and gzip
receipts with default `json.loads(data)`. Python's default JSON object decoder
keeps the final occurrence of a repeated key. Validation only sees the resulting
dictionary, so it cannot reject the discarded field.

For example, a structurally otherwise valid sealed document containing
`"failures":["incomplete computation"],"failures":[]` becomes a receipt with an
empty failures array. The same issue applies to duplicate process fields:
`"returncode":1,"returncode":0` or an earlier diagnostic array followed by an
empty one. Comparing two such files can therefore pass while their textual
evidence is ambiguous.

This is a source-established parser path, not an observed corruption in the
current benchmark artifacts. A fresh execution was deliberately not performed
during root's timing runs.

`record.py:14–20,38–40` already rejects duplicate object keys when sealing
original runner JSON. Normal `json.dumps` output from that producer cannot
create duplicate keys, so this finding concerns malformed/edited sealed-file
ingestion, not a need to discard or rerun the current normal corpus.

Small repair: make `compare.read` reject duplicate keys at every object depth,
using an `object_pairs_hook` or a small shared strict JSON loader. Add
plain/gzip comparator CLI tests with duplicate top-level `failures` and nested
process fields. Require exit1, `passed:false`, no timing ratios and no
traceback. Those tests should run after timings finish; no simulator change or
engine retiming is needed for this parser correction.

## Previously repaired findings

- `runner.gd:39–42` checks every frozen result for unsupported/cyclic evidence;
  the comparator independently rejects `@unsupported` anywhere in the receipt.
- `runner.gd:124–125` runs adapter semantic validation outside timing.
  `record.py` plus mandatory process metadata also covers nested script errors
  that unwind a helper without aborting `_run`.
- JSON-restored inputs are checked for mutation. Original results and inputs
  remain retained and are rechecked after later distinct cases.
- Typed arrays/dictionaries, integer64 values, float64 bits, packed values and
  every script-variable property are represented explicitly in snapshots.
- Both sides receive schema/type/finite-positive timing checks. Comparison
  recomputes statistics from duration samples instead of trusting exported
  median/per-call summaries.
- A failed comparison never publishes `speed_ratio` or
  `time_reduction_percent`.

These are acknowledgments of current source behavior, not repeated open
findings. Prior Python test evidence is recorded in
`/private/tmp/vnb-round9-process-sealing.md`; it was not rerun here.

## Exact evidence and timing boundaries

1. **Value/container parity.** `snapshot.gd:2–5` correctly limits its promise.
   Output dictionary insertion order and reference alias topology are
   normalized away. Object snapshots include script variables, not arbitrary
   native-engine internal state. Retained-result checks observe mutations in
   the selected workflows; they do not prove arbitrary alias-graph equivalence.
   This is appropriate for the selected script-model results.

2. **Bounded repetition.** The first actual result receives semantic validation,
   the JSON-restored execution and three individual repeats receive complete
   snapshot comparison, and each timed batch compares its final result.
   Intermediate timed results are not all separately inspected. Retention
   spans the cases executed in that process; separately launched groups do
   not establish all36-case cross-group ownership behavior in one process.

3. **Process evidence is supplied by the trusted invocation.** Sealing hashes
   the original raw JSON and complete log bytes without changing timing
   fields. The comparator validates the process metadata and digest syntax;
   it does not reopen the original artifacts or authenticate their provenance.
   Root's preserved invocation/raw/log/source bindings remain necessary.
   This is an explicit artifact-integrity boundary, not a demand for signing,
   online trust machinery or a new benchmark architecture.

4. **Effective invocation.** The previously reported
   `OS.get_cmdline_args()` limitation remains an outer-evidence concern:
   consumed engine options may be absent from the runner's flags array.
   Compare the real invocation commands and fixed iteration contents alongside
   receipt metadata. Do not describe declared host labels as hardware
   attestation. This is already reported in the measurement review.

5. **What the timer measures.** Actual adapter/public-API execution, fresh
   input/state construction and model-owned serialization are timed.
   Harness freezing, hashing and exporting are excluded. Retained earlier
   results remain alive. The measurements therefore describe these API
   workflows under that memory condition, not isolated arithmetic kernels,
   frame latency, native input responsiveness or an exported game's FPS.

6. **Platform scope.** The comparator rejects differing engine/OS/architecture/
   display/processor/count/host/method declarations before publishing ratios.
   A successful same-host Mac comparison does not verify Windows execution,
   arbitrary endianness/platform equivalence or native interactive acceptance.
   No new platform-dependent runtime assumption was found in these five
   reviewed files.

7. **Known circuit failure.** Sealing and comparison intentionally reject
   receipts containing runner failures. The confirmed existing failed-step
   recovery defect must remain separate from the valid timing subset and its
   separately compared unchanged failure evidence. Equal failed outputs do
   not become a successful recovery verdict.

## Reviewed byte identities

All paths below are under `scripts/benchmarks/computation/`. Hashes were read
again immediately before writing this report.

| File | SHA-256 |
|---|---|
| `record.py` | `2c441837176d8298d482722901a0d40e9fe3a551893d62a3c572ab61a99375a1` |
| `compare.py` | `1722d9f8cdaee679d35c5c5a896888f51e6b6126884978ff6e140d8bb2fcb996` |
| `test_compare.py` | `a29e1ffeac665100061441208f0e60f5d1b819fb4aaad9dc51bf4077d2ac88a7` |
| `runner.gd` | `df4430bea75380901cb108842eb1bace55de9025ecba0c42f83e734e2cb8ef59` |
| `snapshot.gd` | `026fa6b74ae7285fa70971981cacc664b739164535779903ca452fa9b10252a5` |

No source ownership is claimed. No fresh candidate speed, full regression,
cross-platform or native UI acceptance claim is made.
