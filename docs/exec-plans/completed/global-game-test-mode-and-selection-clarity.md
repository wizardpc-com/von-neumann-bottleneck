# Global game/test mode and selection clarity

## Goal

Make circuit editing easier to read and development testing faster: shorten the one-input `not` symbol, replace the circular selection halo with whole-symbol highlighting, and introduce an explicit global Game/Test mode whose Test mode can enter every campaign level.

## Scope

- Give `not` a smaller, shorter GraphNode footprint while keeping its port hit targets and one-tick electrical behavior unchanged.
- Render selected schematic components by recoloring the complete procedural symbol and leads; retain live red/green/gray port colors and remove the cyan selection circle.
- Add one global session mode service with Game as the default and an optional `--test-mode` launch override.
- Expose the same mode selector on the prototype hub, Hardware Foundations, and Cache Locality Lab.
- In Test mode, bypass campaign prerequisite locks and install isolated temporary reusable-component definitions so every registered level can actually open.
- Keep Game-mode player content separate from Test-mode helper content.
- Add bilingual copy, automated coverage, deterministic captures, and durable documentation updates.

## Explicit non-goals

- Do not change simulation rules, gate delays, test cases, level rewards, or normal Game-mode progression.
- Do not persist mode or progress to disk in this iteration.
- Do not mark Test-mode levels as completed or allow Test-mode helper components to leak into Game mode.
- Do not resize every component or redesign the entire procedural symbol set.

## Affected files and subsystems

- `src/game/game_mode.gd` and `project.godot`: global session mode and CLI boundary.
- `src/ui/prototype_hub.gd`, `src/ui/main.gd`, and `src/hardware_foundations/hardware_foundations.gd`: visible synchronized selectors.
- `src/hardware_foundations/circuit_component_symbol.gd`: whole-symbol selection color.
- Hardware UI/localization tests and current architecture/status/testing documentation.

## Invariants

- Simulation remains deterministic and independent from mode selectors, symbol dimensions, selection, and rendering.
- Game mode remains the default and retains the authoritative prerequisite graph.
- Test-mode unlock is explicit presentation/routing policy; official circuit evaluation still tests the player's actual graph.
- Live port colors continue to represent electrical state even when a component is selected.

## Decisions and rationale

- Use an autoloaded `GameMode` session service so hub and both playable scenes cannot drift into different modes.
- Maintain separate in-memory `PlayerContentState` objects for Game and Test mode. Test helper definitions satisfy level factories, while unlock checks use the mode explicitly instead of fabricating completion.
- Recolor procedural strokes and labels for selection instead of drawing another shape behind the component. This directly identifies the selected hardware without implying a new electrical state at its ports.

## Implementation and verification steps

1. Add the global mode service, synchronized selectors, and test-mode content/unlock boundary.
2. Resize `not` and replace circular selection feedback with whole-symbol highlighting.
3. Add focused tests and bilingual copy; update durable docs.
4. Run all relevant suites, four startup modes plus Test-mode startup, and inspect fresh captures.
5. Inspect logs, links, diff, and Git status; record results and move this plan to `completed/`.

## Progress

- 2026-08-18: inspected repository rules, current dirty worktree, procedural symbol drawing, GraphNode sizing, campaign registry/unlock flow, content-state ownership, hub, and locality/hardware headers. Confirmed that late levels require temporary reusable definitions in addition to unlocked buttons.
- 2026-08-18: added the global default-Game mode service, visible synchronized selectors on all three screens, CLI Test-mode override, separate Game/Test `PlayerContentState` objects, valid-level unlock override, and the bounded temporary library needed to instantiate every current level.
- 2026-08-18: reduced `not` from the generic wide component footprint to a short single-row symbol and replaced the circular selection halo with complete procedural stroke/label recoloring. Live red/green/gray ports remain independent.
- 2026-08-18: completed fresh verification. All eight automated suites and six default-Chinese/English/direct-Hardware/hub-route/Test-hub/Test-route startup smokes exited `0`. Both PO catalogs contain 546 unique matching keys with no duplicates. Thirty-six current final logs had no unexpected error pattern; local Markdown links and `git diff --check` passed. Fresh 1600×900 Game selection, Test hub/map, and locality-header captures were inspected. The only engine error was the known non-fatal Windows root-certificate-store warning. No commit or push was made.

## Temporary limitations

- Mode and progress remain session-local; restarting the application returns to Game mode unless `--test-mode` is supplied.
- Test mode unlocks current registered campaign content only; it is not a general level-authoring or cheat console.
