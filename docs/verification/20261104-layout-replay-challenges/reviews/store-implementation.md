# Round 6 challenge store — implementation handoff

**READY FOR ROOT RUNTIME VERIFICATION — OWNERSHIP RELEASED**

Owner `/root/review_records_final` has released these files to root:

- `experiments/layout_strategy/challenge_store.gd`
- `tests/test_layout_strategy_challenge_store.gd`

Read the frozen Round6 contract, active replay-challenge plan, current Notebook
store and its behavioral suite. Only the two assigned files and this report
were edited. No unowned source, settings, documentation or UIDs were changed.

## Implementation

The store exposes the frozen `read`, `write`, `recover_writer`, and
`normalize_snapshot` APIs for `{version:1,targets:{task_id:canonical_code}}`,
bounded to the four fixed workloads and 32768 UTF-8 bytes.

Whole-file validation uses `Code.decode`, checks task identity and exact code
spelling, and rejects unsupported or malformed nested content without partial
adoption. Supported stale model/condition identities remain byte-exact and do
not acquire live score authority. Missing files return an empty detached map.
Reading and unchanged empty writes do not create the main target file.

Transactions follow the existing NotebookStore ordering: dedicated
`.writer/challenges.json` lease; digest checks before/under ownership; unique
same-directory temporary file; flush and readback verification; final ownership
and digest checks; atomic rename; committed memory updates only after success.
Failures retain original bytes and committed state for an explicit exact retry.
Recovery only reclaims a demonstrably stopped owner, preserves the abandoned
owner record, releases recovered ownership, and leaves saving to a separate call.
Unrelated or interrupted temporary files are never adopted or removed.

## Behavioral suite

The new suite covers:

- All four workloads, both objectives, canonical save/reopen, detached maps,
  idempotence, explicit clear, and real grouped recipe replay
  (Q1 531 / total 552 with exact events, outputs, and Trace identity).
- Supported stale identities alongside current targets; invalid root/nested
  schemas, future versions, mismatched tasks, claimed scores, duplicate keys,
  noncanonical spelling, count/byte bounds, and six malformed UTF-8 classes.
- External appearance, replacement, deletion, path changes and changes during
  temporary preparation, preserving the main file and last committed snapshot.
- Actual temporary-open failure against a directory, actual rename failure,
  exact addition/removal retry, injected main-read/readback failure, unique
  temporary paths and finished-attempt cleanup.
- Live ownership, stale-reader conflicts, Notebook/candidate namespace
  independence, recovery gate contention, conservative stopped-owner recovery,
  ownership-only recovery followed by a genuinely changed explicit save.
- Interrupted temporary files and isolation from GlobalSave, LayoutChapter,
  the default Notebook and both formal/experimental challenge sidecars.

Read denial/readback denial are injected fixtures. Temporary-open and rename
failures use actual filesystem operations. The stopped-owner fixture uses a
synthetic absent PID with the existing native stopped check, and explicitly
skips the successful-recovery branch if that check is unavailable. Root owns
true separate-process contention, killed-process recovery and restart acceptance.

## Verification and file binding

Static source/API inspection completed against the released codec and current
root controller. No known concrete implementation defect remains from this
inspection. Read-only final Git status preserved all collaborator-owned changes.

`git diff --no-index --check /dev/null` produced no whitespace diagnostics for
either new file (exit 1 denotes the new-file diff). Independent UTF-8, trailing
whitespace, final newline, and CR checks passed.

| File | Lines | SHA-256 |
| --- | ---: | --- |
| `experiments/layout_strategy/challenge_store.gd` | 278 | `15ec81202cefe7b7ff5cc74ac79a392a487a4c49e8fb8c151a0a7705c8b81931` |
| `tests/test_layout_strategy_challenge_store.gd` | 485 | `f136f0642fa0104b828657f3e0b17f9fcf6ed1323c4fff2903cbc56003b18c53` |

**No Godot import, parse, runtime or test execution was performed by this agent.**
No Git mutation, network operation, ordinary player-profile access or UID
generation was performed.

Root should run `test_layout_strategy_challenge_store` with integrated codec
in its fresh isolated Godot 4.7.1 QA checkout, then perform the planned real
process acceptance. The implementation is released, not runtime-certified.
