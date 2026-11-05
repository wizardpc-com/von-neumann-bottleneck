# Complete computation measurements

Use Godot4.7.1 and a verifier-created QA project with a
`VonNeumannBottleneckChecks/...` user directory. Never run these against a player
profile. `runner.gd` checks isolation before executing the actual public model
APIs. The three adapters cover circuits, memory systems and higher-level
workloads; `creation_profile.gd` and `region_profile.gd` measure selected
boundaries separately.

Each adapter supplies bounded inputs, actual results and independent semantic
checks. A matching failure cannot stand in for an intended successful workload.
Snapshots retain all script-variable fields, events, integer64 and float64 bits,
packed values and typed containers. Dictionary insertion order and reference
alias topology are normalized away. Unsupported or cyclic evidence is rejected.

The runner compares JSON-restored input, three individual repeats and the final
result of each timed batch. It retains earlier results through later different
cases in the same process and checks for mutation. It does not inspect every
intermediate timed result or prove arbitrary alias-graph equivalence.

## Reproduce a comparison

Freeze the reference runtime from its commit independently of the candidate.
Use identical benchmark `.gd` files, engine, host, declared case set, fixed
iteration counts and sample count on both sides. Do not run other benchmarks
concurrently. For example, in an already isolated QA copy:

```sh
<Godot-4.7.1> --headless --path <isolated-project> \
  --script res://scripts/benchmarks/computation/runner.gd -- \
  --benchmark-group=workload --label=reference --host-label=<same-host> \
  --samples=7 --iterations-file=<fixed-counts.json> \
  --benchmark-output=user://reference.json
```

Capture the complete combined process log and actual exit code in the invoking
process. Preserve the original JSON, log and command. A bare `PASS` line or
exit0 is insufficient: Godot can log a nested script error and continue.

```sh
python3 -B scripts/benchmarks/computation/record.py \
  <original.json> <complete.log> --returncode <actual-exit-code> \
  --output <sealed.json.gz>
python3 -B scripts/benchmarks/computation/compare.py \
  <reference.sealed.json.gz> <candidate.sealed.json.gz> \
  --output <comparison.json>
python3 -B scripts/benchmarks/computation/test_compare.py
```

`record.seal(raw_bytes, complete_log_bytes, actual_returncode)` is also available
to an invocation helper. It adds process evidence without changing measured
fields. Keep raw artifacts: the comparator validates metadata and full values
but does not authenticate the supplied log/JSON hashes against external files.
The owner must bind those files and actual invocation/source identities.

Timing includes fresh input/state construction and normal API serialization,
events and costs. Only harness snapshots/hash/export are excluded. Retained
earlier results stay alive. Report complete workflow boundaries, all sample
ranges and unchanged-case variation; this is not an FPS or native-input test.
The separate profile's component timings are diagnostic and not additive
attribution of the generation duration.

## Failure-recovery regression

`circuit.prologue.diagnostics` includes a valid→short-circuit→valid register
recovery sequence that failed in the Round9 reference and candidate. Round10
retains the last electrically valid final output map, while preserving failed
observations and any storage already committed. Its strict diagnostic now
requires the corrected HOLD to succeed and failed pre-commit carry to remain
unchanged. Full successful snapshots stay exact; intentional recovery
differences are reviewed separately. The old failing diagnostic cannot support
a same-work timing ratio against the repaired workflow.

Round9 separately compared its unchanged full failure evidence while accepting
35 other scenarios. The exact historical accepted case
list, fixed counts, raw and sealed evidence, failed attempts and commands are in
the [Round9 receipt](../../../docs/verification/20261105-computation-kernels/README.md).
The [Round10 receipt](../../../docs/verification/20261105-circuit-failure-recovery/README.md)
contains negative regression proof, complete diagnostic field comparison and
the11 unchanged circuit scenarios.
This finite corpus does not prove all simulator inputs correct.

## Region preparation rejection

`representation_region_compatibility` retains32 complete traces across all
eight authored orders: whole RAW, whole RLE and two existing alternatives per
task, with20 real goal decisions. Legal but over-budget plans remain part of
the corpus. It supplements the existing four online-client traces.

Round11 compares those successful results exactly while separately correcting
`workload_rejections.region`. Invalid preparation parameters now publish a
fresh failed Trace with detached inputs and no residual service costs, output,
encoded blocks or cache work. The strengthened diagnostic fails on the old
runtime; other rejection members must remain unchanged. Do not compare that
changed combined result as equal work or replace its original evidence.
Direct malformed-type coverage belongs to the pure regression, because the
adapter retains its established JSON integer reconstruction.
See the [Round11 receipt](../../../docs/verification/20261105-region-rejection-evidence/README.md).

## Region cold-client reuse

The eight `representation_region_online_rle_c1/c2/c4/c8` and
`representation_region_offline_revisits_c1/c2/c4/c8` cases retain complete
Region results for clients1/2/4/8. Online uses the authored64-address whole-RLE
scan; offline uses an explicit192-address mixed-codec revisit fixture with a
32-byte decoded cache. The latter is a stress input, not a new authored goal.
Keep the existing compatibility/online workflows, unchanged Base revisit
control and rejection diagnostic in the same comparison. Round12 preserves
all twelve complete results, including the already repaired rejection.

`region_profile.gd` runs only with an isolated QA profile and writes
`user://region-profile.json`. It uses seven samples, fixed8 iterations for
online cases and2 for offline cases. One timer executes N actual Base services
and retains all N results per invocation; the other constructs fresh complete
client evidence from one precomputed Base result. Template/oracle/seed
construction and snapshot/hash/export are outside both timers. Full typed
equality against the real Region service suffix keeps absolute preparation
offsets and all fields; mutation probes separately check detachment.

These diagnostic boundaries are not additive portions of Region time. Base
already allocates complete Trace evidence, and its retention differs from the
production first/current lifetime. They do not measure pure arithmetic,
allocation cost, heap peak or Run-button latency. The standalone schema is
different from `runner.gd`; bind original bytes, complete logs, process status,
input/counts, source hashes and full snapshots before comparing it.
Actual public timings and both retained fixture-correction failures are in the
[Round12 receipt](../../../docs/verification/20261105-region-client-reuse/README.md).
