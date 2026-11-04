# P1 pages - Round 2 - 2026-11-04

Uncommitted on `claude/ux-p1-pages-20261104`, based on `0ba32e2`. Ready for lead review after verification below.

- `src/lab/lab_terminal_pages.gd`: shared 28 px regular, light title; 44 px header; 150 x 44 Back / Esc with 16 px text; centred max 1120 px content, 32 px minimum gutters.
- `src/ui/prototype_hub.gd`: settings and achievements use the family header and width. Settings tabs fit current content without a dark filler rectangle; scrolling remains available. Existing region cards retain actual earned counts.
- `src/lab/lab_archive.gd`: same header, width and opaque page background; existing slot cards retained.
- `src/ui/journey_journal.gd`: same header and width; list, detail and actions use 16 px body text (existing 14 px notes retained).
- `src/ui/terminology_handbook.gd`: same header and terminal width; existing progress rail and summary sit below the header. Original bit diagrams retained.
- `src/playtest/playtest_moments.gd`: same header and width, concise title, context and diagnostics left / message and actions right. Source identity selector is inside diagnostics with its choices, selection and callbacks unchanged. Privacy follows the form content.
- `localization/game.{zh_CN,en}.po`: one appended Round 2 title key per language.
- `tests/test_settings_feedback_layout.gd`: source selector collapse/reveal and retained selection checked in both languages and both hosts.

Round 1 accepted opacity, focus/Esc, archive cards, achievement counts and diagnostic identity changes remain in this diff, including `src/playtest/offline_feedback.gd`, `tests/test_offline_feedback.gd` and `tests/test_journey_journal.gd`.

## Comparisons

24 original 1280?720 PNGs, six pages in both languages. Before = round 1 uncommitted state; after = Round 2. Captures use the same page controller calls, fresh disposable profiles under `.godot/p1b`, and the actual Localization API. Handbook baseline was captured before its Round 2 edits. Round 1 intermediate PNGs were moved individually to `.godot/p1b/round1-png`.

| Page | Chinese before / after | English before / after |
| --- | --- | --- |
| settings | [before](before-settings-zh_CN.png) / [after](after-settings-zh_CN.png) | [before](before-settings-en.png) / [after](after-settings-en.png) |
| achievements | [before](before-achievements-zh_CN.png) / [after](after-achievements-zh_CN.png) | [before](before-achievements-en.png) / [after](after-achievements-en.png) |
| archive | [before](before-archive-zh_CN.png) / [after](after-archive-zh_CN.png) | [before](before-archive-en.png) / [after](after-archive-en.png) |
| journal | [before](before-journal-zh_CN.png) / [after](after-journal-zh_CN.png) | [before](before-journal-en.png) / [after](after-journal-en.png) |
| feedback | [before](before-feedback-zh_CN.png) / [after](after-feedback-zh_CN.png) | [before](before-feedback-en.png) / [after](after-feedback-en.png) |
| handbook | [before](before-handbook-zh_CN.png) / [after](after-handbook-zh_CN.png) | [before](before-handbook-en.png) / [after](after-handbook-en.png) |

Replay final captures (baseline PNGs are retained; replay does not reconstruct the old sources):

```powershell
$env:APPDATA="$pwd/.godot/p1b/replay-fresh-data"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd" res://docs/verification/20261104-p1-pages/capture.tscn -- --test-mode --after
```

## Verification

Exact round 1 suite selection, rerun for Round 2:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_chapter_settings_input --suite test_global_save --suite test_handbook_branch_order --suite test_handbook_diagrams --suite test_hardware_settings_input --suite test_journey_journal --suite test_lab_journey --suite test_lab_terminal_pages --suite test_lab_terminal_routing --suite test_late_handbook_access --suite test_late_settings_localization --suite test_learning_handbook --suite test_mode_access --suite test_offline_feedback --suite test_playtest_data --suite test_playtest_feedback_ui --suite test_playtest_visits --suite test_recovery_settings_language --suite test_settings_feedback_layout --suite test_settings_language_input
```

**20 suites PASS, 0 FAIL**; import and user-directory checks also PASS. Every native subprocess exited 0 with no recorded test errors in `results.json`. Run: `.godot/verification/20261104T115632Z-ba3a7ec8`. PowerShell marked the wrapper invocation failed on stderr warnings; the verifier subprocess results above are authoritative for suite outcomes.

Graphical repeats: **settings/feedback 154 checks PASS, 0 failures** (includes the added diagnostics assertions), **terminal pages 58 checks PASS**, both native exits 0. The updated layout test was copied into the same isolated project; production sources and localization match the reviewed working tree byte for byte.

```powershell
$env:APPDATA="$pwd/.godot/p1b/gui-test_settings_feedback_layout"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd/.godot/verification/20261104T115632Z-ba3a7ec8/project" --script res://tests/test_settings_feedback_layout.gd
$env:APPDATA="$pwd/.godot/p1b/gui-test_lab_terminal_pages"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd/.godot/verification/20261104T115632Z-ba3a7ec8/project" --script res://tests/test_lab_terminal_pages.gd
```

Complete suite logs: `logs/test_*.txt`; graphical logs: `logs/gui-*.txt`. `git diff --check` PASS. No pre-existing test failures were observed. The journal ThemeReflection/F8 stack retains its explicit headless NOT_RUN marker; the graphical terminal suite separately exercises nested review/feedback input.

## Limits

No simulation, metrics, formal judgement, task IDs, save schema, rewards or feedback data semantics changed. No proposals needing impact analysis.

Both languages were visually checked. Empty-profile archive and journal captures do not establish long earned-record readability or human play acceptance. The optional external work viewer and native review Windows remain outside this layout scope. Physical input, network delivery, exported binaries and full journey play-through were not tested.

The restricted environment reports failure to read the Windows root certificate store; this is present in round 1 and the current suite logs. Native test results and any explicit NOT_RUN markers are reported separately below.
