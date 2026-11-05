# Round6 player-loop audit

Reviewer: `/root/audit_polish`. Current task branch was clean when inspected.
Base milestone: `e07b4bbba845a1046835884ecf06916930fa8b8a`.
Read-only source/test/design audit; no production changes, Godot run, Git
mutation or native-input observation. Recommendations are for root's scope
decision, not an accepted new product contract.

## Recommended coherent increment

Prioritize a **replayable, same-condition challenge loop over the four current
workloads**, together with the small numeric edit→run correction below. The
player loop becomes: run/keep a useful recipe → offer its real performance under
explicit Q1/copy limits → another player previews and locally remeasures it →
attempt an improvement under that exact goal → compare, keep and share the
improved recipe.

The current notebook already solves retention and truthful same-condition
personal comparison. The missing motivational step is a concrete, reproducible
challenge someone can accept. Adding numeric data randomization would not solve
that: the accepted Round5 finite probe found no performance changes in its16
values-only pairs. Structured new workloads may be valuable after the parallel
strategy audit, but they should not add several new tuning controls before this
existing editing/comparison loop becomes easy to enter.

Do not frame this recommendation as more workload variety or a verified online
leaderboard. It is a genuine local challenge/replay mechanism using the existing
model. It can be useful without a server, new campaign content or new simulation
costs. The integrity agent/root should decide the minimal bounded protocol and
whether the active target persists in a separate sidecar.

## Exact numeric shortcut diagnosis

The routing failure is directly visible in current source:

1. `_spin()` and `_cap_number()` create SpinBoxes whose focused editable node is
   the internal LineEdit (`lab.gd:139–152,397–407`). The source only connects its
   focus signal. There is no numeric-editor `gui_input` or explicit text-commit
   route, and `update_on_text_changed` is not enabled.
2. Numeric changes reach the plan/goal through `value_changed`
   (`lab.gd:241–245,350–353`), then `_edit_value()` or `_edit_goal()`.
   `run_current()` reads `session.draft()`, not any pending editor text
   (`lab.gd:505–509`).
3. `_unhandled_key_input()` rejects **every** focused LineEdit/TextEdit at line906,
   before its Cmd/Ctrl+Enter branch at914–916. Therefore even a command event that
   reaches this callback cannot run while a numeric editor owns focus.
4. There is also a routing boundary to verify through the actual viewport:
   GUI editing may consume the command before the unhandled callback. Moving
   the command branch above line906 alone does not establish a reliable
   numeric-editor shortcut.
5. The global branch currently matches `KEY_ENTER` only, not `KEY_KP_ENTER`.
   A future fix should cover both explicitly, while rejecting key-release and
   repeat events and preserving modal/exit ownership.

The installed engine's supported numeric-submit API still needs confirmation.
`SpinBox.apply()` is the candidate to check; the attempted official-documentation
lookup returned no inspectable source text or citation in this session, so it is
not accepted as API evidence. Root should confirm the callable on Godot4.7.1 and
exercise its expression/clamping behavior in the viewport test. Candidate
official references:

```text
https://docs.godotengine.org/en/4.7/classes/class_spinbox.html
https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html
```

**Bounded repair recommendation:** intercept only Cmd/Ctrl+Enter/KeypadEnter
when focus is one of this lab's four known numeric LineEdits. Use their owning
SpinBox's confirmed submit API to commit before measuring; consume that one
event so there is exactly one run. A numeric `gui_input` hook or a narrowly guarded early
`_input` route can do this; root should choose the one proven by the viewport
test. Reuse `_modal_blocked()` and the visible exit/remove guard check. Leave
ordinary Enter, numeric text Undo/Redo, the Notebook name field, Settings,
feedback editors and future challenge-code text with their existing owners.
Do not parse all text fields manually or move every shortcut into an early
global input handler.

Godot's normal numeric-expression/clamping behavior should remain authoritative.
Test invalid/out-of-range text and ensure the measured plan equals the visibly
committed value; do not silently measure an unapplied number. This is a
recommended behavior to verify, not a claim that the present runtime already
does it.

## Current concrete friction

| Priority | Source observation | Bounded response |
| --- | --- | --- |
| P2 | Numeric focus is returned before Run shortcut handling, as above. `test_layout_strategy_ui.gd:202–218` types text and tests Undo, then explicitly moves focus away; it does not try to run directly. | Commit the known numeric editor and run once from the advertised shortcut. Add real viewport-key coverage rather than calling `run_current()` directly. |
| P2 | There is no challenge/import/share entry in the lab. All personal goals are manually set in Notebook and all starts use four unchallenged default drafts (`lab.gd:183–407`, `session.gd:15–19`). | A single compact Challenges entry can expose “share selected measured plan” and “preview code,” then an explicit start/pin action. A target must be remeasured, not a pasted scalar. |
| P2 | Goal editing is in Notebook, but the same session goal also ranks the Recent table. Recent shows objective and an over-limit label, while exact caps appear only in its tooltip or the other tab (`lab.gd:333–353,536–553,586–604`). | Show the active challenge's actual objective/Q1/copy rule in its compact comparison summary. Ensure current personal-goal context is visible when a run is excluded; do not make players infer a numeric cap from “Q1 over.” |
| P2 | A kept row can be inspected in Notebook, but “Set comparison” exists only on Compare (`lab.gd:295–296,364–380,644–654`). After restart, a saved-reference comparison requires select kept→Compare→Set comparison→Notebook→select other→Compare. | Pinning a challenge directly from the selected measured/kept recipe provides a purposeful target without this repeated tab route. Reuse existing restore and keep semantics. A second unrelated comparison toolbar is unnecessary. |
| P3 | Goals are outside recipe Undo by explicit existing contract (`session.gd:30–34`; session test115). | An imported goal must not silently overwrite a player's personal envelope on preview. Explicit challenge adoption needs its own clear reversible/clear behavior; recipe Undo alone cannot recover an overwritten goal. |
| P3 | Notebook selection replays into a new numbered run, and Continue improving replays once more before restore (`lab.gd:644–675`; `session.gd:75–99`). Repeated browsing can consume recent-run slots despite unchanged recipes. | Keep challenge preview separate from Recent until acceptance or an actual attempt. Give the active challenge a stable title/identity independent of transient run numbers. Do not expand this round into general history deduplication unless real play proves it necessary. |

These are source-derived paths and usability risks. They do not establish how
many users stumble or whether the whole flow is enjoyable; native and newcomer
acceptance remain separate.

## Minimal player-facing contract

Keep the current editor, four workload choices, Notebook, Evidence and Public
pages. Avoid adding another permanent top-level tab or a row of new simulator
parameters. A secondary **挑战… / Challenges…** entry near the existing Compare
actions is enough to open a bounded share/import surface.

- **Create:** use the selected complete correct measurement, even when the draft
  differs. Bind the intended goal and target recipe explicitly. Show the
  challenge condition, objective and both caps before copying. The target itself
  must qualify under those caps; otherwise explain the actual exclusion.
- **Preview:** paste into an initially empty editor, validate, and locally replay.
  Show actual Q1/total/RAM/copy plus the rule. Invalid/stale/oversized input
  changes no draft, goal, selected evidence, notebook, Undo or target.
- **Accept/pin:** make this an explicit action. Preview is not adoption.
  The active challenge keeps its own exact condition/goal/recipe identity.
  Changing personal goal controls or table sorting must not silently relax the
  challenge or change what is being beaten.
- **Attempt:** editing/running remains the existing flow. Compare only a complete
  actual same-condition result. First apply the inclusive caps, then compare the
  declared objective: “outside limits,” “behind,” “tied,” or “improved.”
  A lower partial total, another workload or a softened personal cap is not a
  win. Keep all four physical metrics visible; no combined score.
- **Inspect/restore:** target inspection may show its recipe/evidence without
  changing the draft. Restoring the target remains an explicit one-step Undo
  transaction. Reuse the repaired distinction between draft and selected run.
- **Continue/share:** an improved result can be kept with a name or explicitly
  shared as a new target. No official completion, global “best,” server trust
  badge or automatic network action.
- **Clear/replace/reopen:** clearing/replacing the active target must not erase a
  draft, personal goals or kept plans. If targets persist, state whether the
  current target is saved versus temporary after write failure; preserve exact
  goal/title/recipe on retry. Formal challenge import already has useful tests
  for this distinction, but its model identity and code format must remain
  separate from this experiment.

A small active-target summary should show the exact caps and objective, target
value and current selected attempt verdict. Do not use the general comparison
baseline or current table sort as the target's authority: both are intentionally
editable today. Sharing a target must preserve its exact goal even if the user
later sorts the table differently.

The existing Notebook name field remains a save affordance, not a code editor.
Put long codes in a separate bounded TextEdit with native text Undo, explicit
copy and a preview invalidated on edits. Preserve F8/F10/exit focus boundaries
and avoid deleting a TreeItem while it emits selection.

## Discovery without preloading an answer

The root/strategy audit should decide whether one or two built-in sample
challenges are useful. They should be **opt-in real recipe targets**, computed
through the same preview path, never fake scores or silently inserted ranks.
Do not add a campaign checklist or reward system.

Two candidate starts already supported by Round5 data:

1. **Earlier answer, less repeated work:** `scan_batch`, total objective,
   Q1≤350, copy≤0, direct starter target (307/2456/2176/0). The finite probe has
   a group2/tile1/no-copy reply at339/1368/1088/0, so this is demonstrably
   improvable under the stated limits. Do not label that recipe globally best.
2. **Reuse across serial requests:** `scan_serial`, total objective, Q1≤600,
   copy≤80, direct starter target (307/2456/2176/0). A real retained-temperature
   answer is557/1362/980/80. This teaches a different source of reuse from query
   grouping and uses only existing controls.

Present the challenge and baseline recipe, not a prefilled optimized draft.
Players may still freely inspect the public target and all workload details.
More preset goals over the same four conditions are not by themselves more
structural variety. Root should keep any new workload proposal independently
justified by the parallel production-model probe.

## Focused acceptance recommendation

Root owns engine execution. Suggested tests are behavioral:

1. Numeric focus: start from group1/tile17, focus QueryGroup, replace text with2,
   dispatch Cmd/Ctrl+Enter through the actual viewport, and assert one new run,
   committed group2 and a matching real measurement. Then edit RecordTile to1
   and assert the actual group2/tile1 output/metrics, not the old tile17 draft.
   Repeat with KeypadEnter and goal-cap editors.
2. Preserve text ownership: Cmd/Ctrl+Z inside a numeric/name/code field changes
   text only. Plain Enter follows normal editing behavior. A release/echo event
   produces no extra run. Numeric text plus mouse Run also measures committed
   visible input. Disabled serial/group/tile controls remain disabled.
3. Modal precedence: F8/F10, exclusive Window and visible exit/remove guard
   prevent the lab shortcut; code/name editors cannot accidentally run or
   overwrite plans. Restore exact focus after dismissal and locale rebuild.
4. Challenge preview/adopt: malformed/stale edits clear preview authority.
   Preview preserves all current work; explicit acceptance uses a real replay
   and immutable rule. Target qualifies before being offered as beatable.
5. Real comparison: direct versus group2 under350/0; lowering a personal cap or
   changing the personal sort cannot alter active target identity/verdict.
   Equality produces a tie; over-cap, failed and wrong-condition entries cannot
   win. Both total and traffic objectives use actual results.
6. Preserve loop: target inspect does not edit, target restore is one Undo,
   keep stores the selected attempt rather than a different current draft.
   Any retained target survives the intended process restart from the same
   isolated profile and is remeasured. Failed-write exact retry retains the
   declared objective and title.
7. Verify Chinese/English1280×720 and960×640 real raw frames, numeric/code focus
   and ordinary launch. Scripted GPU input is handler acceptance; the locked
   Mac does not become native acceptance by adding more automated counts.

No source file ownership is claimed. Root can choose this bounded challenge loop
or a probe-supported structured workload after reading all three audits.

## Root's existing physical-block alternative

The newly added task alternative is compatible with a small UI increment if
root's bounded measurements show useful choices. It exposes an existing
physical-layout mechanism rather than changing the experiment's model or four
conditions. The probe log reports1140 measurements and zero failures, but this
report has not independently evaluated its candidate output/frontier; that log
alone does not prove added strategy depth.

Current UI behavior already preserves advanced recipes:
`refresh()` recognizes only exact record/field presets and otherwise displays
“Retained custom layout” (`lab.gd:450–457`). Ordinary `_edit_value()` edits a
detached full draft; changing query counts or copy mode therefore does not
reconstruct the recipe (`467–474`). The destination handler replaces the whole
recipe only when a player explicitly chooses one of its two presets (`265–267`).
I found no present refresh-time erasure to fix.

If physical blocks are exposed, retain that protection. Editing only block
length should copy and update `recipe.block` while preserving every group's
field order and grouping. A layout choice must not implicitly reset an imported
custom recipe's other dimensions. Presets may replace the whole recipe only as
an explicit, Undoable action.

Label this control as **副本每块记录 / Records per copy block**, adjacent to the
copy-layout choice, and retain **每次交替处理记录 / Records per query tile** for
the execution setting. One changes physical address order; the other changes
the visit schedule. Show the current full-block meaning of0 as “all records”
rather than an unexplained zero. Do not use one shared “block” label.

The existing mapper (`layout_recipe.gd:37–65`) loops block-by-block only within
each retained group. A block changes address order only when an effective group
has field-major order and more than one copied field. Record-major groups and
single-field groups keep the same order. Disable an effectless control while
retaining its dormant value, and test restored custom groups rather than
inferring applicability solely from total selected field count. This matches
the current lab's established dormant-choice contract.

This option is a smaller editing surface than portable challenges. If measured
frontiers establish useful physical-block tradeoffs, root can select it first
and pair it with the numeric shortcut fix. The challenge-loop recommendation
still addresses discovery and replay purpose; neither should be advertised as
new workload variety. Avoid implementing both merely to accumulate features.
