# Retained scheduling notebook and constrained comparison — 2026-11-04

Owner: Codex root. Branch `codex/gameplay-systems-20261104`; base `3182a469`.
Status: implementation and staged runtime acceptance complete. Source/evidence
reviews are recorded with this milestone; Git delivery is tracked separately in
the local handoff and Git history.
User authorizes commit/push of significant verified task-branch updates only.

## Goal and evidence

Turn the independent scheduling experiment into a repeatable player loop: measure,
name and keep a recipe, choose response/copy limits, compare real total work or
traffic, continue improving, save the workspace and reopen it in another process.
Scores remain fresh calculations from recipes, never authoritative file contents.

The player-loop and integrity audits agree that retention and a stable launch
profile are the strongest missing links. Root's 1292-candidate envelope probe
found different feasible strategies as Q1 limits change: scan caps350/400/450/600
select sampled group2/3/4/8 plans with total1368/1096/824/552. Serial scan with
Q1<=600 and copy<=80 admits the real retained-temperature557/1362/980/80 tradeoff.
These are finite samples, not global best or fixed game scores.
The independent expanded production-model probe passed2046 candidates,40 expected
space failures,56 repeated/JSON runs and16 value-change comparisons. Shipped
frontier classes in that sample are5/2/7/2. Values-only variations changed outputs
and identities but not performance; randomizing values alone would add no strategy.

## Scope and non-goals

- Keep the four fixed workloads and current model/costs/Trace identities.
- Add a bounded experiment-only notebook: at most8 named plans per workload,
  four workloads,128KiB total. Store exact normalized drafts including dormant
  choices, names, full public task snapshots, model/condition identities, one goal
  per workload and the last selected workload. Do not store metrics or Trace.
- Goals are player filters: optional inclusive Q1 and copy-space caps, followed by
  minimum total cycles or RAM bytes. No weighted score, universal optimum,
  implicit campaign award or extra simulator cost.
- Save workspace explicitly. Keeping/removing a named plan also saves the complete
  proposed workspace. A failed write leaves that proposal in memory, clearly dirty;
  retry saves the currently displayed proposal. Undo, transient history and the
  comparison baseline remain process-only.
- New stable named runner profile is isolated before autoload initialization.
  Existing one-off QA launch remains available.
- No new workload generator, new share protocol, server deployment, ordinary-save
  migration, campaign promotion, release/export, or disputed Opus rollback.

## Contract and compatibility

`notebook_store.gd` is independent of GlobalSave/formal challenge storage.
Canonical snapshot:

```text
version:1, active:<scenario>,
states:{<scenario>:{
  model, condition, task:<full normalized fixed task>,
  draft:<full normalized plan>,
  goal:{objective:"cycles"|"traffic", first_limit:-1|0..1000000,
        copy_limit:-1|0..1000000},
  kept:[{name:<1..40 non-control Unicode characters>,plan:<full plan>}]
}}
```

The entire file is validated before accepting any state. Names are unique within
a workload; no silent replacement or eviction. Supported stale model/conditions
are protected read-only as a whole, preserving the raw file; this bounded UI does
not open arbitrary historical workloads. Unknown/corrupt/oversized/invalid UTF-8
files likewise remain untouched. Temporary exploration stays available.

Writes check the last observed disk digest, acquire an exclusive cooperative
writer lease, use a unique same-directory temporary file, flush and validate,
recheck the disk, then rename atomically. Only success updates committed state.
Reuse the existing candidate writer lease solely within the experiment profile;
never remove a live/unknown owner. Explicit recovery may reclaim a demonstrably
stopped owner using its existing platform checks. This is not a power-loss
durability or arbitrary external-writer synchronization guarantee.

The model remains `layout-schedule-experiment-1`. Goal identity binds the full
condition and normalized goal; it does not change simulation identity. Invalid,
incomplete, wrong-condition or over-limit entries cannot rank. Equal objective
values share rank; all four actual metrics remain visible. Rankings are explicitly
among recent runs or among kept plans, not all possible recipes.

Rollback removes the notebook UI/runner extension without deleting its sidecar.
Old code ignores it. Formal60 tasks, `layout-memory-1`, VNB4C1 and existing valid
achievements retain their semantics and storage. No schema migration is required.

## Ownership and implementation

- Root: plan/docs, `workspace.gd`, experiment runner/profile tests, integration,
  all Git mutations/Godot runs, process and visual evidence.
- Strategy agent: pure `goals.gd`, bounded session extensions, focused goal/session
  tests. No model semantics changes.
- Integrity agent: `notebook_store.gd`, strict schema/file/lease tests.
- Interaction agent: `lab.gd`, new notebook UI test, narrowly updated existing UI
  assertions. No shared translations/project settings.
- Independent review is read-only until root reassigns ownership.

## Acceptance

1. Fresh model/session baseline plus the expanded probe; preserve complete logs.
2. Real cap-boundary/tie/failure/condition/goal identity checks. Changing a goal
   must not edit the draft, create a run or alter official state.
3. Named plans survive24+ transient observations; saving selected evidence must
   retain its recipe even when the live draft differs. Restore is one Undo.
4. Whole-file canonical/bounds/UTF-8/stale validation; no score fields accepted.
   Actual write/rename failures, external modifications and writer contention
   preserve bytes/committed state; failed proposals remain recoverable.
5. Two real processes using one documented stable profile restore exact names,
   active workload, drafts and goals, then reproduce metrics and Trace. Another
   profile stays separate. Concurrent writers cannot silently overwrite.
6. Focused regressions, bilingual1280x720/960x640 GPU views with actual raw-size
   assertions, settings/feedback/name-input/exit focus and ordinary startup.
   Native UI, exports and other platforms retain separate acceptance boundaries.
7. Inspect full test logs/diff/status, independent review, source binding and
   durable handoff, then commit/push the verified increment to the task branch.

## Progress and open boundaries

- Fresh isolated baseline imported and passed model/session at
  `.godot/verification/20261105T021829Z-18f99d78/project`.
- Root and independent strategy probes completed in that isolated copy.
- All three audit reports were read before production implementation; they
  agree on retention and a measured goal envelope. No model extension is required.
- Persistence is explicit, not autosave. The UI must distinguish saved workspace
  from unsaved drafts/goals, and transient histories from retained recipes.
- Long-term enjoyment, native normal nested Settings, export and other-platform
  acceptance are not implied by this bounded implementation.
- Final12 distinct related headless suites have passing latest staged
  observations, not one full-repository regression. Goals75, Session72,
  Store414, Workspace51, Model2669/171measurements and legacy3810/141designs/
  282cases pass; final headless UI216/159 and GPU244/177 pass.
- Real separate processes seed/reopen exact input state, reject a live writer,
  explicitly recover an intentionally stopped writer, change Q1 cap557→558,
  commit different bytes and reopen/reproduce retained metrics/full Trace.
  Another profile stays empty. Deliberate held-writer exit-9 is not graceful
  exit acceptance; six normal phases exit0.
- Independent source and visual reviews closed the original no-op recovery
  evidence gap and misleading selected-run status. The recent table now names
  its actual objective. Initial fixture failures and18 first frames remain
  archived alongside18 final frames, not rewritten as passing observations.
- Actual named runner preparation passed. Final playable copy
  `.godot/experiments/0c8288dacf9e/project` uses
  `VonNeumannBottleneckChecks/layout_strategy/codex-round5-preview-20261104`.
  Normal headless startup exits0 without diagnostics; local launcher
  `.godot/layout-notebook-preview-20261104.command` passes shell syntax.
- 1187 source/test/support files match QA and playable copies byte-for-byte.
  Both source and frame manifests are in the
  [final receipt](../../verification/20261104-layout-notebook/README.md).
- Fresh CUA attempt found the Mac locked; no click/key was sent. Round5 native
  input is NOT_RUN. Exports, other platforms, newcomers, audio and long-session
  use remain separate. No campaign/model change, ordinary save migration,
  server deployment, main integration or release was included.
