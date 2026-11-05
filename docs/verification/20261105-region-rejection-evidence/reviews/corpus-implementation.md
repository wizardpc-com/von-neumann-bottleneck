# Round11 Region compatibility corpus

Implemented by `/root/audit_scores` on 2026-11-05. Sole edited repository file:
`scripts/benchmarks/computation/workload_cases.gd`.

**Ownership is released to root. No Godot process or Git mutation was run by this
agent. Runtime validation and integration remain pending with root.**

## Implemented corpus

New case ID: `representation_region_compatibility`; operation:
`region_compatibility`; subsystem: `representation_region`.

The captured input contains all five task IDs, all eight authored orders, their
complete goals, and four explicit plans per task: whole RAW, whole RLE and the
two existing task-specific alternatives from `test_representation_region.gd`.
The timed adapter calls the actual `Region.run()` once per order and plan and
`Region.meets()` once per plan. Its result retains five task rows containing
twenty plan rows, **32 original complete Trace objects and 20 actual boolean
decisions**. No projection, score-only replacement, reference simulator, cached
result, or fabricated outcome was added.

The existing `representation_online_clients` input and execution path are
unchanged. All other existing adapter helpers are unchanged except the case
list, operation dispatch, semantic dispatch and Region rejection dispatch.
Runner behavior and its complete typed evidence format are untouched.

## Untimed semantic checks

The new validator checks:

- Exactly five authored task rows, four plans per task, eight orders,
  32 actual Trace instances and twenty boolean decisions.
- Complete authored order/goal inputs and submitted plan provenance.
- Successful actual model execution, complete per-client output events and
  independent ordered source-value oracles through the existing validator.
- Complete expected vectors and correct top-level result/expected sums.
- All24 execution/storage fields are nonnegative integers.
- Every retained encoded block binds to its source range, physical bytes,
  directory, payload length and storage size; actual codec decoding restores
  the original source slice.
- Original events have consecutive synchronous cycles; service and preparation
  events reconcile with total and per-phase costs. Preparation precedes service
  and has no client ID; service events retain valid cold-client IDs.
- Actual read/write/transfer bytes and encode work reconcile with the metrics,
  including preparation traffic and retained online source storage.
- Each access retains authored address order and client identity; before/after
  decoded cache snapshots and peak bytes stay within the authored capacity.
- The recorded `meets()` result agrees with an independent comparison of the
  actual full results against captured public goals. Both pre-existing
  alternatives remain accepted; RAW/RLE acceptance is derived from the actual
  goal comparisons rather than guessed.

The existing runner supplies repeated full snapshots, JSON-restored input
equivalence, unchanged inputs and retained-result checks across later calls.
Direct malformed-float/type and alias-detachment coverage belongs to the
separate pure rejection test; this adapter preserves its existing integer
restoration semantics for JSON input.

## Strengthened diagnostic

`workload_rejections.region` still executes the same public short online order
with clients0 and the same whole RAW plan. Only its untimed expectations changed:

- All14 existing numeric execution/storage fields must be integer zero.
- Outputs, expected outputs, blocks and accesses must be empty arrays.
- The exact existing metric schema, submitted order/plan, error and Region
  identity must remain.
- The fresh failed Trace must have no events, zero top-level results, default
  cache capacity, and empty loop/program fields.
- Rejected evidence must not satisfy Region task3 completion.

The old comment permitting retained service evidence was removed. Every other
rejection adapter and validator remains unchanged.

Running this same adapter on the frozen runtime should intentionally fail the
Region rejection semantic checks while still preserving its full old snapshot.
That is a negative control and an intentional diagnostic difference. Do not
weaken the general exact comparator or label that diagnostic case full parity.
Compare its sibling rejection results independently and retain both raw files
and the old failure.

## Static verification performed

- Inspected current diff and status; root-owned production/docs/test changes
  were left untouched.
- `git diff --check -- scripts/benchmarks/computation/workload_cases.gd`: pass.
- A Python static fixture check extracted all ten alternatives from this
  adapter and the existing Region test: exact bounds/codecs equality.
- A Git-read-only function-body comparison against HEAD confirms that all26
  other existing helper bodies are unchanged.
- No engine/parse/runtime/native/Windows/export acceptance is claimed.

File SHA256 at release:
`3ee67c17a7e3d5c985929fed99b0b61b2296de6dab75450a436153a9b0ae6df8`.

## Root verification entry points

Use an imported isolated Godot4.7.1 project and identical adapter/runner bytes on
frozen and candidate runtimes, with the same declared iteration counts:

```sh
<Godot-4.7.1> --headless --path <isolated-project> \
  --script res://scripts/benchmarks/computation/runner.gd -- \
  --benchmark-group=workload \
  --only=representation_region_compatibility,representation_online_clients \
  --label=<reference-or-candidate> --host-label=<same-host> \
  --samples=7 --iterations-file=<fixed-counts.json> \
  --benchmark-output=user://region-compatible.json
```

Capture `--only=workload_rejections` separately for the intentional rejected
evidence change. Candidate should satisfy the strengthened contract; frozen
should fail only its old Region residual-work assertions. Inspect complete logs
and actual exit codes before sealing/strict comparison. Root should run the
new pure rejection suite and the planned existing model/session/support/journey
and workbench checks separately.

This correction is not a speedup claim. The compatibility corpus is bounded to
the eight existing authored orders and these twenty plans, not arbitrary inputs.
