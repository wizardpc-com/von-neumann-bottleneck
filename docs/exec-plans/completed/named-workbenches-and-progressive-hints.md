# Named workbenches and progressive hint boards

## Goal

Add Turing Complete-inspired named per-level workbenches and a three-stage hint flow. Entering a playable level must ensure a `default` workbench exists. Players can create and name additional workbenches, switch between them, and retain each workbench's placed components, route nodes, positions, and wires. A top-right Hint action opens a separate read-only hint workbench and returns to the exact player workbench on exit.

## Scope

- Add a versioned local workbench snapshot store, separated by Game/Test mode and level.
- Save only current circuit topology and component positions; do not persist undo/redo, selection, trace playback, official-test receipts, or runtime storage state.
- Add a compact workbench selector and named-workbench creation dialog.
- Add a top-right Hint action with three progressive stages:
  1. core-idea text and no solution topology;
  2. a curated key subcircuit;
  3. the complete reference topology.
- Make hint workbenches read-only and prevent them from changing completion, sealing, or player workbench state.
- Cover every currently registered prologue level, including the compact tutorial and the locked LOAD/STORE bridge.
- Add deterministic model/UI tests, localization, architecture/status documentation, and visual QA.

## Non-goals

- No cloud synchronization, schematic sharing/export, deletion/renaming UI, or migration from third-party save formats.
- No persistence of campaign completion or reusable-component libraries in this iteration.
- No saving of undo/redo history, clipboard, current selection, trace playback position, debug inputs, or stateful-component runtime memory.
- No scoring penalty, currency cost, achievement, or progression gate for requesting hints.
- No copying of Turing Complete art, text, level solutions, or save formats.

## Affected subsystems and files

- `src/hardware_foundations/`: workbench snapshot store, controller lifecycle, selector/dialog, hint-mode UI and graph loading.
- `src/content/prologue/`: explicit curated partial-hint wire sets for current level definitions where appropriate.
- `src/circuit/logic_component.gd`: safe dictionary reconstruction for snapshot loading.
- `localization/`: Chinese-default and English workbench/hint strings.
- `tests/`: deterministic snapshots, isolation, read-only hints, return behavior, and complete-answer correctness.
- `docs/architecture/`, `docs/status/`, `docs/decisions/`, and testing records.

## Invariants

- Simulation remains deterministic and independent from UI, persistence, or animation timing.
- Ordinary wires remain zero latency; saved geometry never changes delay.
- The visible graph remains the authoritative topology used by official tests and sealing.
- Hint boards use the same component/wire representation as player boards but remain read-only.
- Entering, switching, or exiting a hint never changes player topology, official completion, or reusable rewards.
- Snapshot ordering and IDs are deterministic; save data never contains the operation chain.
- Existing uncommitted user work is preserved and no commit or push is created without a new explicit request.

## Decisions and rationale

- Use a small versioned JSON snapshot at `user://hardware_workbenches_v1.json`. The requested save behavior implies durable local storage, while a version field provides a bounded migration boundary.
- Namespace workbenches by Game/Test mode and level so unrestricted testing cannot overwrite normal campaign designs.
- Seed a new workbench from the level's pristine component inventory and fixed Test Bench terminals; it is not a clone of the currently active workbench.
- Persist component specifications, deterministic IDs, positions, and graph connections only. Undo history is intentionally reconstructed as empty after each load.
- Level 1 uses fixed terminals plus conceptual text; level 2 uses an explicitly curated subgraph; level 3 uses the existing official reference graph. This avoids hidden solution logic and keeps hints reviewable as content.
- Disable disk IO for automated test/capture launches so deterministic verification cannot mutate a player's local schematics.

## Implementation steps

1. Add snapshot serialization/reconstruction and an in-memory/durable workbench store with schema validation.
2. Integrate automatic `default` creation, autosave, named creation, switching, and lifecycle saves into all current level entry/exit paths.
3. Add explicit three-level hint content and construct read-only hint graphs from pristine/reference topology.
4. Add top-right hint/return controls and workbench selection/creation UI with complete localization.
5. Add automated coverage for deterministic save/load, workbench isolation, absence of history, hint progression, read-only behavior, return restoration, and complete reference correctness.
6. Run all relevant suites and startup smokes, capture/inspect representative UI states, inspect final diff/status, document limitations, then move this plan to `completed/`.

## Progress

- 2026-08-19: Inspected repository constraints, current dirty baseline, level factories, graph mutation/history paths, and existing test commands.
- 2026-08-19: Public Turing Complete material confirmed named/switchable schematic concepts and circuit save separation; exact three-level hint content will follow the user's explicit specification rather than inferred undocumented behavior.
- 2026-08-19: Added a version-1 per-mode/per-level named snapshot store, deterministic component dictionary reconstruction, automatic `default`, clean named creation, switch/autosave lifecycle, and disk reload. Unknown schemas now fail closed without overwriting the original file.
- 2026-08-19: Added top-right progressive Hint/Return controls. Stage 1 contains only fixed terminals and conceptual text, stage 2 uses explicit level-authored key wires, and stage 3 uses the full reference topology. Hint nodes are non-draggable and official/seal UI is absent.
- 2026-08-19: Focused circuit, Hardware UI, prologue UI, and localization suites pass. Coverage includes two independent tutorial workbenches, empty history after load, disk reload, all current level-2 subsets, all current level-3 canonical reference signatures, a genuinely passing Half Adder answer, and byte-identical player restoration.
- 2026-08-19: Final verification ran all eight documented suites and the default, Test-mode, direct Hardware Foundations, and direct Cache Locality smokes with exit code `0`. Fresh 1600×900 captures confirmed the ordinary selector, a readable stage-2 hint board, and a compact centered naming modal. `git diff --check` passed; only the known non-fatal Windows root-certificate warning appeared.

## Outcome

The requested bounded feature is complete. Every current playable prologue level owns a durable versioned `default` workbench and supports clean named alternatives. The same visible component/wire graph is serialized without editor history. Three read-only hint stages are available from the top-right control and restore the exact active player design without granting progress. The documented non-goals remain intentionally unimplemented.

## Verification plan

- Unit/model: snapshot round-trip, stable ordering, supported component reconstruction, mode/level/name isolation, default creation, duplicate/invalid name rejection, and manifest absence of history.
- UI: automatic `default`, named creation/switching, independent topology/positions, empty undo history after switch, autosave after wiring/movement, and Game/Test separation.
- Hint UI: top-right entry, all three stages, level-2 partial topology, level-3 full topology, locked editing, no official/seal side effects, and byte-identical player snapshot after return.
- Simulation: full level-3 Half Adder and representative later-level reference circuits continue to pass their official tests.
- Regression: all commands in `docs/development/testing.md`, startup/Test-mode/direct-scene smokes, localization coverage, `git diff --check`, final diff/status.

## Open questions and temporary limitations

- The first version deliberately offers creation and switching but no workbench deletion or renaming after creation.
- Campaign progress and reusable libraries remain session-local as before; only workbench circuit snapshots become durable.
- Stateful runtime contents and debug input settings reset when switching workbenches because the requested save scope is parts and wires.
