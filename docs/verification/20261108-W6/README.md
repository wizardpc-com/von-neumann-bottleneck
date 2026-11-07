# W6 — Scheduling lab visual pass

Standalone experiment only. Model, session, goals, ranking, challenge codes/stores,
Notebook store and campaign state are untouched. No commits or branch changes.

## Before / after (raw 1280×720 GPU frames)

| Route | Before | After |
| --- | --- | --- |
| Settled launch | [before-launch](before-launch.png) | [after-launch](after-launch.png) |
| One source-only run | [before-run](before-run.png) | [after-run](after-run.png) |
| Baseline + changed group | [before-compare](before-compare.png) | [after-compare](after-compare.png) |
| Challenge window | [before-challenge](before-challenge.png) | [after-challenge](after-challenge.png) |
| English comparison | [before-en](before-en.png) | [after-en](after-en.png) |

Both comparison captures use the starter baseline, then query_group=4 and
record_tile=1. The measured tradeoff is Q1 307→403, total 2456→824, RAM
2176→544 B; the red Q1 delta deliberately remains visible beside the savings.

## Changes / owner review

Round 2: challenge windows use the game's 0.88-alpha modal backdrop and fit
their content (including the code page); only one Close remains. The global
Settings button is removed from the window; its keyboard shortcut remains.
Before the first run, only Challenges is shown in the comparison action row.
Copy space is labelled with its measured peak, with no empty track at zero.
The baseline has a small localized chip. Compare shows the verdict beside
Explain, with goal exclusions when applicable; numeric deltas stay in the table.
The five `after-*.png` frames above are the Round 2 captures.

Round 2 source files: `experiments/layout_strategy/{lab,challenge_window}.gd`,
`localization/game.{en,zh_CN}.po`, `tests/test_layout_strategy_ui.gd`, and
`tests/test_layout_strategy_structures_ui.gd` (content-sized screenshot assertion).
Model, Session, persistence and shared UI resources remain unchanged.

- Shared chrome, palette, 14 px controls/table text and 13 px secondary text;
  outlined secondary actions and the existing single primary Run action.
- Before: empty table fills most of Compare. After: no empty table; a compact
  run-to-measure prompt. All four tabs and editor controls remain available.
- Before: numbers alone. After: request intervals above the table; thin baseline
  and solid selected run share a cycle scale, Q1 completion is marked. Intervals
  mean admission→response, not CPU-active time. Hover a row for exact cycles.
  Copy-space strips follow allocate/release events, with the selected peak in B.
- Before: table occupies most height. After: the graph uses up to 230 px; it
  scrolls for larger workloads and shrinks at the existing 960×640 minimum.
  This default space allocation is an owner-review tradeoff.
- Challenge window uses shared panel/outline styling and one in-content Close;
  the native title-bar close/move affordances are removed. Owner-review tradeoff.
- Notebook stays in its existing tab and inherits the same control/table style.
- Table ordering, ranks and measurements retain their existing authority.
  Right-aligned values and per-column same-condition deltas are presentation only.

No proposals needing simulation, persistence or journey impact analysis.

## Reproduction

Engine: `E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.
Set APPDATA and LOCALAPPDATA to fresh `.godot/<qa-run>/{app,local}` inside this
worktree before **every** engine command; no real player profile is used.

```powershell
python -X utf8 scripts/run-experiment.py layout_strategy --godot <exe> --prepare-only --profile w6-evidence
```

Final prepared project: `.godot/experiments/35a924fb9fd6/project`.
Baseline prepared project: `.godot/experiments/7e02f34db874/project`.
Scratch driver: `.godot/w6_capture.gd`; run it with `--script res://w6_capture.gd`
after copying into the prepared project (`-- --before` for the baseline).
The driver instantiates the lab, waits for settled GPU frames, then calls:

```gdscript
host.run_current()                         # one run
host.set_baseline()
host._edit_value("query_group",4)
host._edit_value("record_tile",1)
host.run_current()                         # comparison
host.open_challenges()                     # challenge frame
host.challenge_window.dismiss()
host.toggle_language()                     # English comparison
```

Screenshots use these presenter actions; the GPU suites below additionally
exercise viewport mouse/keyboard input, popup focus, restoration and persistence
guards. They do not establish native OS mouse acceptance.

## Verification

Round 2 final orchestration: `.godot/w6_r2_verify.py`; full logs and receipt:
`.godot/w6-r2-final/`. It uses the imported isolated project at
`.godot/verification/20261107T164239Z-47ed0a28/project`, refreshes the five source
files byte-for-byte, and gives every engine process fresh APPDATA/LOCALAPPDATA.
Scratch uses `.godot/w6-r2-tmp` because the sandbox only permits worktree writes.
The six headless and five GPU fixtures and arguments are the same as below.
Earlier Round 2 failures remain in `20261107T164239Z-47ed0a28`: they detected
the removed goal-exclusion text and a corrupted Chinese test literal; both
are corrected in the final source. Prior-round results below remain historical.
The first final GPU structures run also caught a fixed 720x540 screenshot
expectation for the now content-sized starter code window. Its height assertion
now requires at most 540 px, retains all four content-bound checks, and captures
the actual height at 720 px width. The focused headless/GPU recheck and nonzero
copy smoke are in `.godot/w6-r2-recheck/` (`.godot/w6_r2_recheck.py`).

Final Round 2: **6/6 headless suites, 1822 checks; 5/5 GPU suites, 1542 checks;
zero failures**. Final counts (headless/GPU): UI 224/252, Notebook 159/177,
Challenge 250/282, Explanation 430/headless only, Explanation UI 453/481,
Structures 306/350. The focused Structures recheck supersedes its earlier
fixed-height screenshot failure. All six source/test files match the tested
copy byte-for-byte. Five main routes, the minimum-size English comparison,
and Chinese/English challenge pages were visually inspected. The nonzero-copy
smoke measured 80 B with its track present; frame: `.godot/w6-r2-final/copy-space.png`.
`git diff --check` passes. Native OS mouse interaction and exports remain unverified.

Headless command (six suites, 1818 checks, zero failures):

```powershell
python -X utf8 scripts/verify-project.py --godot <exe> --suite test_layout_strategy_ui --suite test_layout_strategy_notebook_ui --suite test_layout_strategy_challenge_ui --suite test_layout_strategy_explanation --suite test_layout_strategy_explanation_ui --suite test_layout_strategy_structures_ui
```

Receipt: `.godot/verification/20261107T162221Z-07753083/`.
Counts: UI 222, notebook UI 159, challenge UI 250, explanation 430,
explanation UI 453, structures UI 304. Subsequent final changes only localized
new chart strings, collapsed the empty table and removed redundant presenter
state; final-source GPU checks are recorded below.

The first test attempt exposed two 960×640 challenge-summary overflow failures;
these were fixed by shrinking the graph at small heights. Original logs remain
in `.godot/verification/20261107T161925Z-5ed7d4a5/`.

Final GPU command, repeated for each fixture:

```powershell
<exe> --path <final-project> --windowed --resolution 1280x720 --script res://tests/test_layout_strategy_<fixture>.gd -- --capture-size=1280x720 --layout-<capture>-capture
```

Fixture/capture pairs: `ui/strategy`, `notebook_ui/notebook`,
`challenge_ui/challenge`, `explanation_ui/explanation`, `structures_ui/structures`.
Fresh isolated APPDATA/LOCALAPPDATA per fixture. Exact orchestration and full
logs: `.godot/w6_gpu.py`, `.godot/w6-gpu/`.

Final-source GPU: **5/5 suites, 1538 checks, zero failures**:
UI 250; Notebook 177; Challenge 282; Explanation UI 481; Structures UI 348.
Both locales and 1280×720/960×640 are exercised. The modified presenter/test/PO
files in the final prepared copy match the worktree byte-for-byte.
Additional nonzero-copy GPU smoke: 8 requests, measured peak 80 B;
raw frame `.godot/w6-gpu/copy-space.png` (outside the ten comparison frames).
English Notebook, Challenge and Explanation raw frames are in each GPU fixture's
isolated `app/VonNeumannBottleneckChecks/layout_strategy/w6-evidence/` directory.
All ten comparison PNGs and these extra English frames were visually inspected.
`git diff --check` passes.

## Limits

Windows/NVIDIA local Godot only; exports, other OSes and newcomer comprehension
are unverified. The engine reports its existing root-certificate-store error;
no network functionality is exercised. No shared style files were edited.
