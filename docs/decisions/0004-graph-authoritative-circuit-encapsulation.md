# ADR 0004: visual graph authority and HalfAdder encapsulation

## Status

Accepted for Hardware Foundations 01.

## Context

The prologue slice must test genuine circuit construction. A visual puzzle that checks success through hidden Half Adder logic would invalidate that hypothesis, while forcing the existing cache-locality simulation into a premature universal hardware model would risk both prototypes.

The same slice must also turn a passing low-level circuit into a reusable abstraction without designing a complete HDL, serializer, or future component ecosystem.

## Decision

- Keep the new combinational circuit model in `src/circuit/`, independent from the v0.2 DSL/locality simulator.
- Export the current GraphEdit connections into a fresh `LogicCircuit` before every debug or official run. That exported circuit is the only actual-output source.
- Use deterministic backward-reachable evaluation from output probes, one tick for each active basic gate, and zero ticks for ordinary wires and explicit routing junctions.
- Emit a completed `CircuitTrace` before UI playback. Deterministic `visual_step` metadata groups causally ready events for parallel presentation without affecting simulation ticks.
- Let the Test Bench own stimuli and expected truth-table values while keeping its terminals semantically and visually distinct from player gates; terminals remain movable for schematic layout.
- Represent a visible branch as a zero-delay one-input/one-output junction whose output may fan out. A geometric crossing is not a connection. ADR 0006 later extends an ordinary input to accept multiple distinct segments under explicit tri-state resolution, short-circuit, and cycle rules.
- Unlock sealing only after all official cases pass for the unchanged topology signature.
- Implement `ReusableHalfAdder` as a cloned circuit snapshot plus the fixed named interface `A`, `B`, `SUM`, `CARRY`.

## Consequences

- Valid alternative topologies can pass without a prescribed wiring template.
- Players may route multi-segment wires and branch from existing segments while every visible segment remains part of the exported authoritative graph.
- The sealed component preserves the player's implementation rather than replacing it with hidden truth-table logic.
- The locality prototype and Hardware Foundations can evolve independently until evidence justifies shared abstractions.
- Unused supplied gates do not make a circuit invalid, but incomplete, electrically conflicting, cyclic, or unsupported paths fail deterministically.
- Persistence, nested reusable-component placement, broader logic families, and sequential timing remain explicit future work rather than implied capabilities.
