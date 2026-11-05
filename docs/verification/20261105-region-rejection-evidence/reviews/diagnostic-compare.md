# Round11 independent complete evidence comparison

PASS. Read-only review completed against the original process outputs, logs,
sealed receipts, complete typed snapshots and frozen/current source bytes.
No Godot execution, source edit or Git mutation was performed by this reviewer.

## Successful workloads

The unchanged strict comparator accepts both declared valid cases. Every
typed input and result value is exact, including all metrics, full events,
cache/codec evidence and container types:32 compatibility traces plus4
existing online traces. The corpus retains20 `meets()` decisions; the
existing online case retains two more. No result was flattened for parity.

The original three-sample commands and fixed batches (compatibility1,
existing online4, diagnostic1) are verified. Timing observations do not
constitute a speedup claim for this correctness repair.

## Intentional rejected-evidence difference

All13 siblings of `region` are fully typed-exact.
Only Region changes. Its error, failed status, identity, complete submitted
spec/plan and metric key set remain exact. Nine previously nonzero metrics
become integer0; the other five already-zero numeric fields stay exact.
All four completed-evidence arrays become empty; result_value and
expected_value change7→0. Events and all other fresh Trace defaults are
unchanged. No Region-success-only field was introduced.

| Metric | Before | After |
| --- | ---: | ---: |
| total_cycles | 0 | 0 |
| request_cycles | 4 | 0 |
| transfer_cycles | 68 | 0 |
| decode_cycles | 0 | 0 |
| consume_cycles | 1 | 0 |
| stored_bytes | 68 | 0 |
| traffic_bytes | 68 | 0 |
| decoded_values | 64 | 0 |
| decode_ops | 0 | 0 |
| cache_hits | 0 | 0 |
| cache_misses | 1 | 0 |
| evictions | 0 | 0 |
| overfetch_values | 63 | 0 |
| peak_cache_bytes | 64 | 0 |

| Array | Before length/type builtin | After length/type builtin |
| --- | --- | --- |
| outputs | 1/2 | 0/0 |
| expected | 1/2 | 0/0 |
| blocks | 1/27 | 0/0 |
| accesses | 1/0 | 0/0 |

Container builtin2 denotes int,27 Dictionary,0 untyped Variant.
Outputs/expected change Array[int]→Array; blocks changes Array[Dictionary]→Array;
accesses remains Array. These type changes are explicit parts of fresh
rejection evidence. Complete diagnostic/metric dictionary wrappers and
all input provenance types are preserved.

The frozen diagnostic exits1 with exactly15 expected residual-evidence
assertions, and no parser/runtime/warning errors. Candidate exits0 cleanly.
The unmodified strict comparator rejects the combined diagnostic because
the historical process failed. Original receipts remain unmodified; no
equal-work timing ratio is produced for the changed diagnostic.

## Artifact and source binding

| Role | Original JSON bytes | SHA256 |
| --- | ---: | --- |
| reference_valid | 17183930 | `a7dab0c7d67cdf8f46eafb68afd4528f8ce14fd1d940f940f945699368385ebd` |
| candidate_valid | 17183932 | `15ccc9c0e88655f7e95288225f794c313fecff0e5c428fe66519354f9abda055` |
| reference_diagnostic | 115340 | `5fea0f922d834beece9b315d2873beb262419b251ac7018164a7cbf0a467f947` |
| candidate_diagnostic | 110324 | `75beb4d93991ec79d42eb1020a9819156a511899937a75558800f618c477269c` |

Every archived raw JSON matches its still-present isolated engine
output byte-for-byte. Snapshot hashes cover the original serialized
snapshot bytes at exact boundaries. Re-sealing raw JSON plus complete
log and actual returncode reproduces each sealed receipt exactly.

All556 reference manifest hashes match their original Git blobs at
`cf27a8236db7faca56d6361cf9a44d35224b748e` and remain unchanged in the frozen project.
Candidate runtime files match current reviewed source. Only Region model
and its README differ from the frozen manifest; Base plan model, codec,
Trace and general comparison/sealing tools are unchanged. All six measured
harness scripts are identical across source/reference/candidate. Project
settings differ only in the two explicit QA isolation entries and one
additional blank line after [application] in the frozen reference.

The initial review checker rejected that extra blank line. Its failed
JSON is retained at `/private/tmp/vnb-round11-diagnostic-initial-checker-failure.json`.
The checker now permits precisely that observed formatting difference;
no computation artifact, model, assertion or comparator was weakened.

The production branch still delegates Base.run before preparation-field
rejection; unchanged Base implementation and complete unaffected diagnostic
siblings are preserved. This artifact review does not extend the finite
corpus to every malformed input or establish arbitrary alias equivalence.

No native OS input, Windows, export, newcomer or long-session acceptance
is implied. Complete machine-readable checks, source hashes, invocation
commands, container metadata and strict-comparator outcomes are in
`/private/tmp/vnb-round11-diagnostic-compare.json`.
