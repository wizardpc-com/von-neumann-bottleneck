# ADR 0008: hierarchical temporal CPU prologue

## Status

Accepted for the CPU Building Prologue prototype.

## Context

Hardware Foundations 01 established that the displayed graph can be authoritative and that a verified Half Adder can preserve player ownership. Extending directly to a CPU raises three risks: replacing player-built abstractions with hidden success logic, making the player repeat identical bit slices, or prematurely designing a universal HDL/clocked-machine platform.

The intended learning sequence needs both combinational composition and retained state, while preserving deterministic simulation, zero-latency ordinary wires, exact-path parallel presentation, and the independent v0.2 Cache Locality Lab.

## Decision

- Use a dependency-aware session campaign with an arithmetic branch (`FullAdder` → `ALU1`) and a storage branch (`SRLatch` → `Register1` → `RAM2x4`). Unlock the four-bit accumulator CPU only after both branches pass.
- Require every construction challenge to pass a fixed external Test Bench against the exported visible graph. Bind completion to its canonical topology signature and invalidate that evidence after edits.
- Generalize reusable components only as far as this hierarchy needs: named fixed-width ports, cloned source snapshot/signature, source level, generated-from signatures, and small metadata. Do not define a general HDL or serialization format.
- Generate `ALU4` and `Register4` wrappers after the corresponding one-bit design passes. Record their provenance; do not require four identical construction exercises.
- Add `PrologueSimulator` as a deterministic bounded temporal evaluator beside the existing one-bit analyzer/simulator. Basic gates add one tick; wires and junctions add none. Let only the latch challenge opt into raw NOR feedback.
- Define register, two-word RAM, and computer state transitions at an external Test Bench step boundary. Carry explicit runtime state between steps and complete the whole result/event trace before UI playback.
- Model the prologue CPU as a four-bit accumulator with external `LOAD_IMM`, `ADD_IMM`, `LOAD_MEM`, and `STORE_MEM` instructions. Keep instruction fetch, program counter, general ISA, Cache, and Profiler outside this milestone.
- Reuse the sealed `TinyComputer` in a locked final LOAD/STORE bridge. The bridge teaches CPU/RAM transfer and hands off to the existing locality lab without asking the player to repeat the CPU topology.
- Group presentation events into causal waves. Independent components and every segment of a zero-delay routed net animate in parallel along the exact displayed curves; presentation timing never changes simulation ticks or state.

## Consequences

- The player can see their own Half Adder and later abstractions become the vocabulary of larger designs, while official correctness remains graph-derived.
- The campaign contains real topology decisions at each new abstraction and omits repetitive four-slice labor.
- Sequential behavior is deterministic and testable but intentionally simplified. It is not evidence of realistic clocking, analog behavior, or a complete CPU.
- Reusable definitions and completion state are in memory only. Persistence, editable nested wrapper internals, arbitrary widths, and recursive user-defined components require a later decision.
- The locality DSL/`SimulationCore` remains unchanged and independent; the prologue's LOAD/STORE program is conceptual preparation, not a replacement implementation.
