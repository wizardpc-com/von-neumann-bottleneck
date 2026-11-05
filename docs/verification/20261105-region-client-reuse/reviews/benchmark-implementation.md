# Round12 public client sweep and diagnostic timing handoff

Owner `/root/audit_scores`, 2026-11-05. Implementation and static review
completed; **Godot parse/runtime/timing verification is NOT_RUN by this owner**.
Root owns all engine runs and Git integration. Both assigned repository files
are now released for root integration:

- `scripts/benchmarks/computation/workload_cases.gd`
- `scripts/benchmarks/computation/region_profile.gd`

No production models, tests, docs, UIDs, Git state or player files were changed
by this assignment. The production Region edit and new regression belong to
their separately assigned owners.

## Public complete-result sweep

Added eight separate cases, all returning the actual full `Region.run` Trace:

| Family | IDs | Input and provenance |
| --- | --- | --- |
| Online whole RLE | `representation_region_online_rle_c1`, `_c2`, `_c4`, `_c8` | `Region.orders(3)[1]`, authored 64-address scan; only the declared client count changes; RLE `[0,64)` |
| Offline mixed revisits | `representation_region_offline_revisits_c1`, `_c2`, `_c4`, `_c8` | `Region.orders(0)[0]` source asset; explicit name `bounded-192-mixed-revisits`, cache32, addresses `[0,16,0,48,0,16]` repeated32; RLE `[0,16)`, RAW `[16,48)`, RLE `[48,64)` |

The second family is a declared bounded API stress fixture, not an authored
goal, a new game condition or a `meets()` decision. Inputs retain complete
spec, plan, source task/order, family, client count and operation identity.
`region_client_cases()` supplies both the existing public runner and the new
diagnostic helper, so fixtures are not independently recreated in two places.

The new operation goes through the existing integer-input restoration and
typed data/address/plan constructors. It does not project the returned result.
The existing runner therefore still checks full typed Trace snapshots, JSON
restoration, repeats, timed batches, retained results and unchanged inputs.

Validation reuses the existing full `_region_trace` checks for actual source
values, full provenance, physical byte roundtrips, directory/storage formulas,
preparation/service phase order, exact event timing, output count/order,
per-client access identities and finite cache capacity. Additional checks bind
the exact authored/stress input and plan; online results require one cold miss
and63 hits per client plus actual positive preparation. Offline results require
no preparation and exercised hits/evictions. Each client's first access must
show an empty cache and a miss. The existing36-Trace corpus, rejection case and
Base-only control remain independent selections.

## Diagnostic helper and boundaries

`region_profile.gd` is a standalone SceneTree. Before any model execution or
receipt write, it requires a user directory containing
`/VonNeumannBottleneckChecks/`. Output is fixed to
`user://region-profile.json`; no production instrumentation or hooks exist.

It records a cold invocation and **seven** timed samples per selected case for
two independently timed boundaries. Counts are declared and fixed for both
boundaries:8 invocations/sample for online,2 for offline. There is no calibration
or candidate-specific iteration selection in this helper.

1. **Independent Base services:** N actual `Base.run(source, plan)` calls,
   including each Base service's complete Trace allocation. All N results are
   returned and retained for verification. Typed source/plan setup is untimed.
   This retention differs from the production wrapper's first/current service
   references; it is not a timing of that old wrapper loop or a peak-heap
   measurement. Inside a fixed batch, replacing the preceding invocation's
   result also releases that earlier result; initial retained evidence stays
   alive throughout.
2. **Client evidence materialization:** from one precomputed immutable actual
   Base service, allocate a fresh Trace, deep-copy the actual initialized metric
   seed, create every event through the existing details-copy/`Codec.emit` path,
   add the ten existing service metrics in order, append outputs/expected values
   and deep-copy every access row. Preserve single-service overfetch/peak
   quantities, actual measured preparation offset/storage and current container
   types. This mirrors only required existing service emission/aggregation.

The untimed seed comes from the real Base and real complete Region results.
No second preparation simulator or invented preparation formula is added.
Template/oracle/seed construction, full snapshots, hashes and export are outside
both timers. These times are **not additive attribution**, pure computation or
allocation time, public Region speed ratios, Run-button latency or heap evidence.
No ratio or subtraction is reported by this helper.

## Complete evidence and failure checks

Before accepting samples, the helper:

- Confirms actual Base and actual Region success and the public fixture's
  semantic validation.
- Compares each independently executed full Base result with the original
  complete typed Base template.
- Freezes the actual complete Region result and removes only its contiguous
  preparation-event prefix for the materialization comparison. All remaining
  absolute cycles, event fields, types, array metadata, metrics and top-level
  fields remain. The observed preparation prefix must end at the actual
  preparation-cycle metric.
- Checks each cold and final timed materialization against that complete
  service-suffix object, including all fields rather than selected metrics.
- Checks template, actual Region oracle, earlier independent results and
  earlier materialization after every timed batch, plus source/plan/seed/case
  bytes.
- Mutates a disposable materialization's event details, access cache snapshot,
  encoded block bytes and source-provenance bytes, then checks template,
  original Region, earlier results and all original inputs remain exact.
- Retains all complete original evidence across later different cases and
  checks it again before finishing.
- Requires seven samples with positive measured durations for each boundary.

The receipt includes engine/host/flags, full case input, declared fixed counts,
cold timings, all seven durations/per-call values/range/median, actual case and
global failure status, and complete typed evidence for `template`, `region`,
`independent_services`, `materialized_service`, `materialization_seed`.
It also records the original canonical snapshot JSON byte count and SHA256.
Evidence is intentionally large but bounded by the eight declared fixtures;
it is not a compact metric projection.

A synchronous-run watchdog catches an unwound nested script failure and emits
a failed receipt/exit rather than silently waiting. Compile failures still
require root to inspect the engine log and actual process exit. A receipt
write/flush failure produces a failed process/log; the failed write itself
cannot reliably carry its own failure, so accepting JSON without logs/exit is
insufficient.

## Static verification performed

- `git diff --check -- scripts/benchmarks/computation/workload_cases.gd scripts/benchmarks/computation/region_profile.gd`: pass.
- Direct Python whitespace/newline check includes the new untracked profile,
  which ordinary Git diff omits: pass.
- Parsed existing static-function boundaries against `git show HEAD:...`:
  only `cases`, `run_case`, `validate_case` changed, by dispatch/addition;
 33 existing helper bodies remain byte-identical. Only new functions are
  `_region_client_result` and `region_client_cases`.
- All17 adapter and6 profile preload paths resolve to existing files.
- Reviewed seed/suffix/materialization against the current Region loop,
  Base implementation, Snapshot typed representation and existing runner.
- Checked fixed seven-sample/8-or2-iteration declarations and all eight IDs.
- Inspected final diff and Git status; unrelated owner files preserved.

This is source/static evidence, not a GDScript parse result or a measured speed
benefit. Root must import both harness files into the frozen and candidate QA
projects and run the same harness bytes on both.

## Root execution examples

Use the documented pinned Godot4.7.1 executable and an **already isolated,
imported QA project**, not the source/player profile:

```sh
<Godot-4.7.1> --headless --path <isolated-project> \
  --script res://scripts/benchmarks/computation/region_profile.gd -- \
  --host-label=<reference-or-candidate-host>
```

Optional bounded first check:

```sh
<Godot-4.7.1> --headless --path <isolated-project> \
  --script res://scripts/benchmarks/computation/region_profile.gd -- \
  --only=representation_region_online_rle_c1,representation_region_offline_revisits_c1
```

For full public measurements use the existing `runner.gd` workload group,
the eight IDs above plus the existing compatibility/online/rejection/Base
controls, seven samples, and the same reference-derived fixed iteration file
on both runtimes. Keep original logs/JSON/exit codes and strict sealed
comparison; no new comparator or snapshot behavior was added here.

## Released source identities

| File | SHA256 |
| --- | --- |
| `scripts/benchmarks/computation/workload_cases.gd` | `6a480e5215efcf01fc9cdb037d5ff18e68f4c1679ef8ba0f906ebf908eec4c17` |
| `scripts/benchmarks/computation/region_profile.gd` | `566619295630a372d1c7a21c9a0551cff464db34303f93a902d4f5c71155e0de` |

Both files released. Further source edits require renewed ownership coordination.
