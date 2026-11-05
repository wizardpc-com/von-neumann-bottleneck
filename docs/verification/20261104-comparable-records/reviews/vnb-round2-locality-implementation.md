# Locality best-observation implementation handoff — 2026-11-04

Owner: audit_interactions; files now ready for root integration and verification.
Changed only:
- src/locality_chapter/locality_chapter_state.gd
- tests/test_locality_best_observation.gd (new)

API: `LocalityChapter.best_observation_for(level_id, mode = &"") -> Dictionary`.
Empty mode follows GameMode; explicit `game` / `test` reads that namespace. Empty
Dictionary means no current comparable measured recipe. Otherwise returns detached:
- recipe: exact source/cache_lines/passes/blocks/bypass/version/checkpoint
- metrics: actual core replay metrics
- receipt: Dictionary with LocalityRunReceipt field names, including nested metrics
- condition_id: stable hash of task + model + official data + required passes
The root UI can pass result.receipt to its existing _history_record_from_receipt.

Behavior:
- Protect earliest baseline/checkpoints, newest and fastest admissible receipt/recipe
  at existing 12-receipt / 32-observation limits. Cost breaks equal-cycle ties;
  exact ties retain incumbent order across JSON reload.
- Persist exact recipes in existing observations schema; result caches are transient.
- Test gains its own transient recipes/cache and reset lifecycle. No Game snapshot
  fields added. Existing model/catalog/core and workspace fingerprint unchanged.
- Recipe replay is authoritative; saved numbers and checkpoint claims are ignored.
  Ranking checks task passes/cache/group/bypass/fixed-source constraints. Generic
  legacy observations still replay under prior rules but cannot rank if inadmissible.
- Replay uses the official test label, matching a fresh official canonical trace;
  prior synthetic restore label unnecessarily changed receipt signatures.
- Restore now enforces the same 12-receipt bound as live play. Draft/progression
  ownership and completion semantics are unchanged. API results deep-copy state.

New suite uses actual core outputs and covers >32 slower experiments, source/metric
retention, canonical replay, baseline/latest, stable ties and hardware tie-break,
wrong task conditions, incorrect output, detached result copies, poisoned saved
metrics/checkpoint flags, JSON reload, unchanged chapter schema, unfinished drafts,
Game/Test separation/reset, and stale/current model cache identity.

Verification by this agent: inspected full runtime diff and test source;
`git diff --check -- src/locality_chapter/locality_chapter_state.gd tests/test_locality_best_observation.gd`
passed. No Godot or Git mutations performed per ownership agreement. Fresh Godot
verification is REQUIRED by root: test_locality_best_observation,
test_chapter_workspaces, test_locality_restored_baseline, locality/UI/save regressions.
