# Round5 notebook store implementation

Owner `review_records_final` releases these files to root for integration:

- `experiments/layout_strategy/notebook_store.gd`
- `tests/test_layout_strategy_notebook_store.gd`

No other production, test, documentation or shared writer-lease file was changed by this child. No Godot execution, player-file access, UID creation or Git mutation was performed.

## Implemented behavior

- Frozen APIs: `read`, `write`, `normalize_snapshot`, `recover_writer`; result shape is `ok/snapshot/status/reason`.
- Default `user://layout_strategy_notebook_v1.json`, 128KiB total, four known fixed scenarios, eight unique nonblank names per scenario, 40 Unicode characters per name with C0/C1 controls rejected.
- Exact root/state/kept/plan/goal/task validation before accepting any state. Persisted representation must be canonical; duplicate keys, unknown fields, noncanonical numeric spelling and unsupported nested data cannot be silently discarded.
- Full fixed task and current model/condition must agree. Valid older or changed identities protect the entire original file as `read_only/stale`; no partial snapshot is adopted. Unknown schemas, malformed files, invalid UTF-8, oversized files, directories and read failure likewise protect original bytes.
- No saved metrics, score, rank or Trace. Store never simulates. Actual replay remains in Workspace/Session.
- Draft normalization preserves dormant copy choices and structurally valid unfinished drafts. A serial draft with query group8 may persist as editor state, but it is not a measured result. Kept plans additionally pass `Model.validate(task,plan)`; allocation/output authority still belongs to fresh model evaluation.
- All input/returned snapshots are detached. Only successful atomic replacement updates committed memory and disk digest. Failed request returns previous committed snapshot; Workspace retains its separate proposal.
- Each write checks disk digest, obtains the existing cooperative lease, rechecks, writes a unique same-directory temporary file, flushes/checks, reopens and validates exact contents, verifies ownership and original digest, then atomically replaces.
- Lease is scoped through `storage_path + ".writer/notebook.json"`, so `.candidate-writer` is beneath this notebook's dedicated directory. Each write releases its lease. An unrelated candidate profile lock is not touched.
- Explicit stopped-owner recovery uses the existing native context/PID/token checks; it preserves archived owner evidence and changes no notebook content. Recovery releases its temporary lease; subsequent Save separately reacquires/checks.
- Owned failed temporary files are removed only when their name matches this store's exact generated 32-hex suffix. Orphans from other/interrupted writes are never adopted, reused or removed; the main file is authoritative.
- Strict byte validation before UTF-8 decoding avoids replacement of invalid byte sequences. New helper checks overlong, surrogate, truncated and out-of-range encodings; valid Unicode names still round-trip.

## Test coverage authored

The new suite requires a QA `VonNeumannBottleneckChecks` profile and checks:

- Missing/idempotent file, all-four-workload persistence, detached values, dormant settings, exact reopen, actual replay of grouped scan (Q1 531 / total552) and full Trace identity.
- 32 named entries at the maximum 40-character Unicode name length; ninth-per-condition refusal without eviction and valid retry.
- Whole-file malformed root/state/task/recipe/goal/kept matrices, missing fields, partial-valid histories, invalid names, duplicate keys, unknown score fields, canonical numeric/spacing violations, stale identities, six malformed UTF-8 classes, raw-byte preservation and no writer-directory creation on protected input.
- Directory target and injected read-denial path. Read denial is deliberately injection-based, not an actual OS-permission acceptance claim.
- External replacement/appearance/deletion, storage-path mutation, external replacement during temp preparation.
- Actual FileAccess directory-open failure and actual rename-to-nonempty-directory failure, unchanged old bytes/committed state, owner release and identical retries.
- Cooperative writer contention, live-owner recovery refusal, stale reader protection, isolated lock namespace and recovery gate.
- Native-checked synthetic stopped-PID recovery where host support is available; conservative SKIP/refusal otherwise. Real held/killed process acceptance remains root's process harness.
- Interrupted temporary files not promoted to authority, and unchanged GlobalSave/LayoutChapter game state.

## Verification and integration boundary

Static source review completed. `git diff --check` passed for current tracked changes; explicit whitespace/final-newline checks covered these untracked new files and passed. Current source hashes:

```text
2d982321c70a0a1b4b89e418b14cfb3d1154636b9a95556f11eea1b45e40bdca  experiments/layout_strategy/notebook_store.gd
f4db2cff45b39d3dfee96cbbe7669fa6607e224bf386ca3797bd2d93ce4b8a6c  tests/test_layout_strategy_notebook_store.gd
```

Runtime/parse/test acceptance is pending root's Godot run. No pass count is claimed.
`goals.gd` is referenced through the frozen API and is owned by the strategy agent.
The root Workspace implementation observed during integration already retains
pending proposals and uses this store's API. Root process probe already references
`_writer_path`, which is available.

Lease/digest protection serializes cooperating notebook writes; it is not a
power-loss durability guarantee or arbitrary external-writer atomic CAS.
