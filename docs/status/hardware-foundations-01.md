# Hardware Foundations 01 status

> Historical milestone record. The repository has since extended this slice through the CPU Building Prologue; see [`cpu-building-prologue.md`](cpu-building-prologue.md) for current implemented behavior and limitations. The facts below describe the earlier Half Adder validation boundary and are retained as design evidence.

Hardware Foundations 01 is a small prologue gameplay-validation slice. It tests whether building a meaningful low-level circuit and sealing the player's exact solution into a reusable component creates enough ownership and abstraction payoff to justify later hardware-building levels.

## What it implements

- One compact wiring tutorial with movable external digital inputs, a lamp, compact frameless procedurally drawn AND/OR/NOT schematic symbols, generous typed port targets, editable multi-segment wires, input toggles, visible signal flow, and a five-action interaction checklist.
- One freely wired 1-bit Half Adder challenge with semantically external but movable `A`, `B`, `SUM`, and `CARRY` Test Bench terminals plus spare compact AND, OR, and NOT gates.
- A deterministic combinational circuit evaluator. The displayed GraphEdit connections are exported before every run and are the authoritative topology.
- Continuous deterministic live analysis of every component input/output and visible wire. A zero-wire port defaults to red/low; green means high, while gray means an explicit connected high-impedance or unresolved state. Edits in one frame are coalesced into one memoized graph pass after stable indexing, while unchanged circuits are not recomputed every frame.
- Zero-delay ordinary wires and routing junctions, plus a uniform one simulation tick for every active AND, OR, and NOT gate. Screen geometry and component position never affect delay.
- Debug runs for editable `A`/`B` values and a fixed official truth table with expected-versus-actual `SUM`/`CARRY` evidence.
- Automatic readable layouts; ordinary-left-drag component movement and new wiring; output fan-out; multiple distinct segments per input/output port; connection snapping; generous ports; valid-target highlighting; cable cancellation; atomic route undo; Clear Wires; and Auto Layout. Ordinary left-drag cannot detach an existing sink; `Shift` + left-drag explicitly moves that connected input end.
- Turing-style functional wire editing: release either an output or an unconnected input in empty space to create a movable routing endpoint; drag from an existing segment to a free input or empty space to split/extend it; Shift-move a connected input onto another input, an existing segment, or a new endpoint; and treat crossings without a junction as electrically separate.
- Desktop-style schematic editing: Shift-click or Shift-drag toggles multi-selection; selected nodes move together; `Ctrl+Z`/`Ctrl+Y` and `Ctrl+Shift+Z` undo/redo complete actions; `Ctrl+C`/`Ctrl+V` copies and pastes selected player gates/wire nodes plus internal segments. External Test Bench terminals and boundary wires are intentionally excluded from the clipboard.
- Precise continuous erasing: hold right mouse and sweep the cursor tip directly across a wire or component, including external Test Bench terminals. The hit patch is limited to the top of a standard pointer rather than a wide brush; dense path sampling still prevents fast movement from skipping thin wires, and one complete stroke is one atomic Undo action.
- Every component input and output port continuously exposes its electrical state: low is red, high is green, and explicit high impedance/unresolved is gray. Zero incoming segments resolve low; one or more connected `Z` drivers remain high impedance unless another active value drives the port. Matching drivers are legal; simultaneous low/high drivers report a short circuit, while structural same-tick feedback reports a circular dependency. Neutral component bodies do not change color. Base connections are heavier than the Godot default, while moving pulses still follow the exact displayed curve.
- The procedural gate symbols carry compact lowercase English `and`, `or`, and `not` names while the surrounding interface remains localized through semantic keys.
- Completed circuit traces containing deterministic component-processing and wire-signal events with presentation-only causal wave indices. Every signal animation uses the exact current `GraphEdit.get_connection_line()` curve.
- Parallel trace playback: all components ready in one causal layer process together, all segments of a zero-delay branched network travel together, and downstream gates remain later. Distinct procedural input, AND, OR, NOT, and lamp/output effects render simultaneously for the active wave, using a soft symbol halo rather than a rectangular processing frame.
- Mission and Test Bench as coexisting desktop-style embedded windows. They move, resize, minimize from their title bars, close independently, and reopen/restore from the bottom taskbar.
- A gated sealing moment after a fresh four-case pass. The verified graph collapses through a procedural encapsulation effect into one movable player-owned `HalfAdder` component exposing `A`, `B`, `SUM`, and `CARRY`.
- An in-memory `ReusableHalfAdder` that owns a cloned circuit snapshot and evaluates through the same circuit simulator after the original graph is gone.
- A project hub that opens either Hardware Foundations 01 or the preserved v0.2 Cache Locality Lab.

## Architecture contract

```text
Displayed GraphEdit connections
  -> exported LogicCircuit
  -> CircuitSimulator
  -> completed CircuitTrace + outputs + diagnostic metrics
  -> read-only exact-path/component playback

fresh four-case official pass + unchanged topology signature
  -> cloned circuit snapshot
  -> ReusableHalfAdder(A, B -> SUM, CARRY)
```

The official result is never produced by a hidden Half Adder truth function. The Test Bench knows expected values, but actual outputs always come from the current player graph. `CircuitAnalyzer` supplies both the continuous port state and the electrical result consumed by `CircuitSimulator`; there is no separate UI truth solver. Unconnected spare gates remain legal, while player-created shorts or combinational cycles anywhere in the connected topology block execution.

## Official cases

| A | B | SUM | CARRY |
| ---: | ---: | ---: | ---: |
| 0 | 0 | 0 | 0 |
| 0 | 1 | 1 | 0 |
| 1 | 0 | 1 | 0 |
| 1 | 1 | 0 | 1 |

Functional correctness across all four cases is the only completion gate. Active gate count and longest propagation ticks are shown as diagnostics and are not optimization objectives.

## Intentional temporary limitations

- Only combinational input, output/lamp, AND, OR, and NOT components are supported. High impedance is modeled, but no tri-state switch, delay element, latch, or legal feedback component is placeable yet.
- `HalfAdder` exists only in session memory. There is no persistent component library or save/load format.
- The sealed component cannot yet be placed inside another player circuit; no Full Adder, ALU, sequential logic, memory, CPU, or Cache prologue content is implemented.
- Components are supplied and automatically placed; this slice validates topology construction, not palette search, rotation, arbitrary new gate placement, inventory budgets, or cross-level clipboard persistence.
- Undo/redo history is session-only. It covers routes, endpoints, multi-node movement, deletion, Clear Wires, Auto Layout, and paste, but is not serialized with the circuit.
- The floating windows do not persist their layout between sessions.
- Visuals are Godot-native procedural prototype feedback, not a production art pass.

## Validation question

Automated checks establish causal correctness and interaction state, not fun. Manual playtesting must determine whether wiring feels direct, propagation is readable, the Half Adder feels discovered rather than prescribed, sealing feels like ownership rather than a completion dialog, and this loop is worth extending to a separately scoped Full Adder or ALU iteration.
