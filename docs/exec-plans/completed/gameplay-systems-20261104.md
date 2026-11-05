# Gameplay systems: takeover and first playable iteration

Date: 2026-11-04. Baseline: `b65a0bd`. Owner: Codex root.
Branch: `codex/gameplay-systems-20261104`.
Status: first playable increment complete; continuing development objective active.

## Goal and scope

Make improving and comparing a working solution a repeatable playable activity:
real simulation measurements, clear comparison conditions, recoverable experiments,
and fewer repeated editing steps. First audit the previous overall polish and
current systems, then select and implement a bounded complete player loop.

The user's continuing direction includes interaction, simulation depth, personal
scores, challenges and future online competition. This plan records the concrete
first increment; later increments need evidence and explicit scoped decisions.

## Invariants and exclusions

- Preserve the existing 60 tasks, prerequisites, saved works and earned results.
- Deterministic simulation and traces remain authoritative; UI timing is irrelevant.
- Game and Test results remain separate; no telemetry-derived scores.
- Keep disputed previous designs pending review, without unilateral reversal.
- No major model rewrite, player-save migration, online deployment or release.
- Main stays at the starting commit; root alone performs Git mutations and Godot
  runs. Parallel edits require disjoint assigned ownership.

## Work and verification

1. Read current contracts and previous handoffs; inspect actual branch and changes.
2. Parallel audit: interactions; model/metrics/scores; independent polish review.
3. Record prioritized findings, confidence, impact, and deferred design decisions.
4. Define the selected playable increment and rollback boundaries before editing.
5. Implement with meaningful model, isolation, input and persistence checks.
6. Run isolated Godot 4.7.1 suites, review logs and actual Mac rendering/input.
7. Inspect final diff/status; update architecture/testing/status where necessary
   and leave a reproducible handoff.

## Progress

- 2026-11-04: clean current checkout verified at `b65a0bd`; independent branch
  created. Current source explicitly registers 60 tasks; older 40-task memory and
  Mac handoff sections are historical, not the present product boundary.
- Read README, architecture, planning, docs index, current state, shared-checkout
  rules, testing entry points, current overall-polish receipt and prior handoffs.
- Installed engine verified: `4.7.1.stable.official.a13da4feb`.
- Three audits completed. Existing Windows failures reproduced on Mac at
  `.godot/verification/20261104T184925Z-d0fd9b18`: prediction record-source
  1/28 and service undo-context 16/96; locality UI and optional challenges pass.
- Selected first increment: fourth-chapter personal scheme comparison, recomputed
  from current/named/best recipes against all current official orders. Sort by
  cycles, RAM traffic or peak scratch; only existing task-qualified recipes rank.
  Restore a recipe into an undoable draft and pin a personal target for this visit.
  Existing named saves supply persistence; no new save schema or model change.
- Parallel independent improvements: duplicate circuit workbench through existing
  transactional store; restore service multi-selection in Undo/Redo.
- Root fixes unambiguous fourth-chapter corrupted text and isolates locality
  comparisons by mode/conditions. Existing diagnosis disclosure rules remain.
- No new core model is needed for this increment: existing layout preparation,
  bandwidth and scratch accounting already permit meaningful tradeoffs.
  Rollback removes the new reader/UI; all saved designs remain in the existing
  format and original completion authority remains unchanged.
- Implemented the complete personal experiment loop: three separate objective
  rankings, named saves, undoable restore and a condition-bound session challenge.
  Test fixtures prove actual cycle and space wins, ties and unqualified attempts.
- Duplicate circuit workbenches preserve source geometry/wires/colors and require
  new evidence. Service Undo/Redo restores multi-selection and the active group.
- Independent review found a failed-persistence retry blocked by duplicate-name
  protection. Same normalized recipe may now retry via the player save action;
  a differing recipe still cannot overwrite the saved design.
- Full 26-candidate recomputation measured up to 612.281 ms on this M2. Objective
  changes now sort the existing measurement snapshot (maximum 0.314 ms in this
  probe); opening/saving still remeasure. No model or persistent cache was added.
- Final focused model/UI: 37/44 checks PASS. Actual Mac GPU UI: 47/0.
  Circuit duplication: 44 PASS; service Undo: 124/0; 23 related suites have passing
  latest observations across staged runs, not one final full-repository run.
- Native input observed layout/run/ranking, named-save and return paths in an
  earlier integrated snapshot. Exact scope, original failures, source hashes,
  screenshots, timing and raw logs are in
  [the verification record](../../verification/20261104-gameplay-systems/README.md).
- Final independent reviews found no remaining actionable issue in implemented
  scope. No commits/push/release, real player data changes or main mutation.

## Continuing work and acceptance boundaries

- Selected domain is Chapter 4; incompatible model/workload domains remain
  separate. The [audit](../../development/GAMEPLAY_AUDIT_20261104.md) distinguishes
  confirmed defects from preserved disputed presentation choices.
- Next bounded work should inspect existing personal-record metric/identity
  contracts and long-term retention before extending rankings across domains.
- Challenge sharing/online competition needs explicit versioned recipes,
  complete current rules and server-side recomputation; no deployment was made.
- Native acceptance of every edit path, exported packages, all-platform/full-suite
  regression, human understanding and sound remain separate work. The continuing
  user goal is not marked complete by closing this first increment.
