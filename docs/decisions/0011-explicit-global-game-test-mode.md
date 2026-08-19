# ADR 0011: explicit global Game and Test modes

## Status

Accepted for the current playable prototype.

## Context

Normal campaign prerequisites are essential gameplay evidence, but they make repeated late-level development checks expensive. Simply enabling every map button is insufficient because later level factories also require player-created reusable components. Writing fake completion flags or helper components into the normal player state would make progression evidence untrustworthy.

The project has multiple entry/play scenes, so a scene-local testing flag could also leave the hub, Hardware Foundations, and Cache Locality Lab presenting different modes.

## Decision

- Add an autoloaded session `GameMode` with two explicit states: `game` and `test`.
- Default every launch to Game mode. Allow the visible selector or the `-- --test-mode` command-line override to enter Test mode.
- Show the shared selector on the prototype hub and both playable scenes.
- Keep separate in-memory `PlayerContentState` objects for Game and Test mode inside Hardware Foundations.
- In Test mode, treat every valid registered level as enterable and install a bounded temporary library containing the reusable definitions required to instantiate the current campaign.
- Do not mark those levels completed. Official runs still evaluate the player's actual displayed circuit, and any completion achieved in Test mode remains only in Test state.
- Switching back to Game mode restores its exact prior content state. Mode, progress, and window layout remain session-local.

## Alternatives considered

- Enabling map buttons only was rejected because Full Adder, ALU, RAM, CPU, and LOAD/STORE builders would still be missing prerequisite component definitions.
- Marking all normal levels complete was rejected because it fabricates evidence and contaminates player progression.
- Separate test-only scenes were rejected because they duplicate navigation and can drift from the real playable scenes.
- A persistent settings/save format was deferred because current player topology itself is not yet persistently restored.

## Consequences

- Developers can enter any current campaign level from the same UI players use.
- Game-mode unlock behavior and player-owned provenance remain trustworthy.
- New registered levels automatically become enterable in Test mode, but a level introducing a new prerequisite reusable kind must extend the bounded helper-library installer until general save/content tooling exists.
- Test mode is a development convenience, not a simulation cheat: topology, diagnostics, gate delays, official cases, and pass/fail logic are unchanged.

## Evidence

- Implementation plan: [`../exec-plans/completed/global-game-test-mode-and-selection-clarity.md`](../exec-plans/completed/global-game-test-mode-and-selection-clarity.md).
- Focused coverage: `tests/test_hardware_foundations_ui.gd`, `tests/test_ui.gd`, and `tests/test_localization.gd`.
