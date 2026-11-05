# Round9 independent final artifact-integrity review

Reviewer `/root/audit_scores`, 2026-11-05. Read-only final-delivery assignment
from `.godot/collaboration/round9-audit.md`. All engine measurements had ended.
No engine execution, source edits, original-artifact edits or Git mutations
occurred. Analysis and its results were written only under `/private/tmp`.

## Verdict

**Local artifact integrity passes.** Fresh full comparisons using the final
strict parser reproduce all three saved comparison JSON documents exactly:
12 workload,12 memory and11 circuit scenarios,35 accepted scenarios total.
Their actual outer engine commands differ only in project path and role label.
All six accepted receipts have seven samples and the declared fixed iteration
counts.

The separately rejected36th scenario remains rejected: both original processes
exit1, both logs and receipts contain the same11 failures, complete input and
captured result values match, and strict comparison publishes zero timing
cases. It is not included in the35 accepted scenarios.

One packaging follow-through remains for root: `.gitignore:11` ignores `*.log`.
The complete logs exist locally and pass all byte checks, but a normal recursive
add would skip them. Root was notified to include intended archived logs
explicitly, or retain durable nonignored copies, when preparing the milestone.
This review does not certify a later Git index, commit or remote archive.

## Independent checks actually performed

The executable review script is
`/private/tmp/vnb-round9-artifact-review.py`; machine-readable results are
`/private/tmp/vnb-round9-artifact-review.json`.
The final result is `passed:true`, `issues:[]`.

For each of eight original run receipts, including the two known failures:

1. Compared archived gzip raw, gzip sealed, complete log and invocation files
   byte-for-byte by SHA256 with their original `.godot/computation-benchmarks`
   counterparts.
2. Decompressed the original runner JSON; independently recomputed its length
   and SHA256 and checked the invocation's raw/compressed length metadata.
3. Opened the actual `computation-benchmark.json` still in that invocation's
   named isolated `VonNeumannBottleneckChecks` profile. Its original byte length
   and SHA256 match the archived raw JSON. No ordinary player profile was read.
4. Rehashed complete original log bytes and rescanned actual diagnostic lines.
   These match invocation metadata and sealed process metadata.
5. Recreated sealing from original raw bytes, complete log bytes and recorded
   subprocess returncode, then compared every parsed field and type against
   the archived sealed receipt. Sealing preserved every original runner field.
6. Located each original snapshot's exact serialized byte span in the raw
   runner JSON, checked its boundary and declared byte length, and recomputed
   SHA256 from those original bytes. All72 snapshots across both sides of
   the35 valid scenarios and the separate failure scenario match their
   declared hashes. This checks real snapshot bytes rather than digest syntax.
7. Checked original case IDs, sample-array lengths and iteration counts against
   both invocation metadata and the actual archived fixed-iteration file.

The review inspected **431864193 original uncompressed JSON bytes** across
the eight run receipts. No missing original raw/log/sealed/invocation file,
archive drift, wrong raw/snapshot hash, altered sealed field or fixed-count
disagreement was found.

## Fresh complete comparisons

The comparison was rerun in Python against the archived sealed documents,
using the current `compare.py`. Every resulting value, key and numeric type
matches the corresponding saved comparison JSON, including recomputed medians,
ranges, speed ratios and time-reduction values.

| Group | Reference directory | Candidate directory | Accepted scenarios |
|---|---|---|---:|
| workload | `20261105T100056Z-reference-final` | `20261105T100802Z-candidate-final` |12|
| memory | `20261105T100056Z-reference-final` | `20261105T100802Z-candidate-final` |12|
| circuit | `20261105T101607Z-reference-circuit-final` | `20261105T101623Z-candidate-circuit-final` |11|

Directories are under
`docs/verification/20261105-computation-kernels/benchmarks/`.

`final-comparisons.json` matches its original archive. Its three actual
comparator commands point to the corresponding original sealed inputs and bind
the final comparator hash. Their case counts and successful exits agree with
the independently recomputed comparisons.

Actual outer Godot commands were compared, not only the runner's incomplete
`OS.get_cmdline_args()` view. Engine executable path, headless invocation,
runner path, selected group/case subset, host label, seven samples and
iteration-file path all match; only `--path`'s value and `--label` differ.
The declared environment fields also pass the strict comparator unchanged.

The union of accepted case IDs plus `circuit.prologue.diagnostics` equals
the36 IDs in the actual fixed-iteration file exactly, with no duplicates
between accepted groups.

## Original raw JSON hashes

These hashes were independently calculated from decompressed original JSON
and matched against the actual named-profile output files.

| Run/group | Original bytes | SHA-256 |
|---|---:|---|
| reference-final/workload |134073216|`3c430c4d0ce52e73aafa0c56ffb4f071af7cf46279bc10d2598c8161c50d0a7b`|
| candidate-final/workload |134073149|`770bee637bee0dcbdd4bde32b9131c0f5d9ab208b36714f8655f5dede118c635`|
| reference-final/memory |56962685|`be8673c0c671c3fa0b3c123e7d2cc7fc559a34ec6432deec99a175d579a7cbbe`|
| candidate-final/memory |56962635|`2110dba63ec31a7624473888d7ef9d62fb91706b279a99fc3b824a3f0398ca6a`|
| reference-circuit-final |21132653|`3a1302d73ca63dc042e842ec0b5384d8d36ebf5b8cbeef2f863bcd82853402fd`|
| candidate-circuit-final |21132667|`12dd779660e606d5fc44a4643233ac8b5a9106d1ca0b498036075f0f357f0f75`|
| reference-circuit-known-failure |3763594|`57f684446b6a6db899ed5121069495217bdbd3d8828a68739b6c9aac22296243`|
| candidate-circuit-known-failure |3763594|`16351d2591d66abdbcd38b88c41bb66fcc78979575311129bbf1a62ac7683eef`|

All eight separately recomputed complete-log hashes are retained in the
machine-readable review output.

## Fixed harness and current source binding

- The archived six-script measured manifest and36-case iteration file match
  their original collaboration-control files byte-for-byte.
- Every measured script hash matches current source, the frozen reference
  project and the candidate/playable project: **18 of18 file checks match**.
  This includes runner, snapshot, all three adapters and the separate
  Creation profile script.
- Every one of the **556** frozen-reference `src`/`experiments` files matches
  its archived base manifest. This is a direct check of the preserved
  reference files; it does not claim to reconstruct historical Git state.
- All **1244 source/test/support files plus `project.godot`** match the final
  source-binding manifest in both the current checkout and playable QA copy.
  Removing exactly the two QA user-directory setting lines makes the QA
  settings text equal current source settings.
- The final parser hash is
  `0a615f9e1ba14c2c89b5f6f85fa7f46be4d0f3323b47d9a52846e9defed4293e`.
  `test_compare.py` remains
  `aa84998bbae8357096f52a15cb58b26bc09313a0b2447b035454cbd83f7a774d`;
  `record.py` remains
  `2c441837176d8298d482722901a0d40e9fe3a551893d62a3c572ab61a99375a1`.
  These are the released, already-tested parser/sealer bytes.
- Read the archived final Python result:21 tests pass in0.739s. This includes
  the plain/gzip duplicate-field rejection tests. The suite was not
  redundantly rerun during this artifact check; the complete real comparisons
  above did execute with those exact final parser bytes.

## Separate known-failure verification and limits

The known-failure pair explicitly uses **three samples**, while accepted
performance groups use seven. The first version of this independent review
script applied the seven-sample expectation too broadly and stopped only after
all three accepted groups had already passed. Inspection of both diagnostic
commands and receipts confirmed three; only the review script's expectation
was corrected, then the known-failure checks were resumed. No benchmark or
validator was altered.

For that pair, complete snapshots, complete input descriptions and the11-item
failure lists match. Fresh strict rejection matches the saved
`known-failure-comparison.json` result exactly and has an empty timing-case
list. Failure equality is preservation evidence, not correctness acceptance.

This audit verifies local recorded artifacts, source bindings and declared
same-work conditions. It does not independently recreate past subprocess
execution, authenticate a hostile artifact producer, prove arbitrary alias
topology/dictionary-order equivalence, measure UI/FPS or establish Windows,
exported-package or native-input acceptance. No new feature or wider model
change was made.
