# Tri-state live circuit analysis

## Goal

Make Hardware Foundations continuously explain the electrical state of the circuit: every input and output port is red for low, green for high, or gray for high impedance; AND/OR/NOT symbols carry their English names; multiple wires may share a port; conflicting drivers and combinational feedback are diagnosed using the subset of Turing Complete's public rules relevant to this prototype.

## Scope

- Add a language-neutral low/high/high-impedance signal model plus an internal conflict state.
- Compute every component input/output and visible wire after topology or Test Bench input changes.
- Permit multiple distinct wires on the same input or output port while continuing to reject exact duplicate segments and invalid endpoints.
- Resolve multiple drivers by ignoring high impedance, accepting one distinct driven value, and reporting a short circuit when both low and high drive the same input network.
- Detect structural combinational cycles independently of current signal values.
- Keep official/debug execution, live colors, diagnostics, traces, and encapsulation on one deterministic electrical model.
- Draw the lowercase English labels `and`, `or`, and `not` inside the existing procedural gate symbols.
- Extend Simplified Chinese and English presentation catalogs, automated tests, and durable architecture/status documentation.

## Explicit non-goals

- Do not add a tri-state switch, delay line, latch, register, bus-width system, RAM, CPU, or later prologue level.
- Do not model analog current, voltage, heat, or physical wire length.
- Do not copy Turing Complete assets, source code, exact UI layout, or unrelated controls.
- Do not allow animation timing to affect electrical results.
- Do not redesign the existing locality prototype.

## Reference behavior and decisions

- The public [Turing Complete switch documentation](https://turingcomplete.wiki/wiki/Component/8_Bit_Switch) says multiple outputs may share a wire when at most one distinct driven value is present, and that disabled outputs do not remove circular dependencies. This iteration adopts those electrical outcomes.
- The public [Turing Complete controls documentation](https://turingcomplete.wiki/wiki/Controls) distinguishes wire segments, clusters, and movable wire nodes. The existing explicit junction/segment editor remains the visual topology rather than introducing a hidden netlist.
- Public player explanations consistently describe a circular dependency as an output feeding its own same-tick dependency path; a delay breaks it. This prototype detects and rejects such cycles but intentionally does not add the later delay component yet.
- High impedance means undriven/floating. Because this milestone has no tri-state switch, players primarily see gray on unconnected or cycle-unresolved ports. Conflict remains an internal fourth analysis result, is rendered as unresolved gray at the affected port, and is explained explicitly as a short circuit rather than pretending it is high impedance.
- Gate propagation uses conservative three-state logic: NOT preserves Z; AND is low if any input is low, high only if all inputs are high, otherwise Z; OR is high if any input is high, low only if all inputs are low, otherwise Z. Required observer paths still require complete wiring for official success.
- Unconnected spare gates remain legal. A player-created short circuit or combinational cycle anywhere in the connected topology is a live diagnostic and blocks execution.

## Affected files and subsystems

- `src/circuit/logic_signal.gd`: language-neutral signal values and resolution helpers.
- `src/circuit/circuit_live_state.gd`: typed immutable-style analysis result.
- `src/circuit/circuit_analyzer.gd`: deterministic stable-indexed, memoized all-port evaluation, multi-driver resolution, and cycle detection.
- `src/circuit/logic_circuit.gd`: relaxed multi-connection validation.
- `src/circuit/circuit_simulator.gd`: official/debug traces consume the shared analysis rather than a separate single-driver solver.
- `src/hardware_foundations/circuit_graph_edit.gd`: three-state wire presentation.
- `src/hardware_foundations/circuit_component_symbol.gd`: English gate labels.
- `src/hardware_foundations/hardware_foundations.gd`: coalesced event-driven live refresh and three-color input/output ports.
- `tests/test_circuit_simulation.gd` and `tests/test_hardware_foundations_ui.gd`: deterministic signal, short, cycle, live-color, multi-wire, and label coverage.
- `localization/*.po` and focused architecture/status/testing documentation.

## Invariants

- Simulation remains deterministic and independent from UI and animation.
- Ordinary wires and junctions remain zero latency; geometry never affects delay.
- The displayed connection list remains authoritative topology.
- Exact duplicate segments remain invalid, but an input may receive multiple distinct segments and an output may fan out without an arbitrary limit.
- A conflict is never silently ORed or coerced to low/high.
- Official Half Adder completion still requires all four truth-table cases to pass.
- Existing v0.2 locality behavior remains unchanged.

## Implementation and verification steps

1. Add the tri-state result and deterministic analyzer with direct unit coverage.
2. Refactor `CircuitSimulator` to reuse the analyzer for multi-driver resolution, missing inputs, cycle/short diagnostics, ticks, and trace events.
3. Relax graph connection validation and make live recomputation coalesced and event-driven.
4. Apply low/high/Z colors to every visible input/output port and wire, preserving component body colors and playback overlays.
5. Add English gate labels and localized live diagnostics/legend.
6. Run circuit, Hardware UI, localization, locality simulation/UI regressions, startup smoke, and a representative visual capture.
7. Inspect the final diff/status, update durable documentation, and move this plan to `completed/`.

## Progress

- 2026-08-18: inspected repository rules, current circuit model/UI/tests, and public Turing Complete wiring, high-impedance, short-circuit, and circular-dependency behavior.
- 2026-08-18: added the shared signal model and deterministic analyzer, relaxed distinct multi-wire connections, and made official/debug execution consume the same result.
- 2026-08-18: added coalesced topology/input-triggered live refresh, three-color port/wire presentation, English gate labels, localized diagnostics, and automated short/cycle/performance coverage.
- 2026-08-18: all five simulation/UI/localization suites and the startup smoke passed with exit code 0. A 1600×900 capture confirmed neutral bodies, lowercase gate names, red/green live signal paths, and gray unconnected ports. Final whitespace/status audit remains.
- 2026-08-18: final stale-claim, whitespace, diff, and worktree-status audits passed. The plan is complete and retained under `exec-plans/completed/`.

## Unresolved questions and temporary limitations

- A future tri-state switch will be needed before players can intentionally build shared buses; this task only establishes the electrical state and diagnostics.
- Short-circuit visualization is intentionally a gray unresolved port plus explicit diagnostic, because the requested port palette has exactly three logical colors. A later UX pass may add a non-state warning badge without changing electrical colors.
- Delay components and stateful feedback are deferred; all current cycles are same-tick combinational errors.
