# Turing-style component shapes and pin animation

## Goal

Give Hardware Foundations one coherent schematic language: standard logic-gate silhouettes, visibly distinct level input/output terminals, and compact higher-level modules whose processing animation travels from the real input pins through the displayed function surface to the real output pins.

## Scope

- Procedural shapes for basic gates, level terminals, constants, lamps, reusable arithmetic parts, routing/control parts, registers, RAM, and the tiny computer.
- Port-value-aware input/body/output animation on those exact displayed surfaces.
- RAM address cursor feedback when the event exposes a known address.
- Removal of the duplicate settled full-wire layer so one electrical segment appears as one cable.
- Focused automated and visual regression coverage plus durable presentation documentation.

## Non-goals

- No copied Turing Complete art, source code, exact assets, or proprietary layout.
- No simulation, electrical-resolution, propagation-delay, circuit-topology, level-progression, or scoring changes.
- No exposure of hidden subcircuits inside sealed components.
- No full decorative art pass and no change to the Cache Locality Lab device model in this iteration.

## Affected files and subsystems

- `src/hardware_foundations/circuit_component_symbol.gd`: refine gate and terminal shapes and value-aware pin animation.
- `src/hardware_foundations/circuit_module_row.gd`: add the actual procedural row surface used by higher-level components.
- `src/hardware_foundations/circuit_graph_edit.gd` and `circuit_trace_overlay.gd`: retain one settled full-path renderer and a short centered playback token.
- `src/hardware_foundations/hardware_foundations.gd`: construct module rows and pass completed event values into their animations.
- Hardware UI/prologue tests and the component-aligned animation decision/testing documentation.

## Invariants

- Simulation and traces remain authoritative; drawing consumes completed event data only.
- Equal causal waves still animate in parallel.
- Ordinary wire geometry and visual route length add no simulation latency.
- Wire pulses continue to use the exact GraphEdit connection curve.
- Red, green, and gray express signal state only; the neutral component body does not become a value indicator.
- Selection and processing feedback remain independent.
- A higher-level component shows only its public function, ports, and truthful visible state.

## Decisions

- Follow publicly documented Turing Complete 2 outcomes—consistent shapes, IEEE-style wide gates, larger input pins, hover-readable pin labels, and a RAM access cursor—without tracing or importing its assets.
- Use larger terminal pads and short, thick pin leads while leaving GraphEdit's generous interaction hit targets unchanged.
- Use a fixed cyan processing accent for the body path; moving pin tokens carry the event's red/green/gray signal color and optional word value.
- Let GraphEdit render each complete settled cable exactly once; playback draws only a short moving tail on that same curve.
- Represent encapsulated components as compact functional modules: adder sigma, mux routing wedge, ALU arithmetic block, decoder fan-out, register latch, truthful two-word-by-four-bit RAM grid/cursor, control fan-out, and computer datapath split.
- Implement the module as the real per-port row control so its pins remain aligned with GraphNode ports at every zoom and layout.

## Implementation and verification

1. Refine basic gate, terminal, lamp, constant, and junction silhouettes and their exact pin stages.
2. Add functional module rows with kind-specific geometry and pin/value animation.
3. Route each playback event's actual input and output values into the displayed component surface.
4. Add assertions for larger distinct terminals, value-colored moving pin tokens, function-specific module geometry, and RAM cursor activity.
5. Remove the redundant complete signal-wire overlay and verify one centered native cable plus a short trace token.
6. Run all relevant headless suites and startup smokes, capture representative gate/arithmetic/RAM/CPU frames, inspect logs, links, diff, and status.

## Progress

- 2026-08-19: reviewed the current component-aligned implementation and official public Turing Complete 2 notes. Confirmed the reference boundary: consistent updated shapes, IEEE wide gates, larger input pins, hover pin labels, and RAM address cursor feedback.
- 2026-08-19: replaced generic high-level text rows with function-specific module surfaces and routed actual event input/output values through their real port rows. Corrected RAM to a two-word-by-four-bit grid and constrained state events to their real output port.
- 2026-08-19: removed the duplicate complete signal-wire drawing layer after visual inspection confirmed the stacked-wire artifact. GraphEdit now owns the one settled cable; trace playback adds only a short centered marker.
- 2026-08-19: all eight headless suites passed together in the final source state. Default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality smokes exited `0`. Settled/tutorial-processing, storage, and CPU frames were inspected; only the known Windows root-certificate warning remained in final logs. Local Markdown links and `git diff --check` passed.

## Unresolved questions and limitations

- Public material does not specify exact animation timing or geometry. The pin-to-body-to-pin timing is therefore a project-specific readability design, not a claim of exact Turing Complete behavior.
- Multi-bit modules show the event word at the active output pin; they do not visualize individual bits inside the sealed body.
- Pin labels are compact on the surface and complete in the component tooltip; per-pin hover bubbles are not yet implemented.

## Outcome

Hardware Foundations now uses one procedural schematic vocabulary from basic gates through the CPU. Processing visibly carries the event's actual values through the real public interface, RAM exposes truthful address-row feedback, and one electrical segment appears as one settled cable. Simulation, causal parallelism, topology authority, and zero wire latency are unchanged.
