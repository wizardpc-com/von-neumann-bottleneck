# Hardware Foundations 01 execution plan

## Goal

Validate one opening-game hypothesis: constructing a meaningful low-level circuit and sealing that exact player-owned topology into a reusable `HalfAdder` creates a satisfying progression from wiring to abstraction.

## Scope and non-goals

In scope:

- one compact wiring tutorial using inputs, a lamp, AND, OR, NOT, ports, and editable wires;
- one free-topology Half Adder workbench with a fixed external Test Bench;
- deterministic evaluation of the visual graph with zero-delay wires and one tick per basic gate;
- debug runs, the four fixed official truth-table cases, expected-versus-actual evidence, and clear failures;
- sealing a passing player circuit into an in-memory reusable `HalfAdder` with `A`, `B`, `SUM`, and `CARRY` ports;
- procedural wiring, signal-flow, component-processing, and encapsulation feedback;
- a small project entry screen that preserves access to the existing v0.2 locality prototype;
- headless simulation and UI integration coverage plus durable documentation updates.

Out of scope:

- Full Adder, ALU, latch, register, RAM, CPU, Cache, later prologue levels, saves, a general HDL, a persistent component library, production art, performance objectives, Profiler integration, commits, tags, pushing, or publishing.

## Affected systems

- new `src/circuit/` deterministic logic-circuit model, simulator, trace, official Test Bench, and sealed component snapshot;
- new `src/hardware_foundations/` playable scene and trace overlay;
- a minimal `src/ui/prototype_hub.*` entry scene while retaining `src/ui/main.tscn` as the preserved v0.2 locality lab, with only hub navigation and shared window minimization added;
- new circuit simulation/UI tests and the repository testing guide;
- architecture and status documentation only where the implemented facts change.

## Invariants

- The visual GraphEdit connections are converted directly into the authoritative circuit definition; no hidden Half Adder solution decides success.
- Identical topology and input values produce identical results and canonical traces.
- Basic AND, OR, and NOT gates each add one simulation tick; ordinary wires and screen distance add none.
- Playback consumes a completed trace and never mutates or recomputes the result.
- Every animated transfer follows the current rendered GraphEdit connection curve.
- The external Test Bench owns A/B stimuli and expected outputs and is not placeable player hardware.
- The existing v0.2 DSL/locality subsystem and its 321/105-cycle regression behavior remain intact.
- The implementation stays Half-Adder-specific where a broader abstraction is not required by this slice.

## Implementation

1. Add a typed circuit definition with components and wires, strict port validation, single-driver inputs, deterministic cloning, and canonical topology signatures.
2. Add a deterministic combinational evaluator that derives values and gate ticks from the graph, reports unresolved/cyclic/invalid circuits, and emits immutable-style wire and component trace events.
3. Add a pure Half Adder Test Bench for debug and official cases, and an encapsulated component that evaluates a cloned passing circuit through named port bindings.
4. Build a compact tutorial workbench with automatic layout, generous port rows, typed connection snapping, clear drag/valid/invalid/remove/reconnect feedback, input controls, and a short interaction checklist.
5. Build the Half Adder challenge with fixed Test Bench terminals, a deliberately non-template gate inventory, debug and official result evidence, and no performance Profiler.
6. Animate each trace stage through the exact displayed connection curve, then show distinct AND, OR, NOT, input, and lamp/output processing feedback without changing simulation time.
7. Gate sealing on fresh official success; snapshot the authoritative circuit and present a clear component-collapse/reveal moment plus functional post-seal checks.
8. Add a minimal launcher for Hardware Foundations and the preserved locality lab; update targeted documentation.

## Decisions

- Gates are pre-placed in a readable automatic layout but remain movable; the player decides only meaningful topology.
- The Half Adder inventory includes spare basic gates so the challenge does not imply one mandatory placement or wire template.
- A connection may fan out from one output, but each input port has at most one driver.
- Invalid, incomplete, or cyclic graphs fail with structural feedback; failures do not reveal the construction formula.
- Encapsulation is an in-memory circuit snapshot with named bindings, not a generalized serialization or HDL ecosystem.
- Diagnostic gate count and propagation ticks may be shown after a run, but only truth-table correctness gates completion.

## Verification

- new circuit headless test: AND/OR/NOT, connectivity validation, deterministic signatures, zero-delay wires, official truth table, valid and invalid player topologies, and sealed behavior;
- new Hardware Foundations UI headless test: tutorial interactions, authoritative visual connection export, official pass/fail, exact curve path lookup, seal gating, and encapsulated re-check;
- all existing simulation and UI commands from `docs/development/testing.md`;
- project startup smoke through the new launcher;
- representative capture and frame inspection for port readability, signal traversal, per-gate processing, failure evidence, and sealing moment;
- final `git diff --check`, targeted diff review, and `git status --short --branch --untracked-files=all`.

## Progress

- 2026-08-17: repository constraints, existing v0.2 implementation/tests, planning threshold, and Godot GraphEdit connection APIs reviewed; plan created before implementation.
- 2026-08-17: deterministic typed circuit graph, zero-delay wiring, one-tick gates, Test Bench, official report, and immutable-style `ReusableHalfAdder` snapshot implemented with focused headless coverage.
- 2026-08-17: tutorial, freely wired Half Adder challenge, exact-curve trace playback, distinct gate effects, sealing effect, final component reveal, and preserved-prototype hub implemented.
- 2026-08-17: after direct interaction feedback, Mission and Test Bench were moved from a fixed sidebar into coexisting desktop-style floating windows with drag, resize, minimize, close, focus, and taskbar restore. Automatic layouts were shifted to keep the initial circuit unobstructed.
- 2026-08-17: rendered tutorial, active wire, AND processing, encapsulation, and sealed-component frames inspected at 1600×900; layout and causal feedback were iterated from those captures.
- 2026-08-17: fresh circuit, Hardware UI, existing locality simulation, and existing locality UI tests all passed with exit code `0`; hub startup and direct Hardware scene smoke checks also passed with exit code `0`. `git diff --check` reported no whitespace errors.

## Outcome

The scoped playable sequence is complete without implementing later prologue hardware. The authoritative visual circuit drives debug and official results; the passing topology is preserved inside the reusable component; presentation follows exact wires and dispatches distinct gate effects; and the workspace supports direct circuit manipulation alongside movable, resizable, minimizable Mission and Test Bench windows. The next decision requires manual playtesting rather than more scope in this milestone.

No commit, tag, push, or publication was created; the task explicitly left delivery changes uncommitted.

## Temporary limitations to document

- only combinational AND/OR/NOT circuits are supported;
- no persistent component-library save/load;
- no nested placement of `HalfAdder` inside a larger circuit yet;
- no undo history beyond straightforward wire removal/reset controls;
- visuals are procedural prototype feedback, not a production art pass.

## Unresolved items

- None blocking. Manual play-testing will decide whether this interaction is worth extending to Full Adder or ALU work in a later task.
