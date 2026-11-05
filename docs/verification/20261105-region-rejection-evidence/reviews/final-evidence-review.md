# Round11 final source and evidence review

Reviewed at 2026-11-05T12:50:47.506093+00:00 by `/root/review_records_final`.

**No actionable finding.** The current receipt, completed plan and updated status/architecture/testing/audit/queue describe the inspected implementation and actual evidence accurately. Final source/evidence review is complete; no source ownership is retained.

This independent review used read-only file inspection, byte hashes, complete typed snapshot comparisons, log examination and launcher shell syntax checking. It did not run Godot, send native input, invoke Git, edit production/tests/docs/evidence or inspect ordinary player files. Isolated benchmark outputs were read only from the explicitly recorded `VonNeumannBottleneckChecks/round11/...` profiles.

## Verified source and isolated preview

- The1251-entry source manifest was independently rehashed against both current source and QA. All entries match;1250 non-settings files are byte-identical. `project.godot` differs only by the two explicit isolated user-directory settings. The ordinary startup scene is retained.
- All556 frozen source-manifest entries still match the reference project. Within that inventory only `experiments/representation_region/model.gd` and its README differ from current source. The README is documentation, not a second simulation implementation change. This reviewer verified hashes against the recorded baseline manifest, without invoking Git to reread blobs.
- All six measured harness scripts have the recorded hashes in source, frozen reference and candidate. Fixed iteration counts and three samples remain consistent with the invocation records.
- Base is `cf27a8236db7faca56d6361cf9a44d35224b748e`; reference is `.godot/verification/20261105T121412Z-round11-reference/project`; final QA/playable is `.godot/verification/20261105T122827Z-1645209e/project`. The final Region model hash remains `c7e37462fd24f23f01425cc2094e5818d1374070e08f51b46a6f6177b9423528`.
- The executable preview launcher targets that QA with normal startup and no test/capture script; an independent `zsh -n` succeeds. The recorded ordinary `--headless --quit-after8` run exits0, without diagnostics or fixture script. Its complete original log and hash match the archived log. This is not native or GPU acceptance.

## Verified executed checks and retained failures

All candidate logs and result JSON match their original verifier files. Six actual suites, plus import and user-directory checks, exit0 with no error/script/parse/warning diagnostics:

| Suite | Checks / failures |
| --- | --- |
| Region preparation rejection | 854 / 0 |
| Existing Region model/workbench | 3329 / 0 |
| Region session | 47 / 0 |
| Candidate supports | 54 / 0 |
| Candidate journey review | 45 / 0 |
| Representation workbench presentation | 9303 / 0 |

The old pure regression reaches the terminal854/252FAIL marker with exit1. All252 error lines are exactly63 instances of each of the four expected residual-evidence categories; no script/parse/warning failure accounts for them. The old existing Region suite exits0 with3329 checks. Full old logs, backtraces, invocation records and hashes remain intact. The separate independent reviewer's original configuration-blank-line checker failure is also archived, with its precise initial failure and successful follow-up.

## Complete computation evidence

- Rehashed and compared all four archived benchmark groups against their original invocation/log/gzip files and still-present isolated engine outputs. Their raw JSON totals34,593,526 bytes. Resealing each exact raw JSON with its complete log and actual exit code reproduces the archived sealed bytes exactly.
- Verified original serialized snapshot spans, sizes and SHA256 values. Both valid cases have byte-identical complete typed input/result evidence between reference and candidate:32 compatibility Trace objects plus4 existing online Trace objects,20 corpus `meets()` booleans plus2 existing online booleans. This includes all original events, nested state/cache/codec evidence and container metadata, not projected totals.
- The diagnostic inputs match. All13 siblings of `region` are complete typed-exact. Region alone changes its nine formerly nonzero metrics to typed integer0, its four output/cache evidence arrays to empty, and its two top-level scalar values7→0. Five already-zero numeric metrics and all error/identity/failed-status/input fields remain exact;21 metric keys remain present. The declared `Array[int]`/`Array[Dictionary]` to ordinary empty-array changes are accurately disclosed.
- Original diagnostic process exits1 with15 intended semantic failures; candidate exits0 with no failures. The strict comparison record accepts the two valid cases and rejects the historical failed diagnostic without producing an accepted speed ratio. No comparator relaxation is claimed or required.
- Valid complete-call medians29.633→30.25775ms and81.655→84.149ms match the receipt, with the original three-sample ranges. The document correctly treats these as observations about2.1% and3.1% slower and makes no speedup, FPS, heap or cross-platform performance claim.

## Documentation and boundaries

The current receipt, CURRENT_STATE, high-level and detailed simulation architecture, testing guide, computation audit, active execution queue, completed plan and Region README consistently limit this patch to Base-successful preparation rejection. Base precedence, valid costs/results, identity, saved-plan replay and achievement rules remain unchanged. The documentation acknowledges that Base still executes before rejection; next-stage optimization is explicitly separate. Local links in the receipt and completed plan resolve.

Six related suites are not represented as a whole-repository regression. No new GPU, native OS input, Windows, exported-package, newcomer, long-session, audio or heap acceptance is asserted. No present-round locked-screen observation is fabricated. Current task-branch delivery is still root-owned; this report does not verify a future commit or push.

Reproducible reviewer artifacts:

- `/private/tmp/vnb-round11-final-evidence-review.py`
- `/private/tmp/vnb-round11-final-evidence-review.json`

The helper completed3235 read-only artifact/source consistency assertions with zero issues. These are reviewer checks, not additional game-test assertions. Documentation hashes are retained in the JSON to bind this conclusion to the inspected text.
