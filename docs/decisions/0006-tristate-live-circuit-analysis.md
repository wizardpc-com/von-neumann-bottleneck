# ADR 0006: shared tri-state live circuit analysis

## Status

Accepted for Hardware Foundations 01. The zero-wire default described below is superseded by ADR 0007; explicit connected high impedance remains valid.

## Context

Players need to understand a circuit before pressing Run. Coloring only source outputs leaves gate inputs and floating topology unexplained, while using a separate UI preview solver risks disagreeing with official tests. Allowing several segments on one port also requires explicit electrical semantics: matching drivers, high impedance, conflicting drivers, and feedback cannot be treated as the same condition.

The public [Turing Complete switch documentation](https://turingcomplete.wiki/wiki/Component/8_Bit_Switch) permits shared wiring when no more than one distinct active value is driven and notes that disabling a switch does not remove a circular dependency. Its [controls documentation](https://turingcomplete.wiki/wiki/Controls) distinguishes segments, clusters, and wire nodes. This project adopts the relevant electrical outcomes while keeping its own explicit segment/junction editor and procedural presentation.

## Decision

- Define language-neutral low, high, and high-impedance states, plus an internal conflict result. Present low as red, high as green, and high impedance as gray.
- Resolve every input from all incoming segments. Ignore high-impedance drivers, accept any number of matching low or matching high drivers, and report a short circuit when both driven values are present. Never silently OR or prioritize conflicting outputs.
- Detect same-tick combinational feedback structurally with deterministic depth-first analysis. Mark every member of the cycle unresolved and reject execution; a future explicit delay/state component may define legal feedback separately.
- Use one `CircuitAnalyzer` for live colors and `CircuitSimulator` execution. The analyzer sorts IDs/segments once for stable ordering, indexes the wires, and then memoizes one graph evaluation for the current one-output component set.
- Recompute after topology or Test Bench input changes, coalesce several edits in one frame into one deferred pass, and skip analysis when the topology/input signature is unchanged. Do not poll the solver from `_process()`.
- Color every visible input/output port from the live result and every wire from its source state. Keep component bodies neutral. Render an internal conflict as unresolved gray plus an explicit localized short-circuit diagnostic because the player-facing palette has exactly three electrical colors.
- Keep exact duplicate segments invalid, but permit multiple distinct segments on either side of a port. Ordinary wire and junction latency remains zero and geometry remains presentation-only.

## Consequences

- The state visible before Run and the state used by official truth-table evaluation cannot diverge through separate solvers.
- Explicit high-impedance drivers and unresolved feedback are visible as gray without inventing a fourth electrical color; diagnostics distinguish a legal high-impedance state from a short or cycle. ADR 0007 later changes only the zero-wire case to low/red.
- Output fan-out, matching shared drivers, short circuits, and circular dependencies are deterministic and independently testable.
- Idle rendering has no circuit-analysis cost; one logical edit burst causes at most one analysis pass.
- A player-placeable tri-state switch, explicit delay, stateful components, bus widths, net-level editing, and short-circuit animation remain future work rather than implied features.
