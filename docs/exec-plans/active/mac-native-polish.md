> **HISTORICAL / SUPERSEDED as an active queue.** Implementation history only.
> Current scope and remaining acceptance: [CURRENT_STATE](../../CURRENT_STATE.md) and [release blockers](../../../RELEASE_BLOCKERS.md).
> Older task counts and candidate identities below describe their dated iteration.

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
- Gesture fix uses Godot's held-button state when a motion mask is empty, and
  ends outstanding gestures on focus loss. All 20 suites pass, including a new
  empty-mask/focus-loss/undo regression, at
  `.godot/verification/20260907T074723Z-e861eefe/`. The English GUI run failed
  before entering Tutorial and was stopped after its script error; it is **not**
  a pass. Its map screenshot also exposes English title overflow for follow-up.
- Post-fix native Game at 1336×768: NOT body movement and Command+Z succeed;
  dragging from an existing A wire to a second gate creates `JUNCTION_001`.
  The revised Half Adder specification displays every row and all navigation
  buttons without scrolling. Inspector leaves other instruments in place.
- Display metadata: Apple M2, built-in Liquid Retina; current 2940×1912 backing
  pixels / 1470×956 logical display, 60 Hz (2× scale). Mixed-monitor testing is
  still unavailable. Do not store hardware serial numbers in evidence.
- Requested user approval for one-time migration from unstable legacy seed
  fingerprints, retaining designs and full provenance/official-case checks.
  No save-compatibility code or migration has been applied while that is pending.

- Full native ordinary Game continuation at `f15c175`: Half Adder 4/4, Full Adder
  8/8, ALU 32/32, Latch 5/5, Register 5/5, RAM 5/5, CPU 7/7 and LOAD/STORE
  7/7 pass. All construction wiring was performed through native computer-use;
  CPU used 19 wires, with A/B/C/D interface progress and exact per-step output checks.
  No Test bootstrap or reference insertion was used. ALU H1/H2/H3 were requested
  separately and return restored the empty player workbench before manual wiring.
- Native Handbook opens 59/89 terms after the bridge. Command+A replaced CPU with
  Cache, future Cache retained only its unlock explanation, and Escape returned
  focus to the Handbook entry. Native clipboard tooling occasionally reported a
  timeout after successful paste; the actual field value was checked before continuing.
- Latest original player files are copied without modification under
  `.godot/mac-playtest/cpu-native-save-backup/`. No compatibility migration occurred.
- Follow-up UI changes: fixed Test Bench action footer/reset scroll, wrapping map
  headings and bounded bilingual node titles, native Command shortcut labels,
  phase-correct seal/testing copy and observation-specific bridge wording. Word
  terminals now display complete authoritative values; hexadecimal A–F padding
  no longer changes 0xC into 0xC0. Neither numeric state nor signatures change.
- `.godot/verification/20260907T085235Z-954ab7a3/` passes all 20 suites. Its English
  GUI replay fails because the helper still searches the old Tutorial button
  parent; the helper now searches the complete Test Bench. Failure logs retained.
- Handbook binary diagram now consistently shows 1101 and 8 + 4 + 0 + 1 = 13;
  signal illustration faces match the updated dark outlined canvas symbols.

- Complete follow-up verification: English `.godot/verification/20260907T085708Z-82f678ac/`
  and Chinese `.godot/verification/20260907T090007Z-ab01f760/` each pass all 20
  suites and 502 ordinary Game viewport-input checks. The intermediate English
  run `20260907T085423Z-994496c3` misclicked an obscured Mission close control;
  replay cleanup now uses the visible dock toggle and checks that it closed.
- Native post-change ordinary Game in a new isolated directory: Tutorial completed
  again, Command+C/V and Command+Z observed, Half Adder full truth table/navigation
  fits at 1336×768, and the official-test button stays fixed while case rows scroll.
- Native post-change exposed an initial Retina window fallback that used 1600×900
  pixels as though they were display points. Scale only that first Mac fallback,
  retaining existing remembered rectangles and screen-bound clamping. Also refresh
  the Tutorial banner to 5/5 on completion and suppress underlying wire descriptions
  while completion/Handbook is visible.
- Final bilingual Handbook text explains hexadecimal word notation alongside the
  corrected binary diagram. The dedicated isolated directory probe, localization
  test and rendered 558-check Handbook suite pass; logs are under
  `.godot/mac-playtest/postfix-*.log`.

- Final targeted run `.godot/verification/20260907T091751Z-b7310af3/` passes
  all 20 suites and 142 Tutorial GUI checks. The prior `091319Z-03c1d691` caught
  an incorrect Handbook visibility guard; it now uses is_open(). The subsequent
  `091531Z-300737ca` had an intermittent first-entry miss during Mac native window
  startup and was stopped after its script error. Replay now waits for the initial
  window transition and exits with evidence instead of dereferencing a missing
  Mission. All failed logs remain alongside passing runs.
- Final native window review: first Retina fallback is visibly larger (capture
  width about 1202 versus the previous 800); F11 enters fullscreen and the visible
  exit button restores the size. Rapid consecutive F11 generated an unstable
  capture and is not counted as a stable pass. Capture pixel dimensions are not
  an independent measurement of window backing pixels.
- Read corrected binary diagram and hexadecimal explanation in the final native
  Handbook. Original-checkout final import passes with no errors, and original
  player-file hashes before/after import match.
- Commits: `d22bf91` modal/Inspector fixes; `ad26a0c` instrument/Mission polish;
  `f15c175` native gestures; `c3bfea6` fixed test actions, word values and copy;
  `d8c752f` Retina fallback, Handbook and completed-goal feedback. No push.

## Open limitations

The save-compatibility approval and rapid F11/mixed-monitor follow-up remain
pending. Post-change native presentation checks are recorded below. Native Tutorial, Half Adder, CPU, body dragging and mid-wire branching
have now been exercised successfully. Do not infer physical trackpad comfort,
mixed-monitor DPI, Windows EXE behavior, beginner comprehension or release
readiness from the baseline tests.

## Screenshot follow-up: component selection and playability

- User screenshot at 17:38 exposes overlapping `[1]` labels and collapsed module
  bodies in the palette. The prior bounds checks only covered the outside of the
  preview; they did not establish readability inside it.
- Replace the one-row miniature with a complete module silhouette, real input and
  output pin counts/widths, and the existing shared function glyph. Keep the full
  canvas and placement ghost unchanged. Add localized names, one-line purposes,
  and compact port metadata; shorten the placement instruction.
- Verify all available module families in both languages visually, then exercise
  actual native click/drag placement, cancellation, focus and undo in ordinary
  Game. Record observations and further changes here; save migration remains
  outside this UI follow-up until the pending data-change decision is answered.

- `4fc1f6e` commits the complete palette silhouettes, bilingual card hierarchy and
  internal-geometry regressions. Native feedback then exposed initial hidden-panel
  sizing and drag failures, addressed in the follow-up implementation.
- Drag follow-up preserves Godot payloads/previews while using the release event
  for target and snapped position. It cancels over floating instruments, ends
  one-shot drag placement, and preserves click-to-repeat plus undo/redo. Preview
  reconstruction retains runtime symbol configuration. The first palette open
  waits for actual desktop dimensions and exposes all three Tutorial cards.
- Current native ordinary Game: completed Tutorial and the four-case Half Adder
  with manual wiring, sealed and continued to Full Adder; dragged the earned
  reusable module and undid it. Also tested normal/invalid drops, click-repeat,
  right-click cancellation, Command+Z / Shift+Command+Z, Handbook search focus,
  locked CPU text and Escape focus return. No answer/reference insertion.
- F11 window round trip preserved the board. System capture showed a thin corrupt
  top strip after re-entry, while the saved viewport render was clean. Capture
  reliability remains distinct from rendering and from mixed-display acceptance.
- Fresh final isolated import, directory probe and all 20 suites pass in
  `.godot/verification/20260907T105450Z-7953228f/`. Earlier run
  `20260907T102937Z-44a5e78b` retains the too-short-window assertion failure and
  the two wrong-drop-position failures that guided the follow-up; do not count
  its intermediate pointer-only repair as final native evidence.
- Final current-source Chinese and English ordinary Game replays each pass
  528 checks, zero failures, including original CPU and LOAD/STORE progression.
  Runtime/assets/tests in the verification copy match the final working source.
  Bilingual all-19-card renders were inspected again at Retina resolution.
  Source hashes, native scope and outstanding acceptance are in
  `docs/verification/2026-09-07-mac-palette-polish/summary.json`.
