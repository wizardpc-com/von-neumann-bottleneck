# Settings and feedback layout

Goal: make frequently used settings and feedback actions identifiable at a glance, with less scrolling and clearer visual hierarchy.

Scope: prototype_hub Settings, ordinary PlaytestMoments feedback, offline feedback presentation, seven small SVG icons and relevant tests. Existing unsaved work, player saves, consent, export behavior and input/quit guards remain intact. No video/ access, handbook edits, commits or packages.

Design: three icon-led Settings categories with a fixed return/quit footer. Ordinary feedback separates task context from opinion/actions and keeps optional data controls folded. Offline feedback pairs the actual captured scene/history with the note form and fixed export actions. Room and floating presentations share controls; both languages remain supported.

Ownership: root integration/verification/icons; lab_audit Settings; yi_polish ordinary feedback; closeout_review offline feedback. Only root runs Godot.

Verification: preserve the initial diff/hashes, review each change, run focused functional tests in fresh isolated profiles, then inspect actual GPU frames for room/floating views, both languages, and supported aspect ratios. Verify focus, escaping, drafts and local export paths. No network send during visual inspection.

Progress: 2026-10-23 complete. Root reviewed the four runtime files, isolated checks and actual rendered frames. Seventeen related headless suites pass; final geometry checks140, skin lifecycle96, GPU layout160 with20 frames. Two earlier graphical exits without diagnostics passed serial recheck; cause unlocated. Evidence: docs/verification/20261023-settings-feedback/README.md. Native full-game human acceptance remains outside this verification.
