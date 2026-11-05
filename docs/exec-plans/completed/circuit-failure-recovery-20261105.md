# Circuit continuation after electrical failure — Round10

## Goal and scope

Base `b765dd249cd165358dc5329480c529c76f9218bc` on
`codex/gameplay-systems-20261104`. Round9 reproduced a register sequence that
writes3, encounters conflicting5/6 drivers, then cannot HOLD3 after both
drivers return to0. Failed output values are reused before current stimuli
settle. Correct this shared continuation boundary and verify the actual
Hardware Debug/Step host path.

Root owns `src/circuit/prologue_simulator.gd`, benchmark adapter integration,
the related Hardware playback-caption correction, documentation, Git and all
sequential engine execution. Separate agents own
new pure regression and host-flow test files; another independently reviews
the state contract and final implementation. Exact assignments live in
`.godot/collaboration/round10-recovery.md`.

## Contract and impact

An electrically invalid final evaluation remains a complete failed
observation. Its errors, events, outputs and failed overall sequence verdict
must remain visible. The continuation output map instead retains the last
electrically valid map, or the incoming seed if none succeeded. A valid
execution with a wrong expected answer still advances runtime state and
output carry. Do not gate continuation on score/comparison success.

Previously successful complete results and events, including ticks,
`visual_step`, boundaries and canonical fields, must remain identical.
Failure continuation maps and later recovered steps intentionally change.
Do not clear latch carry, globally reorder initial source resolution, alter
wire latency, gate delays, costs or completion requirements. A valid
pre-commit evaluation can still commit storage before an invalid post-commit
evaluation; this increment does not introduce storage rollback.

No persistent schema, saved circuit, official task definition, model version,
ranking condition or old earned result changes. Existing invalid observations
are never retroactively turned into passes. A new successful run retains the
ordinary completion authority. GDScript remains the reference; no native
module, dependency, pooling or threading is involved.

## Implementation and verification

1. Freeze the current successful circuit corpus and runtime independently,
   inspect state/caller contracts, and retain the original failed diagnostic.
2. Add pure regression coverage for whole/incremental continuation, first
   and repeated failures, valid-but-wrong expectations, output-carried latches,
   detached retained evidence and post-commit failure behavior.
3. Update only the output carry boundary when final electrical validation
   succeeds. Strengthen benchmark failure-map assertions without relaxing
   intended recovery success.
4. Compare every captured value/event for all unchanged successful circuit
   scenarios against the frozen reference. Separately inspect expected
   differences in failed observations/continuation/recovery.
5. Run relevant prologue, circuit, storage/CPU and Hardware suites in isolated
   Godot4.7.1 profiles. Exercise actual Debug/Step callbacks with corrected
   visible inputs and persistent register state; distinguish headless,
   viewport input and native OS acceptance. Keep initial failures.
6. Independently review source and evidence, bind the playable QA to source,
   verify ordinary startup, update current documentation and handoff. Commit
   and push a verified milestone only to the authorized task branch.

## Rollback and remaining questions

Rollback restores the original `run_sequence()` carry assignment from the base
commit and its associated tests/contracts. No player-data migration or
rollback is needed. Direct callers that deliberately pass a failed map to
standalone `evaluate()` remain outside this handoff repair. Raw/sealed latch
differences, missing-input contracts and the64-tick limit remain separate
review items. Windows/exported/native and long-session acceptance must not
be inferred from source or GPU suites.

## Progress

- 2026-11-05: previous milestone is committed/pushed; current worktree was
  clean. Read the confirmed recovery analysis and current shared simulator.
  Scope and rollback are recorded before runtime changes.
- 2026-11-05: frozen b765dd2 fails the new pure regression (31 assertions)
  and actual host regression (7 assertions); the first host attempt exposed
  an eager test-class/autoload compilation error, separately retained and fixed.
  Candidate13 related suites pass, and11 successful corpus snapshots match
  every typed field/event. The strict diagnostic now passes.
- 2026-11-05: actual bilingual GPU images exposed a related presentation
  defect: interrupting WRITE playback before its boundary leaves `Stored Q=0`
  during a later failed Debug although incoming storage is3. Two new host
  assertions reproduce against the simulator-only candidate. Scope now includes
  initializing failed playback component captions from the report's actual
  incoming state, even if no commit boundary exists. This changes no simulator
  results or player state; rollback may restore the host condition independently.
  A corrected live-preview capture will explicitly advance its source wave;
  earlier images were captured at the start of its real animation. Preserve
  those original images and do not interpret intermediate pixels as final output.
- 2026-11-05: completed. The strengthened host test changes142/2→142/0;
  six additional affected suites pass after the caption patch. Final GPU
  Chinese/English each158/0 with six raw1280×720 frames. Thirteen distinct
  related suites have passing latest observations; pure recovery308/0.
  Original failed attempts and six initial frames remain archived.
  Eleven successful full typed corpus snapshots are exact, and independent
  diagnostic comparison proves unchanged actual failed evidence/25-event
  prefix with only declared carry/recovered-HOLD differences.
  The later host patch is separate from computation timing evidence.
  Final QA binds1248source/test/support files; ordinary startup exits0 without
  diagnostics and preview launcher passes shell syntax checking.
  See [complete receipt](../../verification/20261105-circuit-failure-recovery/README.md).
  No native/Windows/exported/newcomer/long-session acceptance is claimed.
  Root closes scoped commit/push to the task branch after final evidence review;
  main and ordinary player data remain outside the delivery.
