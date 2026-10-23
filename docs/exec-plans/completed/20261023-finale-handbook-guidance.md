# Finale, handbook and opening guidance

## Goal and scope
Play the supplied ending after a successful chapter 10 final work save. Improve the existing in-game handbook using the supplied concept document, fill later-chapter guidance and diagrams, and clarify the opening steps. Preserve all existing edits and exclude the independent video directory.

## Invariants and decisions
No simulation, task IDs, save format or work contracts change. User selected final chapter save rather than every task completion. Existing cinematic history owns once-only playback. Reference prose is checked against actual models; propagation steps are not rendered frames. Existing handbook IDs retain their meanings.

## Files and allocation
Root: cinematic media/player/test, later-workbench handbook access, evidence. Content worker: handbook and bilingual translations. Diagram worker: diagram drawing and tests. Opening worker: introduction and narrative catalog. Only root runs Godot.

## Steps and verification
- [x] Read source DOCX and current architecture, audit coverage and factual conflicts.
- [x] Integrate ending media and test success/failure, once history and natural decoding.
- [x] Complete operational and later chapter entries with diagrams and contextual access.
- [x] Clarify opening guidance while retaining skip and focus.
- [x] Run related isolated suites and inspect bilingual rendered frames.
- [x] Review diff, document evidence and remaining human acceptance.

## Progress / limitations
2026-10-23: source has 100 concepts, no embedded images, and stops at cache/locality. Later chapters use current model contracts as evidence. Root assigned disjoint scopes. No physical keyboard/new-player or audible-sync acceptance claimed from automated checks.

2026-10-23 acceptance: 17 relevant headless suites have final PASS receipts; handbook1604, diagrams992, GPU access136 and introduction278, ordinary ending28. Evidence: docs/verification/20261023-finale-handbook/. User requested commit and push to main. No new package or human comprehension/audio acceptance.
