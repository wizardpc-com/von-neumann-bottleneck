# Explain measured scheduling comparisons — Round8

## Goal and decision

On task branch `codex/gameplay-systems-20261104`, base
`2893e3a93d4a1995bbd9701134089e7977b8c0cc`, make existing measured tradeoffs
inspectable: selected run versus an explicitly pinned baseline, phase costs,
actual RAM reads/writes, cache read counts and public request timings, with
navigation to the exact original Trace events.

Three independent audits and root inspection identify the gap between the
four-metric comparison and a raw event list. The measured two-scan example
costs442 preparation cycles, saves384 query cycles, ends58 cycles slower and
transfers44B less. This is a useful debugging question with existing evidence;
the feature does not create new simulation rules or claim improved human
understanding without playtesting.

## Scope, ownership and exclusions

- Computation agent owns a pure `experiments/layout_strategy/explanation.gd`
  reducer/comparator and `tests/test_layout_strategy_explanation.gd`.
- Interaction agent owns `experiments/layout_strategy/lab.gd` and a new
  `tests/test_layout_strategy_explanation_ui.gd`, including bilingual text.
- Root owns a detached `Session.baseline_entry()` getter and its existing test,
  integration, documentation, all Godot/native execution and Git mutations.
- Independent reviewer reads contract and implementation without editing.

No automatic search, suggested optimal recipe, Notebook replay deduplication,
cross-condition input transfer, online protocol or service deployment belongs
to this increment. The fixed-runtime replay CLI remains a later priority.

## Contract and invariants

The pure reducer reads detached existing Session snapshots, accepts the expected
current condition ID, and never evaluates a plan or mutates its argument.
It returns either an explicit unavailable reason or a detached complete summary.
Correct output, exact current condition, bounded well-formed events, sequential
event clock, complete public request timing and reconciliation to stored metrics
are prerequisites. Comparison additionally requires the same task/condition.
Same-run comparison is valid and yields zero differences. Failed or partial runs
remain available in the existing raw inspector but receive no improvement
explanation. This local consistency check is not remote authenticity.

Phase cycles are sums of actual durations. RAM reads count `fill` bytes; RAM
writes count `write` bytes. `read`, `evict`, `allocate` and `release` bytes are
not additional RAM traffic. Cache read hits use lookups minus fills; the model's
`requests` includes writes and is not a hit-rate denominator. Allocated copy
space and copied payload are distinct. Preparation/query/output reconcile to
totals; read/write and lookup/fill/hit counts reconcile to authoritative metrics.
No derived summary is inserted into authoritative metrics or hashed events.

Requests remain in public job order, with actual admission, completion and
elapsed completion-minus-admission. Q1 means job0 completion. Overlapping batch
response intervals must not be summed as work; shared preparation is not
arbitrarily assigned to a job. Original event indexes and original same-cycle
order survive navigation. No auxiliary source-map authenticity is assumed.

Compare gets a direct explanation action. Explanation lives within existing
Evidence, alongside retained single-run raw inspection. Both run IDs, measured
plans and delta direction are visible. Each aggregate can navigate to its
selected or baseline event source without changing Session selection/baseline.
Plan descriptions suppress dormant copy settings when copying is off; displayed
differences are observations, not causal attribution to one serialized control.
Memory-event bytes are labelled truthfully.

Inspection, filters and event navigation do not run simulation, insert history,
edit a draft, commit pending numeric text, alter Undo/Redo, goal, challenge,
Notebook dirty state, protected files or campaign completion. Selection,
baseline, condition and locale changes refresh labels; goal changes affect
eligibility context only. Existing modal/F8/settings/exit precedence remains.
Do not aggregate full Traces every frame; cache only by actual run/Trace identity
or refresh at explicit state changes.

Both model versions, six conditions, original four frozen definitions, full
Traces, canonical challenge codes, official60-task awards and v1/v2 storage
contracts remain unchanged.

## Implementation and verification

1. Freeze shared API and file ownership, implement pure explanation/UI in
   parallel, integrate detached baseline getter.
2. Test actual pair and split-field runs, exact stage/traffic/cache accounting,
   copy payload versus allocation, JSON/repeat stability and detached output.
   Include sparse/out-of-order responses, same-cycle order, partial allocation
   failures, missing/stale/mismatched/inconsistent snapshots and invalid types.
3. Test UI observational state preservation, identities, both event sources,
   effective plans, pending numeric edits, language and condition changes,
   unavailable states, keyboard/modal behavior and minimum960×640.
4. Run related isolated Godot4.7.1 headless gates, original model/session/
   structures/goals/workspace/challenges and UI regressions, frozen catalog
   56 measurements/112 code outcomes and formal141 designs/282 cases parity.
   Run rendered bilingual1280×720 and960×640 fixtures; inspect raw frames.
5. Independently review implementation, preserve first failures, fix and rerun
   affected gates. Bind final source hashes to the QA/playable copy; ordinary
   startup smoke. Record native/export/cross-platform limits precisely.
6. Update current state, experiment contract, testing, queue/audit and handoff.
   Close this plan, review exact diff, commit/push the significant verified
   milestone to the task branch under the user's explicit push authorization.
   Independently verify task branch and unchanged main.

## Rollback and open acceptance

This is observational and has no persisted format change. A task-branch revert
of this increment restores the previous inspector while keeping every saved
recipe/target and result meaningful. Ordinary player data is never a fixture.
Source/UI automation cannot establish beginner comprehension, fun, native mouse
acceptance, exported compatibility or online score trust.

## Progress

- 2026-11-05: three read-only audits complete; root chose observational comparison.
  Fresh baseline at `.godot/verification/20261105T070528Z-49a63b5c/project` passed
  import/isolation/model3449 checks223 measurements/session72/catalog680 checks,
  56 measurements and112 exact code outcomes. Full logs read, no diagnostics.
- 2026-11-05: fresh CUA inventory reported locked Mac and failed automatic unlock;
  no native game process or input. Do not retry without a meaningful availability
  change. Implementation can proceed independently.
- 2026-11-05: pure reducer/presenter and detached baseline getter implemented.
  Independent contract review found one missing write-count display; root added
  separate write rows and bilingual assertions. Session78 passes; pure430 checks
  over19 real measurements pass. The initial malformed-event fixture was rejected
  by Godot's typed array before reaching the reducer; use a parsed untyped array.
  Original failure log retained. NaN mutation checks now use binary snapshots
  without JSON's nonfinite warning. UI integration/regressions were pending at this observation; final results follow below.

- 2026-11-05: integrated and verified. Fourteen related headless suites have passing latest staged observations; GPU explanation481, structures348 with captures plus independent320 without captures, original UI246, Notebook177, challenge282 pass. Raw54 final frames inspected. Initial fixture/focus failures and the original null-popup GPU failure are retained; the latter is not reproduced and has no proven root cause. Added explicit open assertion/diagnostics, not a retry or direct-method bypass.
- Final source/QA/playable binding, startup, review and task-branch delivery evidence belong to the accompanying [receipt](../../verification/20261105-layout-comparison-explanation/README.md). No model, format or progression change. Latest user direction prioritizes comprehensive measured computation optimization after this increment; native pilot requires actual bottleneck evidence and full reference parity.
