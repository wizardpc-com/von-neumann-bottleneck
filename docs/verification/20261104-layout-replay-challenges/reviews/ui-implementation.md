# Round6 challenge UI implementation

Owner `/root/audit_polish`; status **focused verification passed; all three files RELEASED to root**.

Frozen scope read from `.godot/collaboration/round6-implementation.md` and
`docs/exec-plans/active/layout-replay-challenges-20261104.md`.

Owned files:

- `experiments/layout_strategy/lab.gd`
- `experiments/layout_strategy/challenge_window.gd` (new)
- `tests/test_layout_strategy_challenge_ui.gd` (new)

No other production/test/doc files will be edited. Root retains all engine/Git
operations. Existing model, Session, goals, Notebook and formal challenge
contracts are read-only.

Implementation: separate modal challenge surface, selected measured recipe
sharing, explicit preview/accept/restore and immutable challenge comparison.
Target storage stays distinct from Notebook saving. Four known numeric editors
commit before shortcut/mouse Run. Root's fresh
`.godot/collaboration/round6-spin-api.log` confirms installed Godot4.7.1 exposes
`SpinBox.apply()` and verifies expression/clamping behavior.

## Delivered behavior

- Compact Challenges entry and current target summary in Compare; no permanent
  tab, model, workload, goal or Notebook schema change.
- Scene-free exclusive Window with measured selected-recipe sharing, separate
  reply action using the immutable target goal, explicit import preview and
  acceptance, two opt-in direct-source starters, retained/stale code display,
  target evidence inspection and one-Undo restore.
- Preview is bound to exact current editor text; editing or text Undo invalidates
  confirmation. Import, preview and acceptance preserve exploration state.
  Foreign-workload codes explain where to switch; no automatic navigation.
- Current target storage status distinguishes saved, temporary, failed removal,
  protected and other-workload pending changes. Retry writes controller proposal,
  independent of current personal goal. Recovery is explicit and separate.
- Notebook wording now says personal conditions to distinguish these from
  challenge targets. Notebook Save never saves targets. Pending target changes
  appear in the exit guard with their own retry action; Save Notebook cannot
  silently leave/discard a pending target.
- Numeric Command/Ctrl+Enter and keypad Enter intercept only the four known
  editable SpinBox LineEdits, apply the native value then run once. Pending
  numeric mouse Run also commits; ordinary Enter and other text owners remain.
- Window F8 routes ordinary feedback to the active window. F10 suspends the same
  Window for existing Settings, follows replacement Settings layers during locale
  change, then returns to the same editor/preview/text Undo/focus. Locale changes
  update window labels without rebuilding its TextEdit.
- Main challenge page scrolls at the720×540 window minimum, keeping header/Close
  fixed; code page has its own full bounded layout. Root main minimum remains960×640.

## New behavioral suite

`tests/test_layout_strategy_challenge_ui.gd` inherits existing viewport helpers
and uses actual model/controller/store and isolated unique profile paths.

Coverage includes numeric actual key events, keyboard/keypad commit, expression,
clamp, invalid expression visible value, plain Enter, pending-text mouse Run,
goal-cap editors, repeat rejection, name/Settings ownership; selected-vs-draft
sharing, immutable-goal reply, starters, accepted target real improvement,
preview mutation/invalidation, wrong workload, code text Undo, F8/F10/locale
focus, active summary/minimum code layout, actual evidence replay and one-Undo
restore; real cooperative writer contention and exact retry after unrelated
personal-goal edits, independent Notebook save, pending target exit protection,
failed-clear preservation/retry, and stale-code copyability.

Optional `--layout-challenge-capture` emits raw target/import/active/retry frames.
Root should pair the GPU run with existing deterministic capture sizing flags.
Raw image sizes and save results are asserted.

## Verification and handoff

- `git diff --check`: PASS.
- New/edited authored file trailing whitespace and terminal newline: PASS.
- Full lab diff inspected; Window/test files reviewed during implementation.
- Read-only Git status confirms only assigned runtime files changed by this
  agent; collaborators' codec/store/controller/docs remain untouched.
- No Godot run, Git mutation, native input or player-profile access by this
  agent. New suite and UI/parser/GPU acceptance remain **NOT_RUN** until root.
- Root may now edit/integrate all three released files and run fresh import,
  focused challenge UI plus existing UI/Notebook regressions. No UIDs were made.

## First-runtime follow-up

Root reassigned the same three files exclusively for repair after
`.godot/verification/20261105T033350Z-75462610/headless/20261105T040758Z`.
I read all four logs and results: import passed, old UI216/0 and Notebook159/0
passed, new UI stopped on an empty-verdict property access. Earlier check
failures were only accumulated and therefore invisible before that fatal.

Root's read-only `round6-numeric-diagnostic.log` confirms the actual numeric
focus, unblocked `_input` processing and one shortcut run. The synthetic printable
KEY_2 did not insert text in that headless route; the visible1 was correctly
measured. The fixture now uses native `LineEdit.insert_text_at_caret()` to prepare
pending numeric text, followed by the unchanged real viewport command/keypad
events. This tests submission, not native OS text entry.

Current repair snapshot:

- New suite prints each failed assertion immediately. Critical missing verdicts
  remain explicit failed assertions with structured starter/accept diagnostics;
  an absent active target stops that dependent scenario to avoid misleading
  follow-on errors. No assertions were relaxed.
- P2 review: protected storage is now explained before pending status, naming
  unsupported/external-change protection alongside temporary target or removal.
  Permanent protection no longer offers an ineffective Retry action. A new
  future-version-file UI scenario checks acceptance, exact proposal, unchanged
  bytes and retained protection after retry, including the exit guard.
- P3 review: locale focus restoration includes `ExitRetryTarget`; the real
  contention/exit fixture now asserts exact retry focus and unchanged state
  across locale rebuild.
- Fresh `git diff --check` and three-file whitespace checks pass.

**Requested root diagnostic:** fresh import and
`test_layout_strategy_challenge_ui`; immediate `CHECK_FAIL` and the two
`CHALLENGE_UI_DIAGNOSTIC` lines now explain any remaining popup/accept failure.
No engine was run by this agent. Files are paused for this diagnostic; repair
ownership remains assigned until the actual new-suite results are known.

## Second-runtime follow-up

Read the full second-run log at
`.godot/verification/20261105T033350Z-75462610/headless/20261105T041652Z/`.
It completed84 checks with36 failures and no fatal error. Both locales shared
the same fixture failures: numeric text preparation and a Share mouse action
that never opened the code page. The subsequent Escape therefore dismissed the
entire Window; starter/accept failures followed from the hidden Window and do
not independently establish a target-authority problem.

Root's new `round6-focus-popup-diagnostic.log` confirms that settling after
numeric focus then dispatching KEY_2 yields visible2, draft1 before submission,
and exactly one measured group2 run after Command Enter. I restored that proven
viewport printable-key path for the first two numeric inputs. The reusable
`pending_number` helper now settles after focus before preparing expression,
clamp or goal-cap text. Numeric assertions include observed text, value, draft,
run count and focus, retaining all original behavior requirements.

The popup diagnostics show MouseButton events reaching the correct Button with
local coordinates, but no pressed signal for plain click, motion+click or
notify_mouse_entered+click. Per root's updated assignment, popup actions now use
`popup_activate`: reveal the actual action, focus it, settle, assert visible
enabled keyboard focus, then dispatch actual Window Enter down/up. No normal
route emits pressed or directly invokes its action. Root-viewport mouse Run
coverage remains. This exercises scripted keyboard activation, not native
popup mouse acceptance. Production numeric routing and target authority were
not changed based on this fixture failure.

Fresh `git diff --check` and all three owned-file whitespace/newline checks pass.
No engine, Git mutation, ordinary profile or native input was used by this agent.
The repair is ready for root import and focused challenge UI rerun. Edits are
paused while root copies/runs the source; ownership remains exclusive pending
the actual results. Keep the temporary starter/accept diagnostics until this
fresh run resolves the formerly hidden route.

## Fresh verification and final release

Read **all** import/test logs and `results.json` from:

`.godot/verification/20261105T033350Z-75462610/headless/20261105T042615Z/`

- Godot4.7.1 import: PASS, exit0, no errors.
- `test_layout_strategy_challenge_ui`: **250 checks /0 failures**, exit0.
- Both locale diagnostics now show visible checked starter previews, then active
  saved targets and actual improved verdict `delta=-1088`.
- This run includes the protected-file temporary-target assertions and exact
  exit-retry locale-focus assertion introduced for independent P2/P3 findings.
- `git diff --check`: PASS. Final three-file status and lab diff inspected.
- Current source SHA256 matches the executed QA copy for all owned files:
  - lab: `dba382169f996fdfe22a4710a37e4b5be6997d1f150c4b6cf8f6c576b2df2b5f`
  - Window: `2e44ba58a49c79fc1e4cbbb096094d476c649bd317e0c2a776e792f687939df3`
  - UI test: `76ccc231614efce6a820dcd2f36fd4a22e0b6962c1bc713c32f29ca74cd04736`

**Released** `lab.gd`, `challenge_window.gd`, and
`test_layout_strategy_challenge_ui.gd` to root for integration and subsequent
regression/GPU runs. Diagnostic lines remain as requested. This agent performed
no engine run or Git mutation.

The new success verifies scripted viewport keyboard submission/window actions
and root-viewport mouse Run in isolated data. It does not establish native
popup mouse input. Root's old-UI/Notebook regression and three GPU suites are
the next checks; no GPU, native, export or other-platform success is claimed
by this release.
