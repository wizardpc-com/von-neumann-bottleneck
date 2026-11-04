# D1 input and recovery diagnosis - 2026-11-04

Base: `0ba32e2`, branch `claude/ux-d1-input-20261104`. No runtime, simulation, judgement, save-schema, cadence, or localization changes. The diff adds reproducible diagnostic tests and this evidence. Original 2026-10-28 native input incident remains OPEN.

## Findings

The old native TextEdit `line -1` incident remains **OPEN**. Its original `demo-zh-round2.log` was not found by recursive exact-filename search under `E:/VNB/temp`; the retained observation is `docs/verification/20261028-content-discovery/README.md:35`.

The suspected third-chapter control is `CodeEdit` / `OverlapProgram` (`src/overlap_chapter/overlap_chapter.gd:726`). `text_changed` calls `_changed(false)` at line 734 without replacing the editor/text; `_save_draft` at line 568 reads text. Explicit caret navigation at line 963 is guarded by a positive, in-range line number. No game defect was established here.

The new probe distinguishes keycode-only injection (no character inserted) from Unicode input (accepted). This explains a possible injection artefact, **not the historical incident**. Both program controls passed Chinese Unicode, exact 4,608-character bilingual clipboard paste, autosave focus retention, and Ctrl+Shift+Up on long/first-line/empty text. Chinese and English GPU runs each passed 18/18; `input-gpu.txt` and `input-en.txt` retain full logs.

Windows Computer Use could not enumerate the sandbox-launched Godot window. OS keyboard/IME composition is therefore unverified. DisplayServer clipboard plus viewport Ctrl+V is separate evidence from OS SendInput. No root-cause workaround was guessed.

System retains workspaces every 2 seconds (`src/system_lab/system_lab.gd:336`); overlap waits 0.7 seconds after the last edit (`src/overlap_chapter/overlap_chapter.gd:143`, timer reset at 557). Layout retains accepted edits immediately (`src/layout_chapter/layout_chapter.gd:268`). GlobalSave saves on their persistent-state signals (`src/save/global_save.gd:617`). Test-mode overlap/system drafts omit Game persistence signals and must not be used to diagnose Game save loss.

## Recovery matrix

Each cell below is a **fresh process relaunch**, not a same-process model restore. Only isolated APPDATA/LOCALAPPDATA were used. Access-only `playtest/offline_tester` bypassed prerequisites; no completion/reward fixture was granted. Input is a deliberately invalid, un-applied program comment marker or a legal layout batch change, not an earned solution. The lab route executes the existing callback body and real scene exit; these are controller tests, not OS clicks.

| Scenario followed by relaunch | System / assembly | Overlap / arrival | Layout / fields |
| --- | --- | --- | --- |
| Normal GlobalSave.request_quit | Draft restored, still unapplied | Draft restored | Design restored |
| Return to map, then quit | Draft restored | Draft restored | Design restored |
| Return to laboratory, then quit | Draft restored | Draft restored | Design restored |
| Force termination immediately after edit | Latest edit absent | Latest edit absent | Design restored |
| Force termination 2.5 s after edit | Draft restored | Draft restored | Design restored |

15/15 observed outcomes match the documented retention boundaries; **13 recovered and 2 deliberately exposed pre-autosave losses**. Raw logs: `recovery-process.txt`; machine-readable results: `recovery-results.json`. Every attempted `taskkill /F /PID <owned child>` returned Access denied in this sandbox. Python's owning parent then used `Popen.kill()` (Windows TerminateProcess); the forced children exited 1 and could not run graceful save/exit handlers. This is genuine abrupt-process evidence, but successful taskkill execution is not claimed.

Unowned hardware/locality/creation/representation/service/prediction workbenches received existing departure/save regression coverage, not a new hard-kill matrix. Layout's unsubmitted scheme-name LineEdit is naming input, not a persisted design field.

## Screens

- `before-overlap.png` / `after-overlap.png`: identical startup route, Chinese 1280x720. No visual runtime change is claimed.
- `input-overlap.png`, `input-system.png`: actual Chinese GPU frames after long-text paste; invalid source is correctly displayed as invalid, not as a successful program.
- `en-overlap.png`, `en-system.png`: same input diagnostic in English .

Baseline was captured before test/runtime edits. These are diagnostic observations, not a redesigned text control or a new product flow. The system panel retains its existing scrollable validation messages.

## Reproduction and verification

Pinned Godot: `E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` (`4.7.1.stable.official.a13da4feb`). Run from this worktree only. Every direct Godot launch must set APPDATA and LOCALAPPDATA to the same fresh `.godot/d1-runtime/<run>` directory first. First import: Godot `--headless --path <worktree> --import`.

```
python -X utf8 tests/test_process_recovery.py
```

The process probe creates a fresh timestamped profile root below `.godot/d1b/process-*`, records exact process outcomes and taskkill diagnostics, and exits nonzero if an outcome differs from the expected retention boundary. The retained evidence run used `.godot/d1-process/*-r2`; the final harness only adds unique output naming and explicit expected-outcome assertions to that run.

```
<godot> --path <worktree> --script res://tests/test_text_input_unicode_clipboard.gd -- --d1-capture=<absolute directory>/input-
<godot> --path <worktree> --script res://tests/test_text_input_unicode_clipboard.gd -- --locale=en --d1-capture=<absolute directory>/en-
```

The input test preserves and restores the previous OS clipboard. Headless execution skips clipboard/GPU assertions (14 checks); GPU execution performs 18 checks. All typed characters come from Unicode events or an actual clipboard paste. It does not simulate IME composition.

```
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_text_input_unicode_clipboard --suite test_global_save --suite test_recovery_settings_language --suite test_recovery_departure_paths --suite test_terminal_language_input --suite test_hardware_settings_input --suite test_chapter_settings_input --suite test_settings_language_input --suite test_workbench_escape --suite test_offline_feedback --suite test_overlap_ui --suite test_system_lab_ui --suite test_layout_ui
```

13/13 focused suites passed, 0 failed. Printed assertion totals: D1 input 14/0 headless; chapter Settings 26/0; departure recovery 161/0; Settings/language recovery 754/0; workbench Escape 105/0. Other suites print a suite-level PASS without an assertion count. Chinese and English GPU probes each passed 18/18.

An additional existing GUI probe was run with `<godot> --path <worktree> --script res://tests/test_recovery_game_input.gd -- --interaction-only --evidence-dir=<worktree>/.godot/d1-recovery-gui` under its own isolated APPDATA. It failed 3 of 4 checks before reaching tutorial input: `tests/test_recovery_game_input.gd:789` expects a visible `HubBrowseJourney`, which is not visible in the current hub flow. See `recovery-gui.txt`. This is pre-existing on the unchanged base runtime, not a D1 text-editor regression. The full GUI recovery journey did not run. No unowned hub/test code was changed.

Suite results are recorded in `suite-results.txt` and `suite-results.json`. Root-certificate-store errors are an environment diagnostic explicitly filtered by the established verifier; they are retained in the full logs. No TextEdit line error was filtered. Counts not printed by an existing suite are reported as suite pass/fail, not invented assertion totals.

## Proposals needing impact analysis

Preventing the demonstrated pre-autosave loss requires immediate text retention or a visible pending-save indication. Analyze `src/system_lab/system_lab.gd`, `src/overlap_chapter/overlap_chapter.gd` and GlobalSave disk frequency/failure handling; risks include disk churn during typing/IME and changed save semantics. Cadence changes were explicitly forbidden here. No evidence-based unowned runtime patch was identified.

## Limits

Original native anomaly unresolved; no physical keyboard/IME, successful OS taskkill, full GUI recovery journey, new hard-kill matrix for unowned workbenches, real player profile, exported package, Mac input, or disk-full/power-loss interruption during atomic writes. RELEASE_BLOCKERS native-input acceptance remains open. No commit, merge or push.


## Round 2 ? GUI routing and window close

The GUI probe opens the current laboratory terminal with viewport Enter, clicks
its real `TerminalJourney` control, and waits for the animated map transition.
After the map, the existing recovery replay explicitly selects classic tutorial
presentation for its original Mission assertions. Layered hints are reached by
clicking the current Yi card's `YiHelp_more` button. Recovery assertions are retained.
No runtime file, persistence cadence, schema or judgement changed.

Renamed probes: `tests/test_text_input_unicode_clipboard.gd`,
`tests/recovery/process_recovery_probe.gd`, `tests/test_process_recovery.py`.
The verifier discovers the first automatically via `tests/test_*.gd`; Python
process orchestration is run separately. Usage and its abrupt-kill boundary are
now documented at the top of `docs/development/testing.md`.

Added matrix row (fresh process per edit and relaunch):

| Scenario followed by relaunch | System / assembly | Overlap / arrival | Layout / fields |
| --- | --- | --- | --- |
| Immediate window close notification mid-edit | Draft restored | Draft restored | Design restored |

`root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)` reaches the real
GlobalSave and workbench scene tree, with `auto_accept_quit = false` as in ordinary
startup. No direct `request_quit` call or manual save occurs in this scenario.
All three edit processes exit 0 and relaunches restore their markers. This verifies
the notification handler, not an OS title-bar click. No runtime fix was needed.
The complete six-scenario matrix passes **18/18**, including two expected early-kill
losses; see `round2-process.txt` and `round2-process-results.json`.

Commands (from worktree root, the same pinned Godot executable above):

```
python -X utf8 tests/test_process_recovery.py
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_text_input_unicode_clipboard --suite test_global_save --suite test_recovery_departure_paths --suite test_lab_terminal_routing
<godot> --path <worktree> --script res://tests/test_recovery_game_input.gd -- --recovery-capture --evidence-dir=<worktree>/.godot/d1b/gui-7
<godot> --path <worktree> --script res://tests/test_recovery_game_input.gd -- --interaction-only --locale=en --recovery-capture --evidence-dir=<worktree>/.godot/d1b/english-final
```

Each GUI invocation used fresh APPDATA/LOCALAPPDATA under `.godot/d1b/`.
Fresh unchanged-step baseline: **6 checks, 3 failures** with capture assertions
included (`round2-before.txt`); the non-capture Round 1 run had 4 checks, 3 failures.
`round2-before-map.png` shows the room where the hidden-button probe stopped.
The matching after-map capture records the same logical route checkpoint.

No new proposals needing impact analysis. Original native IME/input anomaly and
power-loss/atomic-write boundaries from Round 1 remain open. The GUI replay's
hardware portion covers classic Mission presentation, not the focused tutorial.

Focused verifier: **4/4 suites passed, 0 failed** (plus import and user-directory checks). Text input: **14 checks, 0 failures** headless; departure recovery: **161 checks, 0 failures**; lab routing: **39 checks, 0 failures**; global save prints suite-level PASS. Exact logs and verifier results are retained with `round2-` prefixes.

The replay also follows the current one-shot placement flow: Escape is sent only
while placement is still armed, Inspector closes before another placement, and
AND/OR fixture points use empty canvas rather than overlapping NOT. Fullscreen
still checks real window-mode changes, using the existing F11 shortcut. These are
test-driver changes; the circuit, hint isolation, undo/redo, completion and earned
hardware assertions remain in place.

Full Chinese GUI replay: **764 checks, 0 failures**, process exit 0. This includes
the original recovery/editing/hint/camera assertions and ordinary Game builds of
all nine required prologue tasks, followed by entry into SystemLab through the
earned gate. `round2-gui.txt` and `round2-gui-observations.json` retain the complete
run. The root-certificate-store environment error is retained as in Round 1;
no script/input errors are filtered.

Screens (10 total including the six Round 1 PNGs):
- `round2-before-map.png` / `round2-after-map.png`: same map-entry checkpoint,
  before probe stops in the room; after probe reaches the actual map.
- `round2-after-chapter1.png`: final ordinary Game chapter 1 entry.
- `round2-en-map.png`: English map checkpoint, visually inspected.

The existing GUI probe starts at 1600x900 and checks the Mission controls
at 1280x720 in both languages. No product layout was changed. Round 1's Chinese
1280x720 input frames and clipboard checks remain applicable to unchanged runtime.

English interaction-only GPU replay: **246 checks, 0 failures**, exit 0 (`round2-english.txt` and `round2-english-observations.json`). Full English hardware construction was not rerun.
