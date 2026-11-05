# Round9 actual measurement evidence review

Reviewer `/root/audit_scores`, 2026-11-05. Read-only follow-up in
`.godot/collaboration/round9-audit.md`. This agent ran only Python evidence
inspection/self-comparison and read source/logs; no Godot, runtime edits, Git
mutations or ordinary player-data access.

## Verdict

The actual **workload** reference receipt is valid for continued differential
work: all12 selected cases executed, all reported semantic/repeat/JSON/retained
checks passed, the complete snapshots are supported by the hardened comparator,
and independent nested Creation checks below confirm real work and reconciled
costs. This is a baseline, not a speedup or cross-platform acceptance.

Bare benchmark JSON is **not sufficient acceptance authority**. A concrete
circuit retry contains99 validator script errors yet its receipt says
`failures:[]`; that receipt passes self-comparison. The outer invocation/log
checker correctly rejected it. Preserve and require that external verdict.

The final pinned-harness corpus should be rerun after root finishes its small
adapter/harness corrections. The current complete circuit corpus correctly
fails on an existing recovery defect plus one overstrict validator assertion;
it is not an accepted performance baseline.

## Actual workload evidence read and independently checked

Directory:
`.godot/computation-benchmarks/20261105T093116Z-reference-workload/`

- Read `workload.log`, `invocations.json` and the entire `workload.json.gz`.
- Raw decoded bytes: **134073195**.
- Raw SHA-256:
  `e49baeefb1d49ac305b5aba5a10f813df81f83a93d9712291d75e0c3ea974781`.
- Independently recomputed length/hash match the invocation record.
- Invocation return0, no captured diagnostics, receipt failures empty.
- `compare(receipt, receipt)` using current hardened `compare.py`: PASS,
  12 cases, no issues, all self-ratios1. This verifies receipt/schema/support
  handling, not before/after performance.
- Engine `4.7.1-stable (official)`,
  hash `a13da4feb8d8aefc283c3763d33a2f170a18d541`.
- macOS / arm64 / headless / Apple M2 /8 processors /
  host label `yrq-mac-round9` /7 samples.
- Independently hashed all556 runtime manifest entries in frozen QA project
  `.godot/verification/20261105T090809Z-3273d2f7/project`:
  **zero mismatches** against
  `.godot/collaboration/round9-runtime-base-sha256.json`, base2748138.

Additional Python assertions over the saved typed snapshot passed for all seven
selected nested workflows. They did not call or reimplement a simulator:

| Actual nested workflow | Output/work | Original events | Modeled total cycles |
|---|---:|---:|---:|
| RAW transport |1536 symbols restored;436 packet bytes|6148|225601|
| Predictive transport |1536 symbols restored;369 packet bytes|29290|215664|
| Max generation |64 outputs /62 feedback writes|1101|5944|
| Weighted generation |1024 outputs /1022 feedback writes|18024|85367|
| Max generation |1024 outputs /1022 feedback writes|18381|97384|
| Weighted generation |4096 outputs /4094 feedback writes|71680|338593|
| In-memory Session |54 operations /22 commits /22 reveals|complete nested evidence|workflow-specific|

Both transports have successful top-level, encoder and receiver results. Their
actual restored arrays equal the1536-symbol input, packets equal encoder bytes,
and original events contain1536 input reads and1536 recovered writes. For both
top-level transports and each nested encode/decode, independently summed event
`cycles/ops/bytes` exactly equal declared cost totals.

All four generation requests have `ok:true`, valid0..3 symbols, exact requested
length/sampler/seed, original two-symbol initial prefix, one successor selection
and feedback write per generated symbol, and the proper weighted-only sample
count. Their complete event totals independently reconcile to cost.

Session decode is `ok:true`; all22 commits and22 reveals occur. The only three
intentional failed transitions are `predict_first`, `commit_first` and
`prediction_state`. The successful generation and final Session/script fields
are retained in the snapshot. The in-adapter validator also verifies final
profile equality, four actual support receipts, absence of a file lease,
finished prediction, seen check and retained generated result.

Current observed API workflow medians are394687µs for both transports together,
1587977µs for all four generation requests together, and43157µs for the Session.
Do not attribute these combined timings to a single encode, decode or4096 run.

## Concrete findings and limits

### M1 — P1: swallowed validator errors can produce a passing bare receipt

Observed directory:
`.godot/computation-benchmarks/20261105T094215Z-reference-circuit-retry/`.

Independent check found:

```text
SCRIPT ERROR lines: 99
engine returncode: 0
receipt failures: []
compare(receipt, receipt): passed=true
outer invocations.json diagnostics: 99
```

The errors came from my initial typed-array ternary initializers in
`_validate_errors` / `_validate_continuation`; root has replaced them with
explicit typed-array appends. These were benchmark-validator defects, not
simulation failures.

The latest runner's `can_instantiate()` and `_process` guard handle failed script
loading / an aborted entire synchronous run. They cannot catch every helper
error that returns control to its caller and lets `_run` reach `run_finished`.
The actual retry proves this distinction. Root's wrapper rejects SCRIPT ERROR /
ERROR / warnings and therefore rejected the run correctly.

Required acceptance boundary: bind the clean external invocation/log verdict
to the archived raw receipt hash before using comparator output. Do not treat
`failures:[]` or engine exit0 alone as sufficient. A future standalone comparison
tool could require that invocation envelope; no source edit was made here.

### M2 — P2: actual execution_flags omit consumed engine arguments

The workload receipt contains only:

```json
["--script", "res://scripts/benchmarks/computation/runner.gd"]
```

The independently read invocation command also contains `--headless` and
`--path`, which are absent from `OS.get_cmdline_args()`'s saved value. Thus the
receipt comparator's exact flags check cannot by itself bind every effective
engine option. The full external invocation command is available and should
be compared for final base/candidate runs, excluding only declared
project/profile/label/output and iteration-file path differences while checking
the referenced iteration counts themselves. Alternatively record authoritative
invocation metadata with the final evidence.

### M3 — Exact snapshot scope remains value/container evidence

The updated snapshot preserves integer64, float64 bits, StringName, typed
Array/Dictionary metadata, packed arrays and every script-variable property.
Unsupported/depth/cyclic evidence is recursively rejected. The runner now
checks restored-input immutability and retained actual outputs after later
different cases.

Dictionary insertion order and intra-result alias topology are still
normalized away. The source comment says dictionary order is checked
behaviorally, but result-order comparison is absent: retained-result checks
re-freeze the same sorted dictionary representation. Input `var_to_bytes`
checks do preserve input order. Do not claim output dictionary insertion-order
or arbitrary alias-graph equivalence from these snapshots. The selected
Creation change should retain traversal order and have explicit returned
event/state detachment tests, as assigned.

Only the final returned result of each timed batch is compared; three
individual repeats and JSON/retention checks occur separately. This is a
reasonable bounded corpus, not observation of every transient timed result.

The external helper launches each group in a separate process. This actual
workload receipt retains12 results across its12 different cases, not all36
subsystem cases simultaneously. The runner could execute all groups together,
but that was not this invocation.

### M4 — Final harness provenance needs the final run

The workload baseline predates the root's later compile/abort-guard and circuit
adapter corrections. Its invocation records bind runtime/source provenance,
input values, complete outputs and original command, but do not record a
per-file harness digest. Current frozen QA harness files have since been
synced for circuit retries. Root's plan to rerun the final fixed harness is
appropriate; save final runner/snapshot/adapter hashes beside those receipts
and use identical benchmark bytes and fixed iterations for each side.

## Actual circuit failure classification

Three distinct classes must remain separate:

1. **Adapter parse failure:** first run
   `20261105T093758Z-reference-circuit/circuit.log` failed on reserved parameter
   name `signal`. Root renamed it and added the compile guard.
2. **Validator execution defects:** the next retry had the99 typed-array
   errors described in M1. Root fixed those initializers. This retry is not
   successful circuit evidence despite its bare receipt.
3. **Meaningful validation result:** current
   `20261105T094520Z-reference-circuit-validated/circuit.log` and complete
   snapshot report12 failures: one overstrict validator assertion, plus11
   consequences of the real failed-step recovery issue.

The overstrict assertion was introduced in my validator:
`circuit.prologue.register/continued/0` compares sequence final runtime with
the final evaluation's runtime. The authored register is an `sr_latch`
topology, not an edge-triggered `register1/register4`. The actual sequence
runtime is `{"ram":{},"registers":{},"tiny_computers":{}}`; its first final
evaluation runtime is `{}`. `_commit_state()` adds empty storage buckets and
`_has_edge_state()` does not request another evaluation for SRLatch. Observed Q
is correctly known0/width1. Root was notified to relax this representational
assertion (or compare meaningful storage entries), while retaining actual
whole-versus-incremental state equality. No simulator correction is warranted
for this false positive.

The predicted recovery issue **is now engine-confirmed** in both whole and
incremental modes: after A5/B6 creates a short circuit, the valid A0/B0 HOLD step
still reports `circuit.error.short_circuit`, fails to produce the expected OUT3
and emits no successful state boundary. Prior source outputs take precedence
before new stimuli can settle. Preserve this frozen failure and decide any
bounded correctness change separately from the Creation speedup; do not
silently reinterpret the third step as successful.

## Reviewed current harness digests

| File under `scripts/benchmarks/computation/` | SHA-256 |
|---|---|
| `runner.gd` | `df4430bea75380901cb108842eb1bace55de9025ecba0c42f83e734e2cb8ef59` |
| `snapshot.gd` | `ce043b853180e08570cdbb0dca0151875e61c52532a67f81ad3fe4c35897bf5a` |
| `workload_cases.gd` | `bd7f061288e9a9cd181599dd94b200a2921b624de35b37bfc96379de14256db1` |
| `compare.py` | `6371ef07c72b3bee7e897ce186e5ee7367591c17e6d2f901733fd1bf9c2a254a` |

No measured candidate comparison, Windows execution, GPU/native UI acceptance,
or independently executed Godot test is claimed in this review.
