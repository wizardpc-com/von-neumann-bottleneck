# Structural scheduling workloads and retained history

Owner root. Base `e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8` on
`codex/gameplay-systems-20261104`. The user authorized autonomous meaningful
gameplay development and verified milestone commits/pushes on this branch.
Main, ordinary player data and release publication remain outside this scope.

## Goal and measured decision

Make two distinct request structures playable in the existing scheduling lab,
with independent drafts, measured goals, retained plans and replayable challenges.
The Round6 finite probe found a genuine cycles/traffic choice for two serial
temperature scans and a different useful copy layout for phased field requests.
Three independent strategy, UI and compatibility audits support this scope.
They are research evidence; the new IDs require fresh runtime acceptance.

Append exactly these fixed IDs, keeping the original four entries and all their
task data, condition identities, costs, model version and canonical codes:

| ID | Public requests, serial admission | Expected ordered output |
| --- | --- | --- |
| `scan_pair_serial` | Two complete temperature sums | `[363,363]` |
| `split_fields_serial` | Four temperature sums, then four alarm sums | `[363,363,363,363,8,8,8,8]` |

Both reuse the existing fixed17-record data and160B copy allocation limit.
No new cost, penalty, grouping rule, physical control, random seed, campaign
task or award is added. The model remains `layout-schedule-experiment-1`.
The shared input transport remains `VNBSC1:` with envelope version1.

Under the unchanged model the measured pair recipes are direct
307/614/544/0 and copied-temperature557/672/500/80
(Q1/total cycles/RAM bytes/allocated copy bytes). Under Q1≤600/copy≤80,
total and traffic select different sampled recipes. Phased field-major
temperature+alarm measured727/1516/1032/144 versus record-major
791/2044/1560/144. These are finite samples, never global optimum claims.

Two opt-in starter challenges use source-only targets: pair uses RAM objective,
Q1≤600/copy≤80; phased uses total cycles, Q1≤800/copy≤144. The original two
starters keep their exact inputs and codes. Personal goals remain uncapped by
default. One contextual starter button replaces misleading cross-workload
starter actions; preview/accept still preserve all exploration inputs.

## Compatibility and rollback decision

Directly writing six IDs into v1 would make the old binary protect the entire
file and lose access to its earlier four-condition history. Use separate
`layout_strategy_notebook_v2.json` and `layout_strategy_challenges_v2.json`.
Their bounded shapes stay the same with payload version2 and six allowed IDs.
Keep128KiB/32KiB bounds and8 named plans per condition unless measured evidence
shows insufficiency. The legacy decoder freezes its original four-ID scope.

New runtime never rewrites, renames, deletes or backfills either v1 payload.
Startup selects each Notebook/target file independently:

- Existing valid v2, including an empty target map, is authoritative; ignore v1.
- Existing protected v2 stays protected; no fallback to v1.
- Missing v2 plus valid strict v1 restores detached inputs in memory and marks
  an explicit pending copy. New conditions start fresh.
- Both missing starts fresh without creating a payload or lease.
- Missing v2 plus protected v1 protects the source and adopts no partial state.

Normal explicit Save/accept/clear/retry creates v2 from the current proposal.
An unchanged first copy, including an empty legacy target map, must actually
write a file instead of taking the old no-op shortcut. Saved/dirty/exit status
must describe this pending copy accurately; the two sidecars are independent
transactions. Measurements, full Trace and scores are reconstructed from inputs.

Until the first successful v2 commit, remember both source and destination
signatures, including missing source. Detect appearance/deletion/replacement
and refuse stale writes. First-copy writes acquire the exact old per-store
lease followed by the new per-store lease, recheck both, and release both on
every exit. Explicit recovery acts on the exact blocked writer only; it neither
saves nor bypasses changed data. Subsequent v2 writes use only v2 ownership.
This is cooperative local protection, not arbitrary-writer CAS or power-loss
durability.

Rollback to the base reads untouched v1; upgrading again reads v2. Edits made
after that split are independent histories and are never silently merged.
No new migration framework, automatic conversion, combined transaction or
ordinary-profile write is needed.

## Implementation ownership

Exact API agreements and disjoint assignments are recorded in
`.godot/collaboration/round7-implementation.md`.

- Strategy agent: additive model catalog, starter goals/codec, model/codec
  tests and new structural test/probe.
- Storage agent: both protected stores and their suites, strict legacy/current
  decode, copy-forward metadata and two-path writer protection.
- UI agent: lab/window, contextual entry, pending-copy presentation and
  existing/new UI tests.
- Root: Workspace/Challenges controller integration, frozen legacy fixtures
  and parity, process/rollback orchestration, reviews, docs, Git and all Godot.

## Verification and acceptance

1. Freeze original four tasks, representative exact full Traces, all metrics,
   ordered output, canonical codes and actual v1 files from the unchanged base.
   Keep the initial fixture failure separately if a capture needs repair.
2. Remeasure the two new structures under their new IDs. Check exact outputs,
   causal admissions/responses, event accounting, limits, immutable inputs and
   repeat/JSON full Trace identity. Reproduce the objective reversal and layout
   comparison; probe the declared finite physical map sample honestly.
3. Prove all old task/condition/Trace/code identities unchanged, and keep the
   formal141-design/282-case gate. Model/goal/session/Notebook/challenge
   regression retains distinct staged evidence.
4. Exercise current/legacy precedence, maximal/sparse v1 data, unfinished
   drafts, supported stale target codes, no write on read, first unchanged and
   changed copy, clear-to-empty, failures/retries and actual six-condition
   isolation. Unknown new IDs in v1 remain invalid.
5. Run real process old-source/current-destination contention, explicit stopped
   writer recovery, changed writes, restart and frozen-old-runtime rollback.
   Verify v1 bytes and ordinary progress are unchanged.
6. Bilingual1280×720/960×640 root and720×540 popup checks; contextual starter,
   public requests, goals/rank reversal, save/restore/Undo, input/focus and
   pending-copy/protected exit. Independently inspect actual pixels.
7. Operate the bounded new loop natively on Mac when available. Keep native,
   scripted GPU, exports, other platforms and newcomer evidence separate.
8. Bind final source to isolated QA/playable copies, review complete logs/diff/
   status, update durable docs and handoff, then commit/push the milestone and
   independently verify task SHA and unchanged main.

## Progress and open boundaries

- 2026-11-05: clean pushed base rechecked. Three audits complete. Fresh isolated
  baseline import/profile, model2669 checks/171 measurements, Session72 and
  codec397 pass in `.godot/verification/20261105T051242Z-1f038f6c`.
- Original-code freezing initially hit a typed-array fixture assignment;
  its owned engine was stopped after the recorded error. Corrected capture
  exited0 and froze56 measurements,112 code outcomes,exact4tasks and both
  actual v1 file strings before synchronization; original failure retained.
- All three implementation lines released files. Initial integrated import,
  model3449/223measurements, structures1247/88, code516 and frozen680/56/112
  pass. Formal141-design/282-case parity also passes. Store upgrade410 and
  controller upgrade56 pass after correcting parsed-number comparisons in a
  test fixture, without changing storage rules.
- New structural UI passes after repairing a noncanonical empty legacy-map
  fixture. Independent reviews identified that fixture and a missing parent
  directory in the process lease-holder fixture; both repairs are bounded to
  tests. All original failed logs remain in the receipt.
- 21 distinct related headless suites have passing latest staged observations;
  GPU structures346/original246/notebook177/challenge282 pass with42 raw frames
  inspected. Real process source/destination contention, two controlled owned
  crashes, explicit recovery with changed writes, restart, frozen-old-runtime
  rollback and continued separate histories pass. Twelve normal phases exit0;
  the two owned holders intentionally exit−9.
- 442 declared physical/direct candidates and10 full-Trace repeats/JSON runs
  pass7100 checks. Pair/phased finite frontiers contain2/3 metric classes.
  This is bounded strategy evidence, not global optimality or human experience.
- 1218 source/test/support files match QA and standard prepared playable copy.
  Six new UIDs came from actual QA import. Fresh native observation was blocked
  by Mac lock; no click/key was sent and owned cleanup exits−15. GPU and restart
  evidence do not establish this unobserved native path.
- Ordinary playable startup and launcher syntax checks exit0. Final static
  checks rebind1218 files and42 raw frames and scan all three full import logs
  without diagnostics. All47 raw logs are visible to Git; four original final
  empty lines remain unedited and are explicitly recorded.
- Implementation, bounded runtime acceptance, documentation and independent
  evidence/static reviews are complete; no actionable finding remains.
  Authorized task-branch commit/push closes delivery after final staged scope
  and byte checks; no further feature is included. See the
  [full receipt](../../verification/20261105-structural-layout-workloads/README.md).

Formal adoption, online server replay, exported packages, other platforms,
newcomer comprehension and long-session/audio acceptance remain separate work.
The existing Opus dispute list is preserved without automatic rollback.
