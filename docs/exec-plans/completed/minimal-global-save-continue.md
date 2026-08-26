# Minimal global Save / Continue for the first playtest

## Goal

Let an ordinary Game-mode player quit after meaningful progress and resume on a later launch without treating completion flags, telemetry, or Test-mode helpers as reusable-component evidence. Persist only the minimum chapter and concept state needed to return to the existing maps and continue the Demo.

## Scope

- Add a version-1 global save at `user://savegame_v1.json` with a guarded temporary/backup write path.
- Persist Game-mode Hardware completion and reusable provenance metadata, Chapter 1 completion/gate state, and Chapter 2 completion. Systems Notebook concepts remain derived from those restored completions.
- Reconstruct non-generated reusable components only from a Game-mode workbench snapshot whose canonical circuit signature matches the saved source signature and whose current official deterministic test still passes.
- Recreate generated wrappers only from the current registered recipe and the revalidated source component signature.
- Reconcile missing, incompatible, stale, corrupt, or unknown-version global/workbench data by invalidating only the affected level and its dependents.
- Add player-facing Continue and confirmed New Game actions to chapter selection. New Game preserves telemetry and, by default, all Hardware workbenches; an explicit unchecked option may clear only the Game-mode workbench namespace.
- Save after authoritative Game-mode progression/provenance changes and on normal exit, never per frame.

## Explicit non-goals

- No persistence of receipts, run history, Trace/playback position, draft/debug inputs, editor history, selection, clipboard, window geometry, runtime storage values, questionnaire state, telemetry events, or Test-mode progression.
- No cloud sync, accounts, save slots, manual save UI, migration framework beyond schema 1, or Chapter 3.
- No duplication of complete Hardware workbench snapshots inside the global save.
- No fabricated reusable component when the matching workbench topology or deterministic official pass is unavailable.

## Affected files and subsystems

- New `src/save/global_save.gd` autoload: schema, safe disk I/O, provenance reconciliation, save/reset lifecycle, and Continue target.
- `src/content/player_content_state.gd`: narrow Game progression change signal and restoration support.
- `src/system_lab/system_chapter_state.gd` and `src/locality_chapter/locality_chapter_state.gd`: minimal snapshot/restore/reset boundaries without receipts.
- `src/hardware_foundations/circuit_workbench_store.gd`: read-only workbench enumeration and Game-namespace clearing.
- `src/hardware_foundations/hardware_foundations.gd`: use the global Game player-content instance while retaining a separate session-only Test instance.
- `src/ui/prototype_hub.gd` and localization catalogs: Continue/New Game/confirmation entry.
- Focused save/UI tests plus architecture, decision, status, and testing documentation.

## Invariants

- GraphEdit topology plus deterministic official Test Bench results remain the source of reusable provenance; the save is only a recovery index.
- Generated wrappers remain bound to the verified source signature and current catalog recipe.
- A missing/mismatched arithmetic design does not erase an independently valid storage branch, but its registered dependents fail closed.
- Chapter 1 progress is accepted only when the restored CPU/RAM provenance produces the saved handoff signatures. Chapter 2 progress is accepted only when the restored Chapter 1 gate is complete.
- Game/Test state remains isolated. New Game and automatic save never copy or persist Test progression.
- Telemetry remains a non-authoritative observer and is neither read nor deleted by global save operations.

## Decisions and rationale

- Store `PlayerContentState.manifest_snapshot()` rather than circuit topology. On load, locate a matching Game workbench, reconstruct its `LogicCircuit`, and rerun the level's current official verifier before installing the reusable.
- Restore Hardware levels in registered dependency order. Tutorial and LOAD/STORE may use their completion flags only after their prerequisites are valid because neither creates a reusable circuit.
- Do not persist receipts. Completed-level flags are sufficient to reopen later maps; an incomplete level restarts its local evidence flow on re-entry.
- Keep Notebook state derived from Chapter 1/2 completion requirements instead of adding a second concept authority.
- Continue opens the deepest currently valid chapter map. It does not attempt to restore an in-progress Trace or exact screen.
- New Game deletes the global progression save after confirmation. An explicit optional checkbox clears only Game-mode Hardware workbenches; telemetry exports and Test workbenches remain untouched.

## Implementation and verification steps

1. Add the global save schema/service, safe writer/reader, provenance reconstruction, and dependency sanitization.
2. Add minimal snapshot/restore/reset APIs to the three progression domains and connect authoritative save hooks.
3. Integrate global Game player content into Hardware while retaining the session-only Test player content.
4. Add localized Continue/New Game UI with confirmation and optional Game-workbench clearing.
5. Add focused tests for partial branch restores, generated wrappers, chapter gates, concepts, invalidation, corrupt/unknown schemas, New Game, Game/Test isolation, and telemetry independence.
6. Run all documented suites, Game/Test/Continue smokes, representative captures, build/export checks if runtime files changed, and `git diff --check`.
7. Record actual outcomes, move this plan to `completed/`, review/commit, then verify a non-force fast-forward push of explicit `main:main`.

## Progress

- 2026-08-27: Confirmed the current global chapter and reusable state is session-only. `PlayerContentState.manifest_snapshot()` stores provenance metadata but not source topology; the independent Game workbench file contains the reconstructable topology. Chapter 1/2 receipts are unnecessary for reopening completed gates and remain out of scope.
- 2026-08-27: Added schema-1 Game save/load, validated temporary/backup replacement, dependency-ordered workbench reconstruction, current-verifier reruns, generated-wrapper rebinding, and per-domain gate sanitization.
- 2026-08-27: Added Game-only Continue/New Game UI, explicit confirmation, optional Game-workbench clearing, authoritative change/exit saves, and `--reset-local-test-state` integration without telemetry-export deletion.
- 2026-08-27: Fixed JSON integer round trips for circuit `width`/`value` properties so a persisted valid topology retains its canonical provenance signature.
- 2026-08-27: All fourteen test suites passed. Isolated Game/Test/reset startup smokes passed; fresh hub and confirmation captures were inspected; the Windows package built successfully; packaged Game/Test starts both exited `0`; `git diff --check` passed.

## Unresolved questions and limitations

- Continue will resume at the deepest valid chapter map rather than the exact level or transient UI state.
- If a previously sealed source topology no longer exists in any Game workbench or fails the current official verifier, that reusable and only its dependency descendants will require replay.
