# Chapter interaction simplicity — resumed reliability review

Latest user instruction (2026-11-13) resumes reliability, interaction and playable
chapter-loop work, with delegated reviews and commit/push to main after verified
blocks. The earlier closure is historical. The whole-product acceptance goal
is active and not declared achieved; pending rows remain below.

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
| Ch1 system costs | Partial: prediction setup and modal input isolation | Partial: TEST to Run; current results cleared after applied/topology changes | Historical receipts preserved | Fresh bilingual GPU recall and boundary checks | Unverified |
| Ch2 locality | Partial: applied program | Partial: covered TEST to Run | Pending | Scripted bilingual recall passed | Unverified |
| Ch3 overlap | Partial: complete current command reference | Partial: actual edit and Run | Existing draft regressions | Bilingual six-task expanded reference | Unverified |
| Ch4 layout | Partial: tools/results iteration | Partial: real Run, inspect and return | Naming, Undo, rankings/challenge regressions | Bilingual six-task flow and final GPU passed | Unverified |
| Ch5 representation | Partial: valid split input | Pending | Partial: Undo/Redo and task context | Bilingual split input rendered | Unverified |
| Ch6 service | Partial: direct encoding/multiselect | Partial: measured edit/retry | Partial: explicit save/Undo/language context | Scripted bilingual menus passed | Unverified |
| Ch7 address prediction | Partial: per-investigation temporary context | Partial: exact reveal continuation and historical source | Cached work included in leave guard | Bilingual context/reading final GPU passed | Unverified |
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
- Implemented: Layout retains tools/results in two columns, with explicit address
  inspection, fixed return and truthful historical maps. Localized minimum widths
  and viewport resize drive layout; no smaller typography or three-column squeeze.
- Verified: Overlap displays its existing public reference together in all six
  tasks and both languages, including expanded experiment prompts.
- Pending: scheduling conditions live apart from the rankings they filter.
- Second milestone verified: Representation Split follows the selected
  block interior and explains unavailable cases; Service directly chooses encoding
  without intermediate draft edits. New checks160/235 and GPU190/271 passed;
  17 distinct selected suites have passing evidence and22 final images were inspected.
  [Receipt](../../verification/20261113-selection-controls/README.md).
  Initial popup-on-press failure was corrected before delivery; native OS input
  remains unverified, and no full-product acceptance is implied.
- Implemented: Prediction keeps per-investigation temporary context and guards
  inactive work on departure; explicit edits/reset still invalidate the prefix.
  Actual pixel review also repaired event/specification reading space.
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

- Third milestone in progress from clean remote-confirmed e6586b3: preserve temporary
  per-investigation Prediction context, show the existing Overlap reference together,
  and retain Layout tools alongside results with explicit address inspection. Root
  owns engine/Git; three agents have disjoint host/new-test ownership. Simulation,
  saved formats, authored commands and completion authority remain unchanged.
  Verification and full chapter/native/novice acceptance are still pending.

- Third-milestone pixel review found an existing Prediction layout obstruction:
  at1280x720 its event table exposes only part of a row and Task/machine scroll
  gets no usable height. Extend this same interaction block to give both real
  reading space, retaining existing text, font sizes and observation authority.
  State tests alone were insufficient; rerun context and presentation checks.

- Closure:21 distinct selected suites have passing evidence. Final new headless
  counts605/1563/507/390; existing Prediction presentation1225. GPU655/1593/537/416,
  with32 main-flow raw bilingual images independently inspected. A final one-line
  Chinese repeated-success translation repair has2 additional passing existing
  suites and2 dedicated rendered cue frames; main-flow images precede that text fix. Initial failures and
  two before-images are retained in the [receipt](../../verification/20261113-context-and-reference/README.md).
  This block is verified for commit/push; broader development pauses at the user's
  request, without claiming whole-product/native/novice acceptance.

- Resumed from clean remote-confirmed main `df8c1e6`: three read-only audits cover
  core chapters, Layout/Creation and visual/navigation consistency. Root retains
  sole engine/Git ownership. Select concrete reproductions before implementation.

- Resumed boundary block: old runtime reproduces Chapter1 modal shortcut leaks and
  stale Test/Profiler evidence, plus Creation unadded/reselected text loss. Current
  guards keep explicit Add/Replace/Apply and historical evidence boundaries. Safe
  same-index/source reselection rebinds the current collection without committing
  pending text. Final evidence lives in the [boundary receipt](../../verification/20261113-modal-and-example-boundaries/README.md).
  This closes specific defects, not whole-chapter acceptance.
- Fresh core GPU coverage includes official prologue playback, bilingual Ch1/Ch2
  recall/Run and Ch4 six-task iteration. In Ch2's1280px reference frames, the far
  right laboratory header entry is partially outside the viewport; check responsive
  header geometry next, without altering progression or adding navigation routes.
