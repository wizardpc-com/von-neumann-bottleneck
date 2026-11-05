# Round 6 codec/controller independent source review

Reviewer: `/root/review_records_final`

Result: **No actionable defect found in the reviewed current source.**

The follow-up task payload was encrypted and no new readable assignment was
present in the Round6 collaboration files. This is a bounded, read-only
cross-review of the released codec and root controller against the existing
frozen Round6 contract. It does not reclaim implementation ownership.

## Scope and findings

Read complete `challenge_code.gd`, `challenges.gd`, both associated suites,
`goals.gd`, and the relevant Model normalization, condition identity, validation
and evaluation paths. The previously implemented store API was checked for
compatibility without modifying it.

- Transport carries only fixed workload identity, full condition, immutable
  goal and strict recipe inputs. Byte/depth bounds precede parsing; canonical
  comparison catches duplicate keys, alternate numeric spellings and dropped
  unknown data. Nested goal/plan types are checked before typed normalization.
- No-copy canonical transport retains actual scheduling choices and normalizes
  only the model's dormant copied-field/layout values. Copied field/group order
  remains semantic. Old supported identities decode but cannot activate.
- Creation and inspection remeasure the unchanged bounded Model, require
  complete correct evidence and enforce inclusive Q1/copy caps through Goals.
  Objective ties do not add an undeclared tie-break.
- `Code.compare` consumes trusted current inspection/fresh measurement under
  its documented internal contract. The public controller boundary reconstructs
  the attempt from its plan, verifies current full condition and full canonical
  Trace identity, and builds a new authoritative row. Mutated display metrics
  are not score authority. Returned/cached target dictionaries are detached.
- Preview has no state or disk mutation. Accept re-inspects the supplied code;
  controller pending proposals survive failed writes independently of its
  committed map. Exact retry does not consult personal goals, draft or selection.
  Pending removal deactivates the current target while preserving disk bytes
  until a successful explicit write.
- Stale retained codes stay copyable and inactive. Controller/store interfaces
  match for empty/protected reads, normal commits, failed writes and recovery.
  Target persistence does not change the Notebook transaction or campaign data.

The associated tests exercise actual winning/tied/behind/outside measurements,
wrong-condition rejection, fake cached metric replacement, Trace mismatch,
incomplete allocation, exact retry after personal-goal changes, stale inputs,
no preview/accept edit-history mutation and one-Undo explicit restoration.

## Verification boundary

This review performed **no Godot run, import, test execution, Git mutation,
source edit or ordinary player-profile access**. The suites were inspected, not
declared passing. Root still owns engine results, cross-process acceptance and
UI/native evidence. This is a local deterministic recomputation review, not
remote anti-cheat or arbitrary modified-client protection.

Current source binding:

| File | Lines | SHA-256 |
| --- | ---: | --- |
| `experiments/layout_strategy/challenge_code.gd` | 226 | `9c5cc8efaa4fef6a60e98731bdc0ba54ede9569ec8138dc17f1e4cae9ae08d79` |
| `experiments/layout_strategy/challenges.gd` | 143 | `39e4c2856b87be0d37e1560d70967be2774027fe621ec888d12c423d45d440da` |
| `tests/test_layout_strategy_challenge_code.gd` | 377 | `ae0dcb1b6b6a8cbd51d6d5288686fd44cae85c5714fe197c70bf1468b307ae1c` |
| `tests/test_layout_strategy_challenges.gd` | 161 | `fbe6a959236c61e96aa44c915c308a38ee946dab99e8afd366dfb59453894e04` |
