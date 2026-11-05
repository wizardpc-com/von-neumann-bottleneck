# Round9 next computation priorities

Read-only synthesis by audit_polish,2026-11-05. Read the current
`docs/development/COMPUTATION_AUDIT_20261105.md` and all three independent audit
reports (`vnb-round9-{circuit,memory,workload}-audit.md`). Latest coordination
supersedes their initial adapter/verification status. No runtime, Git, engine or
heavy receipt parsing was performed while candidate timing was active. These
priorities and numeric gates are recommendations, not newly approved product
rules or measured native benefits.

## Ordered next work

1. **Close the current Creation acceptance before another optimization.** The
   frozen-base4096 weighted generation was actually measured at about1.18s;
   repeated model/prefix checks are a supported hotspot. The current local reuse
   candidate is implemented. Final reference workload/memory passed; final
   candidate timing/parity was still active in the latest coordination read.
   Require sealed process evidence, complete old/new output/cost/state/Trace and
   typed numeric equality, targeted tests and retained-result checks. Separate
   kernel/whole-workflow savings and state the host. Do not infer candidate
   speedup from source changes or independently measured helper durations.

2. **Fix the confirmed circuit failed-step recovery defect as a separate change.**
   Root's actual validated run found11 stale-input recovery assertions; the
   remaining initial latch continuation assertion was a validator default-map
   over-assumption, already corrected. Preserve the defect log and independent
   recovery analysis. The next patch should refresh current external stimuli
   without losing legitimate latch/storage state, preserve simultaneous commit
   and retain the failed step's immutable evidence. Acceptance: every previously
   successful full Trace remains exact; a valid→failed→valid continuation
   recovers according to its explicit state contract; failed steps never commit
   storage. Declare the intentionally corrected recovery outcomes instead of
   claiming universal old/new parity. Validate pure APIs plus the actual host
   Debug/Step carry path using an isolated profile. Do not mix topology/cost or
   settling-rule changes into this repair.

3. **Make Region rejected evidence internally consistent.** Source confirms that
   invalid preparation parameters retain service costs/output after total time
   and events are cleared. This concerns malformed input, not a demonstrated
   campaign bypass. Define the failed-result and mixed-error precedence contract
   explicitly, then return coherent failed evidence without unnecessary service
   work. All valid public plans, costs and full Traces must remain equal; the
   changed invalid snapshots must be called out. Do not silently loosen the
   current workload validator to conceal the difference.

4. **Measure the next bounded GDScript candidates, then choose one.** Source
   evidence establishes duplication or complexity, not its runtime share:

   | Candidate | Narrow next measurement and preservation boundary |
   | --- | --- |
   | Prologue existing-wire duplicate scan | Official CPU/ALU and legal80-wire stress; measure validation separately. Preserve exact endpoint/port/width/duplicate error order. Work after recovery semantics are settled. |
   | Region cold-client template / Prediction Off reuse | Time normal one/eight-client and Off policy APIs. Reuse only operation-local immutable work; retain every client event, cold-cache behavior and the genuine Off counterfactual for other policies. |
   | Overlap double deep-copy / Layout scratch release | Measure queue64 and batch64 against authored cases; remove redundant copies/scans only while retaining every cycle/event, detached state, physical writes, padding and sparse duplicates. |
   | Restore/review/replay work | Measure an actual isolated profile open/record selection/compare workflow with representative history counts. API-only totals do not establish a UI stall; authoritative replay cannot be replaced by persisted metrics. |

   Prefer the candidate with a material measured user-workflow benefit and a
   narrow parity boundary. Small cache arrays are not automatically slower than
   hash tables. Avoid global memoization/pooling until invalidation, reset and
   returned-object ownership are explicit; existing receipt accumulation and
   layout rejected-state hazards make that especially important.

## Proposed native-pilot gate

No native module is currently selected. Use these concrete gates for a later
isolated plan:

- **Entry:** after the relevant bounded GDScript redundancies are removed, a
  legitimate public operation still has p95 over100ms, or a documented bounded
  batch takes over5s; one pure kernel accounts for at least50% of that inclusive
  operation. Capture at least7 samples in each of3 fresh processes on the same
  pinned engine/host. Snapshot/export time is excluded only when it is benchmark
  overhead; real API serialization, Trace creation and conversions stay included.
- **Trial scope:** one kernel, original GDScript retained as callable reference
  and fallback. Include native-boundary conversions and the complete original
  event/state result in timing. No synthetic-summary API, fast-math, changed
  rounding, event omission, altered algorithmic game cost or new score meaning.
- **Adoption:** median inclusive API speed improves at least1.5× and p95 at
  least30%, saving at least25ms for the interactive case or1s for the batch.
  Repeat on both macOS arm64 and Windows x64, with exact deterministic outputs,
  packet bytes/PRNG/floats, modeled costs, state, complete Trace and all failure/
  lifecycle cases. A slower unrelated representative case by more than5% needs
  explanation and resolution, not averaging away. Exact fallback/rollback and
  packaging acceptance must exist before enabling it by default.

A fast arithmetic microbenchmark without inclusive gains does not meet this
gate. After Creation's repeated validation is removed, event construction or
profile replay may dominate; native marshaling could erase any kernel win.
That residual share must be measured afresh rather than inherited from the old
1.18s reference.

## Keep model and strategy decisions separate

Do not merge raw/sealed latch behavior, reinterpret high-Z/missing input,
increase the64-tick settling ceiling, convert documented32-bit accounting into
float32 arithmetic, change cache warmth, or prune required traces under a
performance label. Existing60-task achievements, versions, scores, packet/save
formats and conditions remain authoritative. New strategy experiments belong
under separate identities, with genuine preparation/throughput/first-response/
space/error tradeoffs. The finite old layout frontier is evidence for experiment
design, not authority to invalidate old achievements or assert a global optimum.
