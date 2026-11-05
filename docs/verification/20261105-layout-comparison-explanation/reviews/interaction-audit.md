# Round8 interaction audit — explain a measured comparison

Owner: `/root/audit_polish`; read-only audit completed 2026-11-05.

Base inspected: `2893e3a93d4a1995bbd9701134089e7977b8c0cc` on
`codex/gameplay-systems-20261104`. `git status --short --branch` showed no
tracked or untracked changes at audit start. No source edits, Godot runs,
native input, ordinary-profile access, Git mutations or new gameplay decisions
were made. Source ownership remains with root.

## Recommendation

Prioritize one bounded interaction: **explain the selected measured run against
its explicitly pinned comparison baseline using both runs' existing Trace**.
Offer a direct “Explain comparison / 查看差异” action on Compare, opening a
comparison mode of the existing Evidence area. Preserve ordinary single-run
evidence and the current editing/running loop.

This closes the most immediate gap between a genuine strategic choice and a
player's next deliberate experiment. Current results already expose useful
tradeoffs. The next missing step is seeing which measured preparation, query
and response costs changed. It does not require another workload, simulator
rule, score authority, persisted format, automatic optimizer or top-level page.

This recommendation is based on current code, original recorded pixels and
existing verified measurements. It is **not** a finding that a human player
was confused, or a claim that the proposed interaction has been play-tested.
The Round7 receipt explicitly records native operation as NOT_RUN on a locked
Mac. Automated UI acceptance and my screenshot review cannot establish fun,
learnability or long-session behavior.

## Concrete impediments

### 1. A correct comparison has no route to its measured explanation — highest priority

`session.gd:163-179` compares only Q1, total cycles, RAM bytes and copy allocation.
`lab.gd:778-796` formats those four signed deltas and a broad tradeoff verdict.
The raw runs already contain the detached full events and Trace identity at
`session.gd:76-100`; the interaction does not expose that pair as a pair.

The original `layout-structures-en-pair-1280.png` visibly shows:

- Baseline #1: Q1 307 / total 614 / RAM 544 B / copy 0 B.
- Selected #2: Q1 557 / total 672 / RAM 500 B / copy 80 B.
- “Tradeoff”: Q1 +250, total +58, RAM -44, copy +80.

Those are truthful results, and no clipping obscures them. However, the screen
does not tell the player how much work the retained copy adds before requests,
how much work subsequent queries avoid, or which actual transfers account for
the 44 B saving. The player must reconstruct this from separate screens.

**Inference:** the gap makes a measured success harder to turn into a reasoned
next plan. The metrics themselves are not defective.

### 2. Evidence requires manual switching and mental comparison

`lab.gd:1060-1111` reads only `session.selected_entry()`. It filters one run
into requests/responses, memory transfers or all events, then shows one event's
details and JSON. `lab.gd:560-568` resets event selection when history selection
changes. There is no baseline-side aggregate, baseline plan description, paired
request timing table or direct jump from a changed total to the relevant events.

The original `layout-strategy-en-evidence-960.png` visibly contains “Run #2 ·
actual events from the selected snapshot”, a Memory transfers list, and one
Fill detail. This is useful verifiable raw evidence, but it is not a comparison.
To compare Q1 or cache fills across two runs, a player must return to Compare,
switch the selected run, return to Evidence, reapply/inspect the relevant rows,
and remember the other result.

The memory list contains allocation/release/eviction bytes as well as actual
fill/write transfers (`lab.gd:1073-1082`). A future explanatory view must avoid
naively summing all displayed “B” values: the underlying simulator counts RAM
reads on Fill and RAM writes on Write; Read/Evict/Allocate/Release bytes are
different facts (`layout_simulator.gd:203-237`).

**Inference:** aggregated evidence with exact links would reduce repeated
navigation and prevent an easy accounting misconception. No human instance
of that misconception was observed.

### 3. The baseline has weaker visible identity than the selected plan

Compare identifies the baseline using a star and `vs #N`
(`lab.gd:586,787-789`). Only the selected run gets a persistent plan description
(`lab.gd:601-603`); other plans are available through tooltips
(`lab.gd:592`). If the draft has changed, the UI correctly says it differs from
the selected snapshot, so the baseline is a third state a player must retain
mentally.

**Inference:** a paired explanation should display both measured plan inputs,
not imply that the current editor is one side of the comparison. Showing changed
controls is useful; hiding dormant stored settings entirely would risk presenting
two different recipes as identical. Mark settings that are currently ineffective,
or show the full concise plan descriptions without implying they caused a delta.

### 4. Reusing two kept plans for a comparison has avoidable repeated operations

Notebook selection invokes `workspace.inspect_kept()` at `lab.gd:685-695`.
That always calls `session.replay()` (`workspace.gd:145-152`), creating/selecting
a real new history row. Setting a baseline is only available on Compare.
Thus a reopened pair currently takes this route:

1. Select kept A in Notebook, producing a fresh measured run.
2. Switch to Compare and set that run as baseline.
3. Return to Notebook and select kept B, producing another measured run.
4. Return to Compare to see the pair.

Additionally, Continue improving invokes `inspect_kept()` again before restoring
(`lab.gd:710-716`), even when the user just selected and remeasured the same kept
recipe. That second replay adds a duplicate measured run. The result is genuine,
but it consumes one of the 24 history slots (`session.gd:94-99`) without changing
the recipe. This is a confirmed code path, not a runtime observation from this
audit, and current tests intentionally establish fresh replay on selection.

**Lower-cost alternative:** a direct explicit “Use as comparison” action for a
kept plan, and reuse an already matching selected replay for Continue improving.
That would reduce navigation/history churn. It still would not explain a
performance change, so I rank it after the evidence comparison. Do not fold it
into the recommended increment automatically; preserving the intentional fresh
measurement boundary requires its own precise action/count tests.

### 5. Active objective context is split between Notebook and Compare

Objective and optional Q1/copy caps are edited and visibly summarized in Notebook
(`lab.gd:350-381,627-645`). Compare correctly changes its rank-column label to
Total rank or RAM rank, and flags out-of-goal selected/baseline runs, but caps
are otherwise in rank tooltips (`lab.gd:576,593,790-796`).

The original pair Notebook image clearly shows RAM ordering with Q1≤600 and
copy≤80; the pair Compare image shows RAM rank but no persistent cap summary.
Switching the objective to inspect the real cycles/RAM rank reversal requires a
tab trip.

**Inference:** the recommended comparison explanation should carry the current
objective/cap context in its header while keeping measured deltas independent
of ranking. This is context for the same interaction, not a request to duplicate
goal editors or revise ranking rules.

### 6. Cross-condition exploration is safe but manual

Each workload intentionally owns independent draft, Undo/Redo, runs, baseline
and goals (`session.gd:16-20,37-41`). Saved plans and challenges are condition
bound (`workspace.gd:122-143`; `challenges.gd:51-68,104-134`). This separation
prevents false comparisons.

A useful strategy must currently be reconstructed manually in another workload.
That is a possible later “copy recipe to another condition” interaction; it
must copy only inputs, require explicit intent, preserve the destination draft
with one Undo, retain invalid serial grouping visibly, and never carry ranks or
scores across conditions. It is **not** part of this recommendation. Direct
cross-condition score comparison would answer a different and misleading
question because work and admission rules differ.

## Proposed testable contract

1. **Selection and identity.** The action binds the current selected run and
   pinned baseline, both correct and from the current condition. The explanation
   says “selected minus baseline”, shows both run IDs and measured plan summaries,
   and retains their Trace/condition identities for inspection. Same-run
   comparison is a truthful all-zero result. Missing, failed, mismatched or
   pruned evidence shows an explicit unavailable state; ordinary single-run
   evidence remains reachable.

2. **Observational action only.** Opening, browsing, filtering and closing the
   comparison never evaluates a new plan, creates a history row, changes the
   selected run/baseline, edits the draft, commits pending numeric editor text,
   changes Undo/Redo, alters the goal/target, dirties the Notebook or writes a
   file. Explanations derive only from already measured entries. A small detached
   baseline-entry accessor is preferable to UI access to Session's private state.

3. **Measured accounting.** Display preparation/query/output cycles and their
   deltas, reconciling to the existing total. Show actual RAM read/write amounts
   and their deltas, reconciling to RAM bytes. If cache facts are added, distinguish
   read lookups, fills/misses, hits and actual writes. The simulator's `requests`
   includes both reads and writes, so it cannot be labeled cache read accesses
   without adjustment. Never sum event byte metadata indiscriminately.
   The separate computation audit should freeze exact aggregation definitions
   before implementation.

4. **Response meaning.** Show the same public job IDs on both sides. Distinguish
   admission cycle, completion cycle and elapsed time after admission. Q1 remains
   public job0 completion, not the earliest arbitrary response. Batch jobs can
   overlap in waiting time; do not sum their elapsed response times and call that
   total work. Use existing response/admission facts (`model.gd:51-54,79-87,
   126-137`), not invented timing.

5. **Inspectable explanation.** An explanatory row can focus the associated
   actual events on the chosen side, labeled with that side's run ID. If the
   ordinary Evidence table is reused, switching its source must not change
   `session.selected_entry()`. Return preserves the pair and previous location.
   A simpler first implementation may expose a side selector plus precise
   phase/request filter instead of a second full event table at 960px.

6. **No fake causality.** Present “preparation +X, query −Y” as measured accounting.
   When several controls differ, show those differences and avoid declaring one
   control caused the whole improvement. Even one-control comparisons are
   observations in this condition, not a global optimizer or universal advice.
   Ineffective/dormant plan differences must not be dressed up as causal changes.

7. **State transitions.** Workload switch, selected-run change, baseline change
   and locale rebuild must refresh/rebind the pair or clearly leave comparison
   mode; never silently show old totals under new run labels. Goal edits may
   change eligibility context but not the event accounting. Viewing results
   outside the goal is allowed and visibly labeled, as it is today.

8. **Size/input bounds.** Both Chinese and English must keep the pair identity,
   source of evidence and primary navigation usable at 960×640 and 1280×720.
   Scroll secondary rows instead of shrinking essential labels. Settings/F8/
   challenge/exit precedence and native keyboard focus should retain existing
   behavior. A new explanation action should not unexpectedly trigger Run or
   editor Undo.

## Acceptance anchors and tradeoffs

- The existing serial pair is a useful first fixture: copied versus direct must
  still show +250 Q1, +58 total, −44 RAM B and +80 copy B. Its phase/transfer
  differences must add back to these exact totals.
- The phased workload can isolate copy layout: temperature+alarm field-major
  versus record-major is −64 Q1, −528 total cycles, −528 RAM B and identical
  144 B allocation. Preserve that identity and explain the measured components;
  do not change the model to make an explanation look cleaner.
- Include source-only grouped/ungrouped batch runs so response ordering/waiting
  is not mistaken for service time; same-run, different valid condition,
  missing baseline, allocation-failed run, stale draft, out-of-goal pair,
  immutable input/deep-copy and language/state transitions.
- Check the pure accounting against complete Trace and stored authoritative
  metrics, with assertions for missing/inconsistent evidence. Do not silently
  render fabricated zeroes on malformed input. Failed/partial runs may retain
  their raw evidence; comparable completed-work explanation is unavailable.
- UI acceptance should prove the observation-only contract by snapshotting
  draft, history, selected/baseline, Undo/Redo, goals, target and sidecar bytes.
  Actual event navigation must identify a real event index from the chosen run.
- Fresh human/native exploration remains necessary: ask whether the user can
  explain the pair's RAM/cycle tradeoff and choose a subsequent plan without
  reading implementation prose. Automated checks can establish truthful behavior,
  not that this is now fun or self-explanatory.

The cost is additional presentation state and more information to fit on a small
screen. Keep the first view compact: identity/plan differences, reconciled costs,
Q1 and a route to requests/events. Avoid an exhaustive profiler dashboard.

A player-chosen one-variable experiment is a plausible later mechanism, but
automatic sweeps now would add many genuine yet still opaque rows and can solve
the limited puzzle space on the player's behalf. The paired evidence view
supports deliberate existing edits first. The cheaper kept-plan baseline action
addresses clicks; server replay addresses credible external competition. Neither
alone closes the current local explanation gap.

## Audit evidence and boundaries

Read current lab/session/workspace/challenges, relevant UI tests, current model
event producer/shared simulator, experiment README, CURRENT_STATE, architecture,
planning/coordination and the Round7 verification receipt. All code references
above are one-based lines at the named base.

Directly viewed these three **original** Round7 GPU frames during this audit:

1. `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_structures_ui/layout-structures-en-pair-1280.png`
   — `fe31761e6c88fb8b921d50aae2564ff7bbfab851bd78979b9c25a91820c9c048`
2. `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-en-evidence-960.png`
   — `e1ae10702af320590c9ef7928e9a972f779cabb546357c08a4c46c570fde7803`
3. `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_structures_ui/layout-structures-en-pair-notebook-960.png`
   — `93a80f15f3cf487396040e809b82ffec185aa2737fd0be3065801d5a58a92fc7`

Current relevant source SHA256:

- `lab.gd`: `142e6e38937f70864c97ec1674e46874810e0ca959a76ae68d1463794bc56ad4`
- `session.gd`: `0329ebd9eca8b9920836f0e62a862c97751a0b2d54147f87de48450d18fa88fb`
- `workspace.gd`: `9aab908753308433f41723474245a2d77190722fbb3c2e469b229454d5a7c25b`
- `challenges.gd`: `2e97bc9ad7adbe3093cb86d825d3cbc1c60c4f250685ea291d21202a483c3ee7`

Existing 21-suite/GPU/strategy/native limitations belong to the Round7 receipt;
this audit adds static inspection and original-frame observation only. No
disputed Opus behavior is reopened, no official task/save/score authority is
changed, and no claim of fresh runtime or human acceptance is made.

Read-only scope released to root. Implementation requires root's accepted
contract/file ownership and fresh isolated verification.
