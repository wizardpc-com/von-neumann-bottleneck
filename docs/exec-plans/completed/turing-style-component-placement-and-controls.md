# Turing-style component placement and editor controls

## Goal

Turn Hardware Foundations from a pre-supplied-parts wiring board into a more complete schematic editor loop: choose an allowed component from a component menu, place as many instances as needed on the grid, select and cut/copy groups, and navigate the canvas with familiar Turing Complete-style controls.

## Scope

- Add a level-aware component menu derived from the components that the current level actually allows.
- Exclude external Test Bench terminals and routing junctions from the menu.
- Let the player arm one component, see a snapped placement cursor, and left-click empty canvas space to place deterministic copies repeatedly until cancelled.
- Make placement, deletion, cut, undo, and redo use the existing atomic editor-history model.
- Add `Ctrl+A` select all, `Ctrl+X` cut, and WASD canvas movement while preserving the existing `Ctrl+C/V/Z/Y`, Shift selection, left-drag wiring/movement, Shift endpoint movement, and right-drag eraser.
- Add double-click selection of a component together with the explicit wire nodes connected to its pins, so a routed part can be moved without manually finding every anchor.
- Update Simplified Chinese and English localization, focused headless coverage, and durable editor documentation.

## Explicit non-goals

- Do not copy Turing Complete artwork, text, level solutions, or source code.
- Do not replace the current campaign, simulation, electrical rules, signal colors, or parallel trace animation.
- Do not add arbitrary components that a level did not already expose.
- Do not implement visual-only rotation. Godot `GraphNode` exposes left input and right output ports only; real four-way rotation needs a custom port/connection layer and will be a separate, explicitly tested refactor.
- Do not add save-file persistence or a general-purpose level/component authoring system.

## Affected files and subsystems

- `src/hardware_foundations/circuit_graph_edit.gd`: placement mode, snapped cursor preview, empty-canvas placement signal.
- `src/hardware_foundations/hardware_foundations.gd`: allowed-component templates, deterministic placement, selection/cut/navigation controls, connected-route selection, history integration.
- `tests/test_hardware_foundations_ui.gd`: menu, placement, cancellation, undo/redo, select-all/cut, connected-route selection, and WASD coverage.
- `localization/game.zh_CN.po` and `localization/game.en.po`: component-menu and control feedback.
- Hardware Foundations architecture/status/testing documentation where durable behavior changes.

## Invariants

- The visible graph remains the authoritative topology.
- Simulation is deterministic and independent of UI, animation, component position, and wire length.
- Ordinary wires and explicit routing nodes remain zero latency.
- Placed IDs are monotonic and deterministic within a level session.
- A level exposes only component shapes/specifications already present in its declared inventory; fixed external terminals remain unique.
- Every placement or cut is one reversible history transaction and a new edit clears the redo branch.
- Right-button continuous deletion, Shift endpoint movement, multi-driver diagnostics, cycle detection, and exact-path parallel signal animation remain unchanged.

## Decisions and rationale

- Derive menu templates from the level inventory rather than introducing a second component whitelist. This keeps content definitions authoritative and avoids speculative campaign architecture.
- Keep placement armed after a successful click so repeated gates are quick to build; `Esc` and the existing Cancel control leave placement mode.
- Deduplicate menu entries by electrical/component specification rather than display instance ID, so `AND · 1`, `AND · 2`, and `AND · 3` appear as one allowed AND item.
- Use the current structured clipboard and history transactions for cut/placement, preserving model/view atomicity.
- Match public Turing Complete interaction outcomes, not its proprietary presentation.

## Implementation and verification steps

1. Add a level-aware component menu and controller-side deterministic placement transaction.
2. Add GraphEdit placement mode, snapped guide, empty-canvas click routing, and cancellation.
3. Add select-all, cut, WASD navigation, and component-plus-route-node double-click selection.
4. Add focused automated tests and localized player feedback.
5. Run the Hardware Foundations UI suite, circuit simulation suite, localization suite, and project/direct-scene smokes; capture and inspect a representative Hardware frame.
6. Inspect the final diff and Git status, record exact verification evidence, then move this plan to `completed/`.

## Progress

- 2026-08-18: read repository rules, prior editor plans, current implementation/tests, and public Turing Complete control documentation; selected a bounded interaction-parity milestone.
- 2026-08-18: implemented the level-derived component menu, repeated snapped authoritative placement, atomic placement/cut history, `Ctrl+A/X`, WASD/F4/F5/F6 controls, and component-plus-routing-node double-click selection. Added bilingual UI text, a deterministic placement capture, focused regression coverage, and ADR 0010.
- 2026-08-18: completed fresh verification. All eight automated suites and four default-Chinese/English/direct-Hardware/hub-route smokes exited `0`; both catalogs contain 529 unique entries with no duplicates; final error-pattern log scanning and `git diff --check` were clean. The 1600×900 placement capture was inspected. The only engine error was the known non-fatal Windows root-certificate-store warning. No commit or push was made.

## Outcome

Editable construction levels now expose their declared hardware as a reusable placement menu instead of making the original pre-laid instances the player's only supply. A placed part is a real simulation component with deterministic identity, immediate live diagnostics, and reversible history. The added controls make selection, rearrangement, cutting, repeated construction, and canvas navigation substantially closer to the public Turing Complete editor workflow while preserving this project's own visuals and graph-authoritative simulation.

## Unresolved questions and temporary limitations

- True four-way component rotation remains blocked on replacing `GraphNode`'s fixed left/right port geometry with a custom port layer; this iteration deliberately does not fake it.
- The component menu is level-local and does not yet persist a cross-level clipboard or player-created arbitrary component categories.
