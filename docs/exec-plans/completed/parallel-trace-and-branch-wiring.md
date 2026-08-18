# Parallel trace and branch wiring execution plan

## Goal

Make Hardware Foundations read and feel like a live circuit editor: all causally-ready work animates in parallel, compact components can be arranged freely, and a single driven signal can be routed through movable wire nodes into multiple branches.

## Scope and non-goals

In scope:

- parallel presentation batches derived from deterministic simulation ticks and dependencies;
- simultaneous exact-path wire animation and simultaneous per-component feedback;
- smaller AND, OR, NOT, input, output, lamp, and junction visuals;
- movable external input/output terminals while retaining their Test Bench semantics;
- output fan-out, explicit zero-delay wire junctions, branch creation from an existing wire, movable junctions, and predictable removal;
- focused model/UI regression coverage and updated durable interaction documentation.

Out of scope:

- copying Turing Complete assets, source code, level content, or its full editor;
- multi-driver buses, tri-state logic, arbitrary wire crossings becoming connections, sequential logic, undo/redo history, or later prologue levels;
- changing simulation results or making animation duration, wire geometry, or screen distance affect delay;
- commits, pushes, publishing, or broad rewrites of the existing v0.2 locality prototype.

## Affected systems

- `src/circuit/`: a minimal zero-delay junction component and deterministic propagation through it;
- `src/hardware_foundations/`: trace batching, multi-item overlay rendering, compact node construction, movable terminals, and branch-point editing;
- `tests/`: deterministic junction/fan-out checks and UI assertions for concurrent animation batches and branch insertion;
- Hardware Foundations status/testing documentation where behavior materially changes.

## Invariants

- The visual graph remains the authoritative topology evaluated by the simulator.
- Each ordinary input port has at most one driver; one output or junction may fan out to many destinations.
- Connecting two driven outputs is invalid; mere wire crossings do not create electrical connections.
- Junctions and wires add zero simulation ticks, regardless of geometry.
- Basic gates retain one simulation tick of delay.
- Playback only presents a completed immutable-style trace; it cannot affect values, ticks, official test results, or sealing.
- Every moving signal follows the exact currently rendered connection segment.
- Same-ready-time events may animate together, while downstream work never appears before its prerequisites.
- Existing v0.2 DSL/locality behavior and tests remain unchanged.

## Implementation and verification

1. Model a one-input, one-output junction as a zero-delay routing node; cover fan-out, deterministic evaluation, and invalid multi-driver cases.
2. Convert trace playback into dependency-respecting parallel batches and render all active wires/components in a batch together.
3. Compact all circuit nodes, enable terminal dragging, and add small movable junction nodes with generous interaction hit areas.
4. Support inserting a branch point on an existing rendered connection, splitting that connection without changing its behavior, then wiring further branches from the new node; support empty-space segment creation and deletion where natural.
5. Update focused tests, run all repository regression suites and smoke checks, inspect representative rendered frames, review the final diff/status, and record actual limitations.

## Decisions

- Reproduce the public interaction logic of Turing Complete—drag to wire, movable wire nodes, one source with many sinks, and explicit junctions—using original Godot-native implementation and visuals.
- Use explicit junction nodes instead of inferring connectivity from geometric crossings. This keeps topology inspectable, deterministic, and editable.
- Group presentation into dependency-aware batches rather than simply playing every trace event at once. Independent branches share a batch; later gate layers remain causal.
- Keep junctions out of diagnostic gate counts and give them zero delay.

## Progress

- 2026-08-17: reviewed repository invariants, current trace/event ordering, GraphEdit topology export, existing dirty-worktree boundary, and public Turing Complete controls; active plan created before implementation.
- 2026-08-17: added zero-delay routing junctions, component-safe removal, output fan-out coverage, and presentation-only causal wave metadata without changing gate ticks.
- 2026-08-17: replaced single-event playback with parallel component/wire batches and a multi-pulse overlay. Input/gate peers animate together, zero-delay junction segments share a wire wave, and later gates remain causal.
- 2026-08-17: reduced supplied component footprints, kept 24 px port targets, made Test Bench terminals draggable, and implemented empty-space wire nodes plus direct existing-wire-to-input branch dragging with transactional rollback and atomic undo.
- 2026-08-17: fresh circuit, Hardware UI, locality simulation, and locality UI suites all passed with exit code `0`; project-hub and direct Hardware scene smoke checks passed with exit code `0`; `git diff --check` passed.
- 2026-08-17: rendered the final 20-frame sequence at 1600×900 and inspected the compact tutorial, explicit branch point, atomic undo state, scaled parallel AND/OR feedback, floating windows, and sealed component.

## Outcome

The requested interaction slice is implemented. Hardware Foundations now presents completed traces as deterministic causal waves rather than serial events; all independent same-layer work is simultaneous, while downstream gates cannot appear early. Supplied gates and external terminals are compact and movable. Outputs can fan out directly, cables can end in movable zero-delay nodes, and dragging from an existing rendered segment to a free input atomically creates a visible branch whose three displayed segments are the authoritative simulated topology.

The functional connection rules follow the public Turing Complete model relevant to this milestone—wire nodes, segments, explicit junctions, one ordinary driver with multiple sinks, and non-connecting crossings—without copying assets, code, or unrelated editor scope.

## Unresolved questions and temporary limitations

- Wire bends are electrically explicit junction nodes in this iteration, not purely decorative Bézier control points or a separate general `WireNet` data structure.
- Undo is atomic for the most recent direct wire, waypoint, or branch action, but this is not yet a general multi-action undo/redo history.
- Supplied components cannot be rotated, copied, deleted, or moved together with selected routing nodes. Player-created junctions can be moved and deleted individually.
- Multi-driver/tri-state buses, wire-cluster coloring/comments, arbitrary segment selection, and merging two already-driven networks remain intentionally out of scope.
