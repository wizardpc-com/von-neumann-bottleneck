# Round 5 strategic depth and workload audit

Owner: `/root/audit_scores`. Read-only production audit at
`3182a469fc3c222854f6976d8f251b6489f7030c`; the task branch was clean when inspected,
and local main remained `b65a0bd`. No Godot run, source edit or Git mutation.
The only new repository-local artifact is the permitted ignored probe described
below. Its ownership is released to root. This report is ready for design freeze;
pending probe results do not block choosing the next bounded increment.

**Recommendation: implement a persistent named experiment notebook plus an
explicit Q1/copy-space envelope over remeasured plans.** This addresses a concrete
loss of player work, makes the already measured tradeoffs usable repeatedly, and
needs no change to the memory model or official achievements. Keep workload
generation and a second share-code protocol outside the first increment unless
they solve a demonstrated need. A personal frontier is a useful view of the
notebook, not a substitute for retaining named work and not a global solver.

The existing four workloads are enough to verify this loop, but not enough to
claim broad long-term strategic depth. A later small, authored variation in
access pattern is more credible than randomizing record values.

## What remains weak, and what is already handled correctly

1. **Record values do not affect performance in this model.** The executor
   consumes declared indices/fields without value-dependent branches
   (`model.gd:108-120`); reads use addresses, LRU state and fixed costs, and
   computation always costs one cycle (`layout_simulator.gd:184-224`).
   Changing a data salt changes output and full condition identity but cannot by
   itself create a different optimization problem. This is a source-derived
   conclusion; the supplied probe also checks it with actual Model executions.
   Do not market random numeric data alone as new strategic content.
2. **Several controls are intentionally ineffective in current contexts.**
   Current fixed queries use monotone indices; with one job per group, changing
   record tile does not reorder them. The UI correctly disables that control.
   Copy layout is correctly disabled for a single copied field, and inactive
   copy choices are excluded from effective source-only `plan_id`
   (`lab.gd:317-342`, `model.gd:203-209`). Preserve these behaviors.
   If arbitrary nonmonotone indices become public, group-one tiling can change
   execution order; the current disabled-control assumption must then be revisited.
3. **All-ready dense scans strongly reward small source tiles.** The accepted
   ready-scan frontier contains source-only plans throughout. Retained copying
   pays real preparation and storage; it should not receive a fabricated bonus
   merely to make its button useful. Serial admission is already the meaningful
   condition where copying gains a different role.
4. **Three/four-field copies cannot fit any shipped workload.** With17 records,
   the one-group UI layouts require208/272B respectively, over the160B limit.
   These are structurally legal plans with real allocation failure, not valid
   low-score competitors. The existing failure remains useful evidence, but
   adding more such settings is not added strategy.
5. **Four metrics are not four independent levers.** At fixed condition and
   copied-word count, `cycles - RAM_bytes = 2Q + O + 6M` is constant. Total-cycle
   and traffic ordering are then equivalent; crossing copy counts can break
   that equivalence. Q1 and copy space expose actual competing dimensions.
   Keep independent numbers, but do not claim that switching the sort column
   necessarily changes the best available plan.
6. **The model compares scheduling and physical representation, not all
   possible algorithms.** Repeated immutable sums have equal answers but are
   recomputed as separate jobs. Result memoization is not a legal plan operation.
   This is a scope limitation, not a reason to silently change the model or
   promise real-world algorithmic optimality.
7. **Useful discoveries are disposable today.** Session keeps24 runs and64
   edits, and protects only the selected run and one comparison baseline while
   trimming old runs (`session.gd:5-6,60-87`). An earlier nonbaseline frontier
   point can be lost after more runs; all work is lost on exit. Fixing this has
   a clearer player benefit than generating more transient workloads.

## The595 sample does not cover the legal UI space

The accepted grid samples:

- request groups1,2,4,8 for scan and1,2,4,8,9 for mixed;
- tiles1,2,4,8,17;
- source only, plus `[0]`, `[0,3]`, `[1,2]` in the two basic copy layouts.

The UI permits every integer group through the actual job count, every tile
length1..17 while grouping is active, and every nonempty field subset
(`lab.gd:215-241,317-341`). Missing group3 is particularly material: simple cost
reasoning predicts an intermediate ready-scan operating point. That prediction
must be measured before it becomes a documented score or best-plan claim.

Successful UI copy configurations include four single-field subsets and six
two-field subsets in both basic layouts. Single-field layouts have equal
physical mapping, so a representative physical set is source-only +4 +12 =17.
Larger subsets are legal edits but fail the existing scratch ceiling. The
current Model additionally accepts grouped/reordered recipes and block sizes
that the normal editor does not author; do not confuse the pure API domain with
the reachable UI domain.

Checkbox click order is preserved in `copy_fields`; `_prepare_copy` consumes
that order (`layout_simulator.gd:159-165`). It does not change the destination
mapping for these UI recipes, and fixed-row source reads make many such orders
metric-equivalent, but event order/identity can differ. Do not silently sort
stored plans or redefine existing plan identity to deduplicate the leaderboard.
Group equal metric vectors for presentation while retaining original recipes.

## Evaluate the three candidate directions

| Direction | Concrete benefit | Main limitation | Recommendation |
| --- | --- | --- | --- |
| Generated workloads | Can change amortization and locality if it changes query access structure. | Numeric randomization is inert; unconstrained generation can add many equivalent or trivial tasks and requires versioned reconstruction/UI. | Defer a general generator. First measure a few authored structural contrasts. |
| Retained personal frontier | Preserves discoveries and makes tradeoffs inspectable across sessions. | Does not create new physical strategies; automatic dominance pruning can destroy named work. | Make named recipes durable; show the frontier of remeasured available recipes, with explicit capacity/replacement. |
| Q1/copy-space envelope with total/traffic objective | Turns real operating tradeoffs into a concrete search goal under one fixed workload. | A budget is a public requirement, not a new physical cost. Some envelopes are infeasible; others yield no better known plan. | Add with the notebook. Filter complete correct measured runs, state empty/tied cases honestly, and avoid an invented aggregate score. |

The coherent loop is: run → name/save → change Q1/space requirements → see which
remeasured saved plans qualify → inspect a measured baseline → restore/edit →
run → retain a better or different feasible plan → reopen the same notebook.
Changing the envelope must not modify the plan, rerun all simulation on each
keystroke, grant campaign completion or overwrite a prior notebook entry.

For the first version, keep the four standard conditions and a small explicit
number of named plans per condition. The integrity audit's proposal of8 per
condition is reasonable. The temporary24-run history remains separate. A named
entry is not automatically discarded because another plan dominates it.
If eight slots fill, require an explicit replacement/delete action rather than
silently keeping only the fastest or newest item.

## A minimal honest envelope contract

Use the current simulation unchanged. Let the selected condition be exactly
`Model.condition_id(task)`. A proposed versioned envelope has:

```text
version: 1
condition: complete current Model.condition_id(task)
objective: total_cycles | ram_bytes
q1_limit: null | nonnegative integer
copy_limit: null | integer in [0, task.scratch_limit]
```

`null` means unrestricted. In particular, **0B means no copy space**, not
“unlimited”; zero Q1 is an allowed infeasible request or should be rejected with
an explicit minimum, never silently reinterpreted. The product must choose one.
Keep a modest declared integer maximum for editable cycle limits; the fixed
current workloads do not need unbounded numbers. Recipe/model validation remains
the authority for all execution bounds.

A row qualifies only if it is a complete correct current-model run under the
same full condition, with known nonnegative Q1 and space, and within each active
inclusive limit. Then minimize the chosen objective. Equality is a tie; rank
or display ties consistently. A nonqualifying/failed row can remain inspectable
but cannot win through zero cycles or `-1` response. If no saved result qualifies,
say “no measured saved plan meets these requirements,” not “impossible.”

Do not assemble componentwise minima from different runs into a fictional
reference. Taking one run's fastest Q1, another's lowest cycles and a third's
space can create an unattainable target. A feasible witness is a single actual
run. It is useful to offer “use this run's Q1/space limits,” but this does not
guarantee that the same run has an available strict improvement.

Do not make strict four-axis domination the sole win condition. A correctly
measured frontier target may have no improvement in the sample. Matching a
target, beating an objective within an envelope, and trading one metric for
another are distinct outcomes and should remain distinct in the player flow.

Current accepted examples already support envelope exploration, **within the
accepted sample only**:

- Ready scan, no-copy budget, Q1≤307: direct307/2456/2176/0 is feasible.
- Raising Q1 to339 admits the measured group2 point339/1368/1088/0.
- Q1≤403 admits group4's403/824/544/0.
- Q1≤531 admits group8's531/552/272/0.
- Serial scan permits the557/1362/980/80 retained-temperature point only when
  both its response and80B copy requirements fit; direct307/2456/2176/0 remains
  the earlier-response, zero-copy option.

These values are measured operation points, not invented scores. Editable
requirements are legitimate player-defined goals, but they do not create the
underlying tradeoffs. The expanded probe may reveal additional feasible points,
so the UI should say best among the remeasured notebook entries.

## Identity, persistence and determinism boundary

Retain only input recipes, names and explicitly versioned requirements as
authoritative persistent data. Stored scores, output flags or Trace hashes may
be diagnostics, never the basis for ranking after load; actually replay recipes.
The full task is currently exactly `id/records/queries/release/scratch_limit`;
queries bind kind, ordered fields, repeat and ordered indices
(`model.gd:224-264,295-314`). Condition identity already adds model and memory
constants/policies (`model.gd:189-200`), and should remain unchanged.

An envelope identity should separately bind the condition, envelope version,
objective and effective limits. Two goals over the same simulation condition
must not become one challenge/ranking bucket. Names, locale, wall time and the
current temporary run number are not part of performance identity.

If only the four fixed conditions are delivered now, there is no need to expand
the scenario API this round. Still persist enough model/condition identity to
detect future preset drift. If later workloads vary, storing only `task_id` is
insufficient: Session currently keys by that ID and reconstructs the fixed task
on access (`session.gd:10-27`). It must instead retain a complete task snapshot
and isolate state by full condition before exposing variants.

For future generated work, materialize the complete bounded task in storage.
If a seed is also retained, bind its generator version and fixed algorithm with
golden expansion tests; do not let a newer generator silently reconstruct a
different task. Preserve semantic field/index order and duplicates. Existing
limits are64 records,8 query specifications,16 jobs,4096 consumed/output values
and a conservative32768-event bound. Any newly exposed workload UI needs its
own narrower useful domain rather than blindly exposing every legal nested input.

The notebook needs a stable **isolated experiment profile** across launches;
the current fresh-per-launch profile otherwise makes persistence invisible.
Adopt the independent integrity audit's protected-file, failure/retry and
concurrent-writer constraints. Keep official stores/`VNB4C1` and campaign results
out of this feature. No new sharing protocol or online service is necessary for
the initial notebook/envelope loop.

## Small useful workload contrasts, proposed for later measurement

All three can use the current production Model with17 records and160B scratch,
so none requires new timing penalties:

1. Sixteen serial sums of field0 at clustered indices `[1,2,3]`.
2. The same sixteen serial sums at dispersed indices `[1,8,15]`.
3. Four complete field0 sums followed by four complete field3 sums, serial.

The first pair changes address locality while holding value count and job count
fixed. A retained one-field projection may keep clustered requests in fewer
cache lines while dispersed requests still thrash; this is a hypothesis pending
the probe, not an accepted score. The third contrasts separate hot-field scans
with the existing simultaneous hot-pair reads, potentially making field-major
copy useful where record-major helps the joint access pattern.

If confirmed, one clear contrast would be more useful initial extra content
than a general random generator or exposing several independent parameter
sliders. If the notebook/envelope increment is sufficient, these remain future
evidence and should not delay its implementation.

## Prepared decisive probe — executed by root

File: `.godot/collaboration/round5-strategy-probe.gd`

SHA256: `89be3b6cd93d0aa246a1d02177bb19c39f81e107da75a108d266125c338e6c55`

- 2046 candidate combinations:1995 in the current workload/UI expansion,
  including40 expected real space failures, plus51 combinations for the three
  unshipped serial contrasts.
- Source-only batch plans cover every legal group and tile1..17. Copied plans
  cover all one/two-field subsets, both effective basic layouts, all groups,
  and declared tiles1,2,3,4,8,17. Serial uses group1/tile17.
- 56 repeat/JSON executions and16 values-only comparisons requiring32 more
  model executions:2134 total evaluations.
- Checks complete outputs, accounting identities, actual output/write counts,
  copy bytes, response/admission events, public Q1, identity and deterministic
  Trace. Infeasible copies are explicitly excluded from the frontier.
- Uses only production `Model.evaluate()`, has the isolated-profile guard, and
  writes to `--probe-output=<path>` or the isolated `user://` default.
- Static count/whitespace inspection passed before ownership release. Root then
  ran the probe; `.godot/collaboration/round5-strategy-probe.log` reports PASS:
  2046 candidates,40 expected space failures,56 replays,16 value comparisons,
  34342.070ms. This agent read the complete log, but has not independently reviewed
  the full resulting JSON. This remains a declared finite sample, not an
  exhaustive proof over the API or all UI click histories.

The shipped frontier counts in this expanded sample are5/2/7/2, so the narrower
Round4 sample did omit operating points. The three new serial contrasts report
2/1/3 frontier classes respectively. Values-only variation checks passed. Specific
new frontier metrics should still be read from the complete JSON before being
quoted. Root has accepted the notebook/envelope increment; no workload generator
or model semantic change is required.

## Decisive acceptance for the recommended increment

- Preserve the four current tasks, official canonical Trace gate and model
  identities; notebook operations never enter official progression.
- Reopen a saved direct and a saved fused scan in a second real process under
  one experiment profile, replay and recover their exact metrics/condition/plan.
- Envelope limits at measured boundary and one below produce the correct
  included/excluded result;0B excludes all copied plans, and null removes the
  constraint. Changing objective cannot manufacture a new measurement.
- Failed allocation, unknown Q1, stale model/condition, corrupt input and wrong
  outputs never rank. Empty feasible sets remain an observation, not an
  infeasibility proof. Tied metric vectors do not claim multiple unique winners.
- Saving/renaming/restoring works without evicting another named plan; restore
  is one reversible edit, and browsing/ranking does not change the draft.
- Generated/changed task content, if admitted later, cannot share histories
  or goals merely because its base scenario ID matches.
- The visible scope says saved recipes survive, while temporary runs/undo and
  unsaved drafts follow their actual stated lifetime. Stable-profile restart
  and file-failure behavior are part of playable acceptance, not optional polish.
