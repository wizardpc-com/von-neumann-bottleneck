# Internal computation audit and measured optimization — Round9

## Goal and scope

After Round8 `2748138d166855e86a5496ce60ca37a8389d4ce7`, audit every active
simulation family, build repeatable full-evidence performance baselines, and
implement the first bounded optimization supported by those measurements.
The user prioritizes correctness, reasonable models/state transitions, real
strategy choices, repeated computation, data structures, Trace generation and
batch experiments. GDScript remains the reference. There is no presumption
that a language change helps.

## Ownership and sequence

Three agents audit and prepare separate adapters: circuit/prologue state,
locality/system/overlap/layout/scheduling memory models, and representation/
prediction/service/creation workloads. Root owns the common benchmark harness,
Git/engine execution, prioritization, integration and final review. Exact live
file ownership is in `.godot/collaboration/round9-audit.md` and the handoff.

1. Inspect current code/tests/contracts; distinguish measured defects from
   potential model or performance concerns. Record unresolved design questions
   without reverting old choices.
2. Run the actual GDScript APIs over representative official/public, legal
   stress, stateful and failure inputs in an isolated pinned-engine copy.
   Record complete results, costs, state and every original Trace event;
   repeat the same input, JSON-restored inputs and batches. Exclude export/hash
   work from compute timings and report workload/setup boundaries explicitly.
3. Measure source-identified hotspots separately. Select the smallest valuable
   optimization; document impact/rollback before changing runtime behavior.
   Keep baseline inputs and full outputs frozen independently of new results.
4. Compare reference and changed implementation exactly, using identical
   benchmark harness and input corpus, fixed batch counts and repeated samples.
   Verify result/cost/state/full Trace, failure behavior, ownership/detachment,
   determinism and old score/condition identities. Run affected actual suites.
5. Review changes independently, bind evidence to final source, verify a normal
   isolated playable startup and document current platform limits. Commit/push
   significant verified milestones only to the task branch; never main/release.

## Invariants and exclusions

No implicit model cost, wire latency, output semantics, transition order,
completion rule, condition identifier, saved format or score interpretation
change. Animation/rendering cannot enter calculation. Hardware-managed caches
and deterministic simplified models remain. Evidence-only optimizations cannot
omit events or silently replace full traces with summaries. Avoid mutable global
memoization and stale-cache risk; prove cache keys and invalidation if introduced.

New mechanisms/workloads, if warranted by audit, must use distinct versioned
conditions and retain old valid results. Native C++/Rust pilots require an
actual high-value measured bottleneck and their own isolated branch/plan,
GDScript fallback, exact complete differential corpus and performance results.
No native migration is authorized merely by a source suspicion. Windows and
macOS support remain requirements; lack of a host is documented, not inferred
from a macOS check.

## Acceptance and rollback

A report alone is not completion: this increment should deliver a measured,
verified runtime improvement or a concrete proven-correctness repair. Runtime
changes remain bounded and revertible independently of player data. Tests must
cover the behavior at risk, not just mirror new implementation. Historical
receipts and signature-only checks do not establish current complete parity.

## Progress

- 2026-11-05: Round8 completed and pushed. Current audits/measurement plan starts
  from the clean task-branch commit above; no simulation behavior changed yet.
  User priorities and GDScript/native constraints captured before implementation.
- Baseline import and 15 existing model suites passed in isolated QA
  `.godot/verification/20261105T090809Z-3273d2f7/project`. All556 tracked
  `src`/`experiments` files matched the base commit and this frozen copy.
- Independent harness review exposed unsupported-field, same-input-only
  ownership and intended-success gaps. Before freezing results, add fail-closed
  snapshots, typed-container evidence, JSON-input immutability, separate
  individual repeats, cross-input retained-result checks and adapter-owned
  semantic outcome validators. Preserve initial harness failures.
- Separate public-API profiling on the frozen base measured4096-symbol weighted
  generation at1.167/1.193/1.183 seconds. Across the4094 actual generated
  prefixes, standalone unchanged-model validation took about0.423s and standalone
  prefix validation about0.478s. These separately measured calls are diagnostic,
  not additive profiler attribution. The selected first candidate is local
  Creation validation/prefix reuse, subject to frozen full-evidence parity.

## Selected candidate and rollback boundary

Keep `Model.predict()` as a strictly validating public entry and preserve its
actual linear rule scan, fallback, tie rules and every event. A private helper
may consume an already validated immutable model and a bounded prefix within one
synchronous generation/codec operation. Validated operation-local canonical
bytes/identity may be reused; no cross-call cache, mutable shared result, new
dependency, threading or native module is introduced. Encoder/decoder bounds
and packet-only receiver authority remain strict. Modeled costs continue to
come from the same event stream, regardless of faster host computation.

Scope is `experiments/creation/model.gd`, optionally its codec callers and
targeted regression tests, after the baseline corpus validates. All packet,
recipe, model, profile, condition and score versions stay unchanged only if
complete differential evidence is exact. Any mismatch blocks this optimization
until explained and corrected. Rollback restores these runtime files from
`2748138`; no save conversion or player-data rollback is needed. Remaining
audit candidates are recorded separately rather than mixed into this patch.

## Outcome

- Implemented only the two Creation runtime files above; retained GDScript,
  strict public validation, packet-only decoding, original rule/event/cost
  semantics and every version. Independent runtime review found no actionable
  defect. No native pilot or model/strategy rewrite was introduced.
- Final frozen-harness corpus:35 accepted scenarios (11 circuit,12 memory,
  12 workload) have exact complete typed input/output/state/Trace parity.
  Seven fixed-count samples on the same Apple M2/macOS engine measure the
  four-generation workflow1.589→0.402s, RAW+predictive1536 transport
  395.804→146.000ms, and Session43.118→34.588ms. Separate three-sample4096
  generation measures1.183→0.280s with unchanged71680 events/338593 cycles.
- The36th scenario confirms an existing failed-step circuit recovery defect.
  Both runtimes fail11 semantic assertions and retain identical full failed
  evidence; strict performance comparison refuses it. The prior12th assertion
  was a fixture assumption about initialized empty state maps, corrected
  without removing those maps from captured results.
- Baseline15 model suites passed. Candidate16 Creation suites and snapshot
  suite have passing latest observations. Final GPU playable198/workbench449
  pass; fixture navigation now opens hidden ledger/works pages explicitly and
  observes actual click activation. Initial GPU failures and the deliberately
  stopped hung fixture are preserved. The three affected headless suites were
  rerun after the helper change.
- Final independent evidence review found a one-shot activation counter could
  not detect duplicate signals. Retained a normal callback through complete
  down/up and settling, disconnected explicitly, then reran both GPU routes
  and all three headless dependents successfully. Full raw/sealed/invocation
  integrity review independently reproduced the35 accepted comparisons and
  checked72 original snapshot byte hashes. Final source binding was refreshed.
- Process sealing closes the observed Godot exit0/script-error false pass;
  strict plain/gzip duplicate-field rejection and21 Python tests pass.
  Source/runtime, actual invocations, original/full sealed evidence, initial
  failures and measurement limits are in the
  [receipt](../../verification/20261105-computation-kernels/README.md).

## Remaining work and rollback

First repair circuit last-valid output carry as a separate scoped correctness
change, preserving prior successful full traces and explicitly changing failed
continuation behavior. Do not silently roll back committed storage or globally
reorder settling. Next define coherent invalid Region evidence. Measure other
duplication candidates before selecting another optimization or native module.

Ordinary isolated startup is verified. Native input remains unrun after the
last locked-Mac observation; Windows, exported builds, long sessions, newcomer
understanding and actual host heap peaks are not established. This increment
does not complete the ongoing game-systems goal. Rollback restores the two
runtime files from2748138 without a save migration; benchmark/test evidence can
remain. Significant verified work is committed/pushed only to the task branch.
