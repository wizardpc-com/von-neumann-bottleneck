# A6 · Completion and Yi cards · 2026-11-08

Five presentation files changed; simulation, completion authority, saved evidence,
catalog copy, public APIs and original bit visuals are unchanged. No commit made.

## Round 2 review

- `ui_cue.gd` toast only: right canvas margin, below visible `workbench_nav`,
  follows button relayout and hides while GuideStage reports a blocking card.
  Dense screens suppress it if no safe slot remains. Original 1.8-second expiry,
  cue names, synthesis and result text remain unchanged.
- Opening: compact single-line sizing at the instruction row's right edge;
  visible label ink and buttons are avoided, including the Address view title.
- Artifact: task label left, measured values right, one complete row per order;
  five vertically arranged task cards align single-order and two-order results.
- W5's immediate local override is redundant: `experiments/creation/workbench.gd:2272`.
  The shared toast recomputes its canvas anchor before rendering. That file is untouched.
- Added toast geometry/blocker/expiry regression checks in `tests/test_f1_cues.gd`
  and label avoidance in guide convergence; adapted artifact container observation.

Round 2 pairs preserve Round 1 as the baseline:

| Route | Before | After |
| --- | --- | --- |
| Opening | [before](round2-before-opening-zh.png) | [after](after-opening-zh.png) |
| Artifact | [before](round2-before-artifact-zh.png) | [after](after-artifact-zh.png) |
| Repeat | [before](round2-before-repeat-zh.png) | [after](after-repeat-zh.png) |

Round 2 verification: all original **10 suites PASS, 0 FAIL**, plus import and
isolation probes; receipt `.godot/verification/20261107T184017Z-4c3f4fa6/results.json`.
Same broad command below, with fresh `.godot/a6-r2-tests/{app,local}` profiles.
F1 12/12, guide 90/90, bridges 32/32; all other counts below unchanged.
All suite logs read in full; all four films reached natural decoder end.
Sound synthesis prefix compared byte-for-byte after newline decoding to HEAD: equal.
`git diff --check` PASS. Native captures use fresh zh4/en2 profiles; logs
`.godot/a6-r2-zh4.log` and `.godot/a6-r2-en2.log` both confirm W5 safe anchor.

W5 local-assignment comparison (reconstructed placement baseline, not an old-runtime
capture): [local zh](round2-local-creation-repeat-zh.png) /
[safe zh](after-creation-repeat-zh.png), [local en](round2-local-creation-repeat-en.png) /
[safe en](after-creation-repeat-en.png). [English repeat](after-repeat-en.png).
All final Chinese/English frames inspected. Original Round 1 pairs remain;
`round2-before-*` preserves its final frames before this review's corrections.

The repeat text already renders as question marks in the baseline; localization
and fonts are outside this toast-placement scope. W5 capture reproduces its exact
local assignment on an instantiated workbench; it is a presentation fixture,
not a player-earned result.

## Changes and owner choices

- `src/ui/level_completion_overlay.gd`: smaller corner radius and shadow, top accent,
  larger body and secondary text. Original emblem, reveal and response timings remain.
  Choice: rounded celebration card versus a flatter instrument card with more legible text.
- `src/ui/yi_opening.gd`: same surface family and larger type; starts below navigation,
  uses the instruction row when free, and avoids buttons and visible label ink.
  Placement follows relayout. If no vertical space remains, the card is hidden rather
  than covering controls. Original pointer-hover fade, lifetime and early dismissal remain.
  Choice: fixed top-centre placement versus control-aware placement with suppression on dense screens.
- `src/ui/yi_help_card.gd`: matching surface, larger body/replies and outline replies;
  reduced motion keeps the existing reading interval but closes without an animated fade.
  Embedded help keeps its existing borderless layout.
- `src/lab/cinematic_artifact.gd`: matching outer card, quieter inset tiles,
  aligned exact storage/cycle order rows and one primary Continue action. Joins the
  existing guide blocker group so opening/help guidance yields while reading results.
  Choice: equal-weight outlined tiles versus a clear outer frame and quieter measured-data tiles.
- `tests/test_guide_convergence.gd`: bilingual geometry checks for navigation, separate
  tool rows and relayout. `tests/test_b2_bridges.gd`: artifact blocks guidance.
- `tests/captures/a6_moments.gd`: reproducible isolated presentation capture fixture.

## PNG evidence

All individual frames are GPU-rendered at 1280×720 (1600×900 logical coordinates).
Baseline was captured before production edits with the identical helper and routes.

| Route | Before | After |
| --- | --- | --- |
| Chapter 4 / fields opening | [before](before-opening-zh.png) | [after](after-opening-zh.png) |
| Floating Yi help fixture | [before](before-help-zh.png) | [after](after-help-zh.png) |
| First-completion presentation fixture | [before](before-completion-zh.png) | [after](after-completion-zh.png) |
| Representation artifact, five actual accepted runs | [before](before-artifact-zh.png) | [after](after-artifact-zh.png) |

[English contact sheet](after-english.png): opening/help/completion/artifact, arranged
top-left/top-right/bottom-left/bottom-right. Original 1280×720 pixels are preserved in
each quadrant. All eight final language/route frames were visually inspected.
[Round 1 repeat toast](unchanged-repeat-zh.png) preserves the original placement.

The completion fixture directly calls the presentation API in Test mode using a
clearly synthetic qualitative summary, with no invented measured number and no award.
It is not a player-earned Chapter 4 completion. The floating help fixture directly
calls the owned card using existing catalog text; real embedded-help interaction is
covered by guide convergence. The artifact uses the existing five-plan controller
fixture from B2: real simulation and public revalidation, temporary unsaved session,
no cinematic history consumed. It is not an end-to-end post-film player journey.

## Reproduction

Only this worktree is writable in this task's sandbox. Scratch captures, imports,
logs and isolated profiles are therefore under ignored `.godot/a6-*`, rather than
the sibling temp directory. Each Godot launch sets fresh APPDATA/LOCALAPPDATA first.
Run from the worktree root; use a fresh profile label per invocation:

```powershell
$env:APPDATA="$PWD\.godot\a6-capture-profile\app"
$env:LOCALAPPDATA="$PWD\.godot\a6-capture-profile\local"
New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script res://tests/captures/a6_moments.gd -- --evidence-dir=res://.godot/a6-after
```

English adds `--locale=en` and uses `res://.godot/a6-en`.
Baseline used `res://.godot/a6-before` before production edits.

## Verification

Exact broad command (isolated APPDATA/LOCALAPPDATA set as above):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_f1_cues --suite test_yi_typewriter --suite test_guide_convergence --suite test_b2_bridges --suite test_completion_evidence --suite test_completion_presentation --suite test_yi_introduction_media --suite test_cinematics --suite test_chapter5_cinematic --suite test_ending_cinematic
```

10 suites PASS, 0 FAIL; import and user-directory probes PASS. Receipt:
`.godot/verification/20261107T180127Z-c112ab58/results.json`.
Per-suite checks: F1 5, typewriter 37, guide 82, bridges 31, completion evidence 8,
completion presentation 78, introduction 246, cinematics 50, chapter-5 cinematic 13,
ending cinematic 26. All four films reached their natural decoder end.

Round 1 focused rerun included the placement guard and new assertions:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_guide_convergence --suite test_b2_bridges
```

2 suites PASS, 0 FAIL: guide 88/88, bridges 32/32; import and isolation probes PASS.
Receipt: `.godot/verification/20261107T180333Z-c9e359dc/results.json`.
All suite logs inspected in full. PowerShell reports a nonzero wrapper status for
the Git global-ignore permission warning; machine receipts record every check process
exit 0 with no unexpected errors. Godot's root-certificate-store diagnostic also
appears in baseline GPU runs and is excluded by the verifier. `git diff --check` PASS.

## Limits

Broader 60-task geometric coverage, native physical input, human pacing, audible
acceptance, exported builds and macOS were not verified. Introduction, first-light
retrospective and film playback logic are unchanged. No new localization strings
or settings. Simulation, progression, save formats and sound synthesis are untouched.
