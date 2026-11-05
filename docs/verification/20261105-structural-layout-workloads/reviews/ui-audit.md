# Round7 UI / playloop audit

Owner `/root/audit_polish`. Read-only audit of clean
`e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8` on
`codex/gameplay-systems-20261104`, verified with Git status and HEAD.
No source/test edits, Godot execution, native operation, Git mutation or player
profile access. Only this requested report was written.

**Recommendation:** append two fixed serial workloads to the existing selector;
reuse the current run/compare/Notebook/challenge loop. Keep the four existing
entries in their current order. No request-count slider, release-rule toggle,
new tab or physical-copy control is needed. Final IDs and curated starter goals
remain root's design decision after the strategy/compatibility audits.
The parallel strategy report now proposes `scan_pair_serial` and
`split_fields_serial`; the UI recommendations below align with those IDs.

## Selection and public request description

Suggested compact bilingual titles:

| Proposed structure | Chinese selector / challenge title | English title |
| --- | --- | --- |
| Two full temperature sums, serial admission | 两次温度 · 逐次请求 | Two temperature scans · serial |
| Four temperature sums then four alarm sums, serial admission | 温度后告警 · 逐次请求 | Temperature then alarm · serial |

Both are deliberately distinct from the existing eight-repeat temperature
condition and the existing nine-job mixed condition. Do not label the second
one merely “Mixed”: its separate field phases are the meaningful distinction.
Use one display function for both the selector and challenge/foreign-code
headings; extending `ChallengeWindow.workload_text()` and generating selector
labels from `Model.SCENARIO_IDS` is sufficient, without a new content framework.

Retain the dynamic record/job/copy-limit note. It should show **17 records /2
jobs /160 B** for the first, **17 /8 /160 B** for the second. The existing
`_public_text()` expands every query repetition and already produces the required
Q1–Q2 and Q1–Q8 descriptions, complete public records, costs and condition hash.
Keep those exact rows rather than summarizing away which request is first.

If a compact structural sentence is useful, put it inside the existing public
reader, not above the permanent controls:

- `Q1、Q2分别统计全部温度；Q2在Q1响应后才就绪。`
  / `Q1 and Q2 each sum every temperature. Q2 becomes ready after Q1 responds.`
- `Q1–Q4统计温度，Q5–Q8统计告警；每份请求等待前一份响应。`
  / `Q1–Q4 sum temperature; Q5–Q8 sum alarm. Each request waits for the prior response.`

Keep the existing statements that Q1 is the first submitted request, source
data is immutable, advance copying is allowed, and copy space excludes
accumulators/output slots. There is no changing data between the repeated scans,
no Q9 sparse inspection in the split-fields workload, and no eight simultaneous
queries in either new serial workload. Do not show predetermined solution metrics
or prefill an optimized recipe.

## Concrete playable loop and truthful goals

The archived Round6 structural probe has1475 candidates /48 replays /0 failures.
Its two relevant probe-only structures have the following measured examples;
these need fresh remeasurement under their **new fixed IDs**, not reused old
condition/Trace identities:

| Structure and recipe | Q1 /total cycles /RAM B /copy B |
| --- | --- |
| Two serial scans, direct | 307 /614 /544 /0 |
| Two serial scans, temperature copy | 557 /672 /500 /80 |
| Split fields, direct | 307 /2456 /2176 /0 |
| Split fields, temperature copy | 557 /2130 /1748 /80 |
| Split fields, temperature+alarm field-major copy | 727 /1516 /1032 /144 |

For the two-scan workload, the existing personal objective selector provides a
real reason to keep both attempts: under Q1≤600/copy≤80, the probe chooses direct
for total cycles and copied temperature for RAM. If a curated starter is added,
**a direct-source RAM target** under those limits has a demonstrated improvement
of44 B. A direct-source total-cycle target should not be advertised as an easy
starter merely because the old eight-scan target was improvable. This is a
finite-sample observation, not an optimality claim.

For the split workload, players can keep a direct early response, a one-field
copy, and a two-field layout; inspect Q1 and the Q4→Q5 transition; then choose
personal limits or an accepted target. The existing “Share with personal goal”
and “Share attempt with target goal” distinction remains essential. Never copy
the current personal limits into an already accepted target after switching
workloads or objectives.

The exact probe data was read from
`docs/verification/20261104-layout-replay-challenges/strategy/structural-results.json`.
A read-only Python projection of public records gives per-query sums363 and8:
the proposed output sequences are `[363,363]` and
`[363,363,363,363,8,8,8,8]`. Those values are independent audit expectations,
not a replacement for root's real model run.

## Hardcoded assumptions and integration risks

1. **Selector only has four labels.** `lab.gd:240–247` constructs a four-element
   label array while its callback indexes `Model.SCENARIO_IDS`; `:457` selects
   by that same model array. Adding IDs alone leaves new workloads unreachable
   and a restored active new ID unable to select a valid menu item. Generate
   all labels from the actual ID list, and preserve the old first-four order.

2. **Challenge display only knows four names.**
   `challenge_window.gd:396–402` falls back to raw IDs. Extend the shared display
   function, including wrong-workload import explanations; avoid a new scenario
   showing a localized selector but raw-ID target heading.

3. **Starter buttons always target old scan IDs.**
   `challenge_window.gd:118–123` labels them “all ready”/“serial” but emits
   `scan_batch`/`scan_serial` in every current workload. In the new serial scenes,
   “Try: serial requests” would preview the *old eight-scan* code and then fail
   the current-workload guard. The host's generic “try a starter” message at
   `lab.gd:827` also assumes one is available.
   Prefer a contextual starter action for the current workload, visible only
   when a supported curated starter exists; root must freeze its goal first.
   Keep preview opt-in and all explicit-accept protections. If the old two
   buttons are retained, give them their exact workload names and do not imply
   they are a starter for whichever workload is open.

4. **Catalog construction infers structure from ID spelling.**
   `model.gd:150–156` uses `begins_with("mixed")` and `ends_with("serial")`.
   New IDs require explicit query definitions; merely appending an ID produces
   one of the old workloads. The UI must never display a “two scans” title over
   unchanged eight-scan requests. This is a model-owner boundary, not a proposed
   rule rewrite.

5. **Model tests assume every scenario is an original Catalog workload.**
   `test_layout_strategy_model.gd:37–45` compares every ID to a Catalog case;
   `:62` infers8/9 groups from the “mixed” prefix. Keep exact old-ID parity
   assertions and add explicit new structure expectations. Use actual expanded
   job counts for generic bounds; do not weaken legacy expected-output tests.

6. **Target store is bounded to four targets.**
   `challenge_store.gd:7` has `MAX_TARGETS=4`; six active conditions must not
   display “saved” after a map fails size validation. `Workspace.snapshot()`
   already emits every catalog ID, so adding IDs changes what an explicit
   save writes even before the user visits them. Storage format/rollback is
   owned by the parallel compatibility audit; UI status must follow its
   accepted contract, not hide a write failure or call a copied-forward but
   unsaved workspace “saved.”

7. **Existing tests are intentionally legacy-specific.**
   `test_layout_strategy_ui.gd` uses selector index1 for old `scan_serial`,
   expects16 request/response rows for the old eight-job batch, and asserts
   original307/2456 and531/552 measurements. The challenge suite's “999 clamps
   to8” belongs specifically to old `scan_batch`. Preserve these anchors.
   Add a separate new-condition loop selecting by ID; do not globally replace
   8/9 with2 or make prior expectations depend on the changed implementation.

8. **Current-format copy is explicitly four-workload copy.**
   `experiments/layout_strategy/README.md:59` and its public-rules paragraph
   describe the original four conditions. Current-state/architecture contracts
   need new facts when implemented; dated Round6 receipts stay historical.
   Launcher isolation, experiment profile identity, Game/Test and formal60
   registration should remain untouched.

Not all constants need changing: four physical fields, the17-record starter,
MAX_JOBS16, eight kept plans **per condition**,24 recent runs and64 edits remain
valid for these two structures. Exposing arbitrary count/layout knobs would
expand the requested gameplay and persistence scope without evidence.

## Bounds, state and numeric input

`lab.gd:443–469` already derives group upper bounds from the sum of repeats.
The correct distinctions are:

| Condition | Expanded jobs | Editable legal grouping |
| --- | ---: | --- |
| old temperature batch | 8 | 1…8 |
| old mixed batch | 9 | 1…9 |
| new two-scan serial | 2 | exactly1; disabled |
| new split-fields serial | 8 | exactly1; disabled |
| old serial scenes | 8 /9 | exactly1; disabled |

All legal new serial drafts disable query tiling; with one sequential full
scan per group it does not reorder useful work. Keep those controls visibly
inactive, while copy choices and enabled personal-goal cap editors stay usable.
The four known numeric editor routes at`lab.gd:1151–1196` are independent of
workload count. Reuse native SpinBox submission and once-only handled command
events; no new special shortcut is required.

The current Session already indexes draft/goal/Undo/Redo/runs/selection/baseline
by task ID (`session.gd:11–41`). New IDs naturally isolate these. Kept-plan
selection is also task-indexed (`lab.gd:639/657/680`), and current challenge
comparison binds task+code+selected Trace (`:800–805`). Preserve those boundaries.
Changing workload closes the challenge Window and resets the evidence cursor;
it must not transport a pending code preview to the next condition.

Two gates deserve explicit testing:

- Switch from editable batch group8/9 to new serial and back. The new draft
  starts group1, old draft/history/selection/goal/baseline/Undo return exactly,
  and the visible group bound follows the actual job count. Numeric blur or a
  pending `_pending_numeric` reference must not apply old text to the new task.
- `Session.edit()` and Notebook drafts accept structurally valid plans even
  when task-specific validation would reject them. Existing UI can clamp the
  visible SpinBox while retaining an out-of-range draft, because refresh uses
  `set_value_no_signal`. Do not silently “repair” imported/restored drafts as
  part of adding IDs. Keep model rejection truthful; verify invalid stored
  group values cannot appear to run a different visible recipe. This is a
  pre-existing edge intensified by shorter workloads, not an observed new
  runtime failure.

## Copy-forward presentation, if root adopts the compatibility recommendation

I read the parallel compatibility audit after drafting the findings above. It
recommends separate v2 sidecars with untouched strict-v1 copy sources. The UI
needs its explicit `origin`/`copy_pending` state rather than inferring migration
from `storage_reason` or file existence. Example detail text:

- `已载入上一版笔记。保存会创建独立副本；原记录保留。`
  / `Earlier notebook loaded. Save creates a separate copy; the original remains.`
- `已载入上一版挑战并复测；新副本尚未保存。`
  / `Earlier targets were loaded and remeasured; the new copy is not saved yet.`

Use the existing storage status, Notebook save, target save/retry and exit
guard. An unchanged inherited target must not appear saved solely because its
code matches the committed in-memory map. A pending copy must reach the exit
guard even with default drafts and no new run. A valid current empty target
map must not revive old targets. Protected old/current-file explanations and
the independent notebook/target transaction boundary remain visible.

The decision and controller API still belong to root; this report does not
authorize changing file versions or adding a migration wizard.

## Minimum layout and acceptance gates

I visually inspected the archived English960×640 Public workload and active
challenge root frames. The selector has a300px width; Public workload already
scrolls; Compare has little spare vertical room once an active target is shown.
The proposed short names are intended to fit the current selector, but their
actual glyph fit is **not yet measured**. Keep the two-pane geometry and place
any explanation inside the existing reader. Do not add a permanent explanation
row beneath the selector or add four new starter buttons to the Window.

Minimum new verification:

1. Six selector items, correct localized name/ID mapping, old order preserved;
   public Q1–Q2 and Q1–Q8 fields/order, absence of unintended Q9, exact data/cost
   disclosure and distinct condition identities.
2. Both new loops run actual default/copy recipes, inspect causal responses,
   keep two measured plans, change goal, restore one Undo and return after
   switching conditions without cross-condition history or challenge leakage.
3. Numeric batch8/9 bounds, disabled serial group/tile, both enabled goal-cap
   editors, ordinary Enter versus Cmd/Ctrl+Enter/keypad, mouse Run after pending
   text, and exact once-only run counts after condition changes.
4. New code preview/accept preserves draft/Undo/selected evidence/personal goal;
   foreign old/new codes name the correct destination without switching;
   reply preserves the original goal. Six-target storage failure/retry and any
   migration state use genuine store results.
5. Chinese/English1280×720 and960×640 root scenes;720×540 challenge Window;
   full selector menu, longest new title, Public workload, active target,
   import/share text, Notebook and exit protection. Retain F8/F10/locale
   ownership and selection contrast already repaired in Round6.

Round6 native Chinese acceptance exists in its receipt; it does not certify
these unimplemented new conditions. This audit itself is source/evidence review
only. No additional source change is authorized until root freezes the plan
and file ownership.
