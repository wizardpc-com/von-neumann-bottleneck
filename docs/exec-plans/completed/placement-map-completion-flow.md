# Placement, Map, and Level-Completion Flow

## Goal

Make component placement feel like a predictable desktop circuit editor, keep the campaign map unobstructed, and give every completed Hardware Foundations or Chapter 1 level a clear learning-summary handoff back to its level map.

## Scope

- Replace the current corner/crosshair placement guide with a low-opacity preview of the selected component at the exact snapped placement position.
- Keep left-click placement armed for repeated copies; cancel it on right click, interaction with an existing component/port/wire, selection/marquee initiation, another editor command, or selection of a different palette item.
- Remove the Test Bench window and its reopen action from the Hardware campaign-map view.
- Keep the Mission window movable, focusable, minimizable, closable/reopenable, and laid out entirely inside the map's reserved left area.
- Add one shared localized completion overlay with a level-specific learning summary, a short presentation-only musical cue, and a Continue button that returns to the relevant level map.
- Trigger that overlay on first completion of all nine Hardware campaign levels and all six Chapter 1 levels.

## Non-goals

- No changes to circuit/system simulation, timing, topology rules, progression prerequisites, official tests, or saved workbench schema.
- No production soundtrack or asset pipeline. The completion cue is a replaceable procedural placeholder and never gates progress.
- No redesign of the level maps or addition of new levels.
- No changes to the preserved Cache Locality Lab completion goal in this iteration.

## Affected subsystems

- `src/hardware_foundations/circuit_graph_edit.gd`: placement-preview and cancellation gesture boundary.
- `src/hardware_foundations/hardware_foundations.gd`: palette state, campaign-map window layout, and Hardware completion triggers.
- `src/ui/level_completion_overlay.gd`: shared summary/continue/music presentation.
- `src/system_lab/system_lab.gd`: Chapter 1 completion trigger and return-to-map action.
- `localization/`: shared and level-specific summary copy.
- `tests/test_hardware_foundations_ui.gd`, `tests/test_hardware_prologue_ui.gd`, and `tests/test_system_lab_ui.gd`: interaction and completion-flow coverage.
- durable status/testing/architecture documentation where behavior changes.

## Invariants

- Simulation completes independently of UI and audio; the overlay only presents already-authoritative completion.
- Ordinary wires remain zero latency and displayed topology remains authoritative.
- One component placement is one existing undoable history transaction.
- Right-click cancellation while placement is armed must not also erase graph content.
- Continue always returns to the matching map and never skips a prerequisite.
- Existing uncommitted work is preserved; this task creates no commit or push.

## Decisions

- Reuse the actual procedural component symbol for basic-gate previews and a dim module silhouette for higher-level components, rather than drawing an unrelated card or bounding box.
- Treat any existing canvas object as an interaction boundary: the first click cancels placement and is then allowed to perform its normal selection/wiring action.
- Keep repeated placement armed after a successful empty-canvas click. Clicking the already armed palette item leaves it armed; a different item swaps the preview immediately.
- Use one root-level modal overlay in both playable subsystems. It owns only presentation and emits `continue_requested`; each host owns its map transition.
- Synthesize a short low-volume completion arpeggio in memory so the milestone has an audio cue without introducing an external asset or dependency.

## Implementation steps

1. Add the truthful ghost preview and explicit placement cancellation signals/state transitions.
2. Adjust campaign-map instruments and reserved geometry.
3. Add the shared completion overlay and localized learning summaries.
4. Wire every Hardware and Chapter 1 completion path to the overlay and Continue-to-map action.
5. Extend focused UI/localization tests and update durable documentation.
6. Run affected suites, full regressions if integration changes warrant it, startup smokes, visual captures, diff checks, and final status review.

## Progress

- 2026-08-19: inspected repository rules, current dirty worktree, placement gestures/preview, map geometry/windows, all Hardware completion paths, Chapter 1 completion evaluation, floating-panel behavior, tests, localization, and status documents.
- 2026-08-19: implemented the actual-symbol low-opacity placement ghost, repeated snapped placement, and cancellation boundaries for right click, existing content, editor actions, and palette changes.
- 2026-08-19: removed Test Bench and its reopen action from the Hardware campaign map, reserved a non-overlapping Mission lane, and retained Mission focus/move/minimize/close/reopen behavior.
- 2026-08-19: added the shared localized completion overlay, fifteen lesson summaries, a presentation-only in-memory cue, and Continue actions returning to the matching map.
- 2026-08-19: extended Hardware base/prologue and Chapter 1 UI coverage, localization coverage, deterministic visual capture hooks, and durable documentation.
- 2026-08-19: all ten documented simulation/UI/content/localization suites passed in the final source state. Default, Test-mode, English, direct-Hardware, and direct-Chapter-1 startup smokes exited `0`; final log scanning found no script, parse, assertion, locked-object, RID, or ObjectDB error.
- 2026-08-19: freshly inspected 1600×900 placement, map, and completion frames. The ghost is the dim actual symbol at the snap point, Mission occupies a clear left lane with no Test Bench, and the localized completion modal presents one lesson plus the Continue action. A longer opt-in audio capture had already completed without a leak.
- 2026-08-19: local Markdown links and `git diff --check` passed. No commit or push was created.

## Unresolved questions and limitations

- The procedural cue establishes the lifecycle and mixing boundary but should be replaced by authored music after the game's audio direction exists.
- The exact opacity and map-window dimensions may need manual playtest tuning at uncommon aspect ratios; automated tests will enforce non-overlap at the 1600×900 design size and on-screen clamping.
