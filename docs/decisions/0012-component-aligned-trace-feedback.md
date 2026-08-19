# ADR 0012: component-aligned trace feedback

- Status: Accepted
- Date: 2026-08-19

## Context

Playback had become visually richer than the displayed circuit. Hardware Foundations drew a radial halo and a second approximate gate, RAM, ALU, or computer model above the real component. The Cache Locality Lab routed its packet through a generic two-turn orbit and drew another radial indicator inside every device. Those effects preserved simulation correctness, but they implied component geometry and internal behavior that the player had not built and that often disagreed with the visible symbol.

Current public Turing Complete material emphasizes consistent component shapes, standard wide-gate symbols, larger readable pins, visible pin labels, and state feedback on the actual component (including a RAM cursor). Its controls also expose explicit run, step, and reset actions. We adopt those presentation outcomes without copying proprietary art, source, levels, or exact layout.

References:

- <https://steamcommunity.com/app/1444480/announcements/> (`Turing Complete 2 patch notes`)
- <https://turingcomplete.wiki/wiki/Controls>
- <https://turingcomplete.wiki/wiki/Components>

## Decision

- The Hardware Foundations trace overlay renders wire data only. It never renders a component, component halo, or substitute internal model.
- Basic gates and terminals animate on their real procedural geometry: data advances on the existing input lead, the existing body contour receives a fixed processing accent, and data leaves on the existing output lead. Live port colors remain authoritative and unchanged.
- Reusable and stateful components animate their actual displayed row surfaces and state text. A sealed abstraction does not reveal invented internals during playback.
- Cache Locality packets use a short entry-to-body-to-exit lane contained by the actual displayed device. The active device card and its real state label provide processing feedback; there is no orbit or radial indicator.
- Causal-wave grouping, processing duration, exact rendered wire curves, and simulation ticks remain unchanged.

## Alternatives considered

- Redraw more accurate duplicate component models in the overlay: rejected because any duplicate can drift from the actual component and still implies hidden internals.
- Remove component dwell entirely: rejected because players still need to distinguish wire transfer from component work.
- Color the whole component red or green: rejected because signal value belongs to ports and wires; processing is a separate fixed accent.

## Consequences

- Playback is quieter and easier to map back to the circuit the player built.
- Improving a component's displayed geometry automatically improves its processing animation instead of requiring a second overlay model.
- High-level abstractions intentionally expose only their interface and visible state until a future design explicitly adds truthful internal inspection.
- This supersedes only the generic orbit/radial portions of ADR 0002 and ADR 0003; their causality, single-focus, and floating-instrument decisions remain accepted.
