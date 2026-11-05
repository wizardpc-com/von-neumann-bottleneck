# Round8 pure explanation implementation

Scope: `/root/audit_scores` owns only
`experiments/layout_strategy/explanation.gd` and
`tests/test_layout_strategy_explanation.gd`. Implemented against the frozen
`.godot/collaboration/round8-implementation.md` contract and active plan.
Files are ready for root-owned isolated synchronization/execution. Source edits
have stopped pending the first engine result and independent review.

## Implemented

- `summarize(entry,current_condition)` produces fixed prepare/query/output/total
  rows, real fill/write RAM reads and writes, cache read lookups/fills/hits,
  copied payload versus allocated copy bytes, and public-order job admission/
  completion/elapsed rows. Rows retain original event indexes only, not copied
  full Trace objects.
- `compare(selected,baseline,current_condition)` consumes detached raw entries,
  emits both summaries and selected-minus-baseline phase/job integer deltas.
  Same-run comparison is valid. Missing/current-mismatched/incomplete evidence
  returns only `ok:false` and a stable reason, never partial improvement data.
- Bounded validation accepts integral JSON numbers. It checks snapshot types,
  current condition, normalized plan, correct ordered outputs, event kinds and
  costs, continuous event clock, read transaction structure, phase/job tags,
  actual output emission and response spans, admission/completion consistency,
  allocation/release shape and reconciliation with existing authoritative
  metrics. It does not simulate cache replacement, reconstruct memory contents,
  evaluate/replay a plan, change source Trace fields, or use auxiliary maps.
- Batch-at-zero and causal serial admission patterns are checked against the
  observed arrays/events. The caller supplies the current condition authority;
  the reducer does not reconstruct a catalog task from its ID, because actual
  Model fixtures can use valid sparse/duplicate/custom content with that same
  allowed ID. This is local consistency checking, not online authenticity.
- No model rules, canonical identities, goal eligibility, codes, saves, official
  state, UI, Session, autoloads or documentation were changed by this agent.

Unavailable reasons currently used:
`entry`, `condition`, `incomplete`, `plan`, `metrics`, `outputs`, `events`,
`phase`, `bytes`, `clock`, `reads`, `jobs`, `timing`, `allocation`; comparison
can additionally reject `task`.

## Authored verification

The new suite executes actual Model fixtures, then checks the observational
result:

- Pair direct614cycles/544B versus retained672cycles/500B: preparation+442,
  query−384, total+58; traffic+340−384=−44; lookup denominator51 versus
  requests68; payload68B versus allocation80B.
- Record/field layouts: shared preparation612cycles/408B; query and total
  differences−528cycles/−528B; allocation144B versus payload136B.
- Source grouping8/tile1: total−1904cycles/−1904B with Q1+224, no copied data;
  overlapping batch elapsed intervals are explicitly not summed as work.
- Sparse earlier completion, public Q1 identity, duplicate and nonmonotone
  indices, tiled tails, source and copy plans, and maximum4096-output/16-job
  workload. Original event indexes remain ordered and retain phase/job source.
- Repeated/JSON summaries, input immutability and nested detached outputs;
  zero-delta same-run comparison; wrong condition/task/missing baseline.
- Malformed numeric/types/events/phases/bytes, inconsistent metric totals,
  changed request identity, wrong fill address/output/span, missing response,
  incorrect allocation and actual failed allocation. Unsigned auxiliary-map
  changes do not affect event-derived summaries.

## Verification status and handoff

This agent did not run Godot or probes. Root owns import, engine tests, renderer
and final acceptance. Before handoff, read-only `git diff --check` passed and a
direct scan found no trailing whitespace in either new file. The pure module
contains no `evaluate`, `run_current`, `FileAccess`, `DirAccess`, `user://`,
`GlobalSave`, `await` or `_process` references. Both files have terminal newlines.
Other visible workspace changes belong to root/UI owners and were preserved.

At this handoff the implementation is **not yet runtime verified**. Root must
read the first full suite result and preserve any initial failure, then run the
planned integration/parity gates. No native/player-comprehension/cross-platform
claim is made.
