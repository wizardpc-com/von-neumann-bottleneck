# Round8 computation and strategy explanation audit

Read-only audit of clean task-branch base `2893e3a93d4a1995bbd9701134089e7977b8c0cc`.
No source/test/documentation edits, Godot/probe execution, Git mutation or player
data access. Numbers below are re-read from archived measured evidence; they are
not new simulation observations. This report addresses
`.godot/collaboration/round8-audit.md`, `/root/audit_scores` scope.

## Recommendation

Prioritize one bounded capability: **explain the selected measured run against
the explicitly chosen same-condition baseline using existing Trace evidence**.
Show preparation/query/output cost and real RAM traffic, then read cache counts
and actual request admission/completion. Let a player follow a summary to the
original events. Keep the existing explicit run, baseline and undoable restore
loop; do not add an automatic sweep or recommended-best plan in this increment.

This can support the concrete question “I reduced query work; why is my total
worse?” without a rule change, arbitrary penalty, invented causal attribution,
weighted score or persistent-format change. It does not itself prove greater
fun or comprehension; it makes existing strategic choices inspectable and gives
native playtesting a specific learning outcome to assess.

## What is missing now

1. `experiments/layout_strategy/session.gd:163` and `lab.gd:778` compare only Q1,
   total cycles, RAM bytes and allocated copy bytes. The correct four-axis
   tradeoff is visible, but its two opposing costs are not. The real evidence is
   already retained by `session.gd:76`: full events, metrics, logical outputs,
   expected values and condition/Trace IDs. `rows()` deliberately drops events,
   while `selected_entry()` returns a detached full entry.
2. `lab.gd:1060` exposes requests/responses or a long event table, and
   `lab.gd:1087` shows raw details. That is useful forensic access but requires
   the player to manually count events and reconcile phases. The evidence tab
   currently has no aggregate phase or per-request elapsed comparison.
3. The `内存搬运 / Memory transfers` filter (`lab.gd:331`, `1060`) includes
   `evict`, `allocate` and `release` alongside `fill`/`write`. Its `B` column
   reports each event's `details.bytes`. Those bytes have different meanings
   and cannot be added as RAM traffic. This is a concrete semantic presentation
   risk, not evidence that the simulator's current traffic metric is wrong.
   Within the same change, use “memory events” and distinguish RAM transfer
   bytes from allocation/internal-movement details.

The source supports these findings. No human misunderstanding or task failure
was observed in this audit.

## Exact evidence available and safe derivations

`src/layout_chapter/layout_simulator.gd:30` already records total, prepare,
query and output cycles; RAM reads/writes; phase reads/writes; requests, fills,
hits, evictions and peak allocated copy bytes. `_event()` at line239 stores
phase, duration, address, record, field and bytes in each event. This is sufficient
for a small pure reducer, with original event indexes retained for navigation.

| Displayed quantity | Derive from measured events | Required interpretation |
| --- | --- | --- |
| Phase cycles | Sum `duration` by `details.stage` | Prepare + query + output must equal total |
| RAM reads | Sum `bytes` on `fill` | Real line fills, 16B each in this model |
| RAM writes | Sum `bytes` on `write` | Actual 4B write-through stores |
| Read lookups | Count `lookup` | Correct denominator for cache read hit/miss counts |
| Read misses | Count `fill` | One miss creates one fill in the present synchronous model |
| Read hits | Lookups minus fills | Prefer `hits / lookups`; zero lookups means unavailable, not 100% |
| Copied payload | Sum preparation `write` bytes | Distinct from allocated/padded copy space |
| Copy allocation | Existing `peak_extra_bytes`, reconciled with allocate events | This is bounded copy space, not all program memory |
| Request admission/completion | `request_admitted` / `response` events and corresponding arrays | Keep public job order and exact event indexes |
| Request elapsed | Completion minus admission | Includes shared preparation and interleaving after admission |

Do not compute a hit rate as `hits / requests`: `_write()` increments `requests`
as well as `_read()` (`layout_simulator.gd:203–237`). For complete runs,
`requests == lookup_count + write_count`.

Do not count `read` cache-to-compute bytes, clean `evict` bytes, or
`allocate`/`release` sizes as RAM traffic. No dirty writeback exists here.
Do not infer “useful bytes”, “wasted cache bytes”, or exclusive miss causes from
a fill alone; a filled line can serve several later accesses. A current job's
fill count is measured work during that job, not an isolated counterfactual
cost of that job.

There is a useful exact reconciliation for a complete run. Let Q be consumed
query values, O emitted values, M actual copied words and F actual fills:

```
total cycles = 2Q + O + 10M + 16F
RAM bytes    = 4M + 16F
```

For the same complete condition Q/O are invariant, so differences are
`10ΔM + 16ΔF` cycles and `4ΔM + 16ΔF` RAM bytes. This is exact accounting for
this simplified model, not a real-hardware formula or a claim that independent
causal effects can be assigned to each plan field. Prefer the phase table for
players; this equation can remain an explanatory detail/test invariant.

## A measured example the feature must explain

Source: `docs/verification/20261105-structural-layout-workloads/strategy/results.json`,
`scan_pair_serial` candidates; exact canonical/basic-plan equivalents are checked
by `tests/test_layout_strategy_structures.gd:85`.

| Quantity | Direct source | Retain temperature | Selected minus direct |
| --- | ---: | ---: | ---: |
| Preparation cycles | 0 | 442 | +442 |
| Query cycles | 612 | 228 | -384 |
| Output cycles | 2 | 2 | 0 |
| Total cycles | 614 | 672 | +58 |
| Preparation RAM read/write B | 0 / 0 | 272 / 68 | +340 total |
| Query RAM read/write B | 544 / 0 | 160 / 0 | -384 total |
| Total RAM B | 544 | 500 | -44 |
| Read lookups | 34 | 51 | +17 |
| Fills | 34 | 27 | -7 |
| Read hits | 0 | 24 | +24 |
| Allocated copy B | 0 | 80 | +80 |
| Q1 completion | 307 | 557 | +250 |
| Q2 admission → completion | 307 → 614 | 557 → 672 | Elapsed 307 → 115 |

The copy performs 17 preparation reads and 17 writes. Its preparation has
17 fills; query has 10 fills and 24 hits across34 read lookups. The global
`requests` metric is68, which is not the global read denominator51.
Its68B payload occupies80B including allocation padding.

An honest concise explanation is: “Preparation cost442 cycles; query work
saved384 cycles, leaving58 more total cycles. Preparation transferred340B;
queries transferred384B less, saving44B overall.” Q1 includes preparation;
later requests reuse its result. The equation independently checks
`10×17 − 16×7 = 58` and `4×17 − 16×7 = −44`.

Another current example is `split_fields_serial`, copy fields `[0,3]`:
record-major791/2044/1560/144 versus field-major727/1516/1032/144
(Q1/total/RAM/allocated copy). Both spend612 preparation cycles and408B
preparation traffic; query changes1424→896 cycles and1152→624B, a528 reduction.
The measured effective-map representatives in the finite probe use different
normalized recipe encodings; do not present the probe's representative encoding
as the exact UI selection. The structural test explicitly covers the two basic
UI layouts. This supports an inspectable physical-layout effect, not the claim
that field-major is always better: the original mixed workload has different
access structure.

## Request timing contract

`model.gd:57–138` already gives each expanded logical request a stable job ID,
fixed output span, admission and response. The actual output events cost one
cycle per output; response follows the final emitted value.

- `first_request_cycles` means public job0 completion. It is not the minimum
  response cycle. A later sparse job can finish earlier in batch mode.
- Batch requests are admitted at0. Serial request i is admitted exactly after
  response i−1. Preparation happens after initial admission and before queries.
- Show jobs in public request order, with admission, completion and elapsed.
  A timeline may retain chronological event order as a separate view.
  Same-cycle zero-duration admission/response events retain original index order.
- Never divide shared preparation evenly among jobs or call elapsed minus
  job-attributed event duration “cache stalls”. Elapsed is a scheduling outcome.
- Unknown completion/admission remains `—`/unknown (internally−1), not zero.
  Failed runs may expose their explicitly partial evidence, but cannot receive
  an improvement verdict or be selected as a valid comparison baseline.

## Bounded implementation shape

Keep one pure explanation module under `experiments/layout_strategy/`, taking a
detached current session entry and expected current condition, returning a
detached summary. A second pure comparison function can subtract summaries only
when both are complete, correct and have the same current condition. Expose a
detached baseline entry accessor on Session; do not reach through mutable
private state or derive the baseline from compact rows that lack events.

The reducer can be linear in already-bounded events (max32768) and jobs(max16).
Use integer counts/totals and original indexes, no automatic model replays.
Cache only by current entry/Trace identity if UI refresh cost needs it; do not
copy full events into every derived row or scan both full traces per rendered
frame. On metric/event inconsistency, show evidence unavailable with a reason,
not a plausible-looking computed comparison. This validation supports local
presentation; it is not remote authenticity or anti-cheat.

Preserve all existing model/cost constants, task/plan/condition IDs, canonical
Trace, eligibility, goal limits, challenge codes, Notebook v1/v2 and target
sidecars. Summary fields must not be inserted into authoritative metrics or
event details: `SimulationTrace` hashes both. `SimulationEvent.to_dictionary()`
strips only presentation `pass_index`/`work_group_index`; experimental job/tile/
admission/response details are signed. `LayoutRun.canonical_signature()` includes
ordered outputs and IDs, but does not directly include source/scratch maps.
Do not promote auxiliary maps into trusted remote evidence for an address
classification feature. This increment does not require address-map inference.

Inspection, changing an explanation filter and jumping to its event indexes
must not add a run, edit the draft, change Undo/Redo, goals, baseline, active
challenge, Notebook state, or official campaign state.

## Player-chosen experiments versus automatic solving

A controlled player choice can deepen exploration: compare two measured plans,
see which effective settings changed, articulate a hypothesis, explicitly run
the selected alternative and read the actual tradeoff. Existing baseline,
restore and Undo provide most of the operation. A read-only changed-settings
display or one explicit “restore this baseline” path is enough; retain the
existing one-step Undo contract.

Do not automatically scan values, choose fields/layouts or rank unseen
alternatives in this increment. Current finite tasks are small enough that this
can replace the puzzle and fill history, rather than help the player reason.
The existing probe grids are development evidence, not player-facing oracles.
An auto-search option would need an explicit product decision and separate
identity/history behavior.

Make effective versus dormant differences truthful. Under `copy_mode=none`,
copy fields and recipe are excluded from `Model.plan_id()` (`model.gd:215`).
They may remain edited in the draft but cannot explain a measured change in
that source-only run. One recipe field can alter many physical addresses;
“one serialized field changed” is not a proof that only one physical factor
changed. Serial full scans often make tile size ineffective, but sparse or
nonmonotone queries can change access order; do not generalize “tile never
matters”. Equal observed totals do not prove a setting irrelevant elsewhere.

## Verification to require if approved

No new strategy probe is necessary to choose this priority. Existing real
measurements and model tests already exercise its core questions. Suggested
bounded verification:

1. Pure reducer tests on actual Model/Session outputs for the pair example
   above and the record/field pair. Reconcile every phase total, RAM read/write,
   lookups/fills/hits and deltas. Assert nontraffic event bytes are excluded
   and the copy denominator is51 reads rather than68 requests.
2. Reuse the independent accounting/causality oracle in
   `tests/test_layout_strategy_model.gd:316`; it already checks unchanged costs,
   ordered outputs, exact event clock, job tags and actual response completion.
   Add the absent phase-specific read-count and transfer classification checks
   to the new reducer suite, not a second simulator implementation.
3. Cover existing sparse/out-of-order batch response, duplicate/nonmonotone
   indices, record tails and failed allocation fixtures. Q1 stays job0;
   elapsed uses actual admission; incomplete timing is never silently zero.
   Same-cycle original event ordering survives filtering/jumps.
4. Comparison refusal for missing baseline, different/current-old condition,
   incomplete run and inconsistent evidence. A failed run remains inspectable
   without “better”/ranking authority. Empty/zero-lookup displays are defined.
5. Repeated and JSON-parsed detached entries produce identical summaries.
   Mutating a returned summary cannot mutate entries. Summary inspection does
   not call Model.evaluate or append session runs.
6. UI assertions cover selection/baseline identification, changed-settings
   direction, event-source navigation, effective inactive fields, keyboard
   access, language reload and minimum size. Prove draft/Undo/Redo/goal/
   challenge/Notebook state unchanged by inspection. Native acceptance should
   actually attempt “why is this slower despite fewer query misses?”; scripted
   UI checks alone do not establish understanding.
7. Existing session/model/structural/goals checks and relevant UI suites are
   regression gates. If shared model/session integration is touched, retain
   the frozen56 observations/112 code outcomes and formal141designs/282cases
   full-Trace parity checks. Do not claim a whole-repository or cross-platform
   pass from this focused set.

The current Round7 strategy receipt reports442 candidates plus10 repeated/JSON
measurements,7100 checks and0 failures. Its sampled two/three frontier classes
are useful evidence of actual choice, not exhaustive optimality. This audit
performed source/test inspection and selective archived JSON arithmetic only;
root owns any new execution and the final playable acceptance.
