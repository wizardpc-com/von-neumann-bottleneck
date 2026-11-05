# Round9 memory/system/scheduling computation audit

2026-11-05. Assignment: `.godot/collaboration/round9-audit.md`, base
`2748138d166855e86a5496ce60ca37a8389d4ce7`, task branch
`codex/gameplay-systems-20261104`.

## Delivered scope and verification boundary

Created only `scripts/benchmarks/computation/memory_cases.gd` (309 lines,
12 cases). Initial SHA256:
`1670b0a879d30fd2e884ef5d6b2a711321ca9300adddcb45d8f54dd4c2cd603a`.

The adapter uses real locality, system, overlap, layout and independent
scheduling public APIs. It creates fresh input/state per invocation, rebuilds
required typed integer arrays explicitly, and returns complete Trace/result
objects. Stateful reuse workflows additionally return the final simulator or
executor object, so the shared snapshotter can inspect all script properties,
including inherited fields. Repeated object references are acyclic and may
appear both as a returned run and the final simulator's `trace`.

Static checks: exactly12 descriptors; every preload resolves; no timing,
filesystem, OS/UI call, signature-only result or manufactured metric in the
adapter. Read-only `git status` confirmed the expected task branch and disjoint
other-agent benchmark/documentation work, which was left intact. No engine,
test, native tool, player profile, Git mutation, production source or existing
test was touched. **Import, runtime validity, actual timings and full evidence
parity remain for root's isolated runs.** Source suspicions below are not
measured bottlenecks.

Read the relevant project rules, architecture contracts, current state and
testing guidance. Reviewed the five primary cores plus event/Trace types,
layout mapping/catalog, overlap catalog/state validation, system parser/topology/
parts/receipt, locality parser and scheduling session/workspace/challenge call
paths. Existing test anchors include `test_simulation`,
`test_system_lab_simulation`, `test_system_applications`,
`test_overlap_simulation`, `test_layout_simulation`,
`test_layout_trace_storage`, `test_layout_strategy_model`,
`test_layout_strategy_structures` and frozen catalog/legacy parity.

## Benchmark cases

| ID suffix (`memory.`) | Actual API and input | What it retains |
| --- | --- | --- |
| `locality.public` | `SimulationCore.run_source` with official row/column DSL at1/2/4 cache lines, plus actual direct-RAM `run_workload` | All7 full traces; final stateless core |
| `locality.blocked64` | `run_workload`, official16 values,64 passes, unblocked versus one-line groups | Both traces including original scheduling detail fields |
| `system.public` | `SystemSimulationCore.run`, official final4/16/64 cases, balanced CPU/RAM and4-bit bus; actual `SystemRunReceipt.populate_from_traces` | All3 traces, complete receipt and topology |
| `system.failure_reuse` | Official255→0 assembly, disconnected topology, parsed legal index63 against a one-item input, then original assembly on the same core | All4 success/failure traces and final topology/core |
| `overlap.public` | `OverlapCatalog.evaluate` and authored reference for all6 tasks, including both backpressure and synthesis cases | All8 full traces and aggregate results |
| `overlap.queue64` | `OverlapSimulator.run`,64 batches,16-cycle transfers,8-cycle computation, one-line cache; prefetch all before consuming in order | Complete queue/eviction/state Trace and final simulator |
| `overlap.failure_reuse` | Actual backpressure reference, premature consume, empty-buffer deadlock, reference again on one simulator | All4 traces and final buffers/cache/queue/engines/state |
| `layout.public_native64` | `LayoutCatalog.evaluate` for all6 official references, then native64 records with both physical orders | All12 official traces, two native traces and final simulator |
| `layout.batch64_reuse` |64 records, one-record all-field scratch batches,8 repeated two-field sums; oversized full copy; duplicate-field recipe; legal run again | All4 traces, actual scratch maps and final simulator memory |
| `scheduling.public` | `Model.evaluate` for all6 current scenarios with direct and full selected-field copy | All12 actual result envelopes and complete LayoutRuns |
| `scheduling.maximum4096` | Existing tested maximum:64 records×4 fields×16 jobs, group16, tile7 | All4096 real outputs, full events and response timing |
| `scheduling.failure_reuse` | Public allocation failure and serial-group schema rejection; duplicate/nonmonotone sparse workload; existing `Executor.measure` failure→success→success→success reuse path | Both public failures, public sparse run, all4 executor traces and complete final executor |

The64-pass locality case is a legal **low-level API stress** because
`run_workload` accepts any positive pass count; it is not a claim that the
authored campaign exposes64 passes. The64-batch overlap stress uses the same
public low-level API with positive bounded task values and a program far below
the16K-character limit; root must confirm actual completion below the4096-cycle
limit. No task IDs, official targets or saved definitions are changed.

Grouped cases intentionally measure complete representative workflows, not a
single instruction or an inferred engine-only cost. Catalog/fresh-input
construction is inside the timing contract. The system receipt includes its
normal signature work, while the runner's own snapshot/export/hash work remains
outside timing. Narrow follow-up probes will be needed before attributing a
whole-case timing to one helper.

## Highest-value source candidates for measurement

1. **Overlap state snapshots are deep-copied twice for every event.**
   `overlap_simulator.gd:244-278` advances one cycle at a time and emits a `state`
   event after every cycle. `_event:291-297` first deep-copies details and buffers
   and copies cache, then `SimulationEvent._init:42-43` copies route and deep-copies
   the entire details graph again. The tiny official workloads hide the
   multiplicative allocation cost; the queue64 case exercises thousands of
   required snapshots. A bounded first experiment is to let the existing event
   constructor perform the sole deep detachment while preserving every key,
   nested value, source line, duration and event position. Do not remove state
   events or fast-forward time: those snapshots are an explicit replay contract.
   Regressions: overlap public references/failures plus retained-result mutation
   checks and exact same-cycle transfer→compute→next-transfer→state order.

2. **Every scratch release scans all source memory again.**
   `layout_simulator.gd:194-201` builds `memory.keys()` and scans source plus
   scratch for each batch, although `current_copy.cells` already enumerates the
   scratch addresses. With64 source records and batch1 this scans roughly the
   same256 source words64 times to remove four copied words each time. Candidate:
   delete only actual allocated copy cells, preserving cache invalidation and
   the release event. Measure `layout.batch64_reuse` and the authored batch/mixed
   references before choosing this. Guards: complete outputs, source/scratch
   maps, source immutability, padding, sparse duplicate reads, partial final
   batch, failure cleanup and old141-design/282-case Trace parity.

3. **Normal authority paths serialize or simulate the same result repeatedly.**
   `session.gd:81-89` converts every event to dictionaries, then
   `LayoutRun.canonical_signature()` serializes the same events again.
   `challenges.gd:119-132` replays selected evidence (intentional authority),
   computes the same canonical signature twice and separately converts all
   events. `layout_chapter.gd:381,391-392,458` evaluates current/starter/best,
   then `layout_state.gd:36-39` re-evaluates current and incumbent for progression.
   Overlap similarly evaluates before `record_pass`, which re-evaluates at
   `overlap_state.gd:29`. These are concrete repeated call sites, but the adapter
   does not time whole UI/save flows. A safe first narrow candidate is to reuse
   one local signature value inside `Challenges.compare`; removing authoritative
   replay or accepting UI-claimed metrics would be a semantic/trust change.
   `workspace.kept_rows:128-140`, challenge target inspection and the presenter
   verdict already cache by input/condition identities; do not describe them as
   unconditionally replaying on every frame.

4. **Small tiles repeatedly scan all sparse indices.**
   Formal `_query_batch:169-181` and scheduling `_consume_tile:112-124` rescan the
   complete index array per batch/tile and skip out-of-range records. For maximum
   jobs and tile1, most loop visits do no memory operation. A future per-run index
   partition may reduce those visits, but must retain original index order,
   duplicates, original output positions, job admission, response completion,
   and `query_tile_first`. The sparse/duplicate reuse case protects these details.
   This is a measurement candidate after event allocation, not an assumption
   that a new data structure is faster at17/64 records.

5. **Validation/normalization and parser setup repeat around small simulations.**
   Scheduling `evaluate:224-233` validates and normalizes, the inherited core
   validates again, then `condition_id` revalidates/re-normalizes the task and
   `plan_id` re-normalizes the plan. Locality `DSLParser.parse:19-32` recompiles six
   fixed regexes per parse. Preserve all public validation and identity behavior;
   if measured material, consider a private already-validated execution path or
   immutable parser setup. The current small data bounds may make these more
   relevant than arithmetic language throughput. No C++/Rust pilot is justified
   by this source review alone.

## Correctness, lifecycle and strategy observations

No current official-output or cost-rule regression was confirmed by this source
review. The code maintains the documented distinctions: locality direct values
versus cache lines, sequential byte system requests, overlap elapsed versus busy
time, layout physical copy writes versus output sink, and scheduling public job0
completion versus whichever sparse job happens to finish first.

Two lifecycle hazards matter before pooling/reusing objects for speed:

- `SystemRunReceipt.populate_from_traces:26-62` does not clear prior signatures,
  case_metrics, trace_signatures, part IDs or passed_cases. Calling it twice on the
  same receipt can accumulate counts and make a previously passing identical
  observation fail. The current production call sites instantiate a new receipt
  (`system_lab.gd:2382`, `system_level_catalog.gd:438`), and the method describes
  an immutable observation. Therefore this is **not a confirmed current gameplay
  regression**; receipt reuse must either remain forbidden or receive an explicit
  tested reset contract before an optimizer introduces pooling.
- `LayoutSimulator.run:34-42` resets most state before validation but assigns
  `data` only after validation succeeds. An invalid run after a valid one retains
  the previous internal data reference; returned failed Trace authority is not
  contaminated. Current later valid runs reassign it. A native wrapper or new
  state-inspection API must not treat every internal field as a fully cleared
  rejected-run state without defining that contract.

Input boundaries are not interchangeable. Original overlap workloads are trusted
catalog definitions: `run` does not fully validate workload array lengths or
positive device durations, while saved-board shape is bounded upstream by
`OverlapState.valid_solution_shape:76-97`. System expected-output size and locality
pass count are likewise trusted at their current entry points. Scheduling has
explicit task/plan/job/value/output/Trace bounds. These are scope boundaries to
preserve or explicitly expand before exposing arbitrary workloads, not evidence
that current player input can bypass those upstream validators.

`SimulationEvent.to_dictionary:46-65` intentionally omits presentation schedule
coordinates; `LayoutRun.canonical_signature:11-13` does not include source/scratch
maps. Thus existing signature tests alone are insufficient for this optimization
round. The new adapter returns actual objects so root's all-script-property
snapshot includes those coordinates and maps without changing their historical
score identity.

Strategy invariants worth retaining in all performance patches:

- Fully associative cache replacement is deterministic and capacities are small;
  replacing its array with a hash table is not automatically beneficial.
- Original batches couple scheduling and copy, while the independent experiment
  separates grouping/tiling from a retained copy. Performance changes must not
  silently make those model versions equivalent or revise old successful work.
- Duplicate query fields/indices and nonmonotone sparse order are legal logical
  workloads; they must survive any preindexing or aggregation.
- Cache hits, preparation, actual RAM bytes, allocated padding, serial release
  and first-response latency create real distinct costs. Never optimize by
  omitting authoritative evidence, charging synthetic constants, or changing
  cache warm state.
- Integer/canonical numeric normalization, event ordering and complete state
  equality are prerequisites for any native pilot across macOS/Windows. Current
  gameplay-scale arithmetic is small; language replacement needs an independently
  measured benefit after the simpler allocation/repetition candidates.

## Handoff

Root may import and run the adapter now. Check actual expected success/failure
roles in addition to deterministic equality; the invalid cases are deliberately
retained, not suite failures. Retain baseline full snapshots from the frozen base
with these exact benchmark files before any runtime optimization. No production
candidate is selected or implemented by this audit.

Adapter ownership is released to root after this report; any compile/runtime
repair requested by root can be made under a renewed explicit file assignment.
