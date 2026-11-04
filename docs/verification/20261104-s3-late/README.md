# S3 late slice — 2026-11-04

Prediction now groups its four policy controls in two columns and displays a
horizontally scrollable request strip. Each revealed card reads the actual
`accesses` and `decisions` entries: address, cache hit/miss/in-flight path, next
guess, issued state, and previous guess correctness. Future requests remain
unknown. Pause reasons come from the predictor. Total waste and Off-baseline
costs remain the existing complete-run measurements; there is no inferred
per-request waste attribution. Events and History use their full reading area.

Creation keeps secondary comparisons behind More tools and hides the seven
evidence tab headings until More tools or Expand evidence is selected. Existing
tab contents, actions and primary guidance remain available. An empty signal
view shows a static examples → frozen rules → output schematic; it is not a
simulation trace. Saved-work ending guidance includes the protected work's name.
No model, judgement, save field or ending trigger changed.

## Chosen comparisons (1280 × 720, Chinese)

| Route | Before | After |
| --- | --- | --- |
| prediction/regular, Reveal ×3 | [before](before-pred-step.png) | [after](after-pred-step.png) |
| prediction/regular, Run to end | [before](before-pred-run.png) | [after](after-pred-run.png) |
| creation/C1_restore, entry | [before](before-C1_restore.png) | [after](after-C1_restore.png) |
| creation/P1_commit, first primary action | [before](before-P1-action.png) | [after](after-P1-action.png) |
| creation/G3_keep, entry | [before](before-G3_keep.png) | [after](after-G3_keep.png) |

All requested routes were captured before editing. Additional entry screens and
English creation/P1_commit before/after are in `.qa/captures/`; both English
frames were inspected. Only ten comparison PNGs are retained here.
Scratch uses `.qa/` because this task's writable sandbox excludes the supplied
external `sol/s3` directory. All Godot runs used isolated APPDATA/LOCALAPPDATA.

Capture command pattern (PowerShell, `$g` is the supplied 4.7.1 console exe):

```powershell
$env:APPDATA="$PWD/.qa/<unique-run>"; $env:LOCALAPPDATA=$env:APPDATA
& $g --path "$PWD" -- --test-mode --dev-enter=prediction/regular@2 --dev-shot=<entry.png>@4 --dev-click=65,557@5 --dev-click=65,557@6 --dev-click=65,557@7 --dev-shot=<step.png>@8 --dev-click=160,557@9 --dev-shot=<run.png>@10 --dev-quit=11
& $g --path "$PWD" -- --test-mode --dev-enter=creation/P1_commit@2 --dev-shot=<entry.png>@4 --dev-click=1200,95@5 --dev-shot=<action.png>@7 --dev-quit=8
```

Other creation entries substitute C1_restore/G3_keep. English adds `--locale=en`.
Baseline prediction used Reveal at 4/5/6, shot at 7, Run at 8 and shot at 9;
the same positions/actions were used. Startup tooltip timing can differ.

## Verification

Exact focused commands (each launched with fresh APPDATA/LOCALAPPDATA):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_creation_workbench --suite test_cpg_connection_fragment --suite test_creation_sample_editing --suite test_ending_cinematic --suite test_creation_draft_resume_input --suite test_creation_draft_undo --suite test_prediction_slice --suite test_prediction_workbench_presentation --suite test_prediction_player_input --suite test_prediction_record_source --suite test_prediction_navigation --suite test_prediction_goal_feedback --suite test_global_save
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_creation_workbench --suite test_cpg_connection_fragment --suite test_creation_sample_editing --suite test_ending_cinematic --suite test_creation_draft_resume_input --suite test_creation_draft_undo --suite test_prediction_workbench_presentation --suite test_prediction_player_input --suite test_prediction_record_source
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_prediction_workbench_presentation --suite test_prediction_player_input
```

| Suite | Final result |
| --- | --- |
| test_creation_workbench | PASS, 385 checks |
| test_cpg_connection_fragment | PASS, 508 checks |
| test_creation_sample_editing | PASS, 270 checks |
| test_ending_cinematic | PASS, 26 checks, 0 failures |
| test_creation_draft_resume_input | PASS, 75 checks, 0 failures |
| test_creation_draft_undo | PASS, 68 checks |
| test_prediction_workbench_presentation | PASS, 1297 checks, 0 failures |
| test_prediction_player_input | PASS, 54 checks, 0 failures |
| test_prediction_slice | PASS, 5591 checks |
| test_prediction_navigation | PASS, 31 checks, 0 failures |
| test_prediction_goal_feedback | PASS, 47 checks, 0 failures |
| test_global_save | PASS; suite reports no numeric count |
| test_prediction_record_source | FAIL, 1 / 28 checks; baseline reproduced |

12 suites pass; one pre-existing assertion fails. Its Chinese caption assertion
requires literal English `off`, whereas the existing `policy_caption` renders
关闭猜测. Reproduced with HEAD's original prediction/lab.gd in the first isolated
project: `.qa/baseline-source.log`. The baseline player-input suite passed 54/54.

Full results/logs: `.godot/verification/20261104T095524Z-93d58db5/` (unchanged
model/global-save/navigation/goal suites), `20261104T095821Z-14975714/` (final
creation suites and baseline-failing record source), and
`20261104T100536Z-00ad40fa/` (final prediction UI/input). Initial UI failures were
resolved; the final UI run includes the new strip-prefix assertions. Root
certificate-store warnings are excluded by the existing verifier.

## Limits and follow-up

- Implemented changes require no simulation or persistence changes.
- Full header unification needs coordination with src/ui ownership; navigation
  destinations and unsaved-work guards were retained.
- More tools folds secondary actions and evidence headings; the left editor and
  currently useful primary actions retain their established layout.
- Saved-name linkage is covered by ending regression, not a new native saved
  player journey through 10-2 → 10-3 → cinematic. Blank G3 capture has no work.
- Proposal needing impact analysis: per-fetch waste is not marked; current output records final aggregate
  waste without exposing final job-use identities. Adding authoritative
  per-fetch attribution would need model-owner analysis in prediction/model.gd.
- No full suite, physical input acceptance or human play-through is claimed.


## Round 2 — s3-late follow-up

Prediction uses a four-column policy row above a full-width request band. Cards
expose only the revealed prefix. Fetch cycles are `access.ready - access.arrived`
(including lookup and demand blocking, excluding subsequent compute and final
drain); they are not a share of total run cost. Guess correctness belongs to the
next revealed decision's `mismatch`; a pending guess never receives a verdict
from an unrevealed request. Issuance and suppression reasons remain in card
tooltips. Off cards omit guess fields. Completed bands compare the actual
`baseline_cycles` / `baseline_traffic_bytes` with this run's measured totals.
The detailed cost decomposition and immutable recording source remain available.
The duplicated address/history paragraph is replaced by the current decision reason.

Creation's empty view now marks selected examples, learned/frozen rules, current
session generation and existing saved works from session data. The arrow identifies
the first incomplete stage; saved works means the collection, not an assertion
that the current draft was saved. Existing output tracks take precedence.
Creation goal and optional-recipe copy are shorter. The controlled-comparison
constraints remain in the short line plus its full tooltip and existing Learn note.

Both headers place Handbook alongside the existing title/navigation/settings.
Prediction Hint moves to the header. Quit retains its handler but uses the normal
navigation style. Creation retains Journey and the existing guarded departure;
prediction retains its temporary-session discard guard and playtest exit hook.
No action was removed: creation Language is in the unit navigation row, prediction
Language is on Task and machine; Settings language remains available. Creation
keeps the original Save draft action. No shared chrome file was changed.
The unused round-1 PO blocks were removed; both PO files now match the base.

### Retained comparisons

Round-1's ten images remain. These ten additions bring the total to twenty:

| Route | Round-2 before | Round-2 after |
| --- | --- | --- |
| prediction/regular, reveal three | [before](round2-before-pred-step.png) | [after](round2-after-pred-step.png) |
| prediction/regular, Off run to end | [before](round2-before-pred-run.png) | [after](round2-after-pred-run.png) |
| creation/P1_commit, learn | [before](round2-before-P1-action.png) | [after](round2-after-P1-action.png) |
| creation/G3_keep, entry | [before](round2-before-G3.png) | [after](round2-after-G3.png) |

English: [creation after learning](round2-creation-en.png),
[prediction last-stride run completed](round2-pred-en.png).
C1_restore entry/action and additional captures are in `.godot/s3b/`; inspected,
but not duplicated in the retained twenty. English chapter title still uses the
existing ellipsis; the full task name remains in the unit selector.

Before routes used the round-1 click command above before any source edit.
Final creation uses the same command and primary-action position. Prediction's
changed layout moves the buttons, so final captures perform the identical three
`step_current()` operations followed by `run_current()` on the real instantiated
workbench. The English capture additionally selects Last stride through the real
OptionButton, calls `edit_policy()`, then `run_current()`. Capture scripts and full
logs: `.godot/s3b/capture_prediction.gd`, `capture.py`, `final.py`, `caponly.py`.
All capture profiles are isolated under `.godot/s3b/data-*` and each PNG is 1280×720.

### Fresh verification

Full round-1 suites plus direct Settings/departure neighbours:

```powershell
$env:APPDATA="$PWD/.godot/s3b/suites-data"; $env:LOCALAPPDATA=$env:APPDATA
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_creation_workbench --suite test_cpg_connection_fragment --suite test_creation_sample_editing --suite test_ending_cinematic --suite test_creation_draft_resume_input --suite test_creation_draft_undo --suite test_prediction_slice --suite test_prediction_workbench_presentation --suite test_prediction_player_input --suite test_prediction_record_source --suite test_prediction_navigation --suite test_prediction_goal_feedback --suite test_global_save --suite test_late_settings_localization --suite test_recovery_settings_language --suite test_recovery_departure_paths
```

Final affected-suite reruns (each with a fresh isolated profile):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_creation_workbench --suite test_prediction_workbench_presentation --suite test_prediction_player_input
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_prediction_workbench_presentation --suite test_prediction_player_input
```

| Suite | Final result |
| --- | --- |
| test_creation_workbench | PASS 385 checks |
| test_cpg_connection_fragment | PASS 508 checks |
| test_creation_sample_editing | PASS 270 checks |
| test_ending_cinematic | PASS 26 checks, 0 failures |
| test_creation_draft_resume_input | PASS 75 checks, 0 failures |
| test_creation_draft_undo | PASS 68 checks |
| test_prediction_slice | PASS 5591 checks |
| test_prediction_workbench_presentation | PASS 1221 checks, 0 failures |
| test_prediction_player_input | PASS 54 checks, 0 failures |
| test_prediction_record_source | FAIL 1 / 28; reproduced on untouched 0ba32e2 |
| test_prediction_navigation | PASS 31 checks, 0 failures |
| test_prediction_goal_feedback | PASS 47 checks, 0 failures |
| test_global_save | PASS; no numeric count emitted |
| test_late_settings_localization | PASS 511 checks, 0 failures |
| test_recovery_settings_language | PASS 754 checks, 0 failures |
| test_recovery_departure_paths | PASS 161 checks, 0 failures |

15 suites pass, one existing assertion fails. Read complete logs in
`.godot/verification/20261104T101519Z-f9621fa5/` for unaffected suites,
`20261104T102251Z-e6ebb02a/` for final creation, and
`20261104T103059Z-1bb94381/` for final prediction. The earlier prediction geometry
and creation Language-visibility failures were corrected; intermediate logs remain
in scratch. Presentation tests deliberately replace the always-visible Language
expectation with reachability on Task and machine, and add full-width band,
real-baseline, inactive-field and prefix-boundary checks. No task text assertion
or formal gameplay contract was changed.

Untouched baseline: `.godot/s3b/baseline.py` exports `git archive --format=zip
0ba32e2` into `.godot/s3b/base`; it byte-compares the prediction lab, model and
record-source test against `git show 0ba32e2:<path>`. No worktree registration,
stash, branch operation or main-checkout write was needed. After isolated import:

```powershell
$env:APPDATA="$PWD/.godot/s3b/data-baseline-record"; $env:LOCALAPPDATA=$env:APPDATA
& E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --path "$PWD/.godot/s3b/base" --headless --script res://tests/test_prediction_record_source.gd
```

`.godot/s3b/baseline-record.log`: exit 1, 1 failure / 28 checks,
`Cross-task caption identifies the record and rule`. The Chinese caption uses
关闭猜测 while this old assertion requires the English literal `off`.
The root certificate-store warning is also present on the untouched base and is
excluded by the existing verifier. Godot-generated untracked UID files from root
import were inventoried/hashes retained in `.godot/s3b/generated-uids.json` and
removed individually; no unrelated source changes were removed.

### Limits / impact-analysis proposals

No new simulation, judgement, task, save or reward changes. The round-1 proposal
for authoritative per-fetch waste attribution remains deferred to the model owner;
this round adds no such attribution. Quit remains as an action to preserve behaviour.
No full suite, native OS quit/relaunch, human play-through, or fresh saved-work
ending journey is claimed. The collection stage is observed state, not new save
acceptance evidence. Final diff passes `git diff --check`; changes remain uncommitted.
