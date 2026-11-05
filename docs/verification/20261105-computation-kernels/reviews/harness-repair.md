# Round9 benchmark comparison and circuit outcome validation

Owner: `/root/audit_scores`, 2026-11-05. Assignment:
`.godot/collaboration/round9-audit.md`, “Harness repair and semantic validators”.
The three assigned files are released to root. No production source, shared
runner/snapshot, player data, Git state or Godot execution was changed by this
agent.

## Delivered changes

`scripts/benchmarks/computation/compare.py` now validates the complete version1
receipt shape before reading fields. Missing top-level/per-case fields,
unsupported snapshot sentinels anywhere, null evidence, malformed metadata,
non-JSON/nonfinite values, failed receipts, duplicate/missing cases, bool/float
iteration counts and nonpositive/nonintegral duration samples fail cleanly.
Durations and iteration counts are bounded positive int64; `cold_us` may be0.
Reported summary statistics never authorize a speedup: the comparator computes
medians/ranges from raw duration samples and iterations.

Same-host timing binds engine, OS, architecture, display, processor name/count,
nonempty caller-supplied `host_label`, execution flags, samples and timing scope.
Only the `--path` project-directory value is normalized, allowing independently
frozen reference/candidate projects. Equal snapshot values must also have equal
snapshot-byte/digest metadata. Every comparison failure suppresses **all**
speed-ratio and time-reduction fields, including otherwise matching cases.
Malformed JSON/read failures at the CLI return failure JSON instead of traceback.

`scripts/benchmarks/computation/test_compare.py` contains15 tests, with loops
covering every missing field and both sides of the comparison. They preserve
existing complete-output/Trace checks and add malformed schema/types/numbers,
unsupported matching evidence, metadata/host/flags, raw-duration recomputation,
and CLI failure behavior.

`scripts/benchmarks/computation/circuit_cases.gd` now exposes the required
untimed `validate_case(spec, result) -> Array[String]`. The original12 top-level
fixtures and actual public API calls remain unchanged. Validation checks:

- all4 Half Adder truth-table results independently using XOR/AND and actual
  four-active-gate traces;
- Boolean live and official Trace diagnostic differences, exact structured
  error keys, no successful work for rejected traces, complete declared
  component/wire/observer/gate counts for legal stress;
- all authored prologue step counts, stimulus/expected-value preservation,
  actual output widths/known values, settling/events and state boundaries;
- prologue diagnostic contracts including intentional oscillation/timeout,
  width/duplicate/cycle/conflict failures, raw versus sealed latch distinction,
  and known-plus-high-Z missing-driver behavior;
- whole-sequence versus one-step continuation state/value/event agreement;
  only `tick`, `visual_step` and `sequence_step` coordinates are excluded in
  this *within-result* semantic comparison. Root snapshots still preserve all
  original fields and coordinates in reference/candidate comparisons;
- failure does not commit storage and the next valid HOLD really succeeds;
- all18 DigitalValue width/input combinations across known/from-variant/equal,
  conflict, high-Z, empty-driver-low and width-mismatch resolution.

The validators guard missing/wrong result container/object types and report
issues rather than assuming every nested result exists. They are bounded
outcome oracles for this authored corpus, not arbitrary untrusted-input parsers.

## Critical first-run expectation: recovery may reveal an existing defect

The untouched `failed_step_state_recovery` fixture writes register value3,
provides conflicting A5/B6 with LOAD1, then valid A0/B0 with LOAD0 expecting3.
The validator intentionally requires success/failure/success and unchanged
stored value across the failed step.

Source inspection predicts that the third step may also fail:
`PrologueSimulator._initial_outputs()` at current lines256–281 prefers
`prior_outputs` even for external source components. `run_sequence()` at
lines158 onward forwards the failed step's output map. The new HOLD step can
therefore resolve the retained A5/B6 conflict before the new source values0/0
are evaluated, aborting before recovery.

**This is source-derived, not engine-confirmed by this agent.** Root was notified
before release. Preserve the first actual failure/receipt if confirmed; do not
relabel it successful or silently reset the fixture. Root must scope any
correctness repair or explicit reset/recovery API contract separately. A failed
semantic baseline must not be used to publish performance ratios.

Existing differences intentionally preserved: Boolean official evaluation
rejects a missing required stimulus while the prologue word path accepts a
known driver plus high-Z; raw NOR S=R=1 currently settles Q=NQ=0 while sealed
SRLatch rejects that input. Neither behavior was changed here.

## Verification and boundaries

Fresh authorized command:

```text
python3 -B scripts/benchmarks/computation/test_compare.py
...............
Ran 15 tests in 0.053s
OK
```

Read the full Python output. `git diff --check` produced no whitespace errors;
the new untracked owned files were also explicitly scanned for trailing
whitespace/conflict markers, with no matches. Read the resulting owned source
and current Git status. Shared unrelated edits were preserved.

**Godot import, semantic validator execution, benchmark timing and cross-platform
execution are NOT_RUN by this agent**, per root-only engine ownership. Root must
run the actual pinned-engine isolated baseline and inspect any validator failure
before accepting the harness or selecting runtime optimizations. The comparator
does not authenticate a caller-supplied host label or reconstruct Godot's exact
snapshot JSON encoding from Python; root's frozen-source/receipt provenance and
snapshot writer provide those separate evidence boundaries.

Released file SHA-256:

| File under `scripts/benchmarks/computation/` | SHA-256 |
|---|---|
| `circuit_cases.gd` | `125bec4647b68deba9b564c2faa5129bb0fb294a08b364cc1c973ce8abdde9b8` |
| `compare.py` | `6371ef07c72b3bee7e897ce186e5ee7367591c17e6d2f901733fd1bf9c2a254a` |
| `test_compare.py` | `effc50124e4be5dd8d383b5227c6d88ba46b0710d10cd909dc80ac7b78192968` |
