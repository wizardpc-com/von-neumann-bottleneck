# Round9 independent computation-harness review

Reviewer: `/root/audit_scores`, 2026-11-05. Read-only review requested in
`.godot/collaboration/round9-audit.md`. No engine/test/probe execution or source
edits by reviewer. Root owns fixes and verification.

Reviewed bytes:

| File | SHA-256 |
|---|---|
| `runner.gd` | `3a73de2ec18ed9fe731bc0c9145d35d3941bd091dc25509d0c1ef8c60fedc498` |
| `snapshot.gd` | `b1417d4ec8af612bcd7461f35d54c4915ef719dd18d4e207fbbb54c6191c82dc` |
| `compare.py` | `79f3ab140b4c420c20c9d3025763b789a883f93c8f0fc46a07836391fec872d1` |
| `test_compare.py` | `b1841eac1b1089b59c0cff8f8b2513a34a2dc8e3f4cb52058128b4687df5c324` |

Paths are under `scripts/benchmarks/computation/`.

## Verdict at this snapshot

The approach correctly compares all captured script fields and actual Trace
events, keeps snapshot/export/hash work outside timed regions, compares exact
input descriptions, and refuses different case sets, iteration counts or
declared environments. It is suitable for initial profiling with log review.

**Do not yet use an unqualified PASS as proof of complete result/ownership
parity.** Two concrete harness gaps below can allow incomplete or shared mutable
evidence to pass. Actual success/failure-path inspection remains pending the
first benchmark receipt; equal erroneous outputs alone are not correctness.

## Findings requiring attention before final parity claims

### H1 — P1: unsupported snapshot evidence can produce a passing receipt

`snapshot.gd:5–8,31–36,52–54` returns a normal Dictionary marker
`{"@unsupported": ...}` after `push_error()` for excessive depth, a nonscripted
object or unsupported type. `runner.gd:95–107,121` checks nullness and equality,
but does not add a runner failure when a marker is present. `compare.py:39–62`
does not reject markers either.

Consequently two results with the same unsupported field can compare equal
while that field's real contents are omitted. The runner can print PASS/exit0
because its `failures` list does not include serializer errors. A separate log
scanner may reject the process, but the saved JSON and comparator are not
self-contained fail-closed evidence.

Recommended bounded repair: return/collect explicit serialization errors in
the runner, or recursively detect the reserved unsupported marker and add a
failure; independently reject such evidence in the comparator. Keep the depth
bound as an error, not as a silent lossy representation. Add a test with a
nested unsupported marker on **both** reference and candidate; equality must
still fail. A dedicated Godot test for an unsupported/cyclic result is useful,
but no such probe was executed by this reviewer.

### H2 — P1 for shared-state optimizations: ownership test uses only one input

`runner.gd:89–123` retains the first result, then reruns only the same spec or its
JSON equivalent. A simulator using one mutable global result object, cleared
and refilled for every input, can pass these checks: all writes restore exactly
the same values. When the next distinct benchmark case runs, the old result
object is no longer retained by the harness (only its frozen snapshot remains).

This does not establish that result A survives running a different input B.
It is a material gap if an optimization adds pooling/caching/reuse. The grouped
failure/recovery adapters help for their own workflows, but are not a generic
substitute for an A/B retained-result check.

Recommended repair: outside timing, retain actual results for multiple distinct
inputs and re-freeze A after B. Where a module has only one top-level spec,
provide a small adapter-owned pair of distinct legal inputs. Also freeze the
JSON-restored spec before/after its call: currently only the original spec gets
an input-immutability check.

The snapshot format itself normalizes object references into repeated values;
it does not preserve alias topology. That is acceptable for value evidence,
provided ownership/alias safety is explicitly checked behaviorally and is not
claimed solely from equal snapshots.

### H3 — P1 before selecting a speedup: success-path expectations are absent

`runner.gd:95` only requires a nonnull result. A planned successful workload
that immediately returns the same validation error on every run still becomes
a valid fast benchmark. The comparator cannot distinguish this from the
intended computation. This is especially relevant for legal stress fixtures,
creation model/training limits, failed-state continuation and grouped results.

Required next step: inspect the first actual saved full results and record
intended versus observed outcome for **each inner workflow**, not just the 36
top-level case IDs. Keep deliberate failure fixtures. Normal official
circuits/sequences must pass; failed diagnostic inputs must produce the
intended structured errors, and recovery runs must execute their real success
path. Stress cases should have nontrivial operation/event counts matching the
declared work. This can be a separate untimed semantic validation stage rather
than embedding expected numeric outputs in the measurement adapter.

An equal source baseline is a reference for preservation, not independent
proof that the selected fixture exercises its intended workload.

## Additional bounded improvements / scope limits

### H4 — P2: comparator numeric/record validation is permissive

`compare.py:41–53,63–71` uses optional `.get()` checks and positive comparisons.
It does not require all metadata/`failures` fields to exist. Python treats
`bool` as an `int`; only the reference iteration value gets an `isinstance`
check, and a numerically equal candidate float is accepted. Positive infinity
in duration arrays passes `value > 0` and can produce meaningless ratios/NaN.
Other malformed types raise instead of returning a failed comparison.

Runner-produced normal records contain bounded integer durations, so this is
not evidence of an observed bad timing. Still, a tool advertised as rejecting
incomplete evidence should require the schema, use exact integer checks for
iterations/sample counts/durations and finite positive timing values, and
return a clear failure for malformed records. Add tests for both missing fields,
both unsupported snapshots, nonfinite duration, bool/float iteration counts
and absent snapshot/input. Existing Python tests cover changed/omitted events,
case sets, failures, input changes, scalar snapshot type changes, batch counts
and architecture differences; those are useful and should remain.

### H5 — P2: same OS/architecture is not necessarily the same timing host

`runner.gd:73–77` records engine, OS, architecture and display; comparison checks
those. Two different Macs with the same architecture/engine would satisfy this
while having different CPUs, power/thermal conditions and background load.
For the current task, root can control the single physical host and document it
in the invocation receipt. If receipts are intended to travel, record an
appropriate nonsecret host/hardware identifier and execution flags, and keep
different-host semantic parity separate from comparable performance.

Likewise snapshot script paths identify names, not source bytes. Keep the
frozen-base commit/source inventory, adapter/harness hashes, invocation, pinned
engine binary and final source binding alongside results. Do not infer them
from matching `res://...` paths.

### H6 — P2: only the last result of a timed batch is checked

`runner.gd:116–121` discards intermediate outputs and checks only `last`.
Repeated full checks before and after batches are good bounded regression
coverage, but do not establish every call in the batch was identical. A
stateful bug whose period divides the batch length could be missed. Keep timed
loops free of serialization; add a separate small untimed repetition corpus
that checks each result if making strong determinism claims.

### H7 — P3: snapshot is a value-normalized representation, not fully lossless

Scalar integer/float/StringName types and packed arrays are distinguished, but
typed Array/Dictionary element/key/value metadata is not recorded
(`snapshot.gd:19–30`). Dictionary insertion order and reference sharing are
also normalized away. A typed array becoming untyped can therefore have the
same frozen value. For current script properties, many declared types remain
enforced by their owner, but returned nested containers can still differ.

Either preserve container typing where it is part of the public API or narrow
the word “lossless” to semantic value/full-field evidence and retain independent
API/ownership tests. Do not add opaque object IDs: those would make unrelated
equivalent runs differ without solving the behavior contract.

### H8 — Timing interpretation

- The cold call, JSON-restored call and same-input repeat supply preliminary
  execution before measured batches; fixed iteration files are essential for
  reference/candidate comparability because automatic cold-based sizing can
  differ. The comparator already rejects unequal counts.
- Snapshots, export and harness hashing are outside timing. **Model-owned**
  canonical strings/JSON generated as part of the public API remain inside;
  clarify the receipt phrase “serialization excluded” so it does not imply
  that unavoidable API work has been removed.
- Multiple full baseline/repeat results remain alive during timing. This is
  symmetric when complete outputs are unchanged, but the measurements are API
  batch cost under that retained-memory condition, not isolated arithmetic
  kernel time or GPU/UI latency.
- Seven samples and ranges are useful; alternate/repeat base/candidate runs
  before attributing a small difference to an optimization. A same-host
  headless result does not establish Windows or native interactive acceptance.

## Observed verification versus still pending

Read the actual root-owned receipt:
`.godot/verification/20261105T090809Z-3273d2f7/results.json`.
It records pinned engine `4.7.1.stable.official.a13da4feb`, import/user-directory
checks and 15 related model suites all passed. The import log search found no
SCRIPT ERROR / Parse Error / ERROR matches. This is existing-suite evidence,
**not** a benchmark result or an independent execution by this reviewer.

No first full benchmark receipt was available in the reviewed task paths at
report creation. Outcome classification, unknown marker inspection, actual
snapshot completeness and measured speed attribution therefore remain pending.
Root should provide the exact receipt path for a read-only follow-up; no extra
engine runs are needed from this agent.

## Requested follow-up acceptance

1. Make unsupported evidence fail closed in runner and comparator.
2. Add cross-input retained-result and JSON-input immutability checks.
3. Inspect actual nested outcomes/event counts before timing interpretation.
4. Retain fixed batches, same source/harness corpus and exact full-value parity.
5. Bind final run/engine/source metadata and preserve any first-run failures.

No source ownership is claimed; root remains free to implement the fixes.
