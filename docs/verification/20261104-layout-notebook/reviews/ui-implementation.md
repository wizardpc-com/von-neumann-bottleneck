# Round5 UI implementation — ready for root verification, ownership released

Owner `/root/audit_polish`. The assigned three files are implemented and released:
`experiments/layout_strategy/lab.gd`,
`tests/test_layout_strategy_notebook_ui.gd`,
`tests/test_layout_strategy_ui.gd`.

Implemented Notebook as tab3, preserving original Compare/Evidence/Public indices.
It has inclusive Q1/copy checkbox+numeric limits with a visible no-cap summary,
total/RAM objective, remeasured kept-plan table, selected-run naming/keep, explicit
Save workspace, guarded removal, exact replay-only selection, and explicit restore.
Recent runs also receive truthful constrained rankings. Existing table keyboard
helper now follows actual ranked row position instead of assuming ID order.

Exit guard now distinguishes dirty workspace versus saved retained work and
session-only history, provides Save and exit, stays open on failed save, and also
serves the required removal confirmation. All existing modal/focus routes retained.
New UI suite inherits existing real viewport helpers, exercises actual recipe
measurements, goals, text Undo, restore, locale, size captures, live writer
contention, failed save-and-exit and a fresh scene/store reopen. Root still owns
actual two-process acceptance.

`notebook_path:String=""` is a UI fixture-injection field passed to
`workspace.setup(notebook_path)` before building. Ordinary default remains Store-owned.
Stable runner profile remains under Checks, so the existing lab guard needs no change.

## Integration API question — resolved

`Workspace.setup()` intentionally snapshots pristine defaults as `_committed`.
Therefore `not workspace.is_dirty()` does NOT mean the file has ever been saved,
including after a measured-only first run. UI must not call that state “Saved.”
Root added `has_saved_workspace() -> bool`. UI now uses it for the global state,
notebook status and exit text/buttons; a pristine notebook is “New workspace,”
not “Saved.” The new UI suite explicitly checks that distinction.

## Verification and handoff

- `git diff --check` passed after the completed source changes.
- Inspected changed source, the old UI-test diff, full new notebook UI test and
  final Git status. Other agents' source/store/session/runner/doc files preserved.
- No Godot/import/headless/GPU/native run by this agent. Root must perform fresh
  verification; no runtime or viewport acceptance is claimed.
- Run `test_layout_strategy_ui` and `test_layout_strategy_notebook_ui` alongside
  the new model/session/goals/store/workspace checks. New suite inherits the old
  suite's actual viewport/key/click helpers; it overrides `_run`, so only its own
  notebook flow executes.
- New captures use `--layout-notebook-capture`: each locale writes notebook1280,
  notebook960 and actual save-failure960 PNGs. They check the raw Image dimensions
  and `save_png()` return. Root's GPU helper supplies the flag.
- Tests bind unique QA-only notebook paths before the scene enters the tree.
  `LeaveProbe` overrides only `_finish_quit` to observe that failed Save and exit
  does not leave, and successful save reaches the leave call. Production still
  invokes `get_tree().quit()` normally. Fresh-scene reopening is verified here;
  actual separate processes remain root's process-probe responsibility.

Additional final details:

- Selected kept rows are remeasured with `Workspace.inspect_kept`, leaving the
  emitting TreeItem alive; goal sorting/rebuild never auto-replays it.
- Failed keep that has accepted a proposal in memory clears the submitted name
  and selects that proposal; retry is the explicit Save workspace action.
- Baseline comparison still reports real signed deltas, with an additional
  visible note if selected or baseline lies outside the current goal.
- Keeping/removing saves the full workspace, with the confirmed remove text
  stating this. Removal cannot exit or mutate draft/evidence/Undo.
- Locale rebuild preserves the unsubmitted name and selected Notebook tab;
  protected state, writer recovery, name Undo, F8/F10 and cancellation focus have
  behavioral assertions.
- Original Cmd/Ctrl+Enter behavior in focused numeric editors was left unchanged;
  that audit friction is not part of this frozen increment.

All three files are now RELEASED to root. No further source edits by this agent
until a new explicit ownership assignment. API assumptions are resolved.
