# Separate query scheduling from copying — 2026-11-04

Owner: Codex root; branch `codex/gameplay-systems-20261104`, base `b65a0bd`.
Status: bounded playable increment completed and independently reviewed.
All earlier increments are preserved. The user's later instruction authorizes
committing and pushing the verified milestone to this branch, never main.

## Goal

Build a playable, independently versioned layout experiment where the player can
separately choose query grouping/tiling and real copying. Measure output correctness,
total work, first-request completion, RAM traffic and scratch from actual events.
Use the resulting evidence to decide whether these mechanisms produce useful
strategy choices. Do not declare depth merely because more controls exist.

Round3 measured2555 candidates under the current official model and found one
nondominated metric triple per task in that sample. Copy batches also reorder
queries; cold-field copies can win because of scheduling and source-cache warmth.
See [the measured question](../../verification/20261104-portable-challenges/strategy/README.md).

## Scope and boundaries

- Add a standalone `experiments/layout_strategy/` scene, pure model and bounded
  session comparisons, accessible through the existing isolated experiment runner.
- Use explicit model/condition identities distinct from `layout-memory-1`.
- Reuse authoritative memory operations and Trace objects. A narrow extraction
  of the existing execution step may be needed; it must preserve official runs
  byte-for-byte in representative Trace evidence, metrics, outputs and identities.
- Keep the original campaign, completion, named designs, challenge codes, sidecar
  and global save unchanged. The new session must never write their records.
- No campaign registration, production network, online ranking claim, new engine
  dependency, exported package or release. Commit/push authorization was added by
  the user during implementation; root alone performs those task-branch actions.

## Accepted bounded design

Expose source-only query tiling even when nothing is copied. Physical copy may
be absent or retain one complete selected-field copy for the whole run. Partial
copy windows are deferred until their lifetime is explicitly designed.
Query jobs preserve the original outputs and public sparse-index order. Grouping
several ready jobs by record can reuse cache lines but postpone the first
submitted request's complete response. Output cost remains one cycle per logical
value; response time must come from emitted completion events, not an estimate.

Compare a public batch of ready queries with a declared serial-request boundary.
For serial requests, the next request becomes eligible only after the previous
response. This is a separate workload contract, not a hidden penalty or new
interpretation of the official tasks. Constants and original memory costs stay
explicit; there is no invented scheduling charge to force a desired frontier.

Four scenarios use17 immutable records and a160B copy-scratch ceiling: eight
temperature sums or eight hot-pair sums plus one sparse inspection, each with
batch/serial admission. Query groups are contiguous public jobs; record tiles
control interleaving within each group. Outputs preserve query, repetition,
index and field order, including repeated and nonmonotone indices.

The new identity is `layout-schedule-experiment-1`. First response always means
public job0, even if a later sparse request finishes sooner. Each response is
emitted immediately after its last real value/output operation. No scheduler
penalty or cache reset is added. Copy scratch excludes accumulator/output memory.
The session keeps24 runs and64 draft edits per workload, with explicit baseline
selection, inspection and undoable restoration; exiting loses this session only.

## Compatibility and rollback

The experimental scene and session data are opt-in and independent. Removing its
runner entry and files restores the old product entry without data migration.
Any shared simulator extraction must be behavior-preserving and separately
reviewed; retain the prior evidence to prove this. Existing VNB4C1 challenge codes
continue to mean the same official rules. Experimental results cannot be imported
as old official results or count toward player progression.

If measurements show one universally dominant experimental strategy or misleading
response timing, revise the hypothesis before calling this a successful gameplay
extension. Do not raise old thresholds or invalidate legal old results.

## Work and acceptance

1. Read existing costs, query ordering, launch/profile safety and previous evidence.
2. Parallel read-only audits; root freezes the contract and disjoint ownership.
3. Implement pure model and decisive correctness/accounting/causality tests while
   independently implementing a playable bilingual comparison/restore interface.
4. Run a declared finite strategy grid. Require at least one measured competing
   pair for the proposed response/total objective, plus a case showing why copy
   preparation matters. Preserve unsuccessful hypotheses in the evidence.
5. Test bounds, exact outputs including duplicates/sparse tails, deterministic
   replay and JSON round trips, response availability/order, real writes and
   allocation failure, and complete identity separation from official records.
6. Verify the original model against old measured Trace samples and its existing
   simulation/navigation/score/challenge/save checks. No original metric drift.
7. Run actual GPU/UI checks, inspect bilingual minimum-size frames and ordinary
   startup, independently review implementation/evidence, and deliver an isolated
   playable launcher. Native input and package acceptance require their own proof.
8. Update current state, model contract, testing guidance and local handoff; move
   this plan to completed only after its bounded playable contract is verified.

## Progress

- 2026-11-04: live branch/main/status and completed round3 handoff rechecked.
  Three independent audits completed; implementation ownership is disjoint.
- Corrected discovery:340 candidates passed in6.042s. Ready scan grouping trades
  first/total307/2456 for531/552; serial retained temperature trades307/2456/0B
  for557/1362/80B. These are finite sampled comparisons, not global optima.
  The initial failed proof remains in the receipt: retained copy addressing had
  incorrectly used query-tile origin instead of the copy's own origin.
- Root created bounded session/history and a frozen141-design/282-case official
  Trace parity gate. Two agents implement the pure model and bilingual lab while
  a third independently reviews the model; root retains all Godot/Git operations.
- Disk-full interruption was recovered. Three prior final preview import caches
  were restored and startup-checked with actual receipts; the earlier APFS clone
  attempt has no completion receipt and is not accepted. Root reused one QA copy.
- Production model2669 checks/171 measurements, session35 checks, and legacy3810
  checks/141 designs/282 cases passed. Eighteen initial focused suites plus the
  later UI suite provide19 distinct related staged observations, not a final
  full-repository regression.
- Production grid595 combinations (385 delivered,210 extra probes) and90 selected
  repeat/JSON replays passed in12.770009s. Delivered frontier class counts are
  4/2/5/2. Actual response/total/copy-space tradeoffs satisfy the bounded hypothesis;
  finite sampling does not establish global optimality or long-term fun.
- Fixed the TreeItem signal-emission deletion crash, translated Settings returning
  focus beneath the exit guard, and English minimum-height spacing. Final UI
  headless214/0 and Apple M2 GPU242/0 passed.
- Two first-language frames revealed wrong raw dimensions despite early texture
  metadata checks. Engine windowed flags alone did not repair them. The fixture
  now resizes after scene construction and checks stable actual Image dimensions;
  all12 final bilingual frames meet1280x720/960x640. Original failures and12 initial
  diagnostic frames remain archived.
- Native CUA observed ordinary run, baseline, edit, comparison, restore, Cmd-Z,
  main-language change and exit protection. First process accidentally used a
  capture flag and showed the existing write-disabled dialog in Settings. A second
  normal process lost the CUA window route during language selection and was
  deliberately terminated. Normal native nested Settings remains unverified.
- Final1170 source/test/support files match the QA copy; settings differ only in
  isolation and experimental main scene. Normal isolated startup exited0 with no
  diagnostics; launcher syntax passed. See the
  [complete receipt](../../verification/20261104-layout-scheduling/README.md).

## Remaining boundaries and next investigation

- The experiment keeps only24 runs/64 edits per workload within one process.
  Persistence, sharing, sliding-copy lifetimes and campaign integration are not
  implemented by this bounded plan.
- Broader strategy/workload understanding and player exploration precede any
  promotion into formal tasks. Preserve old identities, valid results and rollback
  until that separate compatibility decision is reviewed.
- Normal native nested Settings, exports, other platforms, newcomer understanding,
  long sessions and audio require their own evidence. No online-trust claim.
