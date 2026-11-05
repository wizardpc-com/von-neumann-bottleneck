# Round7 model/catalog and codec implementation

Owner `/root/audit_scores`. Implementation is **READY FOR ROOT RUNTIME REVIEW**.
All six listed files are now **RELEASED to root**; no further edits will occur
without reassignment. No Godot/native process or Git mutation was performed.

Read the frozen Round7 plan and ownership contract before editing. Initial
working tree contained only root's new execution plan; other agents' files
have not been edited.

## Changed owned files

- `experiments/layout_strategy/model.gd`
  - Adds literal frozen `LEGACY_SCENARIO_IDS` with the original four IDs/order.
  - Appends `scan_pair_serial` and `split_fields_serial` to current IDs.
  - Adds only their explicit query structures in `scenario()`.
  - Leaves model version, Executor, normalization, validation, condition/plan
    hashing, memory costs and the original scenario construction unchanged.
- `experiments/layout_strategy/challenge_code.gd`
  - Adds detached normalized `starter_goal(task_id)`.
  - Retains exact original scan goals350/0 and600/80.
  - Adds pair RAM goal600/80 and phased cycle goal800/144.
  - `starter()` uses ordinary source inputs and existing create/replay path.
  - No grammar, envelope, dormant-plan, decode/inspect/compare change.
- `tests/test_layout_strategy_model.gd`
  - Asserts exact original and additive catalog lists.
  - Preserves the former original catalog/output assertions by looping over the
    explicit legacy list. Existing general grid covers all six conditions.
- `tests/test_layout_strategy_challenge_code.gd`
  - Adds starter-goal normalization/detachment and no-mixed-starter assertions.
  - Adds actual new target/output/condition/serial-group/allocation coverage.
  - Proves the pair's same copy improves traffic by44B but is58 cycles behind
    under a cycle goal; inclusive557/80 boundary, phased improvements412/940,
    original-envelope reply tie and old/new cross-condition exclusion.
- `tests/test_layout_strategy_structures.gd`
  - Extends the existing model suite solely to reuse authoritative run and
    event/accounting/causality helpers. Its own `_run()` has QA-profile guard.
  - Exact new definitions/output vectors; independent conditions/caller safety.
  - 17 basic physical plans ×2 new tasks, including cold fields.
  - Seven exact previously observed structures, response arrays and metrics.
  - Repeated/JSON complete new-ID Trace for each representative.
  - All seven frozen Round6 probe Trace hashes must reproduce under the
    original probe-only IDs; new IDs must preserve every event/metric/data/map
    while intentionally changing case/name identity and full Trace.
  - Serial tile1/4/64 parity versus17, actual goal reversal, inclusive caps,
    request-order effects, task-specific group errors, and genuine failed
    three/four-field allocations. Planned88 actual measurements including
    four expected allocation failures; runtime must confirm the count.
- `.godot/collaboration/round7-structure-probe.gd`
  - Optional root-run isolated probe. Reuses existing complete accounting and
    event checks from `test_layout_strategy_model.gd`.
  - Declares220 distinct effective copied one/two-field maps plus source per
    new task:442 candidates, group1/tile17.
  - Finds the actual four-metric frontier and repeat/JSON remeasures each
    representative twice. Replay count is2×observed frontier classes, not an
    assumed result.
  - Writes complete candidate inputs, metrics, outputs, conditions and Trace
    hashes to isolated `user://round7-structure-probe.json` or root's explicit
    `--probe-output=...`; does not touch notebook/challenge/official data.

## Static verification performed

- Owned tracked diff whitespace check passes; new suite/probe/report have no
  trailing whitespace.
- A byte comparison against current HEAD verifies the entire Executor block,
  everything from `starter_plan()` onward in Model, and codec transport/
  validation/comparison sections are unchanged.
- All seven embedded historical probe hashes exist in the committed actual
  Round6 raw structural results.
- All own diffs inspected; unrelated source and fixtures preserved.

No parser, Godot test or probe execution is claimed. Root should import and run
`test_layout_strategy_model`, `test_layout_strategy_challenge_code` and
`test_layout_strategy_structures` in the updated isolated copy, plus root's
frozen scheduling/code parity and official legacy gate. Root owns import UIDs.
Please retain complete failure logs if a typed-array or fixture issue is found.

## Integration notes

UI can call `Code.starter_goal(current_id)` now; it returns{} for mixed/unknown
tasks. Store legacy validators can use the frozen `Model.LEGACY_SCENARIO_IDS`.
No other agent needs to edit Model or codec for these APIs.

The unchanged same-ID probe task is used only by the structural regression to
prove historical event parity. Player `Session.task()` and transport still
reconstruct the fixed new task IDs; no custom public task authoring is added.
New full Trace identities must not be compared byte-for-byte with old probe
identities, while original four task identities must remain exact.
