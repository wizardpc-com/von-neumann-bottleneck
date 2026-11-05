# Round 4 model implementation — 2026-11-04

Owner `/root/audit_scores`. The three owned files are ready for root import,
runtime checks and independent review:

- `experiments/layout_strategy/model.gd`
- `tests/test_layout_strategy_model.gd`
- `src/layout_chapter/layout_simulator.gd`: only the two authorized helper seams.

No Godot run, Git mutation, official save access or unrelated file edit was
performed. Shared helper diff was inspected; `git diff --check` for that file and
new-file trailing-whitespace checks passed. Runtime correctness is pending root,
not claimed by this handoff.

## Implemented contract

The pure outer model implements every frozen API:
scenario/starter_plan/normalize_plan/validate/condition_id/plan_id/evaluate.
Four public workloads use17 original records, scan8 or mixed9 logical jobs,
batch/serial readiness and160B scratch. There are no old targets, labels or
progression fields in the public tasks.

An internal executor uses base initialization, source/copy mapping, reads,
writes, cache, clock and final result checks. The old query loop now calls
`_consume_query_value()` using the copy's actual `first_record`. The old final
output loop is an `_emit_outputs()` hook; the experimental executor charges each
output span at its job's completion and suppresses only that final duplicate
pass. Old model/version/costs/targets are unchanged.

Actual zero-cost event kinds are `request_admitted` and `response`.
Signature-bearing details include `job_id`, `query_index`, `repeat_index`,
`query_tile_first` for query work, `output_index` for outputs, and the actual
admitted/response cycle. All batch jobs admit at0; serial job j admits at the
preceding response. The first-request metric is public job0, with unfinished
responses/admissions represented by-1. Full-copy preparation is permitted
before queries; query execution obeys readiness.

Schema rules:

- Exact task/plan/recipe/group keys; query requires kind/fields, allows only
  repeat/indices as optional known keys. Normalization adds explicit repeat1
  and empty-indices=all-records, matching the inherited logical contract.
- Known scenario IDs;64 records max,4 bounded integer fields;8 query specs,
 16 total logical jobs,4096 query/output values,64 supplied indices.
- Copy none/full only, unique copied fields; recipe is validated even while
  inactive so raw dormant choices remain valid/editable.
- Query group1..16 and no larger than actual jobs; serial group must1.
  Record tile1..64. Scratch bound0..4096, with public workload160.
- Structural finite integers normalize JSON integral floats to int and reject
  booleans/fractions/NaN/infinity. A conservative static bound ensures fewer
  than32768 events; no truncation or fake completed result.

Conditions bind normalized full task, experiment model and explicit existing
memory constants/policies. Effective source-only plan identity omits dormant
copy fields/recipe; draft normalization preserves them. Every public
`evaluate()` return, including resource failure, has experimental identities.
Invalid schema returns no run; valid space failure returns actual failed trace.
There are no filesystem/network/autoload/official-result calls.

## Test scope authored; execution pending

The model suite includes144 grid plans (4 workloads, groups1/full where legal,
tiles1/2/4/8/17/64, direct and three full projections) plus:

- Corrected scratch addressing for nonzero query-tile origins and tails.
- Every output versus logical oracle; actual copy/compute/output event counts,
  exact cycles/traffic formulas, stage sums, one response/admission per job,
  chronological clock and unchanged operation durations.
- Independent measured tradeoff receipts:307/2456 versus531/552 for ready scans;
  serial retained copy557/1362/80.
- Sparse earlier response with job0 retained as first-request objective,
  duplicate fields/indices, nonmonotone access order, one-record/tail cases.
- Maximum4096-value output without trace truncation.
- Space failure with-1 responses, retained experiment identity and real error;
  reusing one executor across failure/success and different workloads.
- Strict missing/unknown/invalid nested input, limits, unsupported lifetimes
  and rejected serial fusion.
- Immutable caller inputs, normalized integral JSON round trips, deterministic
  full Trace, insertion-order/locale independence, inactive-copy identity,
  changed data/limits/schedule identity and signature-bearing job metadata.
- Old challenge/design rejection and old VNB4C1 inspector rejecting a forged
  experimental model identity.

Root still needs exact legacy Trace parity and the specified old-model/score/
challenge regressions. The independently repaired discovery probe already
passed per the frozen contract; those numbers are assertions here, not a claim
that this implementation has run.

## Integration notes

The session API already calls public `Model.evaluate()` and matches the result
shape. The internal `Executor.measure()` is only a trusted implementation seam;
public identity stamping lives in `evaluate()`. Independent review was asked to
assess whether to move stamping inside that seam as further hardening.

The first test-file write hit actual `OSError: [Errno28] No space left on device`.
No partial test file existed. Root recovered disk space; the full test file was
then written successfully. No deletion was performed by this agent.

Ownership is released for root verification/integration. Any follow-up source
fix should remain coordinated to avoid overlapping root/reviewer edits.

## Fresh root-run evidence inspected after release

Root executed the isolated project
`.godot/verification/20261105T005513Z-6cc70bb5/project`. I inspected the full three
short result logs:

- `test_layout_strategy_model.txt`:2669 checks,171 measurements,0 failures.
- `test_layout_strategy_session.txt`:35 checks,0 failures.
- `test_layout_strategy_legacy.txt`:3810 checks,141 designs,282 cases,0 failures.

All three name Godot4.7.1.stable.official.a13da4feb. SHA256 equality was checked
for the current shared simulator/model/model-test against that isolated copy;
all three match. This supersedes the earlier “runtime pending” status for these
specific checks only. Root still owns the broader regressions and UI acceptance.
The independent read-only review at
`/private/tmp/vnb-round4-model-review.md` found no confirmed source defect.
