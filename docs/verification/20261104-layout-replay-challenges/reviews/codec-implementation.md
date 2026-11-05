# Round 6 challenge codec implementation

Owner `/root/audit_scores`. Implementation ownership accepted from
`.godot/collaboration/round6-implementation.md` and the frozen execution plan.

Status: **ROOT CODEC SUITE PASSED397/0 — OWNERSHIP RELEASED**.

Owned source:

- `experiments/layout_strategy/challenge_code.gd`
- `tests/test_layout_strategy_challenge_code.gd`

Implemented the frozen API:

- `create`, `decode`, `inspect`, `compare`, `starter`.
- `VNBSC1:` inputs only, exact six-key envelope and strict Model/Goals nested
  schemas; 4096 UTF-8 byte cap includes clipboard whitespace. A bounded,
  quote-aware nesting scan precedes JSON parsing. Canonical equality rejects
  duplicate keys, alternate number/key spelling and dormant no-copy variants.
- No-copy export retains scheduling choices but normalizes copied fields/recipe
  to starter defaults without modifying the caller. Semantic array order is
  preserved. Stale model/condition codes decode but inspect returns `stale`.
- Target creation/inspection runs the current actual Model and uses Goals.rank
  to reject incomplete/incorrect/over-cap results. Entries preserve complete
  event, output, map, metric and canonical Trace identity evidence.
- Comparison validates current target code/envelope/challenge ID, bound entry
  recipe/condition, complete evidence shape and Goals.rank eligibility. It uses
  the immutable target goal and exposes a delta only for eligible comparisons.
  This API deliberately consumes successful current inspection + fresh Session
  evidence under the frozen contract; it does not reauthenticate arbitrary
  in-memory scores. Root's current `Challenges.compare` correctly reconstructs
  and identity-checks the attempt before passing an authoritative new row.
- Opt-in source-only starter targets are350/0 batch and600/80 serial.

Error mapping: invalid goal/caps => `limits`; malformed model/condition =>
`format`; unsupported `VNBSC*` prefix => `version`; unrelated/formal prefix =>
`prefix`. Model-token characters follow the existing notebook convention
ASCII33..126, length1..80. Other reasons follow the frozen list.

Meaningful suite covers all four workloads/two objectives, real canonical
Trace/metrics/output repeat equality, no-copy dormant equivalence, advanced
ordered recipes, maximum canonical transport, UTF-8/byte/depth bounds, exact
schema and duplicate rejection, stale identities, inclusive Q1/copy boundaries,
real failed allocation, actual cycle/RAM wins, strict ties, both independent
exclusions, wrong-condition isolation, personal-goal independence, malformed
measurement/target guards and unchanged official progression.

Static verification performed:

- Read complete new source/test and current root controller for API compatibility.
- `git diff --check` passed for tracked changes. Both new files independently
  checked UTF-8, trailing whitespace (none), final newline (present).
- Source226 lines, SHA256
  `9c5cc8efaa4fef6a60e98731bdc0ba54ede9569ec8138dc17f1e4cae9ae08d79`.
- Test377 lines, SHA256
  `ae0dcb1b6b6a8cbd51d6d5288686fd44cae85c5714fe197c70bf1468b307ae1c`.

**No Godot import or suite was run by this agent.** Root should run
`test_layout_strategy_challenge_code` in the isolated4.7.1 QA and inspect its
full result before acceptance. Source and test ownership released for copying,
runtime repairs and integration. No UIDs were hand-created. Other agents' files
and their uncommitted changes were left intact.

Later actual evidence: root ran the codec in isolated4.7.1 QA. I read the full
`headless/20261105T040136Z/test_layout_strategy_challenge_code.log` and
`results.json` under `.godot/verification/20261105T033350Z-75462610/`:
**397 checks,0 failures, exit0**. Controller also passed59/0. Initial Store run
failed and requires its own corrected rerun; this does not imply full feature
or UI/process acceptance.

Earlier read-only follow-up: the parent NEW_TASK payload was encrypted and could
not be read; no new instruction was then present in the readable frozen assignment.
I rechecked current `challenges.gd` and its controller suite plus the store source
without editing them. Controller remeasurement replaces altered cached metrics,
checks full Trace identity and current condition, preserves exact pending targets
across unrelated goal edits, and keeps Notebook storage separate. No actionable
codec/controller API mismatch was found then. The subsequent readable assignment
requested independent controller/process review. That review is now recorded at
`/private/tmp/vnb-round6-controller-review.md`, including a P2 saved-status finding
after detected external conflict. Released ownership remains with root.

Audit wrap-up: both completed physical-layout probes retain the shipped
5/2/7/2 frontier counts. The measured two-scan structure gives a real cycles/
traffic choice, but remains deferred structural research. Full evidence is in
`/private/tmp/vnb-round6-strategy-audit.md`.
