# Measured cold-client service reuse — Round12

## Goal and scope

Start from delivered `82d6d540a8c01e8ed2a810b30a9f078fc7d35365` on
`codex/gameplay-systems-20261104`. Reduce repeated host computation in Region
without changing simulated costs, results, complete Trace or old achievements.
All clients currently receive identical inputs and independently start with
an empty decoded cache. The wrapper repeats the same complete Base service
before emitting each client's independent evidence.

Measure a single synchronous-call reuse of the first Base service result.
Keep GDScript as the reference and preserve every final event and access row.
Only adopt the local production change if complete differential checks and
fresh timing evidence support it. The initial read-only scope is recorded in
`.godot/collaboration/round12-region-performance-scope.md`.

Root owns production changes, documentation, integration, Git and all sequential
Godot/native runs. One agent owns a new pure alias/isolation regression; another
owns the workload client sweep and a separate diagnostic timing helper. A third
reviews the contract and measurement independently. Exact file ownership is in
`.godot/collaboration/round12-clients.md`.

## Invariants and boundaries

- Keep Base-first error priority, the Round11 fresh preparation rejection,
  existing parameter types/bounds, all versions and saved/condition identities.
- One online preparation precedes all clients. Each client starts cold with
  the original within-client cache hit/miss/LRU/eviction sequence.
- Preserve event objects, fields, types, zero durations, order, absolute cycles,
  client IDs, real bytes, ordered outputs, accesses and all metric semantics.
  Do not multiply the single-service overfetch or peak-cache values.
- Source service evidence is read-only within the call. Every client's mutable
  output evidence stays detached from other clients, inputs and later results.
- No global cache, shared client cache, pooling, event thinning, lazy evidence,
  skipped revalidation, UI memoization, model tuning or native dependency.
- Ordinary player data remains outside scope. Rollback restores the local
  service-selection line; no player file needs migration or deletion.

## Implementation and verification

1. Freeze the committed runtime from Git, bind source hashes, import it in a
   dedicated QA profile and preserve its reference identity.
2. Add client1/2/4/8 measurements for an online64-address RLE scan and an
   explicitly bounded offline192-address mixed-codec revisit stress fixture.
   Reuse the36-Trace official compatibility corpus, current rejection case
   and unchanged Base partition/revisit control. Require meaningful independent
   validators and full typed results, not metric-only snapshots.
3. Add mutation tests across client events, nested cache/byte evidence, metric
   surfaces, caller inputs and retained runs. Check edge cases with no requests,
   cache0, uncacheable blocks, zero latency and both preparation modes. Run
   these tests against the reference to establish the existing contract.
4. Measure independent repeated Base services and required client evidence
   construction separately. The latter may use a benchmark-only copy of the
   existing loop, validated against the actual Region service suffix. Base
   timing includes its own Trace work; diagnostic times are not additive
   attribution and cannot establish pure computation or heap allocation cost.
5. Replace only repeated Base selection with the completed immutable service
   result. Keep existing deep-copy/event construction and ordered accumulation.
6. Use identical fixed counts, seven samples, pinned Godot4.7.1 and isolated
   profiles for old/new complete public workflows. Retain cold timings, sample
   ranges, original outputs/logs and strict sealing. Client1 and unchanged Base
   controls must be reported separately.
7. Run Region/rejection, Base plan/cache, session/support/journey, workbench
   presentation and complete-snapshot checks. Run targeted rendered workbench
   verification, inspect raw frames, and bind a normal isolated startup/preview.
8. Independently review source, typed parity, mutation guarantees and actual
   timing evidence. Update current state, architecture, testing and audit.
   Close the plan, commit and push the authorized task branch after verification.

Pure model timings do not establish Run-button or restore latency. Native OS
input, Windows, exports, newcomers, long sessions, audio and peak heap remain
separate acceptance dimensions. If measured benefit is inconclusive, retain
the simpler existing production loop and record the evidence.

## Progress

- 2026-11-05: previous turn completed and independently verified Round11 push.
  Current branch is clean at82d6d54. Read the focused scope and current
  Region/Base/Event code; no native pilot is selected. Implementation begins
  with a frozen reference and disjoint test/benchmark assignments.
- 2026-11-05: frozen reference imported and556 tracked runtime/support files
  matched Git. Existing Region/rejection checks passed. Independent-client
  regression initially found a String/StringName oracle mistake; two key
  insertions were corrected, retaining the original failure and exact probe.
  The same final test passes900 checks on reference and candidate, covering40
  combinations and162 independently executed Base services.
- 2026-11-05: candidate10 related suites plus import/isolation passed. All12
  public benchmark scenarios retain complete typed input/results/Trace and22
  existing goal decisions. Seven fixed samples measure online8-client
  12.718→6.357ms, offline8-client86.719→42.131ms, existing online workflow
  27.857→14.610ms. Client1 controls are about1.0%/2.6% slower; unchanged Base
  about1.9% slower. Actual multi-client benefit supports adopting the bounded
  one-line service reuse; no universal or UI-latency claim.
- 2026-11-05: separate profile initially failed on another typed seed-key
  mismatch. A one-key correction leaves model/comparator unchanged; both final
  runs pass8 cases and11522 recorded checks with full service evidence and
  mutation guards. Initial raw87,746,042-byte failure output is retained.
  These diagnostic boundaries are explicitly non-additive.
- 2026-11-05: rendered workbench2115 checks pass,20 bilingual1280×720 frames
  preserved; ordinary isolated startup exit0. Source/QA binding covers1255
  entries. No new native OS input, Windows, export, heap, newcomer, long-session
  or audio acceptance. All engine execution is terminal.

## Outcome and closure

The production diff is the local immutable service selection and its comments.
All modeled work and mutable client evidence remain. Undoing that selection
restores the baseline without save migration. Evidence, retained fixture
failures, commands, hashes and reviews are in the
[Round12 receipt](../../verification/20261105-region-client-reuse/README.md).

The user explicitly requested finishing only this planned increment, then
committing/pushing related changes and stopping. No further feature, optimization
round or native pilot is scheduled. The broader goal remains paused; outstanding
audit questions and platform acceptance limits are records, not new tasks.
