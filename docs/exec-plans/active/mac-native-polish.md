# Mac native play and incremental polish

## Goal and scope

Continue the original Game campaign from main `0ad0bff` on Mac with Godot
`4.7.1.stable.official.a13da4feb`. Use native computer-use observations of
Tutorial, Half Adder and CPU to improve editing, instrument presentation,
Mission narration and progressive illustrated Handbook content.

This is a bounded follow-up to [visual-learning-polish.md](visual-learning-polish.md).
It does not reopen the superseded eight-task mainline plan. Human novice
comprehension and release acceptance remain separate from automated and agent
play evidence.

## Invariants and affected areas

- Preserve original prerequisites, free building, independently requested H1/H2/H3,
  official simulation/testing and source-verified save rules.
- Preserve seed coordinates and persistent formats. Hint return still clears
  operation history and clipboard under ADR 0015.
- Expected changes: existing hardware/shared UI, bilingual catalogs, focused
  regression tests and Mac verification/status documentation.
- No simulation rewrite, new dependency, automatic answer insertion, save
  conversion or Windows development work.
- User explicitly requested commits after each substantial verified change;
  this supersedes the earlier plan's no-commit default. No push is requested.

## Steps and evidence

1. Read handoff, architecture, current status and open plans; verify clean latest main.
2. Run the documented fresh-copy isolation probe, 20 suites and ordinary Game GUI replay.
3. Launch ordinary Game on the Mac desktop; record observed operations, screenshots,
   current limitations and Retina/window/focus/shortcut results.
4. Fix observed local friction, verify relevant tests and replay affected native actions.
5. Commit coherent changes separately; inspect final diff/status and record the exact
   source version for later Windows validation.

## Progress and decisions

- 2026-09-07: cloned clean latest main `0ad0bffeea9053143cf19f2da11a5b64105079c0`.
  Downloaded official Mac universal standard engine; SHA-256
  `897cb7f9799796c717ae75f31446aed883dc92b1d6c3b33d893cc7843fff2fa9` verified.
- Baseline evidence: `.godot/verification/20260907T045421Z-c0c7b916/`.
  Import and actual Mac isolated user-directory probe pass. All 20 conventional
  suites pass; the 461-check GUI replay exposed a Mac select-all mismatch in the
  replay helper (Ctrl+A instead of Command+A).
- Two original-checkout imports performed as documented. The second has no
  resource/script errors. Native computer-use enumerates the unlocked Mac desktop.
- Native ordinary Game: Tutorial wired and completed, right-click wire removal and
  Command+Z / Command+Shift+Z observed; Half Adder built with port drags, passed all
  four official input cases and sealed. The five resulting player-save files are
  backed up under `.godot/mac-playtest/pre-change-save-backup/` before changes.
- Fixed two observed problems: inspecting a component rearranged other instruments
  and hid test actions; number shortcuts changed the board behind a completion modal.
  Added focused regressions and corrected Mac select-all in the GUI replay helper.
- Fresh fix evidence: `.godot/verification/20260907T053942Z-f10951d4/`:
  isolated import/probe, all 20 suites and 128 Tutorial GUI checks pass.
- Visual follow-up: separate editing/playback rows, primary action emphasis,
  instrument accent markers, dark terminal faces with colored state outlines,
  aligned Half Adder specification cells, compact Mission heading and a Handbook
  learning-progress rail. Chinese workbench wording now consistently says 方案.
  Native 1336×768 window inspection found specification navigation below the fold;
  tightened heading and cell spacing in response. Fresh isolated full Chinese
  Game replay and all 20 suites pass at
  `.godot/verification/20260907T072816Z-db1ac2be/`.
- Native investigation confirms Mac motion events can have `button_mask=0` while
  `Input.is_mouse_button_pressed(LEFT)` remains true. This prematurely cancels
  component dragging and wire branching; a separate gesture fix follows.
- Reopen correction: Half Adder did seal and its backup contains 12 wires and a
  completion record, but the original loader rejects it after restart. A read-only
  probe of that exact backup still passes all official cases, while its serialized
  source signature differs solely with runtime component ordering. StringName
  sorting also changes the default-seed fingerprint. Preserve the backup and
  investigate deterministic ordering and backward compatibility separately.

## Open limitations

CPU native play, visual polish and post-change native checks remain pending.
Native body dragging and mid-wire branching need further investigation; port
dragging works. Do not infer physical trackpad comfort,
mixed-monitor DPI, Windows EXE behavior, beginner comprehension or release
readiness from the baseline tests.
