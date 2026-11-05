# Round10 failure recovery — independent contract review

Reviewer: `review_records_final`, 2026-11-05.
Base: `b765dd249cd165358dc5329480c529c76f9218bc`.

Read-only review of the Round9 recovery analysis, Round10 plan/ownership,
current sequence/evaluation/state implementation, result validity, benchmark
validator and real Hardware Debug/live-preview/Step paths. No source edits,
Godot/native execution, Git commands or player-data access.

## Contract review result

No blocking defect found in the proposed bounded correction:

```gdscript
if after.is_valid():
    prior_outputs = _clone_values(after.output_values)
```

The gate belongs after final electrical evaluation and before expected-answer
comparison, exactly where the existing unconditional assignment is located.
`PrologueSimulationResult.is_valid()` requires both settled output and an empty
error list. It therefore excludes settled-but-invalid sealed-latch states as
well as shorts, oscillation, timeout and validation rejection.

One wording clarification is important for the post-commit case: retained carry
means the **previous step's successful final electrical evaluation**, or the
incoming seed if no final evaluation has succeeded. It does not mean “the latest
valid intermediate evaluation.” A current step's `before` can be electrically
valid while `after` is invalid; the proposed gate correctly retains incoming
carry rather than adopting `before.output_values`. This clarification was sent
to root; it does not require a broader algorithm change.

## State, evidence and authority boundaries

- `run_sequence()` first clones caller runtime state and DigitalValue carry.
  Retaining its existing local carry on failure does not alias the caller's map.
  The returned carry is separately cloned again. Failed `after` result, inputs,
  comparisons, errors, events, offsets and overall failed verdict must remain
  unchanged for that failed step.
- Electrical validity and expected-output correctness remain distinct.
  A valid write with a deliberately wrong expected answer must commit storage
  and advance carry. A subsequent HOLD observes the actual value even though
  the overall multi-step report remains failed. Gating on `step_passed`,
  comparisons or accumulated `all_passed` would violate this.
- A pre-commit electrical failure retains storage and carry. A valid pre-commit
  evaluation can already update storage before post-commit evaluation fails.
  The correction must preserve that committed storage and emitted boundary;
  retaining output carry is not transactional storage rollback.
- Raw feedback and sealed SR-latch output memory use output carry. Clearing the
  map, replacing it with `{}`, or reconstructing it only from register/RAM
  storage would discard valid latch history. Raw S=R=1 teaching behavior remains
  an existing distinct model question; this patch should not redefine validity.
- Standalone `evaluate()` with an explicitly supplied failed seed and global
  initial-source ordering remain outside this correction. Successful paths
  should keep the same evaluation order, two-phase boundaries and full Trace.

## Actual host implications

The shared simulator fix reaches both Debug and incremental official cases:
`hardware_foundations.gd:7068–7076` and `:6762–6772` adopt the returned runtime
and carry. No host-only conditional or production UI workaround is needed.

Changing visible prologue inputs calls `_on_prologue_input_changed()`
(`:8158–8168`), which stops playback and invalidates live evaluation, without
clearing committed runtime or continuation carry. Live preview calls
`evaluate()` with both retained maps (`:6255–6257`) and does not commit. A
corrected preview may clear the electrical error before another Debug run,
while a pending new write must remain uncommitted until Debug.

`_step_playback()` (`:8883–8898`) consumes existing event batches; it does not
execute another sequence boundary. The host regression must distinguish
Debug's actual commit from Step's presentation and prove Step/replay does not
change runtime or carry. Debug itself never invokes formal completion;
no-completion assertions should remain across failure, recovery and replay.
These points were sent to the host-test owner.

## Required regression and differential evidence

The proposed tests appropriately cover:

1. Shared-driver write3 → short5/6 → valid0/0 HOLD3 as both whole and
   incremental calls; electrical validity `[true,false,true]`, overall false,
   exact middle-step short, no pre-commit failure boundary and final OUT3.
2. Exact incoming carry/storage retention after a pre-commit failure, full
   failed observation retained, and no later mutation of failed result or
   caller-owned inputs/state/evidence.
3. First failure with no successful seed, repeated failures and later recovery.
4. Electrically valid but wrong expected answers, including later state carry.
5. Raw and sealed output-carried latches surviving an independent shared-driver
   failure and subsequent HOLD.
6. An explicit post-commit failure: register Q and external BUS initially both0
   drive one observer; DATA1/LOAD1 commits Q1, then Q1/BUS0 shorts. Storage stays1,
   incoming carry stays preserved, failed output records the actual conflict,
   and correcting BUS1/LOAD0 can recover without rollback.
7. Actual host visible-input callbacks, preview recovery, Debug commit, Step
   playback and no granted completion, under isolated Test mode/profile.

The benchmark adapter's current tracking of `last_valid_outputs`, initialized
from incoming carry and advanced only by valid final step results, agrees with
this contract. It retains the expected third-step recovery assertion instead
of accepting the old poisoned failure. Previously successful complete
snapshots, including every tick/visual_step/sequence_step, remain the independent
regression oracle. Expected changes in failed continuation and later recovery
must be separated from unchanged successful parity; an overall failed sequence
is not grounds to discard its failed observation.

## Implementation review status

At this review point the production simulator still has the original
unconditional assignment, and the two newly assigned regression files have not
yet been released. This is approval of the bounded contract and proposed test
coverage, not implementation/runtime acceptance. Root's patch and released test
sources will receive a follow-up read-only review when ready.

## Production patch follow-up

Root's production patch is now present. Direct file comparison against the
independently frozen Round10 reference
`.godot/verification/20261105T111217Z-round10-reference/project`
shows exactly the proposed validity gate plus its explanatory comments in
`src/circuit/prologue_simulator.gd:158–164`; no other simulator line changes.
Current simulator SHA256:
`3ed8eb32b91b9b7b00fcd9a5b8fa7c25f0095e9c561389632b448e2b51723462`.

No actionable source defect found in this patch. The comment explicitly
clarifies final-evaluation carry, preserved latch state, no storage rollback
and independent expected-answer comparison. Existing successful control flow
takes the same cloned assignment; failed observations remain in `after`, step
results and event arrays.

The current circuit benchmark adapter additionally tracks last-valid final
outputs and verifies exact incoming carry preservation for the known
pre-commit failure. Its actual expected-success/rejection assertions are
unchanged. Current adapter SHA256:
`3f16571bc472786020a508b23138929eb88fe21ed0421d4ec682d78d44e7975b`.
For later differential acceptance the same final adapter should be used on both
runtimes; changing assertions does not justify changing captured evidence.

New pure/host regression test sources were not yet available at this
follow-up. Root-owned runtime testing and complete successful parity remain
pending, and no such success is claimed by this source review.

## Released regression review

Both released test files have now been reviewed in full. Their current hashes
were rechecked on 2026-11-05:

- `tests/test_prologue_failure_recovery.gd`, 438 lines:
  `5cf4ecdb8f9a8cddaf203e0b51ed6b10e3186d11367a8b0477f6343ebe757dd7`.
- `tests/test_hardware_failure_recovery.gd`, 426 lines:
  `e0913fe9a1768d905b81c4134cc0b3cef19cf1eb8862022524188afe7199558e`.

No actionable source defect found in either released regression suite.

The pure suite calls real `evaluate()` and `run_sequence()` APIs. Its seven
scenarios cover whole/incremental register recovery, failures before any
successful carry, repeated failures, electrically valid but wrong expected
answers, sealed and raw feedback latch memory, settled-but-invalid sealed
latches, and a concrete post-commit failure. The latter requires committed
storage and the actual WRITE boundary to remain, while incoming carry survives
until a later corrected HOLD. This directly distinguishes carry repair from
storage rollback.

Full `Snapshot` observations and explicit mutation probes make detachment
checks meaningful: subsequent runs and deliberate changes to a returned
DigitalValue, runtime dictionary and event must leave retained receipts
unchanged. The suite preserves real failed outputs, input values, errors and
events. It does not require removal of intentional aliases between views
inside one report. Its synchronous outer-call guard does not replace full
script-diagnostic checking; root's runner must still reject nested script
errors even if an eventual test marker appears.

The host suite instantiates the real Hardware Test-mode scene and installs a
small detached diagnostic descriptor, using supported components and actual
control callbacks. It checks preview versus Debug commit, recovery without
reset, and Step as playback of an existing batch. Its retained result snapshot
includes both `canonical_signature()` and the separate `error_specs` field.
The fixture does not mutate official lesson steps, publish a passing simulator
stub, or grant completion/sealing. It verifies the isolated QA directory
before constructing the host, requires temporary Test workbenches, and checks
Game content and save/workbench main/tmp/bak hashes before and after.

Renderer paths use viewport mouse/keyboard input and require controls to be
visible, enabled, on screen and unclipped. The activation listener remains
attached through the full click and settling interval, and requires exactly
one activation; no hidden signal fallback is present. Headless paths use the
real controls' signals. The two-second fixture playback period prevents a
Pause/Step race without changing model time or execution. These source checks
establish neither successful GPU execution nor native OS acceptance.

Root's `Control` annotation and deferred scene loading repair the original
autoload compilation failure without weakening the gameplay assertions.
The current source hash above supersedes the earlier test-owner release
hash; the current pass/fail output also records locale and input method.

## Independently inspected old-runtime negative evidence

The following actual process receipts and complete logs were inspected.
Log SHA256 values were independently recomputed and matched each receipt.
All invocations bind the frozen reference simulator hash
`ea22934e27dc08fcc1cc64c7158f5f028bf6a5a7150eee02b56c834bf502b371`.

- `.godot/circuit-recovery-checks/20261105T112423Z`: import exited0;
  `test_prologue_failure_recovery` exited1 and reported
  **301 checks / 31 failures**. The failures are the intended old carry,
  continuation, latch and post-commit recovery defects. The pure log contains
  no script/parse error or warning.
- The first host attempt in that same directory failed during compilation
  because the host class annotation triggered dependencies on `WindowMode`
  and `PlaytestData` before autoload initialization. It was deliberately
  stopped with exit−15 and `stopped_for: "script_error"`. This retained
  initialization failure is not evidence of the gameplay defect.
- `.godot/circuit-recovery-checks/20261105T112522Z`: after the annotation
  correction, the current host test hash above ran against the unchanged old
  simulator, exited1, and reported **124 checks / 7 failures**, with no
  script/parse error or warning. All seven failures concern last-valid
  carry retention and subsequent corrected preview/Debug recovery. There
  were no negative assertions about fixture isolation, Step-only playback
  or retained failed evidence.

These old-runtime observations demonstrate that the regressions detect the
target defect through both model and host paths. They are not candidate
passes. Candidate execution, complete unchanged-success parity and GPU
acceptance have not yet been independently inspected in this review and
remain root-owned verification. No engine/native run, source/test edit,
Git operation or player-data access was performed by this reviewer.
