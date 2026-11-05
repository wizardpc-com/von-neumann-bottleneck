# Locality state / restore integration read-only review — 2026-11-04

Current source reviewed: main.gd best controls, restore/undo, invalidation, mode/task
scoping and LocalityChapter best-observation API. No actionable runtime issue found
in that integration. API receipt Dictionary is compatible with the existing history
adapter; restored source/config replaces the editable design and invalidates results,
while prior draft/applied state and caret are retained for current-scene Undo. Gates
remain enforced. Undo is transient and cleared on task/mode departure, as implemented.

Fresh root evidence inspected:
.godot/verification/20261104T195819Z-1ef53586/
- test_locality_best_observation: 81 PASS.
- test_locality_restored_baseline: 15 PASS.
- test_locality_trace_presentation: 144 PASS, 0 failures.
- test_locality_best_restore reports PASS 75/0 but also contains two remove_at
  bounds errors in test code line 93. This is not clean acceptance. Current test
  file differs from the executed copy, so rerun the corrected test.

SHA256 equality confirmed between current and executed locality state and main.gd.
The current best-observation test differs from the executed copy: two additional
real equal-cycle / higher-hardware checks were added after it, so current suite
must be rerun (expected 83 checks if these pass).

No edits or Godot/Git mutations in this review. New follow-up assignments arrived
as opaque tokens; only shared readable implementation/handoff scope was available.
