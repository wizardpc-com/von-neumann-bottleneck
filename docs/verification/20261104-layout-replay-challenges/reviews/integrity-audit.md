# Round 6 integrity audit — portable scheduling challenges

Owner: `/root/review_records_final`. Read-only design audit; **no protocol, model,
schema or product decision has been implemented or approved by this report**.
No engine, Git, network or player-profile operation was performed.

## Recommendation for root's scope decision

The smallest coherent next playable increment is an **offline, replayable target
over one of the four existing workloads**, carrying its own immutable goal and
target recipe. A player can share a measured recipe, inspect another code, accept
its target, and improve the current draft under those exact response/copy limits.
This can preserve `layout-schedule-experiment-1`, all existing conditions,
notebook version1, formal60 progress and `VNB4C1` unchanged.

A structure-varying workload is a different scope. The pure model already accepts
bounded structural variation, but Session, Workspace, NotebookStore and the UI
currently identify editable state by one of four fixed workload IDs. Replacing
the data behind an existing ID is not an isolated codec change. It needs explicit
condition-scoped state and persistence design before implementation.

This is a choice between a smaller social/challenge loop and a broader strategy
extension, not a claim that sharing alone adds new simulation strategies. Root's
strategy and play-loop audits should decide which benefit is needed now.

## Current source boundaries

| Boundary | Verified current source | Consequence |
| --- | --- | --- |
| Formal protocol | `src/layout_chapter/layout_challenge_code.gd:6-9,30-72` | `VNB4C1` is for six formal tasks, their all-case conditions and cycles/traffic/space. Do not overload its prefix or reinterpret its `design`/`objective`. |
| Formal import flow | `layout_chapter.gd:808-844,918-935` | Export remeasures recipe; preview is separate from confirmation; confirmation checks the actual code again. Active target objective is independent of table sorting. These are suitable behavior patterns. |
| Formal persisted target | `layout_challenge_store.gd:85-106` | Supported stale code is retained byte-for-byte and becomes inactive; it is not converted into a current score. Keep the same distinction between decode and live inspection. |
| Experimental condition | `experiments/layout_strategy/model.gd:189-200` | Condition hashes full normalized task, model, memory geometry/costs and policies. A task ID alone is insufficient for comparable results. |
| Plan identity | `model.gd:203-209` | No-copy identity omits dormant copy fields/layout. Notebook editor state intentionally retains them; challenge execution identity need not distinguish those dormant choices. |
| Goal identity | `goals.gd:11-25,27-66` | Goal is exact objective plus inclusive Q1/copy caps; `-1` and `0` differ. `rule_id` already binds condition plus goal semantics version1. |
| Session state | `session.gd:7-14,22-23,76-101,120-139` | Four ID-keyed drafts/goals/histories. Replay records genuine evidence without editing draft/Undo. No arbitrary task object is retained by Session. |
| Kept recipes | `workspace.gd:90-108,120-151` | Keep remeasures selected input, cache is bound to recipes plus full condition, inspect performs fresh replay. These paths can supply target candidates. |
| Notebook schema | `notebook_store.gd:8-10,114-166` | Exact version1 keys and fixed full task equality. Extra target fields or different task contents would be rejected; a stale state protects the whole file. |
| Save isolation | `notebook_store.gd:24-82,219-245` | Digest checks, dedicated lease namespace, unique temp validation and atomic replacement are already established. Proposed state remains separate from committed input. |

No new present production defect is established by this audit. The items below
are design and integration requirements for a proposed extension.

## Minimal fixed-workload transport contract

Suggested schema, pending root's approval:

```text
new experiment-specific prefix + canonical JSON
{
  v: 1,
  task: one of the four current workload IDs,
  model: "layout-schedule-experiment-1",
  condition: current Model.condition_id(Model.scenario(task)),
  goal: {objective: "cycles"|"traffic", first_limit: -1|0..1000000,
         copy_limit: -1|0..1000000},
  plan: strict normalized execution recipe
}
```

No claimed metrics, Trace, success flags, author identity, timestamp, paths,
URLs, random seed or executable data are needed. The exact prefix remains a root
decision and must not collide with `VNB4C1`.

Use the formal codec's bounded two-stage pattern:

1. **Decode**: reject input over a small UTF-8 byte ceiling before parsing
   (4096 bytes is sufficient for this bounded task reference/goal/four-field
   recipe shape; verify the actual maximal encoder fixture). Require exact
   envelope and nested keys, finite bounded integral numbers, canonical
   serialization, valid recipe partition and valid goal. Reject duplicates,
   unknown nesting, noncanonical alternate numbers and trailing content. Preserve
   supported stale identities as inspectable input, not live results.
2. **Inspect**: require exact current model and full condition; validate the plan
   against that actual task; run `Model.evaluate`; require complete correct output
   and eligibility under the transported goal. The measured result is the target.
   A zero-cycle allocation failure, Q1 `-1`, or an over-cap recipe cannot become a
   target.
3. **Export**: perform the same evaluation and goal-eligibility check from the
   selected recipe. Never export copied Tree row numbers as proof.
4. **Confirm**: re-inspect the actual current code and current workload context;
   do not trust a previous preview or a previously selected row.

The strict serialization form should be documented, so manually prettifying JSON
does not create a confusing “same code but rejected” support case. Ordinary
leading/trailing clipboard whitespace can be stripped after the byte bound, as
the formal codec already does.

For no-copy recipes, choose one explicit canonical transport policy. Recommended:
replace dormant copy fields/layout with starter defaults while retaining
query-group and record-tile settings. Reconstruct the full normalized plan before
evaluation. Verify unchanged metrics/outputs/complete Trace across every dormant
variant in the tests. Do not erase dormant fields from the notebook itself, and
do not sort field/group arrays whose order may affect execution.

Use **condition + Goals.rule_id + execution plan identity** to identify the
target/rule combination. A changed cap or chosen objective is a different
challenge even if the target plan and resulting numbers are identical. If goal
comparison semantics later change, update the challenge/goal contract version;
do not silently reinterpret existing codes.

## Attempt, comparison and interaction integrity

- Keep an accepted challenge's goal immutable. Editing Notebook goal controls or
  changing a table sort must not silently make the challenge easier, change its
  objective, or alter the code retried after a save failure. Challenge status must
  show its own caps/objective. A separate explicit action may copy its goal into
  the player's Notebook filters; accepting a preview must not do this implicitly.
- Import/preview must not change draft, Undo/Redo, selected evidence, kept plans,
  Notebook goal, current workload or any completion state. Confirmation sets the
  target only. For another workload, identify it and require an explicit workload
  switch/acceptance; do not use a stale modal callback to write into the new task.
- Apply the target recipe through the existing explicit restore/edit path, with
  one Undo. It should not be a side effect of “Accept target.”
- Judge only a complete actual measurement under the challenge's full condition
  and its own goal. Preserve all four real metrics, then compare exactly the one
  chosen objective. Recommended outcomes: ineligible / improving / tied / beaten
  using positive / zero / negative metric delta; equality is not a strict beat.
  Merely importing the target is not an achievement.
- A valid target is not guaranteed to be strictly improvable. Present “tied” and
  never claim global optimality or guaranteed solvability. Handpicked starter
  targets can be verified beatable without imposing that claim on arbitrary
  player-authored codes.
- Cache a target measurement only by canonical code plus the current full
  condition/model. Goal edits that are unrelated to the challenge need not rerun
  it. Avoid re-evaluating target recipes on every frame or text keystroke; explicit
  Inspect/Confirm and target changes are adequate boundaries.

Two already measured acceptance cases can demonstrate an actual playable loop:

| Fixed challenge | Measured target | Known beating recipe under the same goal |
| --- | --- | --- |
| `scan_batch`, cycles, Q1≤350, copy≤0 | Starter: Q1 307 / total 2456 / RAM 2176 / copy0 | group2/tile1/no-copy: 339 / 1368 / 1088 / 0 |
| `scan_serial`, cycles, Q1≤600, copy≤80 | Starter: 307 / 2456 / 2176 / 0 | retained temperature: 557 / 1362 / 980 / 80 |

These are prior actual measurements in
`docs/verification/20261104-layout-notebook/strategy/README.md:37-46`, not a new
run by this reviewer and not global optimum claims. Their identical starter
numbers make them useful negative tests: batch and serial must still reject
cross-condition comparison. Fresh root verification should bind the new feature.

## Persistence and rollback options

**Smallest first slice:** session-only accepted targets plus portable codes.
There is no new persistent format; the UI must explicitly state the lifetime.
The existing Notebook can keep recipes/goals, but this must not be represented as
persisting the accepted target identity.

**If retained targets are included now:** prefer a separate experimental sidecar
over adding optional fields to notebook version1. Suggested bound is one target
per current workload, four total, ≤32KiB, containing canonical code and an optional
bounded local display title only. Exact filename/schema remain root decisions.

Requirements for that sidecar:

- Separate from ordinary saves, formal challenge storage and notebook version1.
  Use the same stable experiment profile established before autoloads.
- Validate the entire file before adoption; preserve unknown/corrupt/oversized/
  invalid-UTF8 bytes read-only. A structurally supported old model/condition code
  may remain retained but inactive. Do not silently drop invalid entries then
  overwrite the original.
- Reuse the existing proven disk/lease ordering pattern without changing the
  shared lease or extracting a general storage framework for this one feature.
  Use a dedicated lock directory, not the candidate profile's lease namespace.
  Protect external changes, retain proposals on failure, and make exact-code
  retry independent of current Notebook sorting or goal edits.
- A sidecar is **not atomic with the Notebook**. An explicit “Retain target”
  action and its own saved/temporary/protected status avoid implying that “Save
  workspace” committed two files atomically. Keep sidecar failure separate from
  an otherwise successfully saved notebook; avoid a combined success label.
- Clear-target must preserve draft, goal, recipe names, Undo and measurements.
  Define whether failure retains a pending removal or the old active target and
  label it accurately; do not mix the Notebook proposal model with the formal
  store's committed-only return without an explicit controller decision.

Rollback removes the experiment codec/UI/optional sidecar reader while retaining
the sidecar bytes. Old code continues to use the same notebook version1 and ignores
the new file. Do not delete player targets or migrate formal saves as rollback.

## Why structure-varying transport is a separate increment

The pure model already bounds up to64 records,16 jobs,4096 query values,4096 output
values,4096 scratch bytes and a32768-event worst-case estimate
(`model.gd:8-12,224-263`). That is a useful computational ceiling, **not** an
acceptance of arbitrary workload sharing in the current app.

The current mismatches that a structural extension would need to resolve:

1. `Model._task_error` accepts different record/query/release contents under one
   of four IDs, while `Session.task()` reconstructs the fixed catalog task for
   that ID. Passing a custom task only during preview then recording/attempting
   through Session would evaluate a different condition.
2. Session drafts/goals/history, Workspace kept lists and UI selection are keyed
   by task ID. Two custom structures with the same ID would overwrite or mix
   state unless the full condition becomes the bounded context key.
3. NotebookStore explicitly compares every saved task to `Model.scenario(id)`;
   changing any existing fixed scenario makes the complete existing notebook
   stale/read-only. Do not replace the four current definitions in place.
4. Public labels assume four workloads, and task-specific query/record bounds
   drive editor controls. The imported task must be displayed fully and keep its
   own editable draft, not masquerade as the fixed17-record scenario.
5. A seed alone is insufficient without frozen generator version/algorithm.
   Transport a normalized full public task or a versioned finite catalog entry;
   condition identity must still bind actual records, ordered queries, repeats,
   indices, admission and scratch. Preserve repeated indices/order; they are
   semantic, not duplicate cleanup.
6. The larger byte/operation envelope needs worst-case import timing and repeated
   replay tests. Keep parsing cheap and rejection before simulation; consider a
   narrower challenge bound than the model maximum until actual timings exist.

A finite set of independently identified, measured structural scenarios is safer
than immediately accepting arbitrary generated tasks. If root selects that route,
first design a bounded condition-scoped experimental session/notebook or a separate
challenge workspace with a migration/rollback plan. Existing model semantics can
remain unchanged if the only change is new task data, but existing conditions and
notebook inputs must still retain their exact prior meaning.

## Focused acceptance gates for a portable fixed-workload slice

- Roundtrip all four tasks and both objectives; actual output, complete canonical
  Trace and metric equality; normalized no-copy dormant variants; profile restart.
- Strict UTF-8 byte size, malformed/deep nesting, duplicate keys, missing/unknown
  fields, integral/fractional/NaN/overflow forms, recipe bounds and wrong task.
- Current versus old model/condition, every goal component in identity, no mixing
  equal-looking batch/serial numbers, zero caps versus no cap, cap equality,
  failed allocation, incomplete responses, real tie and strict improvement.
- Preview no mutation; edited-code confirmation; workload switch while preview is
  open; sorting/filter changes cannot change target goal or retry code; restore
  preserves one-step Undo; F8/F10/locale and clipboard-focus behavior.
- If sidecar is chosen: whole-file rejection, original bytes preserved, actual
  open/replace failure and exact retry, external change, competing writers,
  stopped-owner recovery, separate-process reopen, and explicit independence
  from the Notebook/formal saves. Never accept persisted scores.
- Preserve existing notebook1 reads/writes and the frozen formal model/Trace
  compatibility suite. UI proof and scripted GPU checks remain distinct from
  native/export/cross-platform acceptance.

Local recomputation verifies what the current local model computes. A portable
recipe/hash is not an authenticated person, remote rank or anti-cheat proof.
Any future online verified board would need independently controlled recomputation
and a separately designed trust/service boundary; no network is needed now.
