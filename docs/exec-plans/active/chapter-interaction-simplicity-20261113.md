# Chapter interaction simplicity — active goal

## Objective

Continue optimizing interaction logic and the operation of every chapter so that
the finished game minimizes avoidable cognitive burden and is simple to operate.
This is a whole-product goal, not closed by one round of bug fixes or green tests.
Base: main239de25. Commit/push authorization and delegated reviews continue.

## Working criteria

For each chapter, inspect actual entry, required goal, editable controls, explicit
submission, execution, feedback, comparison/retry, completion and save/departure.
Remove unnecessary steps and competing commands where existing product rules allow;
retain meaningful choices, explicit Apply, earned diagnosis and observation boundaries.
Use the existing layout to communicate, with minimal extra labels. Disabled actions
must have discoverable reasons; changes must preserve draft/history/record identity.
No new simulation, tasks, art direction, reward thresholds, save formats or dependencies.

## Coverage and evidence gates

| Area | Entry/goal/edit | Run/feedback/retry | Keep/leave/resume | Render/native | Novice comprehension |
| --- | --- | --- | --- | --- | --- |
| Laboratory and journey map | Pending | Pending | Pending | Pending | Unverified |
| Prologue construction | Pending | Pending | Pending | Pending | Unverified |
| Ch1 system costs | Partial: prediction setup | Partial: covered TEST to Run | Pending | Scripted bilingual recall passed | Unverified |
| Ch2 locality | Partial: applied program | Partial: covered TEST to Run | Pending | Scripted bilingual recall passed | Unverified |
| Ch3 overlap | Pending | Pending | Pending | Pending | Unverified |
| Ch4 layout | Pending | Pending | Pending | Pending | Unverified |
| Ch5 representation | Partial: valid split input | Pending | Partial: Undo/Redo and task context | Bilingual split input rendered | Unverified |
| Ch6 service | Partial: direct encoding/multiselect | Partial: measured edit/retry | Partial: explicit save/Undo/language context | Scripted bilingual menus passed | Unverified |
| Ch7 address prediction | Pending | Pending | Pending | Pending | Unverified |
| Ch8 compression | Pending | Pending | Pending | Pending | Unverified |
| Ch9 content prediction | Pending | Pending | Pending | Pending | Unverified |
| Ch10 creation | Pending | Pending | Pending | Pending | Unverified |
| Optional scheduling lab | Pending | Pending | Pending | Pending | Unverified |

Prior passing checks are evidence of their stated paths only, not new acceptance.
Each row needs a concrete scenario and current evidence. Human comprehension cannot
be inferred from test counts; retain that gap until actual unassisted play evidence.

## Ownership and steps

Root: cross-chapter priorities, hub/map, all Godot runs/Git, integration and documentation.
Core reviewer: prologue/Ch1/Ch2. Scheduling reviewer: Ch3/Ch4/optional scheduling.
Late reviewer: Ch5–10. Initial audits are read-only; assign disjoint edit ownership
only after concrete obstacles are identified. Read relevant code/tests/docs first.

1. Build source-backed operation maps; inspect representative current renders.
   Current [whole-chapter audit](../../development/INTERACTION_AUDIT_20261113.md)
   distinguishes source inspection from verified operation and human comprehension.
2. Prioritize problems blocking comprehension or adding avoidable repeated actions.
3. Reproduce each selected issue; implement smallest coherent improvement within
   existing contracts, with before/after action sequence and regression evidence.
4. Run affected tests and actual rendered input; inspect results and pixels, review
   independently, commit/push each verified block. Keep full goal/coverage open.
5. Validate full chapter coverage and final-product interaction claims; do not mark
   the goal complete while rows or necessary player acceptance remain unverified.

## Progress

- 2026-11-13: previous goal turn was progress: four runtime repairs and docs pushed.
  New goal started from clean239de25. Three read-only audits assigned; root owns
  engine/Git. Historical documented Prediction/Service regression failures selected
  for current reproduction before trusting earlier global experience claims.

- First milestone: three runtime changes verified, with20 distinct selected
  candidate suites having passing evidence, final new tests531/124/50, GPU checks
  and10 inspected bilingual1280x720 frames. Initial fixture failures retained.
  [Receipt](../../verification/20261113-interaction-simplicity/README.md).
  This closes only those specified behaviors; all chapter acceptance rows remain open.

## Prioritized findings (not a completion checklist)

- Implemented, milestone verification: prologue F5 during official playback; explicit fast presentation
  of all official results with unchanged per-case evaluation and sealing authority.
- Implemented, milestone verification: Layout pending names survive layout edits, Undo/Redo, Run and
  A/B inspection; clear only on explicit successful save or task change.
- Implemented, milestone verification: Creation pending learning inputs must not look applied; guide
  explicit Learn while preserving old measurements and unsaved generated work.
- Verified existing behavior: Ch1/Ch2 covered instruments return with one toolbar
  click, preserve legal user geometry and draft/history, and deliver the next real
  Run click. Bilingual viewport98/headless and114/GPU checks passed; no runtime fix
  needed. This does not resolve every discovery/space tradeoff. Keep Apply explicit.
- Pending: Layout editing/results switch loses editing visibility each iteration;
  three columns cannot fit existing readable minimums at1280. Do not shrink text.
- Pending: Overlap syntax reference exposes one command at a time, adding lookup steps.
- Pending: scheduling conditions live apart from the rankings they filter.
- Second milestone verified: Representation Split follows the selected
  block interior and explains unavailable cases; Service directly chooses encoding
  without intermediate draft edits. New checks160/235 and GPU190/271 passed;
  17 distinct selected suites have passing evidence and22 final images were inspected.
  [Receipt](../../verification/20261113-selection-controls/README.md).
  Initial popup-on-press failure was corrected before delivery; native OS input
  remains unverified, and no full-product acceptance is implied.
- Pending: Prediction changing investigations clears partial observation without
  explicit loss feedback.
- Current baseline: historical prediction-record and service-undo failures do NOT
  reproduce (28 and124 checks pass). Do not treat old failures as current defects.

- GPU pixel review: bilingual official playback and Creation Learn/Keep controls
  fit actual1280x720. This is scripted rendering, not native/newcomer acceptance.
  Existing circuit occlusion, shortened Trace summaries, hidden third Creation tab
  and duplicate Keep entrances remain broader audit items.

## Decisions and open questions

Assume an unfamiliar player who uses ordinary mouse/keyboard controls, without
knowledge of Godot or project internals. Preserve authored educational challenges;
reduce interface work around them. Platform/export and novice acceptance remain
explicitly open; no claim of absolute minimum cognitive load from expert inspection.
