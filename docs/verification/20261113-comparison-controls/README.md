# Comparison controls and navigation evidence — 2026-11-13

Base main `d4213aa0559b9432d9a9b9db62f4277cffe27616`, clean and remote-confirmed.
This block continues the active whole-chapter interaction goal. It changes the
optional scheduling lab presentation/input only; Chapter2 receives navigation
coverage and a correction to an earlier visual report.

## Behavior

The scheduling lab exposes one set of existing objective/Q1/copy controls above
Compare and Notebook. Recent runs and kept recipes retain separate ranking
populations; both use the same personal goal. Goal changes update the visible
ranking without a new measurement. Evidence and public data hide these controls;
challenge goals, saving, names and existing tabs retain their original ownership.

Numeric text held during inspection survives language rebuilding, including its
caret and selection. Rebuilding does not apply the number or create a run. Direct
language clicks and read-only public-data inspection follow the same protection;
Run and guarded departure keep their existing numeric commit behavior.

Reinspection of the prior exact Ch2 images shows Laboratory and Settings fully
visible. The previously reported clipping was a visual review error; a long task
subtitle uses the intended ellipsis. The new all-task navigation check verifies
actual rectangles, mouse hit tests and save/return paths across languages and
window sizes. No Chapter2 runtime layout change is justified or included.

No simulation, stored format, task gate, score rule, dependency or final art
choice changed. The goal remains active; narrow checks do not prove unfamiliar
players can complete every chapter without assistance.

## Verification

Pinned engine: Godot `4.7.1.stable.official.a13da4feb`, macOS Apple M2,
Compatibility renderer. All runs use QA copies and fresh isolated player profiles.
Candidate: `.godot/verification/20261113T171932Z-af31e4fd/project`.
Frozen baseline: `.godot/verification/20261113T164654Z-f3c671e5/project`.

| Check | Result | Evidence |
| --- | --- | --- |
| Import and isolated user directory | Pass | `logs/initial` |
| Final comparison/input regression | 145 checks, 0 failures | `logs/timing` |
| Same final comparison test, old production code | 129 checks, 52 expected failures; no script errors | `logs/negative` |
| Chapter2 all-task navigation, headless | 1212 checks, 0 failures | `logs/initial` |
| Comparison/input GPU | 175 checks, 0 failures; 8 raw frames | `logs/gpu-initial` |
| Final Chapter2 navigation GPU | 1220 checks, 0 failures; 4 raw frames | `logs/gpu-final` |
| Populated notebook and save-conflict GPU | 177 checks, 0 failures; 6 raw frames | `logs/gpu-final` |
| Explanation / pending exit / notebook, after runtime correction | 453 / 20 / 159 checks, all pass | `logs/corrected` |
| Other related suites, initial candidate | All pass | `logs/initial` |

The other suites are scheduling UI, challenges, structures, session, workspace,
Locality chapter UI and direct task navigation. In total 12 distinct suites have
passing staged evidence. These are not all a fresh rerun on the final source:
the later runtime correction changes only numeric restoration after rebuilding;
the directly affected comparison, explanation, exit and notebook paths were rerun.
The final Ch2 test-driver change was verified by the final GPU run.

The negative test skips menu operations when the old Compare page hides its
controls, so its total differs from the candidate. Its 52 failed assertions include
repeated languages/layouts, not 52 independent defects. Original code loses held
text on rebuilding, commits a directly focused number on Language/Public clicks,
and does not expose conditions on Compare. Candidate checks compare full session,
goal, dirty/disk state and run identity, then verify explicit Run commits once.
The immediate Run after rebuild is explicitly an API timing test; the ordinary
input scenarios use viewport mouse/keys. Neither is native OS input acceptance.

All 18 final images in `images/` are unscaled raw frames: bilingual Compare,
empty Notebook, populated Notebook, save-conflict feedback and Ch2 header states
at the stated1280×720/960×640 sizes. Review checks goal controls, ranking columns,
primary actions and navigation. Scrollable histories still require scrolling;
960px Ch2 canvas nodes may require panning while the top Run remains reachable.
The Ch2 images cover one task per locale/size; all-task rectangles and pointer
hits are covered by the automated test, not inferred from four pictures.

`source-manifest.json` binds 1214 candidate source/resource/test files to the QA
copy (excludes Markdown and generated import sidecars). `baseline-manifest.json`
binds 575 production source/resource files to base `d4213aa`. The baseline runs
the same final new comparison test. `artifact-manifest.json` records raw evidence
hashes. Runner result JSON files retain exact commands, profiles, exit codes and
errors; the initial verifier JSON records suite names, profiles and outcomes.

Reproduce the relevant isolated headless checks with the repository verifier:

```sh
python3 scripts/verify-project.py --godot /path/to/Godot \
  --suite test_layout_strategy_comparison_controls \
  --suite test_locality_header_navigation \
  --suite test_layout_strategy_explanation_ui \
  --suite test_layout_strategy_pending_exit \
  --suite test_layout_strategy_notebook_ui
```

For GPU evidence use a fresh QA profile, omit `--headless`, and run these scripts
sequentially: comparison with `-- --layout-strategy-capture`, header navigation
with `-- --locality-header-capture`, notebook with `-- --layout-notebook-capture`.
The exact sequential runner used here is retained as `run-boundary-checks.py`;
its repository-root lookup expects its original `.godot/collaboration/` location.
Branding checks and local documentation links also pass.

## Corrections and limits

The first scheduling implementation passed existing related suites but its new
numeric-text test still failed after language rebuilding. That failure is retained
and investigated separately from the original negative control. Independent review
also required a direct pending-number→Public tab check, not merely visiting Public
when the numeric editor had already lost focus. Diagnostic logs show the pending
binding was correct but the visible SpinBox reformatted its old committed value
later. Restoration now follows that update and is bound to the current control
instance. Repeated rebuilds and immediate explicit Run are separately covered.

The first Ch2 GPU attempt failed because the startup fullscreen transition yielded
a2560×1440 first image instead of1280×720. The raw wrong-size image and its log are
retained under `images-initial/` and `logs/gpu-initial/`; they are not final evidence.
The driver now reasserts windowed mode and dimensions on each retry, requires five
stable real frames and logs actual mode/window/image sizes. It never rescales an
image to pass. Final frames and checks pass after this driver-only correction.

This receipt distinguishes pure/model checks, viewport input and GPU pixels from
native input, exports and unassisted player understanding. The preceding native
attempt encountered a locked Mac; this block does not inherit a native pass.
