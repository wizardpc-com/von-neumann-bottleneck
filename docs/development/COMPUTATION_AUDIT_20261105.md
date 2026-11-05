# Internal computation audit — 2026-11-05

Base: `2748138d166855e86a5496ce60ca37a8389d4ce7`, task branch
`codex/gameplay-systems-20261104`. This audit supplements the
[gameplay review](GAMEPLAY_AUDIT_20261104.md); it does not revise old results.
The [execution plan](../exec-plans/completed/computation-kernels-20261105.md)
separates measurements, implementation and acceptance. Detailed independent
reviews are under [the evidence directory](../verification/20261105-computation-kernels/reviews/).

## Scope and interpretation

Three agents examined Boolean/prologue circuits; locality, byte-system,
overlap, layout and independent scheduling; and representation, online-region,
linear/persistent state, address prediction, Service and Creation. Root owns
prioritization, engine runs, integration and complete differential evidence.
The baseline's15 existing model suites passed on the pinned Godot4.7.1.
Static review plus finite fixtures does not prove arbitrary-input correctness,
global strategic optimality, native responsiveness or Windows acceptance.

The measurement corpus calls actual public APIs and retains complete results,
state, bytes, costs and every event. It includes authored fixtures, bounded
stress, deliberate rejection, failure recovery and stateful continuation.
Separate semantic checks require each intended workload to execute. Exact
snapshots preserve integer64, float64, typed containers and original script
fields. They normalize dictionary ordering and reference identity; behavioral
input/retained-result tests check mutation separately. Unsupported evidence
fails closed. Timings include normal input construction and API-owned
serialization; only the benchmark's own snapshots/hash/export are excluded.

## Prioritized computation work

| Area | Observed source behavior | Decision |
| --- | --- | --- |
| Creation prediction/generation/codec | Unchanged model, examples and complete growing prefix were revalidated for each output symbol. Encoding also copied every growing prefix. | Implemented operation-local reuse. Four-generation workflow1.589→0.402s;1536-symbol RAW+predictive workflow395.804→146.000ms on this Mac. Full captured results/events are exact; public validation and modeled work remain. |
| Prologue validation | Each existing wire is looked up again through an editing duplicate scan, then checked in a separate `seen` map. | Measure actual graph workloads before changing endpoint/port/width/error order. |
| Prologue topology/state | Stable topology is sorted/signed repeatedly; settling and commit create many small objects. | Required pre/post-state settling, simultaneous commit and observer events must remain. No pooling without explicit reset/ownership guarantees. |
| Overlap Trace | Every cycle emits a required state snapshot; `_event` and the event constructor both deep-copy it. | Candidate allocation reduction. Do not remove cycles, events or detachment. |
| Layout scratch | Each release scans source and scratch although allocated scratch addresses are known. | Candidate direct deletion. Preserve physical memory/cache effects, padding and sparse/duplicate query order. |
| Scheduling/query tiling | Small tiles repeatedly walk sparse index lists. | Candidate per-operation indexing only if measured valuable; preserve output positions and request/response order. |
| Online Region | Identical cold-client service is recomputed before re-emitting client-specific evidence. | Candidate reuse of one local immutable service template; modeled clients must stay cold and detached. |
| Address prediction | Selecting Off still computes another identical Off baseline. | Candidate local reuse. Other policies retain a genuinely independent counterfactual. |
| State/Service/replay | Full state frames, real bytes and strict restore replays generate repeated data. | Preserve dirty eviction/flush and rounded-byte semantics. Measure full application flows before introducing caches. |
| Score/challenge validation | Some signatures and model evaluations repeat across presentation and authority boundaries. | Local immutable reuse may help; never accept UI/persisted metrics as authoritative or remove required remeasurement. |

No C++/Rust pilot is selected. Remove measured redundant work in GDScript first;
a later native trial needs its own isolated branch, full deterministic/Trace
differential corpus, compatibility evidence and measured benefit.

## Retained correctness and model review queue

These issues are scoped separately from a performance-only change.

| Item | Evidence and present impact | Required follow-up |
| --- | --- | --- |
| Circuit evidence documentation | Circuit/Prologue canonical event dictionaries contain deterministic `visual_step`; general simulation prose says it is excluded. | Correct the documented distinction without removing old canonical fields. |
| Raw versus sealed latch | Raw NOR S=R=1 can settle to Q=NQ=0; sealed SRLatch rejects it. The raw UI warns separately. | Review teaching intent; do not silently unify semantics. |
| Missing stimulus | Boolean required inputs reject absence; prologue high-Z resolution may accept a net with another known driver. | Specify the public input contract before changing valid behavior. |
| Settling ceiling | The64-tick limit can reject a deep acyclic circuit as well as feedback. | Any topological fast path or bound change needs explicit version/Trace/old-achievement analysis. |
| Failed-step recovery — corrected in Round10 | Whole and incremental register sequences write3, encounter conflicting5/6 drivers, then previously failed again on legal0/0 HOLD input. Failed prior outputs were resolved before new stimuli. | Retain last-valid final electrical carry; original failed observation and pre-recovery events stay exact. Eleven successful circuit scenarios retain full parity. Actual Debug/Step recovery and a related interrupted-playback caption correction are documented in the [Round10 receipt](../verification/20261105-circuit-failure-recovery/README.md). No global initialization reorder or validator relaxation. |
| Malformed prologue API | Null sequence/certain malformed port arities assume trusted catalog input. | Separate bounded robustness probe and explicit failure contract; not covered by normal campaign success. |
| Invalid Region metrics — corrected in Round11 | Rejected preparation parameters previously cleared total cycles/events but retained completed base-service fields. | A fresh failed Trace retains submitted inputs and clears all published work/output/cache evidence. Base-error precedence remains intact;32 authored-order traces plus4 existing online traces retain complete typed parity. See the [Round11 evidence](../verification/20261105-region-rejection-evidence/README.md). |
| Receipt reuse | `SystemRunReceipt.populate_from_traces` accumulates fields if reused. Production currently creates fresh receipts. | Keep immutable-use convention or add an explicit tested reset before pooling. |
| Layout rejection state | A rejected run may retain the previous internal `data` reference, while its returned failed Trace is clean. | Define reset contract before exposing/using internal failed state. |
| Trusted catalog boundaries | Original APIs accept some workload assumptions upstream; the scheduling experiment has stricter explicit bounds. | Do not treat those entry points as interchangeable arbitrary-input APIs. |

The existing distinctions remain meaningful: wire connectivity has zero
latency; cache contents are hardware managed; overlap busy time differs from
elapsed time; output sinks differ from real copy stores; scheduling job0
response differs from whichever job happens to finish first. Persistent
state's documented32-bit mode uses unrounded GDScript arithmetic with4B cost
accounting; Service uses real float64/Q8 storage. These are explicit simplified
models, not interchangeable precision kernels.

## Round9 measured outcome and limits

All35 accepted scenarios (11 circuit,12 memory,12 workload) have identical
complete typed input/result/state/event snapshots between frozen2748138 and
the candidate. Each process validates intended outcomes, repeat/JSON equality,
input immutability and retained results. The36th scenario's known recovery
failure is separately identical; strict performance comparison rejects it.
That historical broader corpus also preserved invalid Region evidence.
Round11 separately corrects only its preparation-specific rejected result;
the original Round9 artifacts remain unchanged.

The Generation workflow contains64max,1024weighted,1024max and4096weighted
calls, not one generation. Its median improves3.96×; actual public transport
improves2.71× and the complete committed Session workflow1.25×. A separate
three-sample4096 profile measures1.183→0.280s median while retaining71680
events and338593 modeled cycles. Source-identical controls vary; the short
Overlap failure/reuse case is5.2% slower in this observation. No runtime
change touches that path, and no universal performance claim is made.

No host heap-peak measurement, Windows run, exported build or native interaction
acceptance is established. GDScript remains the reference; faster computation
does not change game cycles, memory formulas, saved results or score conditions.
See the [complete evidence and method](../verification/20261105-computation-kernels/README.md).
The separate Round10 correction closes the demonstrated circuit recovery
defect without changing old valid results or post-commit storage behavior.
Round11 defines consistent preparation-rejection evidence while retaining Base
failure priority and all valid measured results. Next measure repeated cold-client
computation and the remaining source-level duplication candidates. Proposed native
thresholds in the independent priority report remain recommendations for a
future scoped pilot, not an adopted platform or product rule.

## Strategy direction

The earlier formal-layout sample found one dominating metric triple per task;
that finite search was not a proof of global optimality. The separately
versioned scheduling experiment already makes source tiling, query grouping,
copying and first response independent choices. Keep all original conditions
and achievements valid while exploring new workload structures there.

Useful future experiments should expose competing real costs: preparation
amortization across request counts, first-response versus throughput, hot-set
reuse versus copying space, mixed lossless storage versus decode traffic,
prediction benefit versus pollution, and precision versus state error.
Resource caps alone do not create a tradeoff when one strategy dominates every
axis. No new workload, goal, model version or leaderboard rule is introduced by
this computation optimization.
