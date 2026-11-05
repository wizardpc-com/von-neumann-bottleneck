# Round8 comparison presenter implementation

Owner: `/root/audit_polish`. Base `2893e3a`, task branch
`codex/gameplay-systems-20261104`. Implemented only the two assigned files:

- `experiments/layout_strategy/lab.gd`
- `tests/test_layout_strategy_explanation_ui.gd`

Both are frozen/released for root's isolated parser/runtime checks. The pure
`explanation.gd` and detached `session.baseline_entry()` are owned by the other
assigned agents/root; this presenter consumes their frozen API.

## Delivered behavior

- Compare has a direct **Explain / 查看差异** action. It opens a comparison mode
  within the existing Evidence tab. The ordinary single-run raw inspector
  remains available through the Evidence mode choice.
- The comparison shows both measured run IDs and plans, the explicit selected
  minus baseline direction, current ranking objective/caps and out-of-goal
  status. Source-only descriptions continue to suppress dormant copy settings.
- A four-column scrolling table offers three focused views:
  1. preparation/query/output/total cycles and RAM bytes, copied payload and
     allocated copy space;
  2. preparation/query/total read lookups, hits, misses, RAM reads and writes;
  3. public-order job admission, completion and elapsed cycles.
- A selected row binds a real phase/job scope. Selected events and Baseline
  events open that side's exact original event indexes without selecting the
  run in Session. A side choice and Back to comparison keep the source visible.
  Existing event type filters apply within the selected scope.
- Raw memory view is now **Memory events / 内存事件**. Its table reports
  **RAM B** only for actual fill/write events. Zero-cost clean evictions,
  allocation/release and internal reads remain available with their original
  event-byte meaning in the detail/JSON.
- Pure aggregation is cached by current condition and both run/Trace identities;
  there is no process-loop reduction or replay. Selection/baseline/condition
  changes invalidate the pair; locale rebuilds preserve the bound source/scope;
  goal edits update eligibility text without altering the summary.
- Missing, failed, incomplete or rejected evidence is visibly unavailable.
  Failed measurements retain the original raw event route.
- New read-only actions preserve pending SpinBox text: before an inspection
  click can blur a numeric editor, a narrow handler suppresses the automatic
  blur commit, restores its prior value and pending text, and retains the
  existing pending-editor pointer. An explicit later Run still applies it.
  No broad change to ordinary editing or Run semantics is intended.

## UI test scope

The new suite inherits the existing actual-viewport harness, then overrides its
run/exercise flow. It uses real Model/Session results and isolated fixture paths.

- Real pair `614/544` versus `672/500`; prepare442, query228/612, total+58,
  traffic−44, payload68 versus allocation80.
- Read denominator51 versus34, hits24, fills27 versus34; it never uses the
  metric68 requests as read lookups.
- Keyboard selection of summary rows; both inspector sources; original event
  indexes and phase scope; clean eviction reports0 RAM B while retaining16
  event bytes.
- Q1 completion557/307 and Q2 admission557/307, completion672/614, elapsed115/307;
  original response output363 remains inspectable.
- Before/after snapshots include all Session states/Undo/Redo/history/IDs,
  proposed and committed Notebook state, targets/committed targets, dirty flags,
  storage status and byte-for-byte saved/current/legacy fixture files.
- Locale rebuild, existing Settings/F8 routes, eligibility-only goal change,
  same-run zero comparison, condition switching and failed allocation raw access.
- Real numeric typing followed by a mouse Explain click, continued event
  inspection, then one explicit Run proves retained pending text and exactly
  one additional measurement.
- Geometry checks at1280×720 and960×640. Optional
  `--layout-explanation-capture` writes six original frames per language:
  costs1280, costs960, cache960, baseline events960, request timing960 and
  failed events960. Image sizes and `save_png()` results are checked.

## Verification so far

- Read the complete owned-source diff and both new/current files.
- `git diff --check -- experiments/layout_strategy/lab.gd`: PASS.
- New test and lab trailing-whitespace scan: PASS.
- Inspected full Git status; collaborators' model/session/docs/tests changes
  are preserved.
- **No Godot invocation by this agent. No parser/headless/GPU/native acceptance
  is claimed yet.** Root owns these checks and may return first failures.
- No Git mutation, profile reads beyond explicitly isolated fixtures, official
  progression changes, simulator/codec/goal/persistence-format edits or online
  actions were performed.

## Review notes

Keep the broad pure validation tests with this suite. This UI assumes actual
Session entries remain immutable under their Trace identities; validation is
local presentation consistency, not online score trust. The presenter never
inserts derived fields into original metrics/events.

Native keyboard/mouse usability and newcomer comprehension require separate
observed acceptance; fixture success and historical screenshots cannot prove
those. The pending-number focus path is intentionally covered by actual
viewport input and needs root's engine result before accepting it.

All requested functionality is implemented for first integration. Do not infer
completion of the milestone from this handoff before fresh root verification.

## First integration follow-up

Root's actual isolated log:
`.godot/verification/20261105T070528Z-49a63b5c/headless/20261105T074051Z/test_layout_strategy_explanation_ui.log`
recorded453 checks and8 failures: each language failed one F8 focus assertion
and three pending-number/state assertions. The full log was read and retained.

The two assigned files were reopened for this bounded repair and frozen again:

- The inherited F8 fixture tried to focus the hidden History table while
  Evidence was active. A dedicated comparison modal test now requires the
  visible event table to own focus before exercising Settings/F8 and verifies
  return to that exact visible control, including real Settings translation.
- Numeric preservation now places the already-committed value in the LineEdit
  before releasing focus, then defers restoration of typed text until after
  SpinBox's focus-loss handling. The intended fix avoids a deferred apply
  reading restored pending text; root's focused probe/runtime result must
  establish that this resolves the observed failure.
- Numeric failure text now includes actual value/text/pending pointer/draft;
  all original observation, file and single-Run assertions remain.
- `git diff --check` on both assigned files passes. Root's added separate
  write-count rows/assertions were preserved.

No Godot run was performed by this agent. The follow-up is not accepted until
root executes the probe/new suite and checks the actual results.
