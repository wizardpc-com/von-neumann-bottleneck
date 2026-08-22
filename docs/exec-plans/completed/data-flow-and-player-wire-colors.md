# Data flow and player wire colors

## Goal

Replace the point-like transfer marker with readable causal data flow, reduce the visible port size without weakening wiring hit targets, and let players organize cables with their own colors in Hardware Foundations and Chapter 1.

## Scope

- Smaller visual ports with unchanged generous hover, drag, snap, and deletion behavior.
- Hardware one-bit flow as a progressive cable/component state change; wider values as one moving numeric badge on the exact cable.
- Chapter 1 transfers as an exact-route flow band plus one readable address/value badge.
- A nine-color player palette, segment/net coloring in Hardware, segment/lane coloring in Chapter 1, and preservation through the existing session/workbench history boundaries.
- Focused automated, headless, and rendered-frame verification.

## Non-goals

- No simulation timing, circuit result, topology, scoring, progression, or Cache Locality Lab changes.
- No decorative art pass, copied Turing Complete assets, arbitrary RGB editor, or performance meaning attached to line length.
- No conversion of system packets into low-level electrical signals.

## Affected files and subsystems

- Hardware GraphEdit, trace overlay, component symbols, workbench snapshots, editor history, toolbar shortcuts, and live-input playback.
- System GraphEdit, transfer overlay, workbench palette/session state, and UI tests.
- Simulation/presentation documentation and localization catalogs.

## Invariants

- Completed deterministic traces remain the sole animation input; animation never determines results.
- Independent events at the same visual step remain parallel, while dependent waves remain ordered.
- Every flow uses the exact displayed GraphEdit curve; geometry and screen distance add no simulation latency.
- One settled cable has one visible full-path renderer.
- Port red/green/gray remains electrical truth. Player wire hue is presentation metadata only and never enters canonical simulation evidence.
- Existing v0.2 Cache Locality behavior remains unchanged.

## Decisions

- Draw a 12-pixel visible port inside the existing 24-pixel transparent icon canvas and retain the current 28–30-pixel interaction hit zones.
- Use nine stable palette indices. `1`–`9` selects a hue; `Ctrl+F` colors the hovered segment, `Ctrl+E` colors its connected net/lane, and `Ctrl+R` samples it. A visible palette menu exposes the same actions.
- Store optional `color_index` presentation metadata on workbench wire records without changing the v1 manifest or topology signature; missing/invalid values use the default cyan.
- Hardware cables use the player hue as their base. Low is dim, high is bright, high impedance is gray/dashed, and active flow is a growing inner stroke. Ports stay red/green/gray.
- One-bit wires show no moving point or badge. Component processing uses progressive surface/lead emphasis rather than token dots. Wider wires show one dark-backed numeric badge moving with the active flow.
- Chapter 1 retains request/data semantics and serialization captions, but replaces the capsule/dot with a route-aligned band and one address/value badge.

## Implementation and verification

1. Add the shared palette and custom single-layer cable rendering, then reduce visual ports while preserving hit zones.
2. Carry color metadata through new wires, branches, endpoint moves, copy/paste, snapshots, and atomic undo/redo.
3. Convert Hardware playback to commit displayed signal states wave by wave and automatically animate valid input changes without changing simulation state.
4. Remove point tokens from component/wire effects and add the wider-value badge.
5. Add the Chapter 1 custom graph renderer, palette/session behavior, and updated transfer overlay.
6. Extend Hardware, prologue, system, localization, persistence, and regression tests; run all relevant suites and inspect representative frames.
7. Record fresh evidence, review diff/status, and move this plan to `completed/`.

## Progress

- 2026-08-19: inspected current port texture/hit zones, GraphEdit paths, live-analysis refresh, causal playback batches, workbench snapshots/history, and Chapter 1 transfer routes. Product choices locked: Hardware plus Chapter 1, player base hue plus electrical state styling, and one moving numeric badge for wider data.
- 2026-08-19: implemented 12-pixel visible ports with unchanged interaction canvases, a shared nine-color palette, single-renderer settled cables, presentation-only workbench/session color persistence, atomic Hardware color history, segment/net/lane tools, and color-preserving route edits.
- 2026-08-19: replaced point tokens with progressive cable/component strokes for one-bit traces, automatic causal playback after input changes, and one exact-route address/value badge for Chapter 1. Reverse read lanes now take independent paths below the system devices; custom hit testing and playback use the same path.
- 2026-08-19: all ten documented simulation/UI/content/localization suites passed with exit code `0`. Default, Test-mode, direct Hardware, and direct Chapter 1 startup smokes also passed. Fresh 1600×900 Hardware and Chapter 1 transfer frames were inspected; `git diff --check` passed. The only engine diagnostic was the pre-existing non-fatal Windows root-certificate warning.

## Unresolved questions and limitations

- No unresolved product decision remains for this iteration. Exact palette hues and animation easing are readability defaults and may be tuned after manual play-testing.
