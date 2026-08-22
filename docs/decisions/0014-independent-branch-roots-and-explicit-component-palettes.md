# ADR 0014: independent branch roots and explicit component palettes

## Status

Accepted for the current CPU Building Prologue.

## Context

The first campaign graph incorrectly made the sealed Half Adder a prerequisite for both arithmetic and storage. That implied an electrical dependency which does not exist: an SR latch does not require an adder. The editor also inferred its placement menu from pre-instantiated reference components, so content authors could not clearly distinguish “parts used by the reference circuit” from “parts the player may choose.” A popup-only menu further hid the construction loop the game is meant to test.

Public Turing Complete materials provide useful interaction outcomes: campaign progress controls available components, the component menu accommodates a growing library, and placed components/wires use familiar selection and undo controls. Those outcomes are references, not assets or level solutions.

## Decision

- The wiring tutorial is the shared campaign root.
- Half Adder belongs to the CPU/arithmetic branch and leads to Full Adder and ALU.
- SR Latch begins the independent storage branch and leads to Register and RAM.
- CPU still requires both the completed ALU and RAM branches.
- XOR is a supported one-bit, one-tick primitive with deterministic tri-state/conflict behavior and its own procedural schematic symbol. It is offered only by later arithmetic palettes, so the Half Adder challenge must still be solved from earlier gates.
- Every editable circuit level declares an explicit `palette_components` supply. Reference components/wires remain deterministic test and capture evidence; they no longer implicitly define player supply.
- The same supply feeds a movable/minimizable Components window and the compact toolbar menu. Drag/drop and click-to-repeat both call the same snapped, authoritative, undoable placement transaction.
- Locked demonstration levels reject both placement paths.

## Consequences

- Replacing Half Adder invalidates only CPU/arithmetic descendants; storage progress and rewards remain intact.
- Players can see and drag suitable components without opening a hidden popup, while fast repeated placement remains available.
- Level authors must intentionally update the palette when introducing a new construction option.
- XOR can participate in real player topology, diagnostics, delay metrics, animation, copy/paste, and encapsulation evidence; it is not a hidden truth-table shortcut.
- This does not add arbitrary component authoring, cross-level persistence, rotation, inventory budgets, or a general HDL.

## Evidence

- Public references: [Turing Complete controls](https://turingcomplete.wiki/wiki/Controls), [component catalog](https://turingcomplete.wiki/wiki/Components), and [official component-menu patch note](https://steamcommunity.com/app/1444480/announcements/).
- Implementation plan: [`../exec-plans/completed/cpu-branch-xor-and-drag-palette.md`](../exec-plans/completed/cpu-branch-xor-and-drag-palette.md).
- Focused coverage: `tests/test_circuit_simulation.gd`, `tests/test_prologue_simulation.gd`, `tests/test_content_registry.gd`, `tests/test_hardware_foundations_ui.gd`, and `tests/test_hardware_prologue_ui.gd`.
