# Reusing an observed baseline — 2026-10-02

The fast-CPU endpoint in cpu_speed is the slow-RAM starting machine in ram_wait.
An optional Test Bench action reuses that already observed experiment only when
program, data, expected output, source test identity, topology and component
provenance match. Source and target are independently simulated again before
recording a target receipt with its own case identity. No stored metrics are
relabelled, and the baseline animation is not replayed. The player must still lock
a prediction and run the changed RAM endpoint. Normal baseline runs remain valid.
Bus-width uses a different copy workload and cannot inherit this evidence.

Fresh isolated Godot 4.7.1 suites:

- `test_system_baseline_continuity`: pass on final implementation; rejects no source,
  missing prediction, changed machine/provenance, unapplied drafts and tampered
  metrics; confirms unchanged source, target identity and no granted completion.
- `test_localization`: pass after the final short-header copy change.
- `test_system_lab_ui`, `test_chapter_workspaces`: pass before that presentation-only
  change; existing prediction/comparison/progression and restoration remain intact.

Run with `scripts/verify-project.py --godot <Godot 4.7.1> --suite <name>`.
Full final logs are preserved here. The first new-test run chose the placeholder
prediction, then indexed an empty result. That test fixture was corrected to choose
an actual prediction and guard the index; no product gate was weakened.

The bilingual `capture.gd` fixture renders the action before reuse and its status
after reuse at 1280×720. It uses actual simulation receipts in Test mode, not a
native player session. The first English capture found the detailed status made
the header too wide. The header now uses a short label; full detail remains in
Test Bench. Final captures verify this correction. Other pre-existing narrow
English toolbar overflow is outside this change.

No model, catalog fingerprint, save schema, prerequisite or official target changed.
Native play and beginner comprehension remain part of the final acceptance pass.
