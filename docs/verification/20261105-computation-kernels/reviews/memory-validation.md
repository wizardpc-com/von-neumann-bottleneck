# Round9 memory adapter semantic-validation handoff

Owner: `/root/review_records_final`
Date: 2026-11-05
Assignment: `.godot/collaboration/round9-audit.md`, “Harness repair and semantic validators”
Status: implementation released to root; engine compilation and execution remain unverified.

Changed only `scripts/benchmarks/computation/memory_cases.gd`.

- Added the requested `static func validate_case(spec: Dictionary, result: Variant) -> Array[String]` at line343.
- All12 declared memory/system/overlap/layout/scheduling cases have validator branches. Nested reports cannot silently pass by returning an empty or wrong-size result collection.
- Validators are called separately from `run_case`; they contain no elapsed-time assertions or captured metric snapshots.
- Extracted shared native-layout, batched-layout, maximum-scheduling and sparse-scheduling fixture builders so execution and validation describe the same inputs. These are adapter-only refactors; workload dictionaries, designs, failure triggers, public APIs and returned objects retain their previous meaning.
- Added explicit trace/event type preloads for fail-closed result checks. No production file, test file, persistent data or Git state was edited.

Validation scope:

| Case family | Success and workload evidence | Deliberate failure/recovery evidence |
| --- | --- | --- |
| Locality | Correct official-data sum, each address read once per pass, real request/compute/store counts, chosen cache capacity, hit/miss/fill/return events, RAM bytes, phase reconciliation and hardware cost | Public direct-RAM case must have no fabricated cache lookups/hits/misses;64-pass cases must execute all64 passes |
| System | Every official final fixture produces declared ordered bytes, reads/stores each input, performs3 arithmetic operations per item, and reconciles CPU/RAM/Bus phases; receipt binds all actual traces and aggregates their metrics | Disconnected topology returns an unexecuted failed trace; out-of-bounds access fails with zero work despite its zero-initialized output matching the expected byte; original assembly run succeeds again on the reused core |
| Overlap | All authored public targets succeed; actual ordered output events and transformed values are checked; compute/transfer service, one state event per elapsed cycle, request/ready counts, queue/eviction accounting and settled state are checked | `not_ready` retains one requested/started transfer but produces no output; `deadlock` has no requested transfer; both end in the matching error event. Reuse must recover the successful workload |
| Layout | Independent logical query evaluation checks complete ordered outputs, per-record/per-field query multiplicity, source maps, copied words, allocations/releases, scratch maps, traffic and phase accounting; official reference targets must actually be met | Full-copy allocation failure reports required space, no completed allocation/copy/output and zero output slots; duplicate fields fail before any workload mapping. Valid batch execution must recover and release all scratch memory/cache lines |
| Scheduling | Valid public envelopes, current model/condition/plan identity, complete logical outputs, real per-job admissions/responses and first-request timing, serial/batch release causality, one output per slot, copied/query read counts and trace bound | Public allocation failure remains an executed failed run; invalid serial grouping remains schema rejection with null run; incomplete responses stay−1, only the first serial request is admitted. Raw reused Executor results intentionally retain inherited layout identity, and both sparse recovery runs must succeed |

Important bounded workloads are checked from input dimensions, not trusted metric claims: the64-pass locality read multiplicity;64 ordered overlap batches with real queue wait/eviction;64-record native output count;64 one-record copy allocations/releases with256 copied words and8 query outputs; and the declared4096-value scheduling output boundary. Sparse scheduling checks retain duplicate and nonmonotone indices/fields.

Shared helpers inspect actual event objects. Sequential locality/system/layout traces must have continuous event time; overlap is checked with its simultaneous-resource/state-event contract instead. Recovery requires distinct trace instances, successful logical outputs and equal metric/event-count outcomes. The root runner remains responsible for full-property/typed-container snapshot parity and retained-object immutability; the adapter does not replace those checks with signatures. The system receipt signature check is supplemental binding verification beside direct result and metric checks.

Source review consulted the corresponding simulator/model implementations and existing locality, system, overlap, layout and scheduling tests. No production-rule correction was necessary or attempted for this assignment.

Source-only verification performed:

-12 declared case IDs all appear in `validate_case`.
-44 static functions; no duplicate function names.
-All preload targets exist.
-No trailing whitespace, unmatched delimiters or unterminated quoted strings under a lightweight lexical check.
-No Godot process was started, no GDScript compiler was run, no benchmark timing was collected, no player profile was accessed, and no Git command was run for this assignment.

These checks do **not** establish compile/runtime success. Root must run the repaired adapter under its isolated Godot4.7.1 QA harness, check original and JSON-restored cases, inspect every semantic issue, and only then freeze the valid baseline. Any unexpected failure should be investigated as an adapter assumption or production finding; do not change production rules merely to satisfy the fixture.

Released file SHA256:

`480bfd9b165e22f9d9c346cd24a31054da33b9f49ef5bc8bc452f0d321723bd7`

Ownership of `scripts/benchmarks/computation/memory_cases.gd` returns to root with this handoff.
