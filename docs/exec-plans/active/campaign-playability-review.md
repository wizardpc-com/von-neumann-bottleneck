# Campaign playability and component dragging

Date: 2026-09-07. Starting source: fb26ca6, clean main.

## Request and scope

Continue improving the game with Turing Complete as a design reference. Reproduce
remaining component-palette dragging bugs, assess every original level for player
choices, discovery, repetition, clarity and progression, and use public developer
and player experience to inform changes. Commit substantial verified increments.

## Boundaries

Keep the original 9 + 5 + 7 campaign and free construction, independent H1/H2/H3,
existing authoritative simulation/test rules, saved provenance and Game/Test
isolation. No eight-task replacement. Major changes to level objectives, gating,
mechanics, architecture or persisted data require a concrete proposal and user
approval before implementation. The earlier restart-compatibility proposal remains
unanswered; this work does not authorize migration.

Small input fixes, visual feedback and clearer bilingual task framing can proceed.
Do not replace puzzle discovery with automatic connections or unsolicited answers.

## Work

1. Reproduce palette dragging through native computer use: both mouse event paths,
   zoom/pan, drop cancellation, Escape, focus loss, instrument overlap and preview.
   Ask for the user's specific symptom while independently exercising these paths.
2. Read all 21 level definitions and their visible briefs/conditions/rewards.
   Separate code/content inspection, automated replay, agent native play and actual
   first-time human enjoyment. Prior native completion is historical evidence.
3. Read Turing Complete developer statements and first-person player feedback;
   distinguish versions, anecdotes and transferable principles from consensus.
4. Implement bounded bug fixes and content/presentation improvements supported by
   actual observations. Put major progression proposals in a reviewable document.
5. Fresh isolated checks and native rechecks; review diffs, commit each coherent
   significant change and report outstanding approvals and acceptance limits.

## Progress

- Confirmed clean source fb26ca6. Current catalog is 9 construction levels,
  5 CPU/RAM/Bus investigations and 7 locality levels.
- Current palette tests cover completed drops but do not yet establish the held
  preview, Escape/focus cancellation, or the user's reported remaining symptom.
- Public research and native reproduction are underway; no proposed level
  reordering or gameplay changes have been implemented.

- Reproduced held-drag Escape leaving the Godot payload active, and focus-out
  leaving repeated placement armed. Both baseline probes fail; repair passes.
  Removed overlapping card drag preview and hide ghost over invalid instruments.
- Final current-source import/probe + all 20 suites pass in
  `.godot/verification/20260907T120142Z-bf175db9/`. The ordinary Game input setup
  passes 567 checks, zero failures, then remains open at Chapter 1 for native work.
- Native recheck: valid drag/undo, Test Bench invalid drop, click-arm/Escape/canvas
  click, and actual OS focus-out by raising the existing editor all behave as
  intended. Command+Tab dispatched to the app was not proof of OS focus-out.
- Full 21-level content/rules review is drafted in
  `docs/design/campaign-playability-review.md`; native Chapters 1/2 follow.
