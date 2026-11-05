# Round9 circuit failed-step recovery analysis

Reviewer: `/root/review_records_final`
Date: 2026-11-05
Scope: read-only causal analysis and recommendation for a separate correction.
No source/test/validator edits, Godot execution, Git commands, or heavyweight receipt parsing were performed.

**Confirmed P2: an electrically invalid step publishes its failed output map as continuation state. A subsequent valid stimulus can therefore fail on the previous step's short circuit before the new input values are applied.**

Actual evidence:

- `.godot/computation-benchmarks/20261105T094520Z-reference-circuit-validated/circuit.log` ends with12 failures.
-11 error lines belong to `failed_step_state_recovery`; both the whole sequence's third step and the third separately continued call unexpectedly return `circuit.error.short_circuit`.
-The remaining line is the previously identified first-register-continuation empty-map validator assumption. Root has already corrected that assumption; it is not another runtime defect.
-The current `src/circuit/prologue_simulator.gd` is byte-identical to the frozen reference used by the baseline. SHA256: `ea22934e27dc08fcc1cc64c7158f5f028bf6a5a7150eee02b56c834bf502b371`.

The diagnostic fixture is legal: distinct drivers may share an input when their values agree. `circuit_cases.gd:710` constructs two4-bit external sources feeding one `register4` data input, with a separate LOAD signal and OUT observer. Its three steps at lines737–742 are:

| Step | Stimulus | Required behavior |
| --- | --- | --- |
| 0 | A=3, B=3, LOAD=1 | Valid write; retained register becomes3; OUT=3 |
| 1 | A=5, B=6, LOAD=1 | Real short circuit; no storage commit |
| 2 | A=0, B=0, LOAD=0 | Valid HOLD; OUT remains3 |

The overall sequence must remain failed because step1 was invalid. Recovery means step2 is independently valid, not that the earlier error disappears.

The causal chain is visible in the runtime source:

1. `run_sequence()` correctly calls `_commit_state()` only when `before.is_valid()` (`prologue_simulator.gd:136`).
2. It nevertheless unconditionally replaces `prior_outputs` with `after.output_values` at line158, including electrically invalid results.
3. `_initial_outputs()` gives a width-compatible prior value priority over the current external input at lines268–272. In the failed fixture, the carried source outputs remain A=5 and B=6.
4. `evaluate()` resolves all connected inputs at lines57–63 **before** evaluating source components with current `normalized_inputs` at lines72–78. `_resolve_all_inputs()` reports the carried A/B conflict immediately at lines305–311 and returns early.
5. The next correct A=0/B=0 stimulus therefore never reaches the source-update stage. `_emit_source_events()` already emitted the new source values, so failed evidence can display the new stimulus while the initial resolver still used the previous failed drivers.

The exact A/B carry above is a source-path deduction from the fixture and runtime; this review did not deserialize the full benchmark snapshots during active timing. The actual log independently establishes the repeated failure in both execution forms.

This path reaches ordinary gameplay. The debug action adopts returned runtime state and prior outputs before checking validity (`hardware_foundations.gd:7068–7079`); official incremental cases do the same at lines6762–6772. Live preview subsequently evaluates with that carried map at lines6255–6257. Fixing only one UI caller would leave the shared sequence API, the other UI path and other callers inconsistent.

Recommended separate correction:

- At the `run_sequence()` continuation assignment, publish a new `prior_outputs` map only when the final electrical evaluation is valid. Preserve the previous valid map when it is invalid:

  ```gdscript
  if after.is_valid():
      prior_outputs = _clone_values(after.output_values)
  ```

- Keep the failed `after` result, its actual inputs/output map, errors, comparison failures, event list, step timing and overall failed verdict intact. The failed observation is evidence; the retained valid map is the seed for the next evaluation.
- Gate on electrical validity, **not** `step_passed`, the expected-output comparison or accumulated `all_passed`. A valid execution with an incorrect expected answer still executes and commits the current circuit exactly as before.
- Do not clear the entire carry map on failure: output-carried latches/raw feedback use it as memory, so clearing it can destroy a previously valid state.
- Do not globally reorder `_initial_outputs()` to always prioritize the current source as part of this fix. That broader change could remove initial settle waves, alter intermediate observer evidence and shift ticks/visual steps in already successful sequences. It needs a separate trace/model compatibility decision.
- No change to `_commit_state()`, waveform duration, gate delay, wire latency, topology validation, storage format or score conditions is needed for this confirmed pre-commit failure.

This is a recommendation, not an implemented or runtime-validated patch. All fully valid sequences take the same assignment as before, so their complete results should remain byte-identical. Failure continuation maps and subsequently recovered steps intentionally change and must be reviewed as such.

There are two contract details to make explicit when implementing:

- After an invalid final step, returned `prior_outputs` should mean “last valid continuation seed,” while `final_result.output_values` remains the failed observation. They should no longer be required to equal one another on that path. The diagnostic adapter currently has an unconditional final-map-equality assertion at lines300–307. Keep its requirement that only step1 fails and step2 succeeds; strengthen the failed-step branch to assert exact preservation of the incoming/last valid carry, rather than removing recovery assertions or marking step2 as another expected failure. For valid final results, retain exact equality with the final evaluated outputs.
- The confirmed case fails **before** the storage commit. Existing execution can also commit a valid `before` result and then diagnose an invalid post-commit `after` result. Do not silently introduce transactional rollback of storage for that distinct case. Likewise, a standalone `evaluate()` caller that explicitly supplies an old failed output map is outside this narrow handoff correction. A broader reset/rollback contract needs separate analysis.

Focused regression tests for the separate correction:

1. Promote the actual3-step shared-driver/register fixture into the prologue runtime suite. Run it as one sequence and as three continued one-step calls. Assert validity `[true,false,true]`, overall failure, preserved register value3, the precise short-circuit error on the middle step, no middle-step state transition, and a successful final HOLD transition.
2. After the middle single-step failure, assert both its continuation map and pre-commit runtime storage equal the incoming valid state, while its `final_result` still retains the failed A=5/B=6 observation. Freeze that failed result and confirm the later recovery does not mutate it.
3. Start with a failure before any valid state, then perform a valid write and HOLD; also include repeated invalid steps before recovery. This distinguishes retaining the initial seed from relying accidentally on one previous successful write.
4. Use an electrically valid write with deliberately wrong expected output, followed by HOLD of the actual written value. The first comparison fails, but the next step must see the write. This prevents an incorrect `step_passed`/`all_passed` gate.
5. Exercise output-carried feedback state: establish a valid latch value, trigger a separate deliberate shared-driver short, then return to valid HOLD. The previous latch value must survive; no “clear all prior outputs” workaround should pass.
6. Run the existing prologue/register/RAM/CPU/LOAD-STORE suites and compare **complete** successful baseline objects/events, including `tick`, `visual_step`, `sequence_step`, boundaries and errors, against the frozen reference. Canonical signatures alone are insufficient if fields are omitted. Keep the old failing diagnostic receipt as historical evidence and compare intentionally changed failure/recovery paths separately.
7. In the isolated Hardware debug flow, repeat equal-driver write → conflicting drivers → equal-driver HOLD and verify input correction removes the short without resetting register state. This is a targeted gameplay confirmation; do not label source analysis or headless corpus results as native UI acceptance.

The new continuation meaning should be documented next to `run_sequence()` and in the simulation architecture paragraph about explicit runtime/prior-output state. Rollback is the original runtime assignment plus its associated new regression/documentation change; no player-data migration is indicated.

This defect should remain separate from the Creation performance patch and should not be used to certify the failed circuit benchmark as a valid timing baseline.
