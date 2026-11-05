# Round11 Region rejection contract review

Reviewed at: 2026-11-05T12:21:33.077221+00:00
Reviewer: `/root/review_records_final`
Scope: read-only production contract, caller, saved-support and identity compatibility review. No production, test or repository-document changes; no Git, Godot or native execution by this reviewer.

## Finding

**No actionable finding in the current production patch.** The change is narrowly consistent with `docs/exec-plans/active/region-rejection-evidence-20261105.md`: only Base-successful calls rejected for preparation parameters publish fresh, coherent failed evidence. This is a source review, not a runtime pass or final milestone acceptance.

## Current-source checks

- `experiments/representation_region/model.gd:15–20` retains the initial `Base.run(spec, plan)`, Region identity assignment, immediate Base-failure return and the exact preparation validation predicate. The helper is reached only after Base succeeded. `online` remains bool; `clients` remains int1–8; `encoder` remains int≥1 with no newly imposed maximum. Offline requests retain the same preparation-field requirements, and floats do not become accepted integers.
- The new helper at `model.gd:63–78` has the exact original rejection metric key set: fourteen integer-zero execution/storage metrics, four empty arrays (`outputs`, `expected`, `blocks`, `accesses`), String error `preparation_machine`, and deep-duplicated submitted `spec`/`plan`. There are21 keys; no Region success-only preparation metrics have been introduced into the failure schema. Invalid input provenance is preserved rather than normalized.
- Fresh `SimulationTrace` defaults (`src/simulation/simulation_trace.gd:6–14`) supply empty typed events, integer result/expected0, passedfalse, capacity1, empty typed loop_order and empty program_source. No service output/cache/block evidence survives the rejected preparation.
- A direct byte/diff comparison with the frozen reference shows only the invalid-preparation return and the new helper. The complete valid path and `meets()` are unchanged. `meets()` checks Trace type and `passed` before examining authored spec/plan/costs (`model.gd:80–89`); this correction cannot grant completion.

## Base precedence boundary

`experiments/representation/plan_model.gd:75–93` may return failures before preparation validation for data, plan, machine, addresses or scratch. Late scratch rejection can already contain accumulated stored bytes; that evidence is intentionally preserved by the unchanged early return.

A meaningful compound-error regression is a RAW `[0,16)` plus RAW `[16,64)` plan with scratch_limit16 and clients0: Base stores20 bytes for the first block and then returns `scratch`. Region must return the complete Base failure with stored_bytes20 and only the Region test_name change, rather than replacing it with the fresh preparation failure. This nuance was sent to root and the regression owner. It is a required test boundary, not an identified defect in the current patch.

## Caller and persistence compatibility

- `experiments/representation_region/region.gd:549–568` runs fixed `Model.orders(task)` and grants support/completion only through `Model.meets()`. Session history keeps detached plans and actual run traces.
- `region.gd:774–812` restores task/plan records by rerunning authored orders, and persists task/plan history rather than authoritative Trace scores or arbitrary order specs. `support_records()` at980, previous-support copying at985 and review evidence at1059 likewise persist plans or rerun the model before accepting them.
- `experiments/representation_region/session_store.gd:13` derives the contract from the authored orders/goals; VERSION and existing schema handling remain unchanged. JSON integer-valued float normalization for saved plan boundaries is an existing separate behavior and does not alter the strict preparation API validation.
- `experiments/candidate_session/journey_review.gd:41–70` reruns fixed authored orders and requires `meets()` before producing accepted saved evidence. `src/campaign/second_act_tasks.gd:24–39` projects that revalidated evidence. No rejected arbitrary preparation spec can become a protected saved achievement through these paths.
- `src/playtest/task_identity.gd:43` retains `representation-region-v1`; its case-set binding remains based on the unchanged store contract. Keeping identity is compatible with this correction because standard authored valid workloads, costs and acceptance rules do not change.

## Source binding

Frozen reference: `.godot/verification/20261105T121412Z-round11-reference/project`.
Metadata: `.godot/collaboration/round11-reference.json`.
Declared frozen base: `cf27a8236db7faca56d6361cf9a44d35224b748e` (this reviewer did not invoke Git).

SHA256, independently re-read during review:

| File | Frozen | Current |
| --- | --- | --- |
| `experiments/representation_region/model.gd` | `f55055dc26b8ee1dc7db6a9cdbe12fc8bf3305632a3c6c10af6ef134acd15137` | `c7e37462fd24f23f01425cc2094e5818d1374070e08f51b46a6f6177b9423528` |
| `experiments/representation_region/catalog.gd` | `710525df1266f8ec0217f086051e72d92192513ea5f98034647573282dc4b92b` | identical |
| `experiments/representation_region/session_store.gd` | `fa6a58df9b4755b1eb8254fb90f7ae527a748bbb1d4aa61ee5cb8c9e8e4d447b` | identical |
| `src/playtest/task_identity.gd` | `ff84ebac32c8ca1ed3f81232a79551010095ceb23d292a7c3ce693848661eedc` | identical |
| `experiments/candidate_session/journey_review.gd` | `ddf97fb592f3cc04e1f65fe7c3088d8221ccfd43dc7486c57598fac16b0335a8` | identical |

## Verification limits and handoff

The new regression and compatibility adapter are owned by separate agents and are not accepted by this report. Root still owns the old/new negative regression,32 complete successful traces and20 `meets()` decisions, determinism/detachment, related suites, full invocation/log review and any preview checks. No elapsed-time observation for this changed rejection is an equal-work speedup claim. No Windows/export/native-input acceptance is implied.

Read-only contract/caller review is complete. **No source ownership is retained.** Any later review of released tests or final evidence should be recorded as a separate follow-up against its exact files and hashes.
