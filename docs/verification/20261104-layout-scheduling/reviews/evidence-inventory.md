# Round 4 final evidence inventory — 2026-11-04

Owner `/root/audit_scores`; READ-ONLY inventory under the resumed root assignment.
No source edits, Godot run, Git mutation or duplicate model review. This is a
snapshot while root is repairing the experimental UI, not a final acceptance.

## Supported claim now

The independently versioned scheduling/copying model has passed its correctness,
cost, causal response, deterministic replay and bounded session checks. The
shared simulator extraction preserves the frozen141-design/282-case official
canonical Trace sample. A595-combination production grid demonstrates real
finite-sample tradeoffs. The standalone lab's final UI/GPU/startup acceptance is
still pending; the latest completed UI run in this inventory failed.

It is safe to say **the new computational gameplay model is implemented and
verified in isolation, with official sampled results unchanged**. It is not yet
safe to say **the whole playable experiment is accepted** or **all project tests
passed on the final integrated source**.

## Exact accepted verifier receipt

Root run:
`.godot/verification/20261105T005513Z-6cc70bb5/results.json`.

Engine `4.7.1.stable.official.a13da4feb`, platform `darwin`. Receipt contains20
successful entries: import, user-directory probe and18 focused test suites.
Every entry has exit0, passed=true and empty errors. All referenced logs were
read and their PASS/error signals inspected. The probe printed an actual
`/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/...` directory.

| Suite | Actual result |
| --- | --- |
| test_layout_strategy_model | 2669 checks,171 measurements,0 failures |
| test_layout_strategy_session | 35 checks,0 failures |
| test_layout_strategy_legacy | 3810 checks,141 designs,282 cases,0 failures |
| test_layout_simulation | PASS mapping, real flow, copy cost, bounds, tails, determinism |
| test_layout_recipe_sources | 13 checks |
| test_layout_trace_storage | 54 checks |
| test_layout_navigation | PASS return, selected route, Continue, unavailable navigation |
| test_layout_preview_selection | 16 checks |
| test_layout_ui | PASS existing Chapter4 hosts, gates, targets, Undo, hints |
| test_layout_scoreboard | 37 checks |
| test_layout_scoreboard_ui | 44 checks,0 failures |
| test_layout_challenge_code | 288 checks |
| test_layout_challenge_store | 166 checks |
| test_layout_challenge_window | 106 checks,0 failures |
| test_layout_challenge_controller | 66 checks,0 failures |
| test_chapter_settings_input | 26 checks,0 failures |
| test_global_save | PASS Save/Continue, provenance, gates, New Game, mode isolation |
| test_localization | PASS catalogs, keys, Chinese default, locale-independent simulation |

`test_layout_ui` is the established fourth-chapter test, not the new standalone
`test_layout_strategy_ui`. Do not use the former's pass to close the latter.
This is a focused run, not a full-repository regression.

Current model, session, shared simulator, their three test files and the frozen
legacy fixture were compared byte-for-byte with the tested project; all seven
matched at inventory time. The model's current sources also match the production
grid's recorded SHA256 bindings. UI files are actively changing and require a
later final manifest; these core matches do not bind the whole final product.

## Supported model and comparison contract

The accepted model is `layout-schedule-experiment-1`, separate from the official
`layout-memory-1`. Four delivered workloads use17 immutable records,160B copy
scratch, eight temperature sums or eight hot-pair sums plus one sparse inspection,
each under known-batch or serial-request admission.

Real reads/writes/cache/compute/output events determine every metric. Source-only
record tiling is independent of copy selection; copying is one full retained
selected-field projection. Bounded copy windows are explicitly deferred. Q1
means public job0's actual response, not the earliest completed arbitrary job.
Serial requests cannot execute future query work before prior response;
preparation may read immutable source in advance. Logical output order remains
stable even when execution order changes.

Metrics are independent Q1 response, total cycles, RAM bytes and peak **copy**
scratch. The last excludes accumulators/output storage. Same complete condition
is required for differences. No weighted score, online trust, persistent
experimental leaderboard, campaign completion or old challenge conversion is
provided. Session history is24 runs and64 edits per workload, with comparison
baseline and Undo restored in memory; it is lost on process exit.

The exact operation identities remain:

```text
cycles = 2Q + O + 10M + 16F
RAM bytes = 4M + 16F
```

Q is consumed query values, O emitted logical values, M actual copied words and
F actual line fills. The test/grid checks use these quantities and actual events.
There is no generic scheduler penalty, artificial cache flush or animation time.

## Accepted production strategy evidence

Receipt:
`docs/verification/20261104-layout-scheduling/strategy/20261105T005822Z/`.

The invocation binds the actual pure-model source and grid hashes, names the
isolated profile and reports exit0. Raw log:595 candidates,90 replay executions,
12770.009ms. JSON: all595 correct, empty failures. My independent review
`/private/tmp/vnb-round4-grid-launch-review.md` recomputed every frontier,
plan/condition hash, response/admission relation, cost residual and sampled
line-aligned scratch amount from the archived JSON; all matched.

| Scenario | Combinations | Frontier metric classes | Delivered |
| --- | ---: | ---: | --- |
| scan_batch | 140 | 4 | yes |
| scan_serial | 35 | 2 | yes |
| mixed_batch | 175 | 5 | yes |
| mixed_serial | 35 | 2 | yes |
| scan16_batch | 175 | 6 | additional probe only |
| scan16_serial | 35 | 2 | additional probe only |

Thus385 combinations cover delivered workloads;210 are explicitly unshipped
16-request probes. Equal settings/mappings exist, so595 is not a count of unique
physical strategies. No global optimum or universal long-term depth is proven.

For the delivered ready scan, source-only job-by-job gives
Q1/total/RAM/copy307/2456/2176/0; fused source tiles give531/552/272/0.
For serial scan, retained temperature copying gives557/1362/980/80 against
direct307/2456/2176/0. These support genuine response/total/traffic/space tradeoffs.
Mixed serial likewise offers341/2784/2208/0 versus825/2404/1624/144.

The earlier discovery proof is historical support, not current model acceptance:
the initial copied-address-origin defect and failed run remain archived;
the corrected340-candidate proof passed before implementation. Keep both.

## Current experiment UI evidence is not accepted

Completed root runs under the same QA directory:

1. `headless/20261105T010018Z/results.json`: import passed; UI process exited-6
   with fatal TreeItem selection/rebuild error. Root records the repair as
   selection-only detail refresh without rebuilding the emitting tree.
2. `headless/20261105T010221Z/results.json`: UI completed186 checks with5
   failures: text Undo in both locales and three English960×640 overflow checks.
3. `headless/20261105T010944Z/results.json`: diagnostic rerun still186 checks,
   5 failures. It records unchanged draft after the text-Undo attempt but unchanged
   text as well; root is investigating rather than weakening the check.

The independent UI review at `/private/tmp/vnb-round4-ui-review.md` additionally
has an open P2: Exit confirmation → Settings → language rebuild can restore focus
to the background Run button and lose the pre-exit editor focus. Root owns the
repair and a new actual-input regression. Static intent or a partially passed
UI suite does not close it.

At inventory time there is no accepted experimental GPU/minimum-size capture
receipt, standalone ordinary-startup result or final repaired-focus review.
Any newer files produced concurrently need explicit follow-up inspection.

## Remaining evidence to close this bounded increment

1. Passing current standalone UI suite after text Undo, English minimum geometry
   and nested exit/Settings-language focus repairs; preserve the failure receipts.
2. GPU execution in both languages at1280×720 and the claimed960×640 minimum.
   Inspect actual saved frames for Comparison, Evidence, Public requests and
   exit guard; verify image write results/dimensions and bind frames to source.
3. Ordinary isolated lab startup and a concrete review launcher or prepared
   project. The earlier launcher review established source isolation plus four
   invalid-argument rejections, not an actually rendered lab window.
4. Independent close-out of the UI P2 against the repaired source and runtime
   evidence. Retest the affected routes after any subsequent source change.
5. Final whole-runtime/test/source equality manifest versus the QA copy, with
   only intentional custom-user-dir/main-scene differences explained. Current
   seven-file equality and grid hashes are narrower.
6. Durable final receipt/index: currently the round4 evidence directory contains
   discovery, strategy and recovery, but no final README/index or archived focused
   verifier/UI acceptance bundle. Preserve exact commands, profiles, results and
   failure history before retiring the active plan.
7. Update CURRENT_STATE, testing guidance, architecture/experiment index and
   handoff for the delivered experiment. The current active plan's “production
   parity and finite grid remain to be run” is stale: those are already passed.
   Its UI/GPU/startup questions remain open. The experiment README's overall
   integration-pending wording is still accurate; after acceptance it should
   link the production evidence and completed plan.

No final full-repository regression, exported package, Windows/Linux run,
unlocked-Mac native input or newcomer/long-session acceptance is established by
the above. These are separate limitations, not reasons to overstate a finite
Mac source/QA result.

## Recovery evidence boundary

`recovery/20261105T005116Z/results.json` records successful import and ordinary
headless startup for each of the three earlier preview projects. Those six
passes show their removed import caches were restored; they are not this new
lab's startup evidence. The earlier APFS clone attempt has no completion
receipt and must not be represented as completed.
