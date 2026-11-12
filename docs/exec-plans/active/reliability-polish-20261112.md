# Reliability and presentation audit — 2026-11-12

## Goal and scope

Finish a bounded audit-and-repair pass on the existing prologue circuit,
Chapter2 optimization and Chapter4 layout/challenge player loops. Fix proven
state/interaction defects; preserve all 60 formal tasks, deterministic models,
score conditions, saves and optional experimental boundaries. Catalogue Claude
visual candidates and historical Logo issues for owner/team decisions.
No new features, final art selection, model rewrite, export or release.

## Ownership and sequence

Root owns integration, Git, sequential Godot runs, documentation and evidence.
Prologue agent: hardware_foundations.gd and new history-context regression.
Performance agent: main.gd and locality trace-presentation regression, then
read-only Chapter4 audit. Visual agent: VISUAL_DECISIONS_20261112.md only.

1. Inspect live source, remote history and collaboration state.
2. Reproduce concrete failures; patch narrowly and test real player actions.
3. Run relevant isolated suites, rendered paths and available native input.
4. Review changes, preserve logs, document limitations; commit and push verified
   blocks to main under explicit user authorization.

## Findings and decisions

- Main 329a484 and old local branch d4b428c have identical trees; current main
  was fast-forwarded before editing. Prior pause ended with the new user request.
- Investigate stale CPU/coach/observation context after topology Undo/Redo.
- Investigate second-chapter comparisons omitting changed Debug data identity.
- Do not change ambiguous first-Debug baseline behavior without a product contract.

## Verification

Use Godot4.7.1 and scripts/verify-project.py with isolated profiles. Add negative
controls using unchanged runtime code. Cover hardware history/failure/navigation,
Chapter2 data comparison/best restore, Chapter4 navigation/rankings/challenges,
workspace persistence and relevant deterministic simulations. Inspect actual logs,
not only PASS markers. Rendered automation, OS-native input, exported packages and
newcomer playtests remain separately reported.

## Progress and limitations

2026-11-12: runtime block complete. Proven topology context/Debug-label and data-signature
comparison defects repaired. 28 distinct focused suites have passing observations;
final Hardware reruns29/0, bilingual GPU35/0 each, Chapter2 GPU149/0,
Chapter4 rankings47/0 and challenge82/0. Two three-process recovery helpers pass.
Negative controls fail on unchanged runtime; final ordinary startup passes.
Native CPU keyboard/mouse pass preceded the final output-label correction;
final label correction is headless/GPU verified. Independent reviews found and
closed clear-all and old-output omissions. Visual decision document drafted and
link-checked; separate documentation delivery follows runtime commit/push.
Evidence: [receipt](../../verification/20261112-reliability/README.md).
Only 4.8GiB disk available at start: reuse this round's QA copy for reruns;
do not delete old evidence or player data. No claim of complete game acceptance.
