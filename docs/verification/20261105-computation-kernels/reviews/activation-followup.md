# Round9 activation check — independent follow-up

Reviewer: `review_records_final`, 2026-11-05. Read-only source/evidence review;
no Godot, Git, production/test edits or player-data access.

**E1 is closed. No additional actionable finding in this bounded follow-up.**

The current `tests/test_creation_workbench.gd` helper retains a normal
`count_activation` Callable, connects it without `CONNECT_ONE_SHOT`, injects
mouse down/up, and waits through the subsequent six settling frames before
disconnecting and requiring `activations[0] == 1`. The observer therefore remains
connected for repeated emissions during the complete tested click interval.
Disconnect is guarded by instance validity and connection membership.
The existing available/visible guards and failure exit are preserved.
Headless behavior still emits once and settles; it is not relabelled native or
viewport-input evidence.

Fresh root-executed verification inspected:

- `.godot/computation-checks/20261105T105418Z/`: actual windowed1280×720 GPU
  invocations for playable loop and workbench both exit0, empty diagnostics;
  complete logs report PASS198 and PASS449 respectively.
- `.godot/computation-checks/20261105T105552Z/`: actual headless invocations for
  playable loop, workbench and choice completion all exit0, empty diagnostics;
  complete logs report PASS98, PASS385 and PASS87.
- Every result/log file in those two original directories matches its archived
  copy under `docs/verification/20261105-computation-kernels/checks/`
  byte-for-byte (three and four files respectively).

The corrected helper SHA256 is
`0a89dfb022d1a593301da71dca85e929316d87803c7115f3c9f2d55c30c1f511`.
Current source, executed QA/playable file and refreshed `source-sha256.json`
all agree. Rechecking the full manifest found no mismatches among its1245
entries:1244 same-byte source/playable files plus the separately recorded QA
settings file. The six measured benchmark `.gd` files still match their recorded
hashes across current source, frozen reference and candidate; this test-only
repair does not alter the earlier timed workloads.

The final receipt now points to105418Z/105552Z, documents the initial one-shot
counter limitation and its fix, and retains the earlier runs. CURRENT_STATE and
the completed plan likewise describe the added duplicate-activation detection
without claiming an observed production duplicate.

This closes the test-oracle gap from
`/private/tmp/vnb-round9-evidence-review.md`. It establishes exactly one
`pressed` emission on each observed selected action during the tested
down/up-plus-settle interval; it does not establish native OS input,
arbitrary delayed behavior, or previously excluded platform/player acceptance.
