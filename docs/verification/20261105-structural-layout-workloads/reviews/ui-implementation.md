# Round7 structural scheduling UI implementation

Owner `/root/audit_polish`. **READY FOR ROOT RUNTIME REVIEW.**
All assigned UI/test files are **RELEASED to root** after static review.
No Godot/native process, Git mutation, profile access, commit or push was
performed by this agent. No parser, headless, GPU or native PASS is claimed.

Read the frozen implementation contract and
`docs/exec-plans/active/structural-layout-workloads-20261105.md` before edits.
Preserved root's controller edits, model/codec ownership, both stores, fixtures,
docs and all unrelated changes.

## Changed owned files

- `experiments/layout_strategy/lab.gd`
  - Builds the selector from `Model.SCENARIO_IDS`, using the same
    `ChallengeWindow.workload_text()` labels as titles and foreign-code routing.
  - Adds optional `legacy_notebook_path`/`legacy_challenge_path` fixture inputs;
    passes them only through the frozen controller setup APIs.
  - Distinguishes fresh, loaded earlier/new-copy-unsaved, current saved,
    write-failed and protected earlier-source states. Read-only protection
    takes precedence over temporary proposals and pending-copy feedback.
  - Notebook and challenge copies retain independent explicit Save/Retry and
    exit actions. Successful Notebook copy cannot silently save targets or exit
    while targets still need copying. Target-copy action says Save target copy.
  - Context includes `starter_task` and `copy_pending`. Starter requests are
    checked against the currently open workload and its actual curated goal.
  - Mixed-workload guidance no longer advertises a nonexistent starter.
  - Retained invalid groups are shown at their exact original value, including
    group8 in a two-job serial draft. The serial group editor is enabled only
    while invalid so players may explicitly repair it to1; valid serial controls
    stay inactive. Query tiling stays inactive for any serial/invalid grouping.
    No Session/model normalization or validation semantics changed.
  - Clears stale pending numeric ownership on workload change.
- `experiments/layout_strategy/challenge_window.gd`
  - Adds the two frozen bilingual names.
  - Replaces the old BatchStarter/SerialStarter pair with one `CurrentStarter`
    (`starter_button` property), visible iff the current `starter_goal()` exists.
  - Contextual starter emits the current task, previews the real code, and still
    needs explicit acceptance. Hidden starter is removed from Tab traversal.
  - Saved-copy action translation uses controller pending/protection state.
  - Preserved root's prior selected/read-only TextEdit colors and all input,
    settings, F8, preview invalidation, clipboard and focus behavior.
- `tests/test_layout_strategy_ui.gd`
  - Adds exact original-four-prefix and six-selector assertion; keeps the
    existing original metrics and UI acceptance anchors.
- `tests/test_layout_strategy_challenge_ui.gd`
  - Existing old batch starter route now activates `starter_button`.
  - Current stale-target storage fixture uses version2; unknown version99 stays.
- `tests/test_layout_strategy_structures_ui.gd` (new)
  - Uses actual model/Session, controller state, real saved inputs and inherited
    viewport-key/button helpers, never fabricated score rows.
  - Pair source/copy measurements assert307/614/544/0 versus557/672/500/80 and
    ordered outputs. Both recent and kept rankings reverse under identical
    Q1≤600/copy≤80 when switching cycles to RAM. Evidence/draft stay unchanged.
  - Phased direct, temperature-only, record-major two-field and field-major
    runs assert exact outputs and metrics, including727/1516/1032/144.
  - Verifies public2/8/9 job bounds, phase ordering, inactive serial controls,
    per-condition drafts/Undo/Redo/history/selected Trace/baseline/goals/kept
    plans/targets, and post-switch mixed numeric submission.
  - Exercises contextual pair/phased preview+accept, old/new and new/new foreign
    codes, hidden mixed starter and unchanged exploration during preview.
  - Loads an actual persisted unfinished pair draft with group8, rejects its
    exact visible input, explicitly repairs via numeric Cmd/Ctrl+Enter, then
    Undoes to8 and rejects again without fabricating a run or writing disk.
  - Consumes root's frozen e1 `notebook_v1`/`targets_v1` strings verbatim for
    loaded-earlier UI, real independent copy saves during exit, reopen and
    original byte preservation.
  - Tests protected earlier source precedence/temporary targets/failed exit
    saves, plus explicitly saving an intentionally empty legacy target map.
  - Tests/captures Chinese and English at1280×720/960×640 and popup720×540.
    `--layout-structures-capture` saves14 checked raw PNGs total and prints
    absolute paths. No desktop capture or unverified manual input is implied.

`tests/test_layout_strategy_notebook_ui.gd` was reviewed and remains unchanged:
it has no version1 current-payload literal requiring conversion.

## Static verification

- `git diff --check` passed after edits.
- Inspected complete owned tracked diff and full new suite.
- All six assigned text files have zero trailing-whitespace lines.
- Current selectors retain original first-four order and original labels.
- No BatchStarter/SerialStarter/batch_button/serial_button references remain in
  owned source/tests.
- Only isolated fixture paths are authored at runtime; inherited official-file
  and mode guards remain in new suite.
- Did not create Godot UIDs or synchronize/run root's QA copy.

## Root verification requested

After current model/store/controller integration is synchronized/imported:

1. Run `test_layout_strategy_structures_ui` headless first. Inspect full errors,
   especially newly exercised retained-invalid SpinBox focus and both-source
   protected exit geometry; do not weaken assertions to accommodate defects.
2. Regress `test_layout_strategy_ui`, `test_layout_strategy_notebook_ui` and
   `test_layout_strategy_challenge_ui`, plus root's controller/upgrade suites.
3. Run new suite graphically with `--capture-size=1280x720` and
   `--layout-structures-capture`. It resizes root/popups explicitly and checks
   the actual images and save results. Independently inspect the14 raw frames.
4. Native new pair/phased exploration and upgrade-copy interactions remain
   separate acceptance. No new-native claim follows from old Round6 evidence.

This report releases files; further edits require root reassignment.
