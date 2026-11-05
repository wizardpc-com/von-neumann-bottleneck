# Round9 workload computation audit and adapter

Owner: `/root/audit_polish`, 2026-11-05. Scope follows
`.godot/collaboration/round9-audit.md` and
`docs/exec-plans/active/computation-kernels-20261105.md`.
Reference milestone: `2748138d166855e86a5496ce60ca37a8389d4ce7`.

## Delivered scope and evidence boundary

Added only `scripts/benchmarks/computation/workload_cases.gd`:
319 lines,12 case descriptions, no class name/autoload, timing, file access,
scene construction, engine invocation or persistent write. The adapter is
**released to root** for import, execution and integration.

At release its SHA256 is
`71a876690379ccda83e5f2b5831fd2cd68c8fcbacd8965f7aa8a7f7dff3c6fb5`.
The no-index whitespace check emitted no diagnostics (exit1 is the expected
added-file diff status). Current status and adapter source were inspected.
Other agents' adapters and root's plan/harness changes were preserved.

**Godot parse, runtime correctness, timings, JSON parity and platform parity
have not been executed by this agent.** All performance items below are
source-supported candidates, not measured bottlenecks. Existing tests were read,
not rerun. Root owns all engine/native/Git operations.

Read the repository rules/plan/current-state entry points, relevant model
contracts and implementations for all six assigned directories. The original
linear scene delegates to `experiments/representation/lab.gd`; there is no
separate `experiments/intelligent_workload/lab.gd`.

## Candidate priorities

### A. Creation repeatedly validates unchanged model and full growing prefixes

`experiments/creation/model.gd:174-180` calls `validate(model)` and
`symbols_error(prefix)` for every public `predict`. Validation checks every
stored training example and JSON-hashes it (`model.gd:102-106`), walks every rule,
and serializes/hashes the canonical model for its parent guard
(`model.gd:107-124`). `generate` already validates model/input/machine, then
calls `predict(model, output)` for every emitted symbol
(`model.gd:195-212`). Thus a valid1024-symbol run repeats unchanged training
validation about1022 times and repeatedly scans its entire growing prefix.
The code supports4096 symbols, so this prefix validation has quadratic aggregate
work independent of the modeled order0–2 context.

The predictive codec has the same issue. Encoding slices `symbols[0:index]`
before each public predict (`codec.gd:27`); decoding supplies the growing output
(`codec.gd:92`). The sender revalidates full example provenance on each symbol;
the receiver reconstructs a model with empty examples, so its validation cost
is distinct. Canonical bytes and identity are also recomputed several times
per operation (`model.gd:201,205,235-236` and codec setup).

Potential bounded direction after measurement: keep strict public entry checks
and introduce a private validated prediction helper for an immutable operation,
with only the required bounded suffix as lookup context. Reuse validated
canonical bytes/model identity within that one operation. Do not put mutable
models in a global cache. Public `predict` must continue rejecting malformed
full prefixes/models. Preserve every original rule-read/fallback/select event,
ordering, CPU/bus costs, cache behavior, exact generated output, canonical bytes,
recipe, source identity and PRNG advances. Replacing the modeled linear row
walk with an indexed hardware lookup would change game costs and is not this
optimization.

Adapter `creation_generation_stress` includes a normal64-symbol max run and
1024-symbol weighted/max runs from a public varied256-symbol training prefix.
`creation_public_transport` includes the real1536-symbol C3 source with RAW and
predictive paths under public machineB. Root can microprofile validation,
prefix processing and event creation separately before selecting a change.

Relevant existing checks: `test_creation_contract` (actual packet restoration,
source independence, complete recipes, counted events, seeded generation,
malformed packet/model and memory bounds), `test_creation_condition_examples`,
`test_creation_prediction_memory`, `test_creation_prediction_flow`,
`test_creation_comparison`, `test_creation_state_regressions`,
`test_creation_evidence_identity`, and session/restart compatibility tests.
New optimization tests should compare all event fields against frozen old
output, not merely output sequences or canonical signatures.

### B. Representation Region repeats identical cold-client simulation

`experiments/representation_region/model.gd:16` computes `Base.run(spec,plan)`.
For each later client, line48 calls it again with the identical full spec/plan.
Public task4's eight clients have identical requests/data/machine and each
starts cold (`README.md:25-29`). The wrapper then copies every event, attaches
the current client ID and re-emits it at the new absolute cycle, and duplicates
accesses (`model.gd:49-55`). Re-encoding the same blocks, decoding identical
misses and resolving the same cache sequence eight times is a concrete source
duplication; its fraction of total runtime is not measured yet.

A possible local optimization is to reuse the already completed service
template within this one `run` while still emitting all distinct per-client
events, independent copied details, client IDs, access rows, outputs and cost
totals. This is not shared cache residency between modeled clients. Preserve
full output equality and no-alias evidence; no scores or conditions change.
`representation_online_clients` captures both public short/eight-client orders
for RAW and the legitimate raw8/RLE56 partition.

Existing `test_representation_region:20-45` independently checks clients'
ordered outputs, sequential events, preparation/service accounting and bytes.
`test_representation_plan` verifies coverage/directory/cache work; cache tests
check transactional rejection and detached values. These tests' signature
checks are useful but root's full property snapshot remains stronger.

### C. Invalid Region preparation parameters leave contradictory residual metrics

`experiments/representation_region/model.gd:16-20` executes a complete legal
base service before checking `online`, `clients` and `encoder`. On invalid
preparation parameters it clears events, sets `total_cycles=0` and `passed=false`,
but preserves already-populated `request_cycles`, `transfer_cycles`,
`consume_cycles`, traffic, outputs, accesses, result/expected values and cache
counts from that discarded service.

This is a source-demonstrable failure-evidence inconsistency and unnecessary
work, not a claim of official false completion: the result remains failed,
authored specs are valid, and completion requires a passing result. Existing
`test_representation_region:74-76` only asserts rejection for these bad fields.
The adapter's `workload_rejections.region` uses a valid public spec with
`clients=0` to preserve the exact current failed result for root to inspect.

If root selects a correctness repair, validate all preparation-specific fields
before service work or create a consistent rejected result, with an explicit
test that failed execution has no work/output or nonzero cost. Such a repair
intentionally changes this malformed-input snapshot; do not silently relabel it
as full old/new parity. Every valid public result must remain exactly equal.

### D. Additional repeated evidence work to profile before changing

- Address prediction always executes an Off baseline after the selected run
  (`experiments/prediction/model.gd:16-29`), even when selected policy is Off.
  The default-Off case duplicates an identical full trace to derive baseline
  totals and pollution. An operation-local Off fast path can potentially avoid
  it while preserving every chosen result and the counterfactual definition.
  Other policies need a genuine Off evaluator; the predictor must never receive
  baseline/future information. The adapter includes regular Off, regular stride,
  pollution, changed confidence/cooldown, queued fallback and64-demand cases.
- Creation prediction reveals re-summarize the entire accumulated event prefix
  (`session.gd:277-297`), and evidence requests repeat that on a detached copy
  (`session.gd:303-310`). This is correct replay with preserved cache counters;
  incremental accounting would require additional state and exact invalidation.
  Profile first, particularly `training` sequences that may be much longer than
  the12–24-symbol authored practice/checks.
- Creation pure profile decode re-learns and regenerates independently for
  current training, kept works, supports and optional comparisons
  (`session.gd:442-586,604-612`). Repeated identities may share work only inside
  one validated snapshot with exact machine/recipe keys; do not weaken hostile
  input validation or trust persisted cost fields. The in-memory session
  benchmark returns all operation results, complete private/public session
  fields and a full pure decode result.
- `comparison.gd:129-155` can replay a complete saved generation for each side
  when a requested difference snapshot has no events. That is on-demand source
  evidence, not a per-frame model run. Creation `_process:1686-1697` only advances
  presentation cursor. Any later memoization should be bound to the exact
  protected recipe and retained result.
- Region UI `refresh_tasks:460-462` revalidates all protected plans through
  `representation_review_evidence:1059-1068`; `show_closure` repeats that
  (`1071-1073`). Restore can replay up to100 histories plus5 supports
  (`774-803`). Service restore similarly replays up to80 histories plus3
  supports (`lab.gd:872-891`), while closure reconstructs the3 supports
  (`1065-1075`). Fresh validation is justified; repeated unchanged in-memory
  evidence within one refresh/restore may be redundant. This adapter measures
  the actual underlying model kernels, not full GUI startup.
- Service `StateReplay.build:56-122` produces one detached full state per
  recorded event, with cumulative response arrays. Selecting a record rebuilds
  all frames (`lab.gd:664`, `state_replay_view.gd:61-69`). This is bounded24-request
  work; its costs must be measured before replacing a straightforward trustworthy
  projector with a cache or lazy representation. The baseline replay case
  returns all frames plus the original complete Trace.

## Model/state/strategy conclusions and preserved choices

Representation's shared byte RLE and variable-block directory are actual encoded
bytes. Automatic decoded LRU owns values and snapshots; oversized inserts leave
other entries and replacements intact. Plan coverage, scratch/machine/address
bounds are checked before events. Region source references, retained64B source,
offline versus online preparation and separate backing-storage peak are explicit
contracts. No arbitrary compression bonus or source-copy omission was found in
the reviewed valid public paths. The original uniform-block model is less strict
about external dictionary types than the later plan models; its public UI uses
bounded controls. Do not broaden type hardening into an unversioned behavior
change during a performance patch.

The linear and persistent-context models are declared teaching arithmetic.
`state_model`32-bit mode is explicitly **unrounded GDScript arithmetic with4B
accounting**, not an exact float32 kernel (`STATE_README.md:17-23`). Service
instead stores real float64 or signed Q8 bytes; word RLE compares bytes and
preserves signed zero. This difference is documented, not a defect to “fix”
by changing numerical results. Dirty states are written before eviction,
every remaining dirty state flushes, and Q8 rounding occurs on each update
regardless of residency. All-ready requests, sequential execution and batch
return only after group compute are explicit mechanics.

Existing tests independently reconstruct recurrence, every physical transfer,
LRU order, final stores and errors. State exact grouped versus resident schedules
trade throughput against first response; Service exact/quantized and mixed
lossless plans remain legitimate alternatives. No reason was found to remove
these strategies or introduce fake precision speed multipliers. Finite public
tests and this small adapter do not prove global optimum or human fun.

Prediction correctly separates overlapping bus work from elapsed time,
coalesces matching in-flight requests, charges unrelated-job waits and drains
tail speculation. “Wrong next guess” and “eventually useful transferred line”
are deliberately different metrics. Cache pollution is defined against an
independent Off run, not claimed as one-step causal attribution.
`test_prediction_slice` exhausts the small public policy family and separately
checks matching/queued paths and causal prefix independence.

Creation restores packet-only truth, includes model/header/checksum bytes,
uses fixed sample-derived counts, prefix-only decisions, deterministic
Park–Miller sampling with recorded rejection draws, and explicit CPU/cache/bus
event accounting. All partial prefix reveals retain frozen model/machine.
`summarize` intentionally writes resolved cost/cache fields onto supplied events;
public evidence passes it detached copies, and repeated summaries preserve
`requested_bytes`. A native pilot would need bit-for-bit floating results for
Service and exact integer/PRNG/byte/Trace parity for Creation, including event
order and every failure contract. None is justified by this source review alone.

## Benchmark case inventory

All case inputs are declared in `cases()`. `run_case()` builds fresh copies;
JSON integer-valued numbers are reconstructed explicitly and required
`Array[int]`/`Array[Dictionary]` parameters are rebuilt. Fractional numbers are
not rounded by the generic normalizer. The declared failure fixtures use
invalid values/dependencies, not intentionally float-typed integral numbers.
No expected metrics manufacture any results.

| ID | Actual path and returned evidence |
|---|---|
| `representation_fixed` | Three original RAW/RLE dense/sparse complete Traces |
| `representation_partition_revisits` | Two plans × scan/192-access revisit, four complete Traces |
| `representation_online_clients` | Two plans × two public online orders; complete Traces and actual `Region.meets` |
| `linear_precision_batch` |32 public samples for three actual precision/batch/reuse configurations |
| `persistent_context` | Three exact/quantized scheduling/residency runs including all final states |
| `address_prediction` | Six actual selected-policy runs, internally measured Off baselines and full chosen evidence |
| `service_baseline_replay` | Public baseline Trace and every actual `StateReplay.build` frame |
| `service_representations` | Three legal plan Traces and all16 format/stream pack/unpack results |
| `creation_public_transport` | Full learn result; public1536 source RAW and predictive results including both halves, packet, costs and all events |
| `creation_generation_stress` | Full learn;64max plus1024weighted/max, all outputs/events/recipes |
| `creation_committed_session` | Every API result in a fresh in-memory C→P→G/check-v2 flow, denied transitions, full final Session and pure profile decode |
| `workload_rejections` | Actual region/partition/linear/state/prediction/service rejection traces; Creation full setup, damaged packet and actual codec/model/generation rejection results |

The session case never calls `open`, `save` or `close`; no writer lease or real
profile is acquired. Its completion calls affect only the disposable in-memory
Session used to exercise strict pure decode. It does not award campaign progress.

## Measurement caveats and recommended first checks

1. Root should import the adapter before timing; this agent did not run an engine.
   Check every expected valid nested result actually executed, especially the
   session's `decoded_profile.ok`. Deterministic failure is not valid performance
   coverage for an intended successful case.
2. A case can return several genuine operations. Report its declared workflow
   boundary; do not call a four-trace region case the time of one client, or a
   full transport case the codec kernel alone. Creation transport includes
   learning; in-memory session includes strict decode/replay.
3. Large Creation results deliberately include nested encode/decode and combined
   events because those are the real API result. Snapshot serialization can be
   large, but root's harness places it outside the timed region. Do not strip
   events or replace them with hashes to make the benchmark faster.
4. Full rendering, actual many-history startup, file transactions, maximal16×4096
   training, all4096-symbol generation variants, UI parsing/IME and Windows/native
   acceptance are not covered by this bounded adapter. Training can build a large
   event list before its final memory-limit rejection (`model.gd:66-92`);
   profile that separately if the upper boundary matters.
5. No production behavior, cost, output, format, condition, score or old
   successful recipe changed. Any later optimization needs frozen baseline
   comparisons and affected suites. Any intentional malformed-input repair
   needs a separately attributed difference rather than a false parity claim.

Audit and adapter handoff complete. Root may now measure and select the bounded
implementation; all source ownership is released.
