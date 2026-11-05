# Round10 independent diagnostic comparison

Verdict: **PASS for the bounded recovery change.** No unexpected runtime-result
difference was found in the four completed Round10 benchmark receipts. This is
a read-only evidence audit, not a new Godot run, native acceptance, or a speed
claim for the previously failing diagnostic.

Readable assignment context: the current collaboration handoff delegates an
independent diagnostic comparison to `audit_scores`; the latest chat payloads
remain encrypted/unreadable, and `round10-recovery.md` still contains the
original regression-file assignment. This review therefore changes no
repository source, test, documentation, Git state or player data. The already
released `tests/test_prologue_failure_recovery.gd` remains untouched.

## Reproducible artifacts

- Checker: `/private/tmp/vnb-round10-diagnostic-comparison.py`
- Complete machine-readable result:
  `/private/tmp/vnb-round10-diagnostic-comparison.json`
- Command actually executed:
  `python3 /private/tmp/vnb-round10-diagnostic-comparison.py`
- Result: exit 0, `passed: true`, 1543 bounded checks, no open issues.

The count includes structural access/type checks and source bindings, and must
not be described as 1543 gameplay scenarios.

Four inspected invocation directories, all under
`/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/circuit-recovery-benchmarks/`:

| Role | Directory | Exit | Runner failures | Scenarios |
| --- | --- | ---: | ---: | ---: |
| Frozen accepted corpus | `20261105T111531Z-reference-valid` | 0 | 0 | 11 |
| Candidate accepted corpus | `20261105T112706Z-candidate-valid` | 0 | 0 | 11 |
| Frozen recovery diagnostic | `20261105T111710Z-reference-recovery-defect` | 1 | 14 | 1 |
| Candidate recovery diagnostic | `20261105T112747Z-candidate-recovery` | 0 | 0 | 1 |

Each actual invocation and receipt specifies **three samples**, with the same
fixed per-case iteration map. The checker initially inherited an incorrect
seven-sample assumption from the previous round, rejected that assumption, then
was corrected after inspecting the actual commands and receipts. No evidence
was modified or filtered to make the check pass.

## Provenance and source binding

Independently verified **49,812,635 original JSON bytes** across the four
receipts, including:

- decompressed byte length and SHA256 against each invocation;
- compressed byte counts;
- raw SHA256 against the original `computation-benchmark.json` still present
  in each named isolated `VonNeumannBottleneckChecks/round10/...` profile;
- complete log scans against recorded diagnostics and process exit status;
- no script/parser errors in any of these four benchmark runs;
- exact reproduction of each sealed receipt from raw JSON, log and exit code;
- all **24 original snapshot byte lengths and SHA256s**, taken from the actual
  serialized JSON bytes rather than a reserialized approximation;
- exact iteration counts, sample counts, scenario sets and unchanged invocation
  arguments except the intended project path and role label.

Frozen reference:

`/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/verification/20261105T111217Z-round10-reference/project`

Candidate:

`/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/verification/20261105T112607Z-5880555a/project`

All **556 frozen runtime files** still match
`.godot/collaboration/round10-reference.json`, which binds them to
`b765dd249cd165358dc5329480c529c76f9218bc`.
All 556 candidate counterparts match the current checkout. The only production
runtime file differing from the frozen base is
`src/circuit/prologue_simulator.gd`. All six measured GDScript harness files
match the frozen harness hashes in the source, reference and candidate copies.

Simulator SHA256s:

- Frozen:
  `ea22934e27dc08fcc1cc64c7158f5f028bf6a5a7150eee02b56c834bf502b371`
- Candidate:
  `3ed8eb32b91b9b7b00fcd9a5b8fa7c25f0095e9c561389632b448e2b51723462`

## Existing accepted results

A fresh invocation of the strict comparator on the sealed accepted corpus
passes all **11 scenarios**, and its complete result equals root's saved
`.godot/collaboration/round10-valid-comparison.json`.

Exact full typed input/result/state/event equality holds for:

- Boolean official, stress and diagnostic cases.
- Prologue full adder, ALU, raw latch, register, RAM, tiny CPU, load/store and
  stress cases.

This is complete snapshot equality, not only final-output equality. It includes
all fields emitted by the snapshot contract, including costs, event arrays,
DigitalValue widths/states and continuation state.

## Diagnostic changes are confined to recovery

The complete authored diagnostic inputs are identical. The 12 diagnostic
members retain their order and types. **Eleven members are completely exact**:
width mismatch, duplicate wire, conflicting drivers, missing driver, forbidden
cycle, oscillation, settle timeout, invalid sealed latch, raw latch both-high,
disallowed raw latch and DigitalValue resolution.

Only `failed_step_state_recovery` changes. Its concrete sequence is:

1. WRITE `A=3, B=3, LOAD=1`, expecting OUT 3.
2. Short `A=5, B=6, LOAD=1`, expecting OUT 3 but electrically invalid.
3. Correct `A=0, B=0, LOAD=0`, expecting retained OUT 3.

The observed old step result is `[true, false, false]`; the candidate is
`[true, false, true]`. The whole sequence remains `passed=false` in both,
preserving the middle failure rather than retroactively awarding success.

Verified exact preservation:

- Whole-sequence WRITE and short step dictionaries, including comparisons and
  the complete actual `PrologueSimulationResult`.
- Every failed observation field, including error text/spec, external inputs,
  input/output/wire values, actual state, settle status and result events.
- The complete first incremental WRITE report.
- All **25 whole-sequence events before the corrected HOLD**.
- Complete committed register state across old/new and whole/incremental runs.
- Topology, initial state and initial carry fields wherever not causally
  affected by the recovery change.

The failed incremental short report changes **exactly one field:
`prior_outputs`**. It now equals its incoming last-valid map and the previous
successful report's output map. Its `final_result`, failed step, canonical
signature, events and stored register state are otherwise exact. This proves
the failed observation remains separate from the continuation seed.

The corrected HOLD receives that retained map and unchanged storage, settles
successfully, has no error and actually observes a known 4-bit value **3**.
Its final carry equals the valid final evaluation's output map in both whole
and incremental workflows.

The whole event count changes from **31 to 41**. The unchanged 25-event prefix
is followed by the corrected HOLD's **16 real events**, replacing the old
6-event repeated-short tail. These additional events represent newly completed
work. The whole canonical signature and final result therefore appropriately
change.

The checker explicitly asserts the exact changed-field sets at each workflow
level; it does not merely omit the recovery member and accept everything else.
The strict benchmark comparator still rejects the failed reference diagnostic
and emits **zero accepted timing cases** for that pair. No repair speedup is
claimed.

## Regression baseline observation

Separately inspected the complete old-runtime log:

`.godot/circuit-recovery-checks/20261105T112423Z/test_prologue_failure_recovery.log`

It completes with **301 checks / 31 assertion failures**, exit 1, and no
GDScript parser/runtime exception. The failing assertions match old carry
poisoning, first/repeated failure recovery, raw/sealed latch continuation and
post-commit recovery. Its script SHA256 equals the released fixture
`5cf4ecdb8f9a8cddaf203e0b51ed6b10e3186d11367a8b0477f6343ebe757dd7`.
The log gives a valid negative baseline; it is not a passing acceptance result.

## Limits

This audit verifies the specified stored benchmark evidence and current
source/reference bindings. Root remains responsible for the final candidate
regression logs, UI/GPU receipt, current-source manifest, archive and delivery.
This report does not establish native mouse/keyboard acceptance, Windows/export
compatibility, long sessions or performance improvement. Standalone `evaluate`
with an explicitly failed supplied seed and transactional storage rollback stay
outside the agreed change. No engine run or Git mutation was performed here.
