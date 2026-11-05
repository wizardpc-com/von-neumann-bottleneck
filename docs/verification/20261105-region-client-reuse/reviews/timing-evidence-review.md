# Round12 timing and complete-evidence review

Read-only review by `/root/audit_scores`, 2026-11-05. No engine invocation,
Git mutation, runtime/test/harness/document edit or ordinary player-profile
access was performed. The original archives and logs were read without changes.

## Finding

**No blocking evidence defect found in the accepted Round12 measurements.**
The12 public cases have complete exact typed parity, including36 existing
Region Traces,8 separate client-sweep Traces,20 compatibility goal decisions
and2 existing online decisions, the unchanged Base control and the complete
rejection workload. All8 corrected diagnostic cases retain byte-identical
complete evidence across the reference and candidate.

The public measurements support a useful reduction for the existing identical,
independently cold multi-client API calls. Across clients2/4/8, elapsed median
API time fell24.46%–51.42%; the two existing multi-order workflows fell32.03%
and47.55%. Single-client and unchanged controls increased0.98%–3.86% in this
run pair and are reported below without adjustment or concealment. These data
do not establish a universal improvement or prove the small control increases
are noise. They also do not measure a player Run callback or simulation cycles.

## Artifact and process checks

Accepted reference public run:
`.godot/region-client-benchmarks/20261105T132834Z-reference`.
Accepted candidate public run:
`.godot/region-client-benchmarks/20261105T143051Z-candidate`.
Accepted corrected reference diagnostic:
`.godot/region-client-profiles/20261105T141917Z-reference-corrected`.
Accepted candidate diagnostic:
`.godot/region-client-profiles/20261105T143310Z-candidate`.

All four original invocation records report exit0 and empty diagnostics/failures.
The full logs independently contain the expected completed PASS markers and no
error, script error, parse error or warning. The public records each contain12
cases; diagnostic records each contain8 cases and11,522 actual runtime checks.
Original engine output bytes in their isolated profiles match the archived
receipts. The four accepted original JSON documents total270,564,758 bytes.

| Original archive | Uncompressed bytes | Original SHA256 |
| --- | ---: | --- |
| `20261105T132834Z-reference` | 47,536,428 | `c2f57e73ecbcfd0842be907c836a5ea535f9a0436eaf0f6b52e0cc86c3774b95` |
| `20261105T143051Z-candidate` | 47,536,395 | `418d5994c806fae6b7180addfb37322d685c34bcff7b88f11f7447c2be4d4bd0` |
| `20261105T141917Z-reference-corrected` | 87,745,973 | `c3cf916633ed3c616ef483d307808189655534656520f775282f7ba516085e1f` |
| `20261105T143310Z-candidate` | 87,745,962 | `f786cb0bffccfd011652194efbf444361aa2aaf919eb4141260e781f47c2113e` |

The accepted raw bytes were rehashed, and each original complete snapshot's
exact byte boundary, declared length and hash were checked before parsing.
Both sealed public receipts preserve every original snapshot and reproduce
the process/log/raw receipt bindings exactly. No old failure was relabeled,
projected into a success or used to compute an accepted time reduction.

The comparison script reads one complete case at a time to bound memory.
It checks the full declared case set first, then passes each actual full typed
snapshot to the unchanged repository strict comparator; all12 comparisons pass.
It additionally checks byte-exact complete snapshot equality. This preserves
all Trace/Event fields and typed container/key metadata, including the
String/StringName distinctions that caught the earlier test/helper defects.

Reproducible main audit:
`/private/tmp/vnb-round12-review-evidence.py`.
Detailed results:
`/private/tmp/vnb-round12-timing-evidence-review.json`.
The main audit completed467,258 explicit checks with no remaining issues.
A supplemental556-file candidate runtime comparison found only the intended
Region model difference; its outcome is recorded separately in that JSON.

## Public measurements

All times below are per actual public adapter invocation, in milliseconds:
**median (minimum–maximum of seven sample means)**. These are ranges of the
seven fixed-batch means, not confidence intervals. Cold calls remain separate
in the original receipts. Both versions use the same per-case iteration file,
inputs, successful results, host, engine and execution method.

| Public case | Invocations/sample | Reference ms | Candidate ms | Candidate elapsed time |
| --- | ---: | ---: | ---: | ---: |
| `representation_partition_revisits` | 8 | 12.498 (12.447–12.598) | 12.739 (12.691–12.812) | 1.93% more |
| `representation_online_clients` | 4 | 27.857 (27.715–27.884) | 14.610 (14.463–14.787) | 47.55% less |
| `representation_region_compatibility` | 1 | 80.417 (79.934–84.699) | 54.661 (54.085–57.479) | 32.03% less |
| `representation_region_online_rle_c1` | 8 | 1.869 (1.865–1.874) | 1.887 (1.880–1.903) | 0.98% more |
| `representation_region_online_rle_c2` | 4 | 3.478 (3.449–3.581) | 2.627 (2.599–2.737) | 24.46% less |
| `representation_region_online_rle_c4` | 2 | 6.663 (6.644–6.688) | 4.003 (3.903–4.340) | 39.93% less |
| `representation_region_online_rle_c8` | 1 | 12.718 (12.628–13.276) | 6.357 (6.280–6.578) | 50.02% less |
| `representation_region_offline_revisits_c1` | 4 | 11.769 (11.747–11.906) | 12.079 (11.921–12.265) | 2.64% more |
| `representation_region_offline_revisits_c2` | 2 | 22.984 (22.919–23.372) | 16.780 (16.644–16.962) | 26.99% less |
| `representation_region_offline_revisits_c4` | 1 | 43.829 (43.586–44.111) | 24.822 (24.647–25.108) | 43.37% less |
| `representation_region_offline_revisits_c8` | 1 | 86.719 (86.372–87.380) | 42.131 (41.914–43.503) | 51.42% less |
| `workload_rejections` | 1 | 1.035 (1.029–1.042) | 1.075 (1.062–1.135) | 3.86% more |

The Base-only control is four complete Base Traces. `representation_online_clients`
contains four complete Region Traces and two goal decisions; compatibility
contains32 Traces and20 decisions. These workflow numbers must not be described
as one client or one player click. Each of the eight new client-sweep cases is
one complete public Region Trace. The offline case is an explicit192-access
mixed-codec stress fixture, not a new authored game goal.

Every clients2/4/8 candidate sample range is below its corresponding reference
range. The two existing multi-order workflows also have non-overlapping ranges
in the beneficial direction. However, the unchanged Base control is1.93% slower,
online client1 is0.98% slower, offline client1 is2.64% slower and rejection is
3.86% slower. Their measured ranges also shift upward; this review does not
normalize those shifts away or claim that a single sequential process pair can
distinguish small host/method variation from every small regression.

This is one sequential reference/candidate process pair with seven samples,
not randomized interleaving, a multi-session confidence study or cross-platform
performance evidence. The multi-client reductions are substantially larger
than the observed control shifts, supporting this narrowly scoped reuse while
preserving those limitations in the delivery claim.

## Diagnostic checks and interpretation

The same final helper bytes execute on both versions. Each family uses fixed
counts for both boundaries: online8 and offline2 invocations/sample, with seven
samples. Complete actual Base/Region oracles are constructed outside timers.
Actual materialization retains the measured preparation offset, fresh events,
deep copies, all output/access evidence and current metric/container types.

For each case the independent audit checked the complete actual Base template
against each retained independently executed Base result; every original
Region field against the materialized service result with only its real
preparation-event prefix omitted; every event field and absolute cycle; the
actual preparation offset; ten summed service metrics; and unchanged
single-service overfetch/peak-cache values. Across versions, the complete
five-surface evidence snapshots are byte-identical: template, full Region,
all independent services, materialized service and initialization seed.
The runtime helper's input/template/retained-result mutation and immutability
assertions all completed successfully; snapshots alone do not prove arbitrary
alias topology.

The following medians are milliseconds per diagnostic invocation, with full
seven-sample values/ranges and cold timings retained in the JSON. They are
separate measurements, **not additive attribution or public API ratios**.

| Diagnostic case | Invocations/sample | N Base services reference | N Base services candidate | Materialization reference | Materialization candidate |
| --- | ---: | ---: | ---: | ---: | ---: |
| online_rle_c1 | 8 | 0.909 | 0.915 | 0.731 | 0.726 |
| online_rle_c2 | 8 | 1.852 | 1.838 | 1.455 | 1.447 |
| online_rle_c4 | 8 | 3.707 | 3.714 | 2.913 | 2.892 |
| online_rle_c8 | 8 | 7.643 | 7.503 | 5.955 | 5.957 |
| offline_revisits_c1 | 2 | 6.214 | 6.158 | 5.057 | 4.918 |
| offline_revisits_c2 | 2 | 12.484 | 12.322 | 9.851 | 9.713 |
| offline_revisits_c4 | 2 | 24.769 | 24.750 | 19.433 | 19.201 |
| offline_revisits_c8 | 2 | 49.410 | 48.712 | 38.328 | 37.773 |

The Base boundary includes complete Base Trace allocation and retains all N
results per invocation, unlike production's first/current references. The
materialization boundary includes a fresh Trace, deep copies, existing event
construction, access/output copies and ordered accumulation. Initial template,
Region oracle, seed, snapshot traversal, hashing and export are excluded.
Earlier evidence remains retained through later calls. These lifetime and
allocation details prohibit subtracting the two timings from a public call
or treating their sum as a decomposition. They also establish neither peak
heap nor a pure decoder/allocator time. The continued linear materialization
cost is visible without inventing an8× performance promise.

## Source binding and rejected evidence

The frozen reference is based on
`82d6d540a8c01e8ed2a810b30a9f078fc7d35365` at
`.godot/verification/20261105T130540Z-round12-reference/project`.
All556 manifest files match the actual committed Git blobs and frozen files.
The candidate is
`.godot/verification/20261105T142756Z-4bd0e0fc/project`.
Of those556 runtime/support files, only
`experiments/representation_region/model.gd` differs:

- Reference: `c7e37462fd24f23f01425cc2094e5818d1374070e08f51b46a6f6177b9423528`.
- Candidate: `71c5a91016a00163b9a3be2f64ca90030f8992469866977521ed5858814ae6d3`.

Six common public harness GDScripts match the recorded hashes in source,
reference and candidate. The separately corrected diagnostic helper is
`229639c318054dd15af06bac08c3ff2844354f15169e205e642c8c3fe2f4a9cd` on both
measured versions. Its change from the preserved initial helper is exactly
an explicit String insertion for `service_cycles` plus its explanatory comment.
The complete comparator, Snapshot, Base model and declared fixture adapter
were not relaxed to accommodate it.

The original14:15:27 UTC reference diagnostic remains an **excluded failure**:
exit1,16 assertion failures, no PASS,87,746,042 raw bytes, SHA256
`04493a7aa657faf8df4d95bd77f5a5ffbe9874676f6de9c3cc348c47d634a87b`.
Its archive size/hash and log hash were independently checked. It is not used
in the accepted timing table. The successful14:19:17 UTC corrected run supersedes
it for performance interpretation, while both remain evidence.

The first audit-script pass stopped at a source-text assertion because that
assertion omitted the correction's explanatory comment. Its result is preserved
at `/private/tmp/vnb-round12-evidence-initial-checker-failure.json`. Including
that exact comment corrected only the audit's text expectation; no artifact,
Trace, input or timing assertion changed, and the final full audit passed.

## Delivery boundary

This review supports complete model/API equivalence and the measured Mac API
benefit only. Root's pure regression, scripted rendering, ordinary startup and
final integration checks remain separate evidence. No native OS input,
Windows, exported-package, newcomer, long-session, audio, heap or real
Run-button/restore-latency acceptance is inferred. No additional optimization
round, new content or native pilot is proposed by this closeout review.
