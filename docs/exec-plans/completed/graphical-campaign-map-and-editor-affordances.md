# Graphical campaign map and editor affordances

## Goal

Make the next Hardware Foundations interaction pass easier to read and operate: wiring should advertise exact valid targets before release, component selection should behave like a predictable desktop schematic editor, and the campaign should be selected from a visible dependency graph rather than a text list hidden inside the Mission window.

## Scope

- Add exact per-port target rings and hovered-wire feedback for ordinary wiring, wire branching, and Shift endpoint movement.
- Preserve live red/green/gray electrical colors outside an active edit gesture.
- Allow ordinary left-drag on empty canvas to replace the selection; keep Shift-drag as additive/toggle selection and Shift-click as single-item toggle.
- Keep interaction priority deterministic: port, component, rendered wire, then empty canvas.
- Add a registry-driven graphical campaign map in the central canvas with dependency curves, branch lanes, completed/unlocked/locked states, tooltips, and clickable level nodes.
- Keep the Mission window as a compact map explanation/legend and the Test Bench window as the player-owned component library.
- Add Simplified Chinese and English presentation copy, focused UI tests, a deterministic capture, and durable documentation updates.

## Explicit non-goals

- Do not copy Turing Complete art, text, source code, puzzle layouts, or exact screen composition.
- Do not change circuit electrical semantics, simulation timing, official test cases, progression prerequisites, or rewards.
- Do not add new prologue levels, persistent saves, arbitrary level authoring, component rotation, or a new rendering dependency.
- Do not turn wire geometry into simulation delay.

## Affected files and subsystems

- `src/hardware_foundations/circuit_graph_edit.gd`: deterministic hit priority, selection modes, hovered-wire presentation, and exact port-target guides.
- `src/hardware_foundations/hardware_foundations.gd`: wiring-source context, live-color restoration, graphical map descriptors, and map lifecycle.
- `src/hardware_foundations/campaign_map_view.gd`: content-driven dependency layout, drawing, and level-node interaction.
- `tests/test_hardware_foundations_ui.gd` and `tests/test_hardware_prologue_ui.gd`: selection, wiring affordance, map topology/state, and progression coverage.
- `localization/game.zh_CN.po`, `localization/game.en.po`, and focused architecture/status/testing documentation.

## Invariants

- The visible circuit graph remains the authoritative topology.
- Simulation stays deterministic and independent of UI, animation, positions, and wire geometry.
- Ordinary wires and routing nodes remain zero latency.
- Existing multi-driver short/cycle diagnostics, right-button erasing, Shift endpoint movement, transactional history, and parallel exact-path playback remain intact.
- The campaign registry remains authoritative for level identity, ordering, dependencies, localization keys, unlock state, and rewards; the map contains no duplicate hard-coded level list.
- Locked levels cannot be entered through either UI or the internal router.

## Decisions and rationale

- Draw the campaign in a dedicated Godot-native `Control` layered over the disabled circuit canvas. This uses the otherwise-empty central space without coupling campaign state to `LogicCircuit` or pretending level dependencies are electrical wires.
- Derive horizontal depth from level prerequisites and vertical lanes from cross-branch parent relationships. This keeps the current fork/merge legible while allowing registered content to participate without campaign-controller edits.
- Keep map nodes as real `Button` controls so keyboard focus, disabled state, tooltips, automated tests, and the existing locked-emitter lifetime fix continue to work.
- Use visual target rings during wiring instead of replacing electrical port colors. On gesture end, reapply the already-computed live state rather than recomputing every frame.
- Treat unmodified empty-canvas drag as replacement marquee selection and Shift-drag as toggle selection. Port/component/wire hits retain priority so selection cannot steal a wiring gesture.

## Implementation and verification steps

1. Implement the graphical map view and integrate it with registry-derived descriptors and existing level buttons.
2. Add exact wiring target/hover overlays and controller-side source context with live-state restoration.
3. Refine empty-canvas selection behavior and add focused automated assertions.
4. Add bilingual copy and update current-status/architecture/testing documentation.
5. Run all relevant headless suites, default/English/direct-Hardware/hub-route smokes, and inspect fresh map/editor captures.
6. Inspect final logs, links, diff, and Git status; record outcomes and move this plan to `completed/`.

## Progress

- 2026-08-18: inspected repository rules, current dirty worktree, content registry, campaign UI, GraphEdit gesture priority, selection implementation, regression tests, and the existing 1600×900 map capture. Confirmed that the central map canvas is empty and that current connection feedback is component-level rather than exact-port-level.
- 2026-08-18: implemented a registry-derived central dependency map with real button nodes, automatic branch/depth layout, dependency curves, and completed/unlocked/locked presentation. Inspected a 1600×900 progressed-state capture with both desktop windows open.
- 2026-08-18: added exact compatible-port guide rings and exact-path wire hover without replacing continuously maintained live port colors. Added ordinary replacement marquee selection/empty-click clearing while preserving Shift toggle semantics and deterministic hit priority.
- 2026-08-18: added focused Hardware UI and prologue progression assertions plus deterministic map/wiring-guide capture hooks. Updated bilingual copy and durable architecture/status/testing guidance; full regression verification remains in progress.
- 2026-08-18: completed fresh verification. All eight automated suites and four default-Chinese/English/direct-Hardware/hub-route startup smokes exited `0`. Both PO catalogs contain 539 unique matching keys with no duplicates. Fourteen current logs had no unexpected error pattern; local Markdown links and `git diff --check` passed. Fresh 1600×900 map and wiring-guide captures were inspected. The only engine error was the known non-fatal Windows root-certificate-store warning. No commit or push was made.

## Unresolved questions and temporary limitations

- The graphical map is a fixed readable dependency overview, not a freely editable/pannable level-authoring graph.
- Wire selection remains represented through explicit routing nodes and endpoint gestures; this pass does not introduce a separate persistent selected-wire object model.
