# ADR 0015: versioned workbench snapshots and read-only progressive hints

## Status

Accepted for the current CPU Building Prologue.

## Context

Each construction level previously recreated one unnamed graph whenever it opened. Players could not keep alternative designs, and leaving a level discarded its layout/topology. The requested hint flow also needs to reveal real circuits progressively without overwriting the player's attempt or granting hidden completion.

Public Turing Complete material confirms the useful product concepts rather than an exact format: schematics are independently named/switched and stored separately, the schematic browser supports creating new designs, and campaign saves are distinct from schematic files. Its exact current three-stage hint implementation is not documented publicly, so the hint stages here follow the user's explicit content contract rather than inferred behavior.

## Decision

- Entering every playable prologue level ensures a `default` workbench exists.
- Players may create a Unicode name up to 32 characters and switch between workbenches in the current level.
- Workbenches are namespaced by Game/Test mode and level and stored in a version-1 JSON manifest at `user://hardware_workbenches_v1.json`.
- A snapshot contains supported component specifications, stable IDs, component/route-node positions, and normalized visible wires. It deliberately excludes undo/redo, clipboard, selection, trace/test receipts, debug values, stateful runtime memory, campaign completion, and reusable rewards.
- New workbenches start from the pristine level inventory and fixed Test Bench terminals rather than cloning the current attempt.
- Automated test and deterministic capture launches use the same store in memory and never read/write the player's file.
- The top-right Hint action enters a separate read-only graph:
  1. conceptual text plus fixed external terminals;
  2. explicitly curated key components and wires;
  3. the complete existing reference topology.
- Level-2 subsets are authored alongside their level content. Level 3 is not separate success logic: it uses the same reference `LogicCircuit` representation and can pass only through the ordinary simulator/Test Bench.
- Entering a hint saves the active player workbench. Exiting reconstructs that active workbench from its snapshot with a fresh empty operation history. Hint graphs cannot run official completion or sealing actions.

## Consequences

- Players can retain alternative solutions and component placement between launches without persisting a potentially brittle edit-command log.
- Test mode experiments cannot overwrite Game-mode workbenches.
- Hint topology is inspectable along the same displayed wires and component symbols as player topology, while completion remains tied only to the player's authoritative graph.
- Workbench topology is now durable even though campaign progress and reusable-component libraries remain session-local. A later persistence milestone must coordinate those separate manifests instead of claiming this file is a whole-game save.
- Version 1 has no rename/delete/share/export UI and no migration from unknown schemas. Unsupported/corrupt component entries fail closed; required fixed terminals are restored from current level content.

## Alternatives considered

- Persist the editor operation chain: rejected because the request explicitly excludes it and replaying historical commands is more fragile than loading current topology.
- Clone the active workbench on creation: rejected because “new design” should provide a clean comparison baseline.
- Draw hints as screenshots or a second hidden truth table: rejected because that would break visual-topology authority and could drift from simulation.
- Copy the full answer into the player's graph: rejected because it destroys ownership and allows hint use to masquerade as player construction.

## Evidence

- Public references: [Turing Complete schematic browser/export discussion](https://steamcommunity.com/app/1444480/discussions/0/3814034023686291937/), [separate schematic-list discussion](https://steamcommunity.com/app/1444480/discussions/0/591771059512948154/), and [save-level console documentation](https://turingcomplete.wiki/wiki/The_game_console).
- Implementation plan: [`../exec-plans/completed/named-workbenches-and-progressive-hints.md`](../exec-plans/completed/named-workbenches-and-progressive-hints.md).
- Coverage: `tests/test_circuit_simulation.gd`, `tests/test_hardware_foundations_ui.gd`, `tests/test_hardware_prologue_ui.gd`, and `tests/test_localization.gd`.
