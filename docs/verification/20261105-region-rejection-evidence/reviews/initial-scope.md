# Proposed Round11 scope: consistent Online Region rejection evidence

Read-only scope review by `audit_polish`, 2026-11-05, following the11:37Z
assignment in `.godot/collaboration/round10-recovery.md`. No production/test
source edits, Godot/native execution or Git mutation were performed.

## Recommended bounded change

Repair only the `preparation_machine` rejection branch in
`experiments/representation_region/model.gd:15-20`.

Keep the existing `Base.run()` call and base-error precedence for this first
correctness correction. If base service is valid but preparation-specific
parameters are invalid, return a **fresh failed Trace with detached input
provenance and no published work or output**, instead of editing three fields
of the already populated service result.

This fixes the confirmed contradictory result with one production file and
focused regression coverage. It deliberately does not remove the redundant
base computation, reuse cold-client service, add validation to the shared
base model, change simulation costs, or alter any valid result. Validation
before service work can be considered separately after the rejection contract
is stable; moving the existing condition to the start now would silently
change which error wins for inputs that are invalid in both domains.

## Confirmed defect, including retained actual evidence

Current `Region.run()` executes `Base.run(spec,plan)`, sets the Region identity
and returns immediately on a base failure. For a base-successful input with
invalid `online`, `clients` or `encoder`, it sets only:

- `passed = false`
- `metrics.error = "preparation_machine"`
- `events = []`
- `metrics.total_cycles = 0`

The remaining service fields and top-level values survive.

The source finding in `docs/development/COMPUTATION_AUDIT_20261105.md` and the
Round9 workload audit is independently supported by the archived actual
typed snapshot:

`docs/verification/20261105-computation-kernels/benchmarks/20261105T100802Z-candidate-final/workload.json.gz`

Case `workload_rejections` has recorded snapshot SHA256
`389cf59d2fe8373afc600e4d79a399b9d39ff1c0c941642034ca5b2f05d17750`.
Its `region` result is the public short online order with `clients=0` and the
whole RAW plan:

| Field | Archived value |
| --- | --- |
| `passed`, `events`, `total_cycles` | `false`, `[]`, `0` |
| `request_cycles`, `transfer_cycles`, `consume_cycles` | `4`, `68`, `1` |
| `traffic_bytes`, `decoded_values`, `peak_cache_bytes` | `68`, `64`, `64` |
| `cache_misses`, `overfetch_values`, `stored_bytes` | `1`, `63`, `68` |
| `outputs`, `expected` | `[7]`, `[7]` |
| top-level `result_value`, `expected_value` | `7`, `7` |
| `blocks`, `accesses` | one populated row each |

This is a real inconsistency in rejected evidence. It is not evidence of false
completion: `Region.meets()` first requires passing traces and exact authored
specifications, and the existing result is already failed.

## Exact rejected-result contract

For a base-successful input rejected by the current preparation validator:

1. `test_name` remains `representation-region-v1`; `passed` remains false;
   `metrics.error` remains exactly `preparation_machine`.
2. Preserve the current rejection metric key set. Keep deep detached copies of
   the submitted `spec` and `plan`; do not silently normalize invalid values.
3. Zero all14 existing numerical metrics:
   `total_cycles`, `request_cycles`, `transfer_cycles`, `decode_cycles`,
   `consume_cycles`, `stored_bytes`, `traffic_bytes`, `decoded_values`,
   `decode_ops`, `cache_hits`, `cache_misses`, `evictions`, `overfetch_values`,
   `peak_cache_bytes`.
4. Empty `outputs`, `expected`, `blocks`, `accesses` and top-level `events`.
   The attempted plan/data remain inspectable through the input provenance.
   Do not retain codec or cache results from the discarded service.
5. Fresh Trace defaults provide top-level `result_value=0`, `expected_value=0`,
   `cache_capacity_lines=1`, empty `loop_order` and empty `program_source`.
6. Keep the current accepted parameter domain: `online` is a bool; `clients`
   is an int from1 through8; `encoder` is an int at least1. Valid offline
   requests still require valid clients/encoder as they do today. Do not add
   an encoder upper limit or coerce integer-valued floats.
7. A base-invalid input still returns its existing base failure, with Region
   `test_name`, before checking preparation fields. Do not normalize other
   base rejection results opportunistically in this patch.

A small private constructor for this one rejected result is sufficient. It
may copy the existing service metric schema then reset the explicit execution
fields, or construct that same schema from detached inputs. Prefer explicit
field lists over a generic rule that clears every future numeric field.
Do not call `Base.run()` with a fabricated invalid plan to obtain a blank trace.

No Region-only success metrics need to be added to this rejected-result shape:
the current branch does not expose `preparation_cycles`, `service_cycles`,
`source_storage_bytes`, `representation_bytes` or other wrapper-success fields.
Adding them would be an extra API-shape decision with no current caller need.

## Exact public callers and implications

| Current caller | Actual use | Boundary to preserve |
| --- | --- | --- |
| `region.gd:549-568`, `run_current()` | Runs every `Model.orders(task)` on the editor plan, checks `meets`, records run/optional completion, retains traces and support plans. | Authored legal specs and existing completion authority remain unchanged. Do not inject a test order or fake error into the production UI. |
| `region.gd:774-803`, `restore_session()` | Recomputes saved runs and protected supports from plans plus fresh authored orders. | Saved flags/metrics are not trusted; every valid restored Trace and checkmark must stay equal. |
| `region.gd:985-994`, `copy_previous_support()` | Revalidates the preceding task's protected recipe before undoable draft reuse. | The repair must not change any valid support acceptance. |
| `region.gd:1059-1068`, `representation_review_evidence()` | Revalidates all five protected plans for visible Region closure and journey paths. | Same complete per-order measured metrics and no newly granted progress. |
| `candidate_session/journey_review.gd:39-68`, `evaluate_domain()` | Replays protected/saved plans in read-only combined journey review. | Read-only evidence and all five Region decisions stay equal; no file writes or leases introduced. |
| `workload_cases.gd:126-142`, `run_case()` | Executes the public online short/eight-client orders and `Region.meets`. | Existing valid benchmark result objects and every event remain exact. |
| `workload_cases.gd:242-245`, `_rejections()` | Calls the real Region API with the public order modified to clients0. | This sub-result intentionally changes; preserve the old archived snapshot as diagnostic evidence. |

`session_store.gd` references the model for version identity and
`clean_plan()`/asset validation; it does not call `Region.run()`. Persisted
formats retain task IDs and plans, not arbitrary preparation specs or stored
metrics. Its `contract_id()` hashes the unchanged authored orders/goals.
`src/playtest/task_identity.gd:24-46` also uses this identity/contract. These
files should remain unchanged.

Visible consumers in `region.gd:628-662`, `order_cost_strip.gd:45-54` and
`public_observation()` present actual selected traces. Current normal call
paths supply Catalog orders, so malformed preparation specs are API/test
boundary inputs rather than an editable user control. A production UI rewrite
or a new failure display is not required to correct this pure rejection.

The Region README contains historical candidate-only/main40 wording, whereas
the current host has `record_official_run()` and the journey has60 tasks. Use
the current call graph above for authority analysis; do not repeat the old
claim that the model is unreachable from the current journey.

## Focused test plan

Add one pure `tests/test_representation_region_rejections.gd`, or extend the
existing model section of `test_representation_region.gd` without broad UI
changes. A separate pure suite gives a cheap old/new negative control.

Required checks:

- A valid public online order and RAW plan with clients0 must reject with the
  full clean contract above. Run the new test on the frozen old runtime first:
  the residual metrics/output checks should genuinely fail.
- Cover each invalid field independently: missing, null, incorrect scalar or
  container type; clients0/negative/9; encoder0/negative; non-bool `online`.
  Include direct float1.0 and bool values for integer fields. These type cases
  must call GDScript APIs directly: the computation adapter intentionally
  rebuilds JSON integer-valued numbers as ints and therefore cannot preserve
  this exact malformed-input distinction.
- Apply invalid clients/encoder to both `online=true` and `online=false`:
  existing parameter requirements must not be relaxed.
- Exercise whole RAW, whole RLE and mixed plans so the test would expose
  residual decode work as well as transfer/cache/output data. Include public
  short and eight-client scan requests.
- Verify full deterministic typed equality across fresh repeated rejected
  calls, every top-level Trace field, no input mutation, detached nested
  `spec`/`plan`, and retained-result immutability after later valid calls.
- Verify `Region.meets()` grants nothing for rejected results.
- Compound-invalid inputs must preserve current base-error precedence:
  invalid prep plus missing data, empty/bad plan, invalid base machine,
  out-of-range address and scratch rejection. Compare these entire delegated
  traces to the frozen current baseline; do not opportunistically clear any
  existing base fields.
- Validate boundary successes, including clients1/8, encoder1 and bool
  online/offline, without changing their full results.

Run existing relevant suites through the isolated verifier:

1. `test_representation_region`: five tasks, actual codec/cost/output oracles,
   alternative solutions, rejection, authored identity and immutable history.
2. `test_representation_session`: existing schema, saved plans, replay,
   exact completion and draft/Undo/save continuity.
3. `test_candidate_supports` and `test_candidate_journey_review`: protected
   plans/history-cap/reopen and exact read-only review evidence.
4. `test_representation_workbench_presentation` or
   `test_representation_visual`: ordinary selected-record costs and paired
   orders still present genuine unchanged valid results.

If shared Base/Trace/codec code remains unchanged, their complete suites need
not be expanded merely for this local failure branch. `test_representation_plan`
is a useful neighboring check if root factors any shared initializer; that
factorization would be a larger scope than recommended here.

No new GPU/native claim is needed for a pure model error return with no host
change. Existing UI suite results must still be inspected. Actual native,
Windows, exports and long sessions remain separately unverified.

## Full-Trace compatibility and evidence delivery

Freeze the completed Round10 runtime before implementing Round11. Do not use
a reference copied after editing the Region model.

Use the existing typed `Snapshot.freeze()` helper or its current strict
comparator. Capture all eight authored orders for baseline RAW, whole RLE and
the two existing task-specific alternatives (32 traces, including legal but
over-budget plans). Include `Region.meets()` outcomes. Compare complete objects:
all metrics and provenance, block bytes/directories, cache snapshots, outputs,
result/expected values, event order, cycle/duration, component/details and client
IDs; also default Trace fields. Preserve typed-container distinctions, repeat
determinism, input immutability and later-call detachment.

The existing `representation_online_clients` benchmark already provides four
valid complete traces across two plans/two public orders. It should remain
byte-for-byte equivalent, but it does not alone cover the offline tasks.

Treat `workload_rejections.region` as an explicitly intentional diagnostic
difference. Compare its exact old/new field changes and require the error,
input provenance, failed status and identity to stay. Compare every sibling
rejection result unchanged. Do not weaken the general exact comparator,
overwrite the old snapshot, or call the now-different complete rejection case
full parity. Remove/update the adapter's historical comment at
`workload_cases.gd:523-524` only when the production correction and stronger
rejection assertions land together.

This is a correctness repair, not a performance result. The recommended patch
still computes the one base service internally before rejecting the wrapper.
Report no speedup and do not conflate host calculation time with modeled work.
Cold-client template reuse and moving validation ahead of service remain
separate measured optimization opportunities.

## Identity, saved data and rollback

Keep `Region.VERSION`, Catalog orders/goals, model costs, session schemas,
contract fingerprint, telemetry identity and all progression gates unchanged.
The intentional difference is confined to malformed preparation-parameter
results that already failed. Valid stored plans replay under the same model
and conditions, so no player-data migration is needed.

Rollback restores the single Region rejection branch from the frozen Round10
base and reverts its corresponding diagnostic expectations. No saved file
must be rewritten or deleted; old archived evidence stays intact. Before any
delivery, root should bind the exact changed production/test/doc files,
inspect full logs, and keep the initial failing negative control.

Recommended ownership after root approves the plan: one agent owns the pure
regression file; another prepares/reviews the exact valid corpus; root owns
the tiny model change, benchmark expectation update, engine execution and
documentation. This document proposes scope only.

## Source identities at this review

| File | SHA256 |
| --- | --- |
| `experiments/representation_region/model.gd` | `f55055dc26b8ee1dc7db6a9cdbe12fc8bf3305632a3c6c10af6ef134acd15137` |
| `experiments/representation/plan_model.gd` | `698029a07aa2b26097307b40fffbee99c87bcebaacc257d939d1ea942927d136` |
| `experiments/representation_region/catalog.gd` | `710525df1266f8ec0217f086051e72d92192513ea5f98034647573282dc4b92b` |
| `src/simulation/simulation_trace.gd` | `f56cd6bf07973d2284b240a7e83ef0f7b1db7d04db97531fc4ea855ab4b7d7a4` |
| `scripts/benchmarks/computation/workload_cases.gd` | `bd7f061288e9a9cd181599dd94b200a2921b624de35b37bfc96379de14256db1` |
