# Prototype v0.2 core-loop execution plan

## Goal

Turn the tagged v0.1 technical slice into a focused v0.2 gameplay-validation prototype in which the editable program is the only execution source, trace playback follows the visible machine topology, component feedback explains each event, Profiler evidence is opened and investigated by the player, and Cache capacity creates a software-versus-hardware tradeoff.

## Scope and non-goals

In scope:

- replace the old fixed-form DSL with a Python-shaped, indentation-based subset and nested IR;
- preserve deterministic simulation metrics while enriching `SimulationTrace` with source, route, and investigation details;
- replace manual wiring with a fixed topology, automatic layout, optional visual dragging, and exact connection-curve playback;
- move Program, Test Bench, Profiler, and Cache configuration into workbench drawers;
- add a 105-cycle Official target, session run history, and replaceable 1/2/4-line Cache cards;
- update automated tests and durable documentation.

Out of scope:

- additional levels, free-form topology, new hardware families, register limits, saves, progression, production assets, localization, CI, commits, tags, or publishing.

## Invariants

- `DSLParser` produces the only executable program representation; no hidden traversal switch is allowed.
- `SimulationCore` remains deterministic and UI-independent.
- Playback consumes a completed trace and never mutates or recomputes simulation results.
- Ordinary connections have zero simulation latency; costs remain component-owned.
- Cache remains hardware-managed.
- Existing reference results remain 321 cycles for one-line column-first and 105 cycles for one-line row-first.

## Implementation

1. Replace flat DSL structures with nested instructions, line-aware validation, and recursive execution.
2. Add trace route devices, source lines, program source, and cache-line evidence while preserving canonical determinism.
3. Rebuild the UI around a fixed workbench and mutually exclusive drawers.
4. Resolve every animated route from actual GraphEdit connection curves, including reverse and multi-edge travel.
5. Drive source-line, wire, port, and component feedback from the current trace event.
6. Replace the always-visible Profiler with summary, waiting tree, memory events, trace inspection, and run history.
7. Replace the Cache dropdown with 1/2/4-line cards and evaluate the Official 105-cycle target outside the simulation core.
8. Update tests and documentation, then run automated and visual acceptance checks.

## Decisions

- The old DSL is intentionally not backward compatible; v0.1 remains available at its Git tag.
- The Official target is correctness plus at most 105 cycles. Hardware cost is evidence, not a hard pass condition.
- Component positions are automatically laid out but may be dragged for visual organization; Auto Layout restores the canonical arrangement.
- Profiler presents facts from player-generated traces and must not recommend a loop order.

## Verification

- simulation, UI, and project-smoke commands from `docs/development/testing.md`;
- exact cache/cycle matrix and deterministic trace signatures;
- exact GraphEdit curve equality before and after moving a device;
- source-line, component-state, drawer, run-history, and Profiler drill-down integration checks;
- manual visual checks for miss, hit, line return, pause/step, moved nodes, and both valid Official solutions;
- final `git diff --check`, diff review, and status inspection.

## Progress

- 2026-08-15: plan created; clean `main` baseline and all three existing checks were already passing.
- 2026-08-15: Python-shaped parser, nested IR, recursive execution, line/route/detail-aware trace, and exact reference metrics implemented.
- 2026-08-15: fixed auto-laid-out workbench, connection-curve playback, component feedback, instrument drawers, investigative Profiler, Run History, Official target, and replaceable Cache cards implemented.
- 2026-08-15: automated simulation, UI integration, and startup smoke checks passed with exit code `0`.
- 2026-08-15: column-first, Profiler, and row-first captures inspected; request, miss, RAM access, line return, Cache hit, component states, and contained drawer layout were visually verified.

## Outcome

All planned v0.2 scope is implemented without adding levels, assets, arbitrary wiring, or progression. The editable DSL is now authoritative, and one `SimulationEvent` supplies the source, route, timing contribution, component response, and Profiler evidence used by presentation. Both intended Official solutions are valid: row-first with one Cache line reaches 105 cycles at hardware cost 4, while column-first with four lines reaches 105 cycles at cost 13. The next useful work is player validation, not further expansion of this slice.

## Unresolved items

- None. Scope and tradeoffs were confirmed before implementation.
