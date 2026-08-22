# ADR 0010: level-authoritative component placement

## Status

Accepted for the Turing-style schematic-editor interaction pass; its inventory-derived menu source is amended by [ADR 0014](0014-independent-branch-roots-and-explicit-component-palettes.md), which introduces explicit supplies and direct drag/drop.

## Context

Hardware Foundations already evaluates the visible graph, but construction levels still began with every usable component pre-instantiated. Deleting a supplied gate could therefore leave Undo as the only recovery path, and the interaction felt like arranging a worksheet rather than freely constructing a schematic. The public Turing Complete controls and campaign behavior establish a useful outcome: a level controls which component types are available, while the player decides how many instances to place and where to place them.

Adding an unrelated second component whitelist would duplicate content ownership. Treating placement as visual-only would also violate the graph-authoritative simulation invariant.

## Decision

- Derive each editable level's component menu from the unique electrical specifications in that level's declared component inventory.
- Exclude fixed external Test Bench terminals and runtime-created routing junctions. A level may therefore keep its interface unique while allowing repeated player hardware.
- Deduplicate by kind, ports, widths, and properties rather than display instance ID. Several supplied `AND` instances create one `AND` menu entry.
- Keep a selected menu item armed for repeated empty-canvas placement until `Esc`, the Cancel control, or another menu item changes the mode.
- Give placed components deterministic monotonic IDs, add them to the same catalog/circuit used by live analysis and official tests, and record each placement as one reversible editor transaction.
- Add Turing-style `Ctrl+A`, `Ctrl+X`, WASD navigation, and component-plus-connected-wire-node double-click selection to the existing shortcut/selection model.
- Preserve an original procedural presentation. Public interaction outcomes are a reference, not authorization to copy Turing Complete assets, wording, source, or level solutions.
- Defer rotation until ports and connection hit testing can rotate electrically and visually together. Godot `GraphNode` exposes fixed left-input/right-output slot geometry, so rotating only the symbol would be misleading.

## Consequences

- Players can recover deleted gates and explore topologies with more/fewer instances without changing level data or hidden success logic.
- Content packs remain authoritative for allowed hardware; locked demonstration levels expose no placement menu.
- Extra components affect the real graph and diagnostics. They may be functionally harmless, create shorts/cycles, or contribute gate/delay diagnostics exactly like supplied components.
- Component counts are not budgets or optimization objectives in the current prologue. A later level may add explicit inventory/cost data without changing the placement transaction boundary.
- True four-way rotation, cross-level clipboard persistence, user-authored component categories, and disk saves remain separate follow-up work.

## Evidence

- Public reference: [Turing Complete controls](https://turingcomplete.wiki/wiki/Controls).
- Implementation plan: [`../exec-plans/completed/turing-style-component-placement-and-controls.md`](../exec-plans/completed/turing-style-component-placement-and-controls.md).
- Focused coverage: `tests/test_hardware_foundations_ui.gd` and `tests/test_hardware_prologue_ui.gd`.
