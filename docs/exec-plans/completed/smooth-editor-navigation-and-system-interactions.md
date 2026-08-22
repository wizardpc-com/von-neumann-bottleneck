# Smooth editor navigation and Chapter 1 interaction parity

## Goal

Make Hardware Foundations keyboard camera movement continuous and smooth, and make the Chapter 1 system workbench use the same useful selection, movement, deletion, and edit-history conventions.

## Scope

- Replace key-repeat-driven Hardware Foundations WASD jumps with frame-rate-independent held-key movement.
- Add the same smooth WASD navigation to the Chapter 1 system graph.
- Add Chapter 1 empty-canvas marquee selection, Shift toggle selection, selected-group movement, right-button cursor-tip wire erasing, Delete, Ctrl+A, Ctrl+Z/Ctrl+Y, and Ctrl+Shift+Z.
- Record Chapter 1 wiring and component-position edits as reversible transactions.
- Keep fixed CPU, Bus, and RAM slots present; deleting a selected fixed device clears its incident routes instead of removing the level's only hardware slot.
- Extend headless UI coverage and update durable interaction/testing documentation.

## Non-goals

- Do not change either simulation core, timing formula, typed topology, level progression, part catalog, or official tests.
- Do not add component cloning, a free-placement palette, arbitrary junctions, or branching wires to Chapter 1.
- Do not redesign the workbench windows or the system chapter map.
- Do not persist undo/redo history between levels or application sessions.

## Affected files and subsystems

- `src/hardware_foundations/hardware_foundations.gd`: smooth camera input.
- `src/system_lab/system_graph_edit.gd`: selection and precise continuous erase gestures.
- `src/system_lab/system_lab.gd`: shortcuts, edit transactions, history replay, movement capture.
- `tests/test_hardware_foundations_ui.gd` and `tests/test_system_lab_ui.gd`: interaction regression coverage.
- `docs/architecture/simulation.md`, `docs/development/testing.md`, and Chapter 1 status documentation when durable behavior changes.

## Invariants

- Simulation remains deterministic and independent of UI frame rate.
- Moving components or the camera changes only displayed geometry.
- Wire geometry and screen distance add no simulation latency.
- The visible Chapter 1 connection list remains the authoritative typed topology.
- Signal animation continues to resolve the exact current rendered route.

## Implementation and verification

- [x] Add delta-based held-key pan with focus/modal guards and verify equivalent movement across different frame slices.
- [x] Port the useful selection and eraser gesture layer to `SystemGraphEdit`.
- [x] Add atomic Chapter 1 edit snapshots for routes, colors, positions, and selection; wire shortcuts and movement boundaries to history.
- [x] Add headless assertions for selection, group movement, erase precision/continuity, deletion semantics, undo/redo, and unchanged topology under geometry-only movement.
- [x] Run Hardware Foundations UI, Chapter 1 simulation/UI, localization, and relevant startup smokes.
- [x] Inspect the final diff and `git status`, record results, and move this plan to `completed/`.

## Decisions

- Chapter 1's CPU, Bus, and RAM are fixed typed slots rather than palette instances. A delete gesture on a device therefore removes its incident routes, leaving the required slot available for reconnection; this preserves recoverability and the Parts window's replacement semantics.
- Edit history is session-local and cleared when a level session is loaded. Level sessions continue to persist only final positions, topology, colors, parts, and program source.
- Keyboard motion records physical press/release events and applies that state in `_process(delta)` at a constant frame-delta-scaled speed. Canvas/component clicks retake keyboard focus, visible text editors keep their input, and application focus loss clears the state. Discrete shortcuts remain event driven.

## Progress

- 2026-08-22: Confirmed Hardware Foundations currently pans by one fixed 72-pixel step per key event and Chapter 1 lacks editor selection, erasing, and undo/redo transactions.
- 2026-08-22: Replaced both editors' keyboard camera path with held-key delta movement. Added Chapter 1 selection feedback, body/group movement, precise continuous erasing, fixed-slot deletion semantics, and snapshot-based reversible editing.
- 2026-08-22: Six relevant suites and four startup smokes exited `0`. A 1600×900 Chapter 1 workspace capture showed the revised toolbar fitting without overflow. Log scanning found no product error; the existing Windows certificate-store warning remained non-fatal.
- 2026-08-22: Follow-up playtest exposed intermittent focus retention after text editing. Replaced global held-key polling with editor-owned press/release state, explicit graph focus recovery, immediate release stopping, and focus-loss cleanup; both editor UI suites passed the new regression path.

## Outcome

Hardware Foundations WASD no longer depends on operating-system key repeat. Chapter 1 now shares the useful prologue editor grammar while preserving its constrained CPU/Bus/RAM topology and deterministic simulation boundary. Final component positions, routes, and colors still persist in the level session, while the undo chain intentionally does not.

## Unresolved questions and temporary limitations

- Chapter 1 intentionally keeps its three fixed system slots and direct typed routes; prologue-only cloning, branch junctions, endpoint waypoints, and component placement are not meaningful in this chapter and remain absent.
