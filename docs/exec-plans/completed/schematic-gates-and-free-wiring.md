# Schematic gates and free wiring

## Goal

Make Hardware Foundations look and operate like a compact schematic editor: standard procedural logic-gate symbols, unmistakable green/high and red/low feedback, heavier readable wires, direct right-click deletion, and symmetric free wiring from ports, existing segments, or empty-space waypoints.

## Scope

- Replace text-filled AND/OR/NOT boxes with original Godot-drawn schematic symbols while retaining generous port hit targets and movable components.
- Draw input/output/lamp and junction components as compact schematic terminals rather than large form-like nodes.
- Use green for known high signals and red for known low signals on driven output ports and wires; keep component drawings and receiving input ports neutral.
- Increase base connection thickness and keep trace pulses on the exact displayed connection curve.
- Hold right mouse to erase every wire and component crossed by the pointer path, including external Test Bench terminals; group one stroke into one Undo action.
- Support wiring in either direction between compatible ports, output fan-out, output-to-empty and input-to-empty waypoint creation, existing-wire-to-input branching, and existing-wire-to-empty branch routing.
- Keep ordinary left-drag dual-purpose like a desktop schematic editor: drag a component body to move it and drag an available port to draw a new wire. Moving an already-connected wire end requires an explicit `Shift` + left-drag on its input port.
- Preserve explicit-junction semantics: crossings do not connect, inputs remain single-driver, and two ordinary driven networks cannot be shorted together.
- Add focused automated coverage and refresh the durable Hardware Foundations interaction documentation.

## Explicit non-goals

- No copied Turing Complete art, source code, level data, component palette, rotation system, or full editor reimplementation.
- No implicit OR from multiple drivers, tri-state buses, arbitrary output-to-output shorts, or geometric wire-length latency.
- No change to Half Adder truth-table requirements, gate delays, sealing rules, locality simulation, or animation authority.
- No general multi-action redo stack; the existing single-action undo surface may restore new deletion actions where practical.
- No commits or pushes.

## Affected files and subsystems

- `src/hardware_foundations/circuit_component_symbol.gd`: procedural schematic drawing and signal-state presentation.
- `src/hardware_foundations/circuit_graph_edit.gd`: wire hit testing, right-click deletion, and segment-origin free-routing gestures.
- `src/hardware_foundations/hardware_foundations.gd`: node construction, signal colors, waypoint/branch transactions, component deletion, and undo integration.
- `tests/test_hardware_foundations_ui.gd`: symbol geometry, signal color, free-routing, deletion, and topology-authority checks.
- Circuit tests only if the domain connectivity contract changes; ordinary wires remain model-owned and deterministic.
- Localization catalogs and Hardware Foundations status/testing documentation for new durable player-facing behavior.

## Invariants

- The visible GraphEdit topology is the circuit evaluated by `CircuitSimulator`.
- A normal net has at most one driver and any number of sinks.
- Ordinary wires and junctions remain zero latency; geometry never changes propagation time.
- Intersections are visual crossings unless an explicit movable junction exists.
- UI drawing, colors, and deletion gestures never determine simulated values.
- Playback remains parallel by causal wave and follows the exact rendered segments.
- Existing v0.2 and localization work remains intact.

## Implementation and verification

1. Add procedural schematic visuals with port-aligned AND, OR, NOT, source, observer, and junction symbols.
2. Add neutral/high/low visual-state adapters and make both persistent wires and moving trace pulses use green/high and red/low consistently.
3. Implement continuous right-button path hit testing and atomic stroke-level deletion for wires and every component class.
4. Complete symmetric waypoint/branch gestures, including input-to-empty and segment-to-empty routing, plus Shift-gated existing-end reconnection with transactional validation and rollback.
5. Extend headless UI coverage, then run circuit, Hardware UI, localization, locality regressions, startup smokes, and representative 1600×900 visual captures.
6. Inspect the final diff/status, record verification and limitations, and move this plan to `completed/`.

## Decisions and rationale

- Use standard schematic geometry drawn procedurally in Godot. This communicates gate meaning without introducing copied third-party assets or an art pipeline.
- Treat green/red as presentation of known Boolean state on output ports and wires. Component drawings and receiving input ports stay neutral, and unknown/unrun wires also stay neutral so the UI does not invent a simulated value.
- Keep free routing as explicit zero-delay junction segments. This reuses the authoritative graph model and makes every real connection visible and editable.
- Protect Test Bench terminals from deletion because they define the fixed external interface, while allowing player-owned gates and junctions to be removed.
- Disable implicit left-button disconnection. A connected sink has one unambiguous incoming segment, so `Shift` + left-drag moves that endpoint without accidentally changing output fan-out.
- Reject multiple ordinary drivers with visible feedback rather than silently combining values.

## Progress

- 2026-08-17: reviewed repository invariants, current branch/junction implementation, existing regression tests, public Turing Complete control semantics, and current Godot GraphEdit/GraphNode APIs; plan created before implementation.
- 2026-08-17: replaced text-filled gate rows with compact original procedural AND, OR, NOT, input, observer, and junction schematic visuals aligned to their real GraphNode ports.
- 2026-08-17: made known high green and known low red on driven output ports, base connections, and exact-path pulses; increased ordinary connection thickness from 6 to 9 pixels.
- 2026-08-17: added point right-click deletion with atomic undo; the 2026-08-18 follow-up below superseded its original fixed-terminal protection and point-only gesture.
- 2026-08-17: completed output/input-to-empty endpoints, segment-to-input/empty branching, and Shift-gated movement of connected input ends to free inputs, existing wires, or empty endpoints. Ordinary left-drag remains component movement/new wiring and cannot implicitly detach an existing sink.
- 2026-08-17: expanded Hardware UI coverage, ran every regression and smoke, audited both catalogs, inspected settled 1600×900 signal output, reviewed the final diff/status, and closed the plan.
- 2026-08-17 follow-up: removed the visible GraphNode panel and selected-card border from schematic parts while retaining their full drag/port hit area; component playback now uses a radial halo instead of a rectangular highlight.
- 2026-08-17 follow-up: separated device styling from signal state. Component bodies and receiving input ports now remain neutral; only driven output ports and connected wires use high/low color, while processing animation uses a fixed accent.
- 2026-08-18 follow-up: replaced point-only right-click deletion with a continuous sampled eraser. One held-right stroke removes every crossed wire and component, including Test Bench terminals, and one Undo restores the entire stroke.
- 2026-08-18 follow-up: reduced the continuous eraser from a 20-pixel-radius brush to a 2-pixel-radius cursor-tip contact patch. Wire collision includes only the visible line thickness; a near miss in surrounding empty space no longer deletes it, while denser sampling preserves reliable fast sweeps.

## Verification record

- Simulation, locality UI, circuit simulation, Hardware Foundations UI, and localization suites each completed freshly with exit code `0` and their expected `PASS` line.
- Hardware UI now covers procedural symbol presence and centered gate ports, 9-pixel base connections, red/green port state, exact-path playback, plain-left protection, Shift endpoint movement to input/wire, two-direction empty endpoints, segment-to-empty branching, cursor-tip-precise continuous right-button erasing across wires/player gates/Test Bench terminals, near-miss protection, stroke-level atomic undo, Half Adder official tests, and sealing.
- Project hub, direct Hardware scene, English startup, and hub-to-Hardware route smokes each completed with exit code `0` and no project parse/runtime errors.
- Both gettext catalogs contain exactly the 385 currently referenced semantic keys, with zero missing, duplicate, unused, or placeholder-mismatched entries.
- A settled 1600×900 Chinese frame was inspected: AND/OR/NOT shapes are distinct, A/high and its wire are green, NOT/low and lamp wire are red, known-low unused B remains red, connection paths are heavy and readable, and labels fit.
- The frameless follow-up reran all five headless suites and the project smoke with exit code `0`; a fresh 1600×900 frame confirmed that normal component panels are invisible, while the Hardware UI suite also asserts that selected panels remain transparent.
- The signal-color follow-up reran all five suites and the project smoke with exit code `0`; a fresh frame confirmed fixed neutral component bodies and receiving ports, red/green output ports, and full-path red/green wires.
- `git diff --check` completed without whitespace errors. Existing uncommitted v0.2, Hardware Foundations, and localization work was preserved; no commit or push was created.
- Godot's existing Windows `Failed to read the root certificate store` warning remained present but did not affect any exit code.

## Outcome

Hardware Foundations now presents a compact schematic rather than text-heavy GraphNode cards. Electrical state is immediately legible without changing simulation: component drawings stay neutral, while driven outputs and wires show high in green and low in red. The connection editor accepts meaningful free routing from either port direction and existing segments, while explicit junctions keep topology visible and deterministic. A held-right sweep behaves as a continuous, undoable eraser across every wire and component; intentional movement of an already-connected sink still requires Shift so ordinary left interaction does not accidentally rewrite a working circuit.

## Unresolved questions and temporary limitations

- The prototype still supplies a fixed set of gates; a component palette and copy/rotate workflow remain a later editor milestone.
- Explicit waypoints are electrically transparent junctions rather than purely decorative curve handles.
- Multi-driver and tri-state network authoring remains intentionally unavailable.
- Shift endpoint movement operates on the unambiguous single-driver input end. A fan-out output may own several segments, so changing its source still requires moving/deleting each destination segment rather than guessing which branch the player meant.
