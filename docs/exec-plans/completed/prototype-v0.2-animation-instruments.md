# Prototype v0.2 animation and instruments correction plan

## Goal

Correct the v0.2 presentation so a trace visibly progresses through one causal stage at a time—program issue, component processing, wire transfer, and receive—and replace mutually exclusive right-side drawers with movable, resizable instruments that may remain open together. Make edits to the program visibly change the execution plan and the next run.

## Scope and non-goals

In scope:

- continuous presentation paths through component interiors and exact GraphEdit connection curves;
- single-focus component feedback synchronized to packet position;
- draggable, resizable, independently closable Program, Test Bench, Profiler, and Cache panels;
- live program traversal/address preview, dirty state, and last-executed receipt;
- tests, visual capture, and durable documentation updates.

Out of scope:

- simulation cost changes, new DSL syntax, new levels, arbitrary wiring, persistent window layouts, art assets, saves, progression, commits, tags, or publishing.

## Invariants

- `SimulationCore` output, deterministic metrics, and the 321/105 reference results remain unchanged.
- The simulation event route remains authoritative; presentation may prepend Program → CPU only for instruction issue.
- Every inter-component transfer continues to use the actual GraphEdit connection curve, including after device movement.
- Playback remains read-only and Profiler continues to present facts rather than optimization advice.
- Program edits invalidate stale evidence and the next run executes exactly the current editor text.

## Implementation and verification

1. Build each event's presentation route from component-internal processing loops plus visible wire curves and record normalized processing intervals.
2. Highlight only the component whose internal interval currently contains the packet; show wire travel without simultaneous endpoint highlighting.
3. Add a reusable floating instrument control and migrate all four drawers without changing their contents or data authority.
4. Add live execution-plan/address-order preview and last-run receipt to Program; keep it open during playback so source highlighting is observable.
5. Extend UI tests for continuous component paths, single-focus feedback, coexistence, movement/resizing, and program change evidence.
6. Run simulation, UI, smoke, capture representative frames, and perform final diff/status checks.

## Decisions

- Instruments are embedded floating panels rather than native OS windows so they remain inside captures and the workbench coordinate system.
- Component processing is a presentation phase with no additional simulated cycles.
- A valid program preview describes loop order and the first addresses but does not run the simulation or predict advice.

## Progress

- 2026-08-15: plan created from direct playability feedback; implementation started.
- 2026-08-15: continuous Program/component/wire presentation routes, two-turn PROCESS orbits, short packet tails, passive waiting context, and single-focus strong highlighting implemented.
- 2026-08-15: four drawers replaced by embedded floating instruments with independent visibility, drag, resize, close, and z-order focus.
- 2026-08-15: Program live traversal/address preview, dirty state, exact-source capture, and last-run cycles/misses receipt implemented.
- 2026-08-15: simulation, UI integration, and startup smoke checks passed with exit code `0`; UI tests cover route stages, single focus, instrument coexistence/movement/resizing, and program effects.
- 2026-08-15: consecutive render frames verified Program → CPU → Cache activation without future-component pre-lighting; side-by-side Program/Profiler capture verified contained scrolling and independent windows.

## Outcome

The reported presentation defects are corrected without changing simulation costs or reference results. A load now visibly issues from Program, processes inside CPU, travels over the current GraphEdit curve, and processes at Cache; multi-hop returns dwell separately in RAM, Bus, and Cache. Strong component highlighting is exclusive and future processing loops stay invisible until reached. Instruments coexist as a player-arranged workspace, and program edits now show both an immediate address-order effect and a measured last-run effect.

## Unresolved items

- None. The requested interaction corrections are specific enough to implement and verify locally.
