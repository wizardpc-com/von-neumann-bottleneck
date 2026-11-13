# Input and saved-design preservation — 2026-11-13

Base: `main` `3a8e6059207d7af7f473b572f203a76e2c7b3b49`.
This is a source reliability pass; no new release package or final art selection.

## Fixed behavior

- Hardware New/Duplicate naming overlays block board Undo/Redo, deletion, colors,
  Debug and camera shortcuts with non-text focus. Escape cancels and Enter submits
  through the original dialog handlers.
- Escape during a held component drag ends that gesture before level navigation.
  It retains one undoable move, matching the existing focus-loss behavior. Remaining
  held motion/release cannot restart it; a later Escape still opens the map.
- Formal Chapter4 named copies cannot be replaced by a different same-name recipe
  from ordinary tools or the shared state. Identical normalized recipes can retry
  persistence. A rejected save retains the entered name and current editable draft.
- The optional scheduling lab commits pending numeric text through its existing
  editor path before deciding whether close needs an unsaved-work guard. Cancel
  restores focus; Save and exit retains the visible value. Closing runs no simulation.

No simulation, modeled metrics, task unlock, save schema, dependency or art change.
The scheduling experiment remains separate from the six formal Chapter4 tasks.

## Verification and evidence

Godot `4.7.1.stable.official.a13da4feb`, macOS / Apple M2 OpenGL.
Final QA: `.godot/verification/20261113T112322Z-18f406a3/project`.
All runs used `VonNeumannBottleneckChecks/` profiles, leaving ordinary saves alone.

Twenty focused suites plus import and the actual user-directory probe passed in
[candidate-results.json](candidate-results.json). This includes full authored
prologue progression fixtures, Chapter2's seven-level progression and comparison,
formal Layout six-host navigation, rankings and challenges, experimental notebook
and challenge UI/storage, global save and localization. All final test files match
that QA; the additional drag repair was applied afterward and covered by five
[final Hardware regressions](final-hardware-results.json). There are **22 distinct
passing headless suites**, not a full-repository regression.

All four new regressions also passed with the actual GPU:
[gpu-final-results.json](gpu-final-results.json). Scheduling's close probe intercepts
actual departure to count it and inspect the saved value. GPU checks use rendered
viewport events, not native OS input. No fresh screenshot collection or visual-art
acceptance is claimed.

The old production tree is independently bound to the base commit for556 files.
Negative controls reproduced all four defects: initial naming-modal test6 failures,
expanded naming-modal test22, initial named-copy test8, pending exit4 and drag2.
These are expected failures and never included in successful test totals. The
named-copy test was later strengthened with Game/Test and retry-signal checks;
its old version is retained here. Original test inputs and complete lossless logs
are archived alongside [log hashes](log-sha256.json), result JSONs and
[the sequential runner](run-focused-checks.py.txt). No unexpected script diagnostics
occurred. Final import and `python3 scripts/check-branding.py` passed.

[Source hashes](source-sha256.json) bind1215 runtime/test/asset/config files between
workspace and final QA; only the two documented QA profile settings differ.
[Verification summary](verification-summary.json) records baseline and native command.

## Native Mac check

A [seeded fixture](native-fixture.gd.txt) opened the actual tutorial and Duplicate
name overlay after one40×20 component move. Through CUA native keys, Cmd-Z,
Backspace,3 and F6 left the board unchanged under focused Copy. Escape closed the
dialog; Cmd-Z changed position800,190→760,170 and redo restored800,190 with the
corresponding history transitions. Cmd-Q ended the owned process with exit0.
Screenshots were observed in the chat; [the state log](logs/native-hardware.txt.gz)
retains the transitions. The fixture only observes state after setup; it does not
inject the tested native keystrokes. This is a narrow final-source input check,
not a full native solve, drag-Escape test or exported-build acceptance.

## Reproduction and limits

Use `scripts/verify-project.py --godot <4.7.1> --suite <name>` for each suite listed
in the results. On an imported isolated project, run each new test with
`--windowed --resolution 1280x720 --script res://tests/<name>.gd --
--capture-size=1280x720` for GPU checks. Inspect full logs, not exit status alone.

Windows, exported Mac packages, full newcomer completion, audio/long-session,
server-recomputed online rankings and final visuals remain unverified. The
[visual decision list](../../development/VISUAL_DECISIONS_20261112.md) now also
retains the rejected global13px Creation-workbench rule; maintenance instructions
correctly distinguish core40/full60 and the old-home-only Logo slot.
