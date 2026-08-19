# Component-aligned trace animation

## Goal

Make every playback effect agree with the component that is actually displayed. Signal movement remains visible, but the UI must not draw a second approximate gate/device model, an unrelated radial halo, or an invented circular route inside a component.

## Scope

- Hardware Foundations wire and component playback.
- Cache Locality Lab packet and component-processing playback.
- Focused automated and visual regression coverage.
- Durable animation documentation whose current behavior changes.

## Non-goals

- No simulation, tick, propagation-delay, electrical-state, test-bench, or scoring changes.
- No copied Turing Complete art, source code, exact layout, or proprietary assets.
- No full component art pass and no new future CPU/cache simulation model.

## Affected files and subsystems

- `src/hardware_foundations/circuit_trace_overlay.gd`: wire-only trace overlay.
- `src/hardware_foundations/circuit_component_symbol.gd`: processing feedback on the real procedural symbol.
- `src/hardware_foundations/hardware_foundations.gd`: dispatch activity to the displayed symbol or generic component rows.
- `src/ui/trace_overlay.gd` and `src/ui/main.gd`: remove the generic orbit and use the actual device body/port route.
- Hardware/UI tests plus architecture, testing, and decision documentation.

## Invariants

- Simulation and traces are authoritative; animation consumes completed events only.
- Equal causal waves remain parallel.
- Ordinary wire geometry adds no simulation latency.
- Wire pulses follow the exact rendered connection curve.
- Live red/green/gray port state is not replaced by processing color.
- Selection remains independent from processing feedback.

## Decisions

- Use public Turing Complete interaction outcomes as the reference boundary: consistent component shapes, readable pins, visible circuit state, and simulation controls. Do not infer or copy hidden implementation details.
- Hardware wire pulses stay in the shared overlay; component activity moves onto the real symbol or its real generic row surface.
- Locality packets traverse entry, body center, and exit of the displayed device without circular detours; the displayed device itself supplies processing emphasis.
- Component captions remain in the existing trace/status UI instead of floating over an invented symbol.

## Implementation and verification

1. Remove duplicate component rendering and radial effects from Hardware Foundations.
2. Add exact-geometry activity phases to procedural gates, terminals, and junctions.
3. Pulse the actual generic component rows for reusable/stateful hardware.
4. Remove the Cache Locality Lab processing orbit and radial indicator.
5. Update focused tests to assert wire-only overlays and real-surface activity.
6. Run all relevant headless suites, both startup modes, diff/log checks, and inspect fresh mid-animation captures.

## Progress

- 2026-08-19: inspected repository rules, current playback code/tests, and public Turing Complete controls, component catalog, official site, and current patch notes. Confirmed the mismatch comes from duplicate overlay models and generic radial/orbit effects.
- 2026-08-19: converted Hardware Foundations to a wire-only trace overlay; basic gates and terminals now animate their real geometry, while reusable/stateful parts pulse their actual row surfaces and state text.
- 2026-08-19: replaced the Cache Locality two-turn orbit and radial indicator with a short lane contained by each displayed device. Component cards remain the only strong processing surface.
- 2026-08-19: all eight headless suites and four startup smokes passed. Fresh NOT, RAM, CPU, and locality frames were inspected; log scanning found only the known root-certificate warning, local Markdown links passed, and `git diff --check` passed.

## Unresolved questions and limitations

- This iteration aligns feedback with the existing displayed shapes. A later art pass may improve those shapes, but must keep the same animation/simulation boundary.

## Outcome

Playback now communicates wire transfer and component work without drawing structures the player did not build. Parallel causal waves, exact rendered curves, state commit boundaries, and deterministic simulation remain unchanged.
