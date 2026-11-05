# Round9 circuit/prologue audit and benchmark adapter

Owner: `/root/audit_scores`. Date: 2026-11-05. Audited task-branch base:
`2748138d166855e86a5496ce60ca37a8389d4ce7`.

Status: source audit and assigned adapter authored; **no engine execution,
runtime verification, performance measurement, Git mutation or player-data
access by this agent**. Root owns those activities. Source performance findings
below are candidates, not measured bottlenecks. No runtime, tests or repository
docs were edited.

Assigned artifact:
`scripts/benchmarks/computation/circuit_cases.gd` (381 lines at handoff).

## Adapter scope and reconstruction

`cases()` returns 12 deterministic bounded input descriptions. The seven
prologue campaign cases use current `PrologueLevelCatalog.definition()` and
`reference_circuit()` fixtures; reusable inputs are constructed in memory from
the same earlier reference graphs. This does not load/install player content or
create progression evidence. The Boolean Half Adder uses the four-gate topology
and unused spare in `tests/test_circuit_simulation.gd::_valid_half_adder`.

`run_case()` constructs fresh `LogicCircuit`, `LogicComponent`, `LogicWire`,
input dictionaries and typed step arrays. JSON-restored numeric values and
StringName keys/labels are rebuilt explicitly. `LogicComponent.from_dictionary`
provides the existing port/property reconstruction. Wires are appended as
objects, preserving deliberately malformed fixtures for simulator validation;
there is no UI `GraphEdit` export or repeated `connect_ports()` editing cost in
this compute adapter. Typed component reconstruction is inside the timing
contract; current catalog/reference fixture production in `cases()` is outside.

Every returned object/Dictionary is the full actual API result. The Boolean
stress/diagnostic cases intentionally invoke both `CircuitAnalyzer.analyze()`
and `CircuitSimulator.evaluate()` and return both complete outputs. Thus their
timings cover that pair, not an isolated evaluate call. `sequence_continuation`
returns the whole sequence, every incremental one-step report, and final
`runtime_state` plus `prior_outputs`; the two execution forms have different
absolute event offsets by design and must not be blindly asserted identical.
No Trace is replaced with a digest or summary.

| ID suffix | Workload | Coverage |
|---|---|---|
| `boolean.official` | Four Half Adder official cases | Required-subgraph pruning, unused spare, longest-path metrics, complete successful events |
| `boolean.stress` | 128 NOT gates, 64 routing junctions, 32 observers (225 nodes, 224 wires) | Recursive graph evaluation, deterministic ordering, zero-wire latency, complete live indexes/ticks and Trace |
| `boolean.diagnostics` | Eight named subcases | Agreeing/conflicting/missing drivers, cycle, duplicate wire, invalid endpoint/port, no observer |
| `prologue.full_adder` | Current eight authored steps | Two sealed half-adders plus OR, full output and Trace |
| `prologue.alu` | Current 32 authored steps | All four operations, selectors, repeated stable topology |
| `prologue.latch` | Current five authored steps | Raw NOR feedback, SET/HOLD/RESET and feedback boundary events |
| `prologue.register` | Current five steps, whole plus incremental | SR-latch output-carried state and public continuation contract |
| `prologue.ram` | Current five steps | Parallel Register4 cells, selected write/hold, independent addresses |
| `prologue.cpu` | Current seven-step program | Graph CPU, Register4/RAM2x4 commit, LOAD/ADD/LOAD_MEM/STORE_MEM |
| `prologue.load_store` | Current seven-step program | Sealed TinyComputer state branch and final bridge fixture |
| `prologue.stress` | 32 NOT gates, 32 junctions, 16 observers (81 nodes, 80 wires) | Bounded fixed-point depth, routing closure and observer-event growth |
| `prologue.diagnostics` | Twelve named subcases | Width/duplicate/conflict/missing driver, cycle/oscillation/65-gate timeout, raw/sealed latch distinction, failed-step recovery, DigitalValue matrix |

The diagnostic DigitalValue matrix covers widths 1/4/32 and values
`-1,0,1,15,16,4294967295`; each returns constructor/from_variant values and
actual equal/conflicting/high-Z/empty/wrong-width resolution. No random input,
timestamps, persistence, autoload calls, engine timing, expected-metric
substitution, UI or cached mutable fixtures are present.

## Highest-value measurement candidates

1. **Avoidable quadratic wire validation in PrologueSimulator.**
   `src/circuit/prologue_simulator.gd:218` calls
   `LogicCircuit.connection_diagnostic()` for every existing wire.
   `src/circuit/logic_circuit.gd:64` scans the complete wire list until it finds
   that same existing wire and returns the duplicate diagnostic; the simulator
   deliberately ignores that diagnostic, then separately detects duplicates
   with `seen` at lines 228–232. For a valid distinct-wire topology this adds
   `E(E+1)/2` endpoint comparisons across the batch, in addition to sorting.
   This is a concrete source complexity fact, not yet a measured runtime share.
   Smallest plausible correction: retain endpoint/port/width diagnostics but
   offer an internal path that skips only the existing-wire duplicate scan;
   preserve the existing ordered `seen` duplicate behavior and public editing
   checks. Full result/error ordering must match. Profile the 80-wire case and
   official CPU/ALU, then test wider legal topologies if root finds a signal.

2. **Repeated stable topology ordering/signature work.**
   `CircuitSimulator.evaluate():21` computes a topology signature;
   `CircuitAnalyzer.analyze():24` computes it again. Required traversal and
   sorted IDs are rebuilt for every truth-table row. Prologue `evaluate()` sorts
   IDs during normalization/indexing/cycle search/initial outputs, then again
   throughout `_resolve_all_inputs`, the component loop, junction refresh,
   changed-event emission and observer emission on each settle tick
   (`prologue_simulator.gd:56–90,245,256,285,315,807`).
   A per-invocation immutable ordered-ID list/index is safer than a mutable
   cross-run cache. Any optimization must preserve exact event/error order,
   active-subgraph membership, and all public live indexes. Do not cache against
   an incomplete key: circuit components, ports, widths, properties, wires and
   names are mutable public data and canonical evidence includes them.

3. **Repeated public sequence work and canonical strings.**
   Every stateful step settles before and after commit
   (`prologue_simulator.gd:130–158`). That is required model behavior, not
   automatically duplicate work. However, those calls repeat stable topology
   validation/signatures and `_sequence_signature()` then constructs canonical
   strings containing every retained result and topology again
   (`1015–1024`). Provenance source signatures are nested in component
   properties, so official CPU/bridge input signatures can be appreciable even
   for small graphs. The API currently produces these strings; keep their exact
   bytes in parity and account for their cost rather than deleting them.
   UI also executes each authored official case and reruns the full sequence at
   completion (`hardware_foundations.gd:6762,7118`), with separate state and
   evidence purposes. Avoid changing that trust/presentation boundary based on
   compute timings alone.

4. **Per-tick allocation and Trace volume, pending profiling.**
   Input/output Dictionaries, small typed input arrays, duplicate DigitalValues,
   sorted string state signatures and every observer event are generated each
   settle tick. `_emit_changed_events()` emits observers even on unchanged
   ticks (`807–851`). `_value_map_signature()` sorts keys and constructs strings
   each nonstable round (`999–1007`). Event construction duplicates values and
   input arrays (`prologue_event.gd:43–49`). Removing observer events, collapsing
   settle rounds or pooling externally returned mutable objects would change
   full evidence/ownership; not justified merely by total-cycle equality.

5. **Lower priority Boolean overhead.**
   Final wire count rescans all events (`circuit_simulator.gd:195`), wire-sort
   comparators repeatedly build canonical IDs, and DFS/index keys are formatted
   strings. These have simple local alternatives but should follow actual
   timings; the normal four-gate Half Adder may be too small to matter.

No C++/Rust pilot is supported by the audit alone. First measure algorithmic
redundancy in the reference GDScript with identical complete outputs.

## Correctness, semantics and documentation review items

These are **retained review items**, not authorization to alter verdicts or
legacy evidence. The adapter exposes several of them for root observation.

### A. Canonical evidence contradicts the documented presentation exclusion

`docs/architecture/simulation.md:11` says `visual_step` is absent from canonical
simulation evidence. Actual `CircuitEvent.to_dictionary():51` and
`PrologueEvent.to_dictionary():63` include it; both result canonical methods
serialize those dictionaries. This is a verified source/documentation mismatch.
Do not silently remove the field during optimization: doing so changes existing
canonical bytes. Decide whether the document or a versioned evidence contract
should change separately.

Canonical signatures are also incomplete differential oracles:
`CircuitLiveState.canonical_signature():45–62` omits ticks/evaluation order,
valid-wire/index objects and error_specs. Prologue `_sequence_signature()` only
includes each final `result` and runtime state; the separate `all_events` list
contains before-settle and explicit commit events not all retained in those
final results. Root's full script-property snapshot is the correct oracle.

### B. Raw and sealed latch S=R=1 semantics differ

`_validate_settled_state():558` checks only `KIND_SR_LATCH`. A raw two-NOR latch
with both inputs high reaches a stable Q=NQ=0 state and has no corresponding
invalid-latch check. The UI explicitly adds a warning after successful raw
latch debug (`hardware_foundations.gd:7091` vicinity), so this may be intentional
teaching behavior, despite the general architecture wording that stable S=R=1
fails. `raw_latch_both_high` and `sealed_latch_invalid` freeze both actual paths
without changing them. Discuss/disclose; do not merge them into one rule in a
performance patch.

### C. Missing stimuli are rejected differently by the two APIs

Boolean `evaluate()` explicitly rejects missing required external inputs
(`circuit_simulator.gd:82–86`; existing multidriver test line 139).
Prologue normalization maps missing source inputs to high-Z (`245–253`);
`DigitalValue.resolve()` ignores high-Z if another driver is known, and the
prologue validity check only requires no errors plus settling. There is no
equivalent required-input error. Thus a missing input on an otherwise driven
net can yield a valid prologue result. The adapter's `missing_driver` records
this source-derived hypothesis. Official authored steps provide inputs, so
this is not evidence of a current campaign bypass. Architecture wording that
all missing stimuli fail is broader than this implementation.

### D. Fixed settle ceiling also limits acyclic combinational depth

`MAX_SETTLE_TICKS=64` applies to valid DAGs as well as feedback. A sufficiently
deep NOT chain can time out while a Boolean Analyzer evaluates the same class
of topology recursively without that ceiling. No general component-count/depth
bound was found in the simulator; the visual snapshot limit of 512 is not a
simulation-depth rule. The adapter intentionally retains a 65-gate timeout
result and a smaller legal 32-gate stress result. Increasing the bound or
topologically settling DAGs can change error/Trace/tick behavior, so preserve
the existing limit in this optimization increment unless separately versioned.

### E. State commits are simultaneous, with two explicit state carriers

`_commit_state():626–663` reads the single settled pre-boundary result while
building copied register/RAM/computer maps, then assigns all maps at the end.
This supports simultaneous storage semantics and avoids sorted-component-ID
write-through dependencies. `run_sequence()` only calls it for a valid before
result. After a failure it nevertheless replaces `prior_outputs` with the
failed result's output map; subsequent recovery therefore deserves full parity,
not merely a final register assertion.

SRLatch/raw feedback state is carried by `prior_outputs`; `_commit_state`
does not write the `latches` map. This is consistent with the documented API
carrying both runtime state and prior outputs, but callers forwarding only
runtime state would lose latch history. Official UI forwards both. The register
continuation fixture and failed register-step fixture retain every intermediate
report to reveal accidental ownership or carry-state regressions.

### F. Abstraction costs and supplied-graph validation are design contracts

Reusable prologue components execute their `behavior_kind` implementation,
not a recursive replay of `circuit_snapshot`. The source signature records
provenance, while the block is a standardized abstraction. Therefore a player's
upstream gate count/depth does not automatically contribute downstream timing.
That is documented abstraction behavior, not an optimization bug or a claim of
cycle-accurate CPU cost. A strategy expansion here needs a new explicit model.

Both analyzers validate/evaluate all supplied components; unused valid spare
gates are legal, but disconnected invalid/cyclic/conflicting material may fail
an otherwise complete observer subgraph. Boolean execution limits emitted
component events and gate metrics to the required upstream graph, yet outgoing
segments of required components can include a destination outside that set.
Keep the present distinction between structural validity and measured active
work; do not prune invalid unused subgraphs as an unnoticed optimization.

### G. Public malformed-input assumptions remain separate hardening work

`run_sequence(null, ...)` eventually accesses `circuit.canonical_signature()`,
although `evaluate(null, ...)` returns a structured missing-circuit error.
Custom supported component kinds with malformed port arity can reach indexed
primitive inputs; the public component constructor clamps widths but does not
validate per-kind arity. These are source-level robustness gaps outside ordinary
catalog-produced input. No crash-generating null/arity test is in the timed
adapter; root can create a separately bounded failure probe if prioritizing
hardening. Empty sequence semantics (passed with no final result) also deserve
an explicit API contract before being treated as achievement evidence.

## Relevant existing tests and recommended parity gates

Already read, not executed here:

- `tests/test_circuit_simulation.gd`: gate tables, default-low/explicit-Z,
  multi-driver resolution, cycle detection, zero-latency fan-out,
  deterministic metrics/events, official Half Adder and cloned encapsulation.
- `tests/test_prologue_simulation.gd`: width and hexadecimal behavior,
  zero-latency junction chains, XOR/FullAdder, latch/register/RAM/CPU sequences,
  state boundary event counts/waves, current catalog/reference correctness.
- `tests/test_prologue_continuation.gd` is UI/navigation continuation, not the
  pure runtime-state continuation test its filename might suggest.
- Focused source reads of `test_hardware_prologue_ui.gd` and actual host calls
  established event-playback/state forwarding boundaries; that suite is still
  a root-owned required integration gate for circuit/prologue behavior.

Before a runtime optimization lands, preserve every adapter output under repeat,
JSON-restored specs, frozen-base differential and retained-result immutability.
For the proposed duplicate-scan removal, add/retain exact diagnostics for
missing endpoints, invalid ports, width mismatch and duplicate segments,
including deterministic ordering. Test valid topology mutations between runs,
because the circuit model is mutable. Verify current pure circuit/prologue
suites, affected GraphEdit connection behavior and relevant Hardware
Foundations integration, then bind the final source to evidence.

## Verification and handoff limitations

- Source inspection and a fresh `git diff --check` produced no reported tracked
  whitespace problem; the newly untracked adapter was manually reread.
- **Godot import, syntax/type checking, benchmark execution, performance
  conclusions, full differential parity, tests and native acceptance are all
  pending root execution.**
- The case count is deliberately bounded. It is not exhaustive truth-table
  coverage of every reusable bit width/operation, unbounded circuit-depth
  safety, arbitrary malformed JSON hardening, UI responsiveness, or cross-host
  acceptance.
- Ownership of `circuit_cases.gd` is released to root after this report; ask this
  agent for assigned-file repairs if the first import reveals a problem.
