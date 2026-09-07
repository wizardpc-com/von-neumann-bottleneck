# 0019 — Eight-task mainline and standard modules

> Superseded product direction, 2026-09-05: the user withdrew replacement of the original mainline by eight tasks, demotion of construction to an optional workshop, and replacement of the floating desktop by a fixed workspace. The original Game route is restored. This document is retained as historical comparison evidence; simulation, provenance, save protection, and Git safety still apply. See [recovery status](../status/in-place-recovery.md).

Status: accepted, 2026-09-05. Product authority: [approved blueprint](../design/DEMO_REDESIGN_BLUEPRINT.md).

## Decision

The default Game entry is `src/demo/demo_menu.tscn`. Eight stable task IDs cover selection, staged storage, CPU comparison, two upgrade scenarios, cache reuse, access order, grouping and a capstone. Deep gate construction remains an optional workshop. New mainline completion requires behavior, workload and published constraints; it does not require predictions, diagnosis answers, playback completion or opening a finding.

`src/demo/` supplies content, validation and presentation over the existing `PrologueSimulator`, `SystemSimulationCore` and `SimulationCore`. Those engines and their timing/state semantics are unchanged. P-1/P-2 export the visible editable circuit. Performance tasks use fixed, disclosed standard routes and the displayed program/configuration. Standard modules have explicit authored identity; they never masquerade as workshop-sealed player content. The four-bit state model, eight-bit system timing model and locality model remain distinct.

The fixed workspace keeps the task, program/data or circuit, settings and run summary visible. Run parses a draft and executes only a valid snapshot in one action. Failed parsing preserves the previous result. Valid results and completion are recorded before any optional event inspection. Event navigation highlights only a matching current design and never changes a Trace. Author-computed baselines are identified as reference runs. Hints do not apply their reference text or topology to a player design.

## Persistence

`DemoProgress` owns `user://demo_progress_v1.json`, independently of `savegame_v1.json` and named workshop files. It saves current task/stage, drafts, accepted independent designs, comparison identity and replay signatures. Game loading replays accepted designs through current validators; saved flags are insufficient authority. Unverifiable evidence remains retained with `verified=false`. Draft edits do not erase accepted achievements. Temporary write and backup replacement protect interrupted saves; future/corrupt formats fail closed. Test state is separate and never writes Game progress. Old chapter records remain accessible under Legacy records and labs; they do not imply completion of different new task contracts.

## Superseded product constraints

For the new mainline this decision supersedes the mandatory prologue entry gate and old node counts in ADRs 0008/0016; default floating presentation and playback/review gates in 0002; the separate Apply click in 0003; and prediction/diagnosis gates documented in the old chapter statuses. Simulation, source provenance, draft/execution separation and Git safety portions of those decisions continue to apply. Legacy lab scenes retain their historical behavior for saved work and regression; they are explicitly secondary to the new mainline.

## Consequences and verification

A small new controller avoids inheriting the old investigation controllers' tightly coupled gates. The existing workshop and legacy lab controllers remain substantial code; this change does not claim to have redesigned every optional legacy tool. New model, route/UI, input, localization and save tests complement the original suites. [Current status](../status/demo-redesign.md) distinguishes playable implementation, bounded solution enumeration, rendered/input evidence and human acceptance.
