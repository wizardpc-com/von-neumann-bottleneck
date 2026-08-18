# Default-low ports and schematic editor history

## Goal

Make Hardware Foundations behave like a small desktop schematic editor: every unconnected input resolves to low, `Ctrl+Z`/`Ctrl+Y` undo and redo complete editor actions, `Ctrl+C`/`Ctrl+V` copy and paste the selected player subgraph, and `Shift` supports additive/toggle multi-selection.

## Scope

- Change empty input-driver resolution from high impedance to deterministic low in both live analysis and official/debug execution.
- Preserve high impedance as a real signal state for unresolved cycles, absent external sources, and future tri-state components.
- Generalize the existing one-way wire history into reversible undo/redo actions for connections, branches, endpoint moves, erasing, component deletion, clear-all, pasted subgraphs, automatic layout, and user node movement.
- Add `Ctrl+Z`, `Ctrl+Y`, and the Turing Complete-compatible `Ctrl+Shift+Z` alias.
- Add `Ctrl+C`/`Ctrl+V` for selected gates and wire nodes, including only connections whose two endpoints are copied.
- Exclude external Test Bench input/output terminals from copy/paste so level interfaces remain unique.
- Add `Shift` click toggling and `Shift` drag rectangle toggling for components and wire nodes; ordinary dragging of a selected node continues to move the selected group through GraphEdit.
- Localize status/tooltips and update automated/headless coverage and durable documentation.

## Explicit non-goals

- Do not add cut, select-all, rotation, component palette placement, cross-level clipboard persistence, or OS clipboard serialization.
- Do not make ordinary wire crossings electrically connected.
- Do not add a tri-state switch, delay, latch, or sequential circuit semantics.
- Do not redesign the Cache Locality Lab or copy Turing Complete assets/source code.

## Reference behavior and decisions

- The public [Turing Complete controls documentation](https://turingcomplete.wiki/wiki/Controls) defines undo, redo, copy, paste, selection, component/wire-node area selection, and subgraph copy/paste behavior. This iteration adopts those editor outcomes while retaining this project's left-drag wiring, Shift-connected-endpoint move, and right-button eraser rules.
- User-requested `Ctrl+Y` is the primary redo shortcut; `Ctrl+Shift+Z` is also accepted because it is the documented Turing Complete default.
- Copy/paste is an in-session structured clipboard, not text or OS clipboard data. IDs are generated monotonically and topology remains deterministic.
- A copied subgraph includes selected non-terminal components and only wires wholly internal to that selected set. External Test Bench terminals and boundary-crossing wires are not duplicated.
- Each paste is one undoable action. A new edit after Undo clears the redo stack.
- Short circuits and cycles remain unchanged; only the empty-driver identity changes from `Z` to `0`.

## Affected files and subsystems

- `src/circuit/logic_signal.gd` and `circuit_simulator.gd`: default-low electrical behavior and required-input validation.
- `src/hardware_foundations/circuit_graph_edit.gd`: Shift selection rectangle and selection feedback.
- `src/hardware_foundations/hardware_foundations.gd`: reversible history, keyboard routing, structured clipboard, pasted ID/position mapping, and move transactions.
- `tests/test_circuit_simulation.gd` and `tests/test_hardware_foundations_ui.gd`: default-low, history branching, selection, and copy/paste coverage.
- `localization/*.po`, architecture/status/testing docs, and a focused ADR.

## Invariants

- Simulation remains deterministic and independent of UI/animation.
- Ordinary wires and routing nodes remain zero latency; geometry has no electrical meaning.
- The displayed graph remains authoritative topology.
- Undo/redo restores both model and view atomically and cannot leave dangling wires.
- Copy/paste never duplicates external signal identities.
- Every new user edit after Undo invalidates the redo branch.
- Existing Half Adder official behavior and the preserved v0.2 locality prototype remain regression-covered.

## Implementation and verification steps

1. Add default-low resolution and update simulator expectations/tests.
2. Normalize existing edit actions into reversible forward/reverse transactions and add a redo stack.
3. Record node movement and auto-layout as position transactions; make Clear Wires undoable.
4. Add Shift toggle/rectangle selection and an internal selected-subgraph clipboard with deterministic paste IDs and offsets.
5. Add localized shortcuts/status copy, focused tests, ADR/status/architecture updates.
6. Run all simulation/UI/localization suites, startup smoke, a representative visual capture, and final diff/status checks.
7. Move this plan to `exec-plans/completed/` after verified completion.

## Progress

- 2026-08-18: read repository rules, current circuit/editor/history implementation, tests, and public Turing Complete control behavior; implementation pending.
- 2026-08-18: implemented zero-wire low resolution while preserving connected explicit high impedance, and removed the obsolete required-wire execution error.
- 2026-08-18: generalized route/deletion history into reversible transactions, added redo branching, made Clear Wires/Auto Layout/node movement undoable, and added keyboard routing.
- 2026-08-18: added Shift click/rectangle selection, selection halos, structured selected-subgraph copy/paste, deterministic pasted IDs, and fixed Test Bench terminal exclusion.
- 2026-08-18: all five simulation/UI/localization suites and the project startup smoke passed with exit code `0`; a fresh 1600×900 Hardware render confirmed default-low ports, exact-path signal colors, Chinese guidance, and toolbar fit. Final diff/status inspection completed without rewriting pre-existing work.

## Unresolved questions and temporary limitations

- The clipboard is intentionally local to the current Hardware Foundations scene and is cleared when the phase graph is rebuilt.
- Selection covers component nodes and explicit wire nodes, not individual curved segments; internal segments follow copied endpoints.
- A later component palette can decide whether pasted gates should count against an inventory or budget; this prototype has no such resource model.
