# Round10 pure continuation regression tests

Owner `/root/audit_scores`, 2026-11-05.
Only `tests/test_prologue_failure_recovery.gd` was added.
The file is released to root for import, before/after execution and integration.
Root owns UID generation and all engine/Git operations.

SHA256:
`5cf4ecdb8f9a8cddaf203e0b51ed6b10e3186d11367a8b0477f6343ebe757dd7`

## Test contract

The new pure `SceneTree` suite builds small legal circuits and calls the actual
public `PrologueSimulator.evaluate/run_sequence` APIs. It does not use UI,
autoload state, files, player progress or manufactured simulator results.
The existing complete typed `Snapshot` helper checks full result/event
determinism and retained-object mutation. Existing successful-corpus parity
remains root's independent compatibility evidence.

Seven scenario invocations cover:

1. **Register write3 → shared-driver5/6 conflict → equal-driver0/0 HOLD3.**
   Whole-sequence electrical validity must be `[true,false,true]`, overall
   verdict remains failed, the middle observation retains its real stimulus,
   driver values, conflict and events, and only successful WRITE/HOLD steps
   emit storage boundaries. The same three incremental calls must end with
   the same stored word and continuation values. The failed call must retain
   its exact incoming valid output map and runtime storage.
2. **Failure before any success and repeated failures.** Both calls retain
   the initial empty seed; the second observes its new9/10 drivers, then a real
   WRITE3/HOLD3 succeeds. Whole and incremental paths agree. This catches
   accidental dependence on having already completed one valid write.
3. **Electrically valid WRITE7 with wrong expected answer9.** Its comparison
   remains failed, but actual storage and output carry must advance to7.
   The next HOLD succeeds. Direct carry equality prevents a mistaken
   comparison/aggregate-success gate from hiding behind storage semantics.
4. **Sealed output-carried latch.** Establish Q1 by RESET then SET, introduce
   a separate shared-driver guard conflict, then correct the guard and HOLD
   Q1/NQ0. Preserve full last-valid carry and both retained receipts.
5. **Raw two-NOR feedback latch.** The same independent guard sequence runs
   with explicit feedback permission. Its two actual HOLD boundary events
   remain present. Clearing all carry on failure cannot pass this test.
6. **Settled but invalid sealed latch.** Stable SET=RESET=1 retains the
   existing `invalid_latch_state` diagnostic and settled=true, emits no
   successful boundary, and cannot replace last-valid carry. A later HOLD
   recovers Q1. No raw-latch teaching/validation rule changes are introduced.
7. **Concrete post-commit failure.** A register1 and a separate external
   guard driver initially agree at0. Writing1 is electrically valid before
   commit; the newly stored output then conflicts with GUARD0. The failed
   receipt must retain the completed write boundary and runtime word1 while
   keeping incoming last-valid output carry. Correcting GUARD to1 and HOLDing
   recovers the committed1. This explicitly preserves the existing
   nontransactional storage contract; it does not request rollback.

The register test repeats the complete whole sequence and compares every
captured field/event. It also freezes valid/failed reports across later calls,
checks authored steps/topology remain unchanged, then deliberately mutates
the failed report's carry DigitalValue, returned register map and an event.
Earlier valid and later recovered reports must remain unchanged, and the
failed evaluation's output/state must stay distinct from its returned
continuation/storage copies. It does not demand removal of intentional aliasing
between views within one report.

## Verification performed and pending

Read current simulator/value/result/event APIs, existing prologue fixtures,
the Round9 recovery analysis and the Round10 plan before implementation.
Inspected current shared status before/after; preserved root/sibling edits.
All five preload paths exist. Explicit whitespace/conflict-marker scan is
clean; `git diff --check` reported no issue. The new file is untracked, so
ordinary `git diff` does not include its contents; the written test regions
were read directly.

**No engine run or runtime pass is claimed.** Per the ownership assignment,
root must import this new script and run it against both frozen base
`b765dd249cd165358dc5329480c529c76f9218bc` and the candidate in isolated QA:

```text
<Godot-4.7.1> --headless --path <isolated-project> \
  --script res://tests/test_prologue_failure_recovery.gd
```

The suite prints `PASS: prologue failure recovery checks=... failures=0` and
exits0 only after its assertions. An interrupted synchronous outer test call
is guarded to exit1 on the next frame. Complete process logs must still be
checked, because a nested GDScript helper error can unwind independently.
Expected reference failures should be preserved; no assertion should be
weakened merely to obtain a green candidate result.

The post-commit fixture and all new expectations are source-derived until
root's actual engine observations confirm them. It intentionally leaves
direct `evaluate()` calls that receive an explicitly failed seed, global
source initialization order, storage rollback and model/score versions
outside this increment.
