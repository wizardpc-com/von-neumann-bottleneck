# Wire feedback and guidance iteration

Started 2026-09-14. The owner requests continuing evidence-driven iteration until
manually stopped, adding Mission/Handbook accuracy and useful diagrams, with lower
player cognitive load as the priority.

## Scope and invariants

- Repair actual drag/trace placement, direction, synchronization and reduced-motion defects.
- Review five-region/40-task Mission requirements against authoritative models;
  correct misleading statements and illustrations without changing win conditions.
- Reuse the current Handbook and visual vocabulary; explain one decision at a time,
  keep factual detail available on demand and avoid leaking Hint solutions.
- No new chapter, simulator rewrite, save format, unlock change, online deployment,
  or removal of free wiring/branch/delete/undo/floating tools/separate Hint.
- Preserve unrelated project.godot, plan downloads and generated UID files.

## Stages

1. Reproduce wire/replay issues and repair the concrete failures.
2. Validate narrow suites and ordinary Game interactions; commit a reviewable stage.
3. Audit Mission and Handbook facts, then correct confirmed errors and improve the
   most useful diagrams. Keep terminology, colors and diagram roles consistent.
4. Check both locales, compact/Retina geometry and native editing/reading paths.
5. Continue bounded iterations on evidence. Stop when the owner requests it;
   avoid speculative changes merely to keep modifying code.

## Current findings / progress

- Source only editor was running at start; previous candidate package predates
  4290ca5. User's exact animation symptom remains an open optional clarification.
- Confirmed: bus badge and cable reveal use different progress curves; paused
  badge coordinates become stale; branch/endpoint origins cache old screen points;
  reduced-motion preference omits trace feedback.
- First isolated verification recorded under
  `.godot/verification/20260914T030419Z-787e72ab`: parsing and simulation pass,
  geometry/new UI assertions need fixes. Final recovery route also failed at
  LOAD/STORE entry and will be investigated/repeated after the focused repairs.
- Parallel bounded tasks review Handbook diagrams and Mission facts. Main agent
  owns combined validation and local native UI; avoid simultaneous Godot processes.

## Evidence

[Wire iteration evidence](../../verification/20260914-wire-iteration/README.md).
Keep direct rendering, scripted input, native mouse and exported-package acceptance
separate. No Windows real-machine or external beginner claim without actual evidence.

## Verified stage

- Wire repairs committed as `2d5662c`; final targeted wire/hover and hardware suites pass.
- Full 40-suite check and ordinary Game replay pass; Chinese and English each 634/0.
- Mission review covers source requirements of all 40 tasks; four factual corrections.
- Nine illustration topics render in both locales, 36 final 1280 × 720 frames.
- Native keyboard Continue/task entry/exit worked. Native mouse API repeatedly
  returned noWindowsAvailable; held drag/pan/zoom remains an explicit native gate.
- Dynamic Mission query presentation is corrected and checked (`b485bea`): mandatory cases
  precede supporting guidance; single queries omit redundant repeat-one labels.
- Handbook controls and static captures are finalized (`e24c34e`), including the
  final 242/0 Tutorial input replay.
- Remaining queue: native held drag/pan/zoom, long focus/DPI sessions and external
  player clarity evidence. Preserve the existing candidate until a new freeze is requested.
