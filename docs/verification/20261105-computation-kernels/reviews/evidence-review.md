# Round9 final evidence and claim review

Reviewer: `review_records_final`, 2026-11-05.

Read-only scope: final computation receipt, current Round9 status, completed plan,
computation audit, linked invocation/comparison/test evidence, benchmark workflow
construction, and current source/playable manifests. No runtime/test/doc edits,
Godot execution, Git commands, or player-data access were performed.

## Finding E1 — P2: the claimed once-only GPU activation check cannot detect duplicates

`tests/test_creation_workbench.gd:28–37` connects its counter with
`CONNECT_ONE_SHOT`, then asserts `activations[0] == 1`. The connection disconnects
after the first emission. If one injected click emits `pressed` twice, this
counter still observes exactly one, so the assertion passes. This is a test
oracle defect; no duplicate production activation was observed in this review.

The final receipt at
`docs/verification/20261105-computation-kernels/README.md:168–169` describes
“visible/once-activated checks”; the shared handoff more explicitly claims
“exactly1 actual GPU activation.” The existing successful GPU logs establish an
available viewport action that activates at least once, but this callback does
not establish the claimed once-only property.

Smallest correction: retain a Callable, connect without `CONNECT_ONE_SHOT`,
observe the complete injected down/up and subsequent settling interval, then
disconnect if the button remains valid and assert the count is one. Preserve
the existing visibility and failure-exit guards. Re-run the two GPU routes and
the three inherited headless dependents, then refresh the changed test's
source/playable binding and final receipt. Root was notified before this report.
An alternative is to narrow the claim to “at least one activation,” but retaining
a real duplicate-activation check is preferable.

## Verified claims without further actionable findings

- Final comparison artifacts contain 12 workload, 12 memory and 11 circuit
  accepted cases, all `passed:true`, no issues, and parity/timing eligibility
  for each listed case. The additional circuit diagnostic is separately marked
  failed, exits1 on both sides with11 diagnostics/assertions, and the strict
  comparison publishes zero timing cases.
- The receipt's three workflow medians, ranges, rounded ratios and reductions
  exactly match the retained comparison artifacts:
  generation1589.433→401.527ms, public transport395.804→146.000ms,
  Session43.118→34.588ms. The stated5.2% Overlap control slowdown also agrees.
- Actual adapter construction confirms the generation timing includes learning
  and four generation calls (64max,1024weighted,1024max,4096weighted); transport
  includes learning plus both RAW and predictive transport; Session includes54
  recorded transitions,22 commit/reveal pairs, generation, pure profile decode,
  and the underlying strict packet decoding. The docs clearly distinguish
  workflow timings from single-kernel/FPS claims.
- Separate reference/candidate profile records have three samples each at
  lengths64/1024/4096. Recomputed sample medians agree with the published
  comparison. Every4096 sample reports71680 events and338593 modeled cycles,
  with matching output digest and cost/count fields. The document correctly
  attributes full-event differential proof to the separate workload corpus,
  not these digest-only profiles.
- Reference suite results list15 model suites plus import/user isolation;
  their logs contain PASS and no scanned diagnostics. Candidate results contain
  16 Creation suites with the stated kernel1602/contract162/state20/cost40/
  comparison89/Undo68/retry95 assertion counts. The initial snapshot result is
  retained as `passed:false`; its explicit rerun logs PASS10/failures0.
- Final GPU logs103116Z report playable198 and workbench449, with exit0 and
  empty diagnostic lists in actual command records. Headless103343Z records
  playable98/workbench385/choice87. The route loops over both locales and
  exercises save, reopen and exact recipe replay. Native OS input is correctly
  excluded. E1 limits the once-only assertion, not the observed successful
  action or these aggregate counts.
- Python's final archived output reports21 tests and OK. The ordinary isolated
  startup invocation exits0 and its complete archived log has only the engine
  banner.
- Source manifest contains1245 entries:1244 same-byte source/playable files and
  one differing `project.godot`. Every recorded source and QA hash matched the
  actual bytes during this review. The settings diff is exactly the two QA
  user-directory entries. All556 frozen runtime-manifest files match their
  actual reference-copy bytes; current runtime differences are the two intended
  Creation `.gd` files and their contract documentation.
- Actual final invocation records use seven samples, shared fixed iteration
  file, identical engine/options except project path and role label. Diagnostic
  invocations separately use three samples and their one-case filter. Profile
  names are explicitly isolated. All scoped document links resolve locally.

## Scope and acceptance limits

No production correctness defect or measurement-number mismatch was found in
this evidence review. Complete raw/sealed artifact recomputation and byte/log
integrity verification are separately assigned to `audit_scores`; this review
does not substitute a report digest for that check.

The receipt appropriately preserves initial failures, separates finite corpus
parity from arbitrary-input correctness, reports source-identical control
variation, and excludes host heap peaks, native OS input, Windows, exported
builds, newcomer understanding and long-session experience. Dictionary ordering
and alias topology normalization, final-only timed-result checks and separate
process groups are disclosed. Proposed native thresholds remain future design
recommendations.

E1 is the sole requested correction from this review. After its fix and fresh
evidence, the remaining examined claims are appropriately bounded.

## Follow-up disposition

E1 was subsequently fixed and independently rechecked with fresh GPU105418Z
and headless105552Z evidence. It is now closed. See
`/private/tmp/vnb-round9-activation-followup.md` for the corrected helper hash,
exact new counts, archive-byte checks and refreshed source/playable binding.
The original finding above is retained as review history.
