# W3 · Chapter 6 service workbench · 2026-11-08

Ready for Claude review; uncommitted. Simulation, contracts, task IDs, saves and original signal marks are unchanged.

## Before / after (owner-review trade-offs)

| Route | Before | After | Visible change |
| --- | --- | --- | --- |
| `service/move_state`, pending | [before](before-move.png) | [after](after-move.png) | Compact pending target card replaces empty lanes and history. |
| Same route, initial measured run | [before](before-run.png) | [after](after-run.png) | Verdict and larger real response/state lanes lead; history retains source/configuration and quality errors. |
| `service/prompt_response`, pending | [before](before-prompt.png) | [after](after-prompt.png) | Same hierarchy; active task is marked. |
| `service/one_plan`, pending | [before](before-plan.png) | [after](after-plan.png) | Same hierarchy; full contract remains visible. |

English: [measured overview](after-run-en.png), [state journey](after-state-en.png). All 11 PNGs are 1280×720 and visually inspected. English labels and state evidence fit. The footer is reserved for edit/event hints; verdicts stay above the response bars.

Other review choices: task tabs and references occupy separate rows; edit list, tools, LRU and codec chips share one scrolling column; run/undo actions stay fixed below; Run remains the sole primary action after success. Journey navigation is Map → Laboratory → Settings; visible Quit is standalone-only. No replay pacing changes.

## Changed files

- `experiments/service_plan/lab.gd`: navigation, pending/result visibility, task emphasis, readable type and grouped editor/footer.
- `experiments/service_plan/response_journey_view.gd`: scale-aware canvas type, larger state/response view, right-aligned numeric columns.
- `experiments/service_plan/state_replay_view.gd`: secondary text remains at least 13 physical pixels at the default 0.8 window scale.
- `tests/test_service_plan.gd`: scroll viewport bounds and verdict location assertions; more precise geometry failure diagnostics.
- `tests/test_service_player_input.gd`: existing verdict assertions read the upper verdict label, following the requested status-line change; input and numerical expectations retained.
- `localization/game.{zh_CN,en}.po`: append-only W3 block, two shortened helper strings.
- This README and 10 PNGs (six final routes recaptured in Round 2; four baseline images retained).

## Verification

Engine: `E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.
Each command ran from this worktree. The verifier creates separate imported projects and APPDATA/LOCALAPPDATA; captures also used fresh isolated directories. Scratch lives in `.godot/w3/` because this sandbox permits writes only within W3.

Exact verifier invocations (prefix `python -X utf8 scripts/verify-project.py --godot <engine>`):

1. Baseline: `--suite test_service_undo_context` → **124 checks, 0 failures** (`.godot/verification/20261107T161727Z-6346bc5f`). The older baseline failure does not reproduce here.
2. `--suite test_service_player_input --suite test_service_plan --suite test_service_journey_input --suite test_service_learning_ui --suite test_service_commission_ui --suite test_service_design_shelf --suite test_service_undo_context --suite test_service_context_navigation --suite test_service_number_display --suite test_service_state_replay --suite test_service_state_replay_view --suite test_service_split_actions` (`20261107T162857Z-07356daf`). Reused unaffected passing results: context 21, number display 24, split 30, replay projection 3118, undo 124.
3. `--suite test_service_player_input --suite test_service_plan --suite test_service_state_replay_view --suite test_service_journey_input --suite test_service_learning_ui --suite test_service_commission_ui --suite test_service_design_shelf` (`20261107T163111Z-f4badcb8`). Final Chinese passes: player input 50, replay view 71, journey input 15, learning 51, commission UI 27, design shelf 48. The plan suite's two scroll-content geometry assertions were then updated as described above.
4. `--suite test_service_plan --suite test_service_player_input --locale en` (`20261107T163259Z-ee2f2a96`) → **7268 + 50 checks, 0 failures**; the plan suite itself checks Chinese and English layouts.

Final successful coverage: **12 distinct suites / 10847 checks / 0 failures**, plus the English repeat. Earlier implementation failures were corrected; their raw logs remain under `.godot/verification/`. No baseline failures are being waived. `git diff --check` passes.

Navigation smoke: `.godot/w3/nav.gd` activated both real header buttons, verifying `task_tree.tscn` and `prototype_hub.tscn` destinations (`nav2.log`: 2 passes). A Windows certificate-store warning occurs at engine startup; no network behavior is claimed.

## Capture reproduction

Pending baseline images used the documented `-- --test-mode --dev-enter=service/<key>@2 --dev-shot=<absolute PNG>@9 --dev-quit=10` route after initial import. Measured baseline uses the untouched baseline verifier project. Final captures use `.godot/w3/capture.gd` and `.godot/w3/captures.py`: ordinary Test-mode navigation, settle 8 seconds, call the public `run_current()` for measured images, wait 4 seconds of existing replay; state capture calls `show_response_history()`. The two real viewport-input suites independently exercise Run, slot/format edits, replay and continuation. Capture calls are presentation evidence, not physical-mouse acceptance.

Re-run final PNGs with `python -X utf8 .godot/w3/captures.py`; this sets fresh APPDATA/LOCALAPPDATA for each route. The scripts/logs are local ignored scratch, retained for the lead's review.

Proposals needing impact analysis: none. Not verified: physical mouse feel, high DPI, novice comprehension, full-game or packaged acceptance. Owner should review the reduced pending display and fixed footer/scroll trade-offs before integration.

## Round 2 review fixes

Secondary actions use InstrumentTheme's outlined nav style, including Handbook; unavailable actions are dimmed. Codec chips retain the displayed representation and latch on for alternatives to RAW64. The compact target card shows pending marks before a run and selected-record values afterwards (rejected records retain pending marks); other evidence tabs retain their own full reading area. LRU follows Split directly. The response lanes keep the larger type while reducing vertical spacing. English verdict numbers have spaces, and the footer contains editing/event hints only.

Fresh final verification and recapture evidence are recorded below. Initial Round 2 failures exposed stale status-label assertions and insufficient height for the success/continuation state; both were corrected. Raw failed logs are retained locally. Test assertion relocation in `test_service_player_input.gd` is the sole additional file beyond the Round 1 owned set; it is required by the reviewed verdict/status separation.

Final Round 2 run: the exact 12-suite invocation in Verification item 2, using the same engine, completed in `.godot/verification/20261107T165200Z-20b17188`: **10847 checks / 0 failures**, all 12 suite results and import/profile checks passed. English repeat: `--suite test_service_plan --suite test_service_player_input --locale en` in `20261107T165050Z-36e01fc1`: **7268 + 50 checks / 0 failures** (before the final response-row spacing adjustment; final plan suite still checks both languages). The known engine certificate-store warning persists; no script/runtime errors were waived. Final `git diff --check` passes.

Final captures use the same six routes in `captures.py`, each with a fresh UUID-suffixed APPDATA/LOCALAPPDATA profile; logs are `.godot/w3/after-*-final.log`. No simulation, save, commission, progression or model files were changed. Physical-input feel/high DPI/full-package acceptance remain unverified.

## Round 3 review fix

The target card includes inline excess for failing items. The verdict is one short line; history keeps source/configuration and score/final-state errors without repeated totals. Detailed failure and continuation text remains in the verdict tooltip. Response bars are 26 units tall with 28-unit row spacing, and the chart receives the freed height. The late-response chart caption explains the outcome without repeating measured/limit numbers. Commission feedback remains unchanged.

Changed this round: `lab.gd`, `response_journey_view.gd`, the existing assertions in `test_service_plan.gd` and `test_service_player_input.gd`, this README, and three PNGs. No other production files changed this round; no commits.

Fresh 1280x720 captures: [after-run Chinese](after-run.png), [after-run English](after-run-en.png), and [Task 2 measured English](after-prompt-run.png). All three were visually checked. Reproduce with `python -X utf8 .godot/w3/captures-round3.py`; each launch uses fresh UUID-suffixed APPDATA/LOCALAPPDATA. Logs: `.godot/w3/after-*-round3.log`. Older pending/state captures remain Round 2 evidence.

Final 12-suite verification: **10847 checks / 0 failures**, all 12 suites and import/profile checks passed in `.godot/verification/20261107T170414Z-2e39efae/results.json`. The plan suite includes both locales. The known engine certificate-store warning persists; no runtime failures were waived. The earlier failed attempt is retained at `20261107T165907Z-6ea10d02`; the corrected run `20261107T170152Z-7ccb6dd1` also passed all 12 suites before the last caption-only change and stricter stream-label assertion. `git diff --check` passes. The exact invocation is Verification item 2 with the pinned engine above. Physical mouse feel, high DPI and packaged acceptance remain unverified.
