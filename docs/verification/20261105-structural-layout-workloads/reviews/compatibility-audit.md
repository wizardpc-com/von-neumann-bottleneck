# Round 7 persistence and compatibility audit

Reviewer: `/root/review_records_final`. Source-only audit at
`e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8` on
`codex/gameplay-systems-20261104`; read-only Git inspection found a clean
worktree. Main remains `b65a0bd3064888f41c5caeb8d7d0717d2b901658`.
No Godot/native/network operation, source edit, Git mutation or player-profile
access was performed. Only this assigned temporary report was written.

**Recommendation for root's design decision:** add two new fixed workload IDs
under the unchanged simulation and `VNBSC1:` contracts, and use separate
version2 Notebook and challenge sidecars with strictly validated, explicit
copy-forward from the frozen four-ID version1 format. Do not write the six-ID
collection back into either existing version1 file. No present Round6 runtime
defect is alleged here; the risks below are concrete consequences of the
proposed catalog expansion.

The inspected runtime, tests and experiment README establish these couplings:

| Current source | Actual coupling and consequence |
| --- | --- |
| `model.gd:6-7,150-156,189-200,224-226` | Four allowed IDs, current scenario construction and the full normalized task participate in condition identity. Changing data under an existing ID or bumping the model token invalidates old conditions/codes. |
| `session.gd:11-19,37-41,120-139` | Draft, goal, Undo, recent runs, selected run and baseline are indexed by task ID. New independent IDs already obtain independent default states. Checkpoint restoration validates the whole proposal before adoption. |
| `workspace.gd:18-59` | Startup restores inputs, while every snapshot iterates **all** current scenario IDs and emits version1. A normal Save after merely adding two IDs would write six states, even if the player never visits the new workloads. |
| `notebook_store.gd:114-165,169-187` | Version1 requires a known active ID, at most the allowed number of states, known state IDs, exact nested shapes, and current task/model/condition. One bad or stale state rejects the whole file. Drafts may intentionally be unfinished; kept plans must satisfy task validation. |
| `challenge_code.gd:15-79` | Canonical codes contain an explicit task ID, unchanged model, full condition, goal and plan. Decode structurally accepts known tasks; inspect replays only current conditions. Codes contain no stored score authority. |
| `challenge_store.gd:6-9,113-154` | The target file is version1, explicitly limited to four targets, and rejects any unknown outer/inner ID. Supported stale model/condition codes are retained exactly and remain inactive in the controller. |
| `challenges.gd:16-45,78-98` | Proposed and committed maps are separate; persistence emits version1. A cached target is called saved only when the current file exists, storage is unprotected and the proposal is committed. |
| Both stores' `write`, `_disk_unchanged`, `_writer_path` | Digest checks, separate cooperative leases, own temporary files, verified readback and replacement already protect each store. Those checks currently cover only that store's one path, not a future legacy copy source. |

Direct additive version1 is small in line count but does not satisfy rollback
compatibility. The old binary rejects a six-state Notebook at the count/ID
checks; a new active ID fails even earlier. For challenges, a new-ID target
fails the old whitelist even when the map contains only one item; five/six
targets additionally fail the old capacity. The old binary preserves bytes
through read-only protection, but cannot restore the previously accessible
four-condition work. This is a whole-file availability regression, not a claim
that the old store deletes data. Merely filtering the new IDs out on rollback
would require an explicit conversion and could discard new work.

Keeping old conditions writable in v1 while storing only new conditions in an
extra file is another possible design, but it splits the active task/full
workspace across writers and creates merge/exit/save semantics absent today.
It is a larger product contract than one independent v2 Notebook plus one
independent v2 challenge file, and is not the recommended increment.

For v2, use `layout_strategy_notebook_v2.json` with the existing input shape and
`version:2`, and `layout_strategy_challenges_v2.json` with `version:2`. The new
catalog permits six states/targets; the legacy decoder must retain a separate,
literal four-ID whitelist and a four-entry bound. Expanding
`Model.SCENARIO_IDS` must not silently expand what counts as a valid legacy
file. The old v1 payload paths remain read-only copy sources and are never
rewritten, renamed, truncated, cleared or backfilled by the new binary.

The sidecar version is independent from the calculation/code version:
retain `layout-schedule-experiment-1`, `VNBSC1:`, envelope `v:1`, current goal
normalization, transport normalization and plan identity. Add explicit new
scenario branches without changing the old four returned task dictionaries.
Appending IDs rather than repurposing a menu position also minimizes UI/index
drift. New task names and exact catalog content are root's frozen design
decision. There is no need to introduce a VNBSC2 code solely because the
workload catalog grows. Existing codes must remain byte-identical; new-ID codes
will be cleanly unsupported by the old binary.

The following startup precedence is bounded and avoids silent fallback:

| Current v2 payload | Corresponding v1 payload | Behavior |
| --- | --- | --- |
| Valid, including a deliberately empty map | Any state | Use v2 exclusively. Do not merge v1, revive removed targets or let a damaged old file block valid v2 work. |
| Unsupported/corrupt/stale/unreadable/directory | Any state | Protect v2 and show its reason. Never fall back to v1 and then overwrite or bypass the protected current file. Temporary exploration remains possible. |
| Missing | Valid strict v1 | Restore a detached input copy in memory, mark its origin and pending copy explicitly, and write v2 only on a normal explicit save action. |
| Missing | Missing | Fresh defaults; no payload, migration marker or lease is created by reading. |
| Missing | Unsupported/corrupt/stale/unreadable/directory v1 | Protect the copy source, adopt no partial state, and keep exploration temporary. Do not silently treat this as a fresh empty history. A separate “start fresh despite protected legacy” action would be a new decision and is unnecessary for this increment. |

Notebook and challenge selection happen independently. A valid Notebook v2
with only challenge v1 is a supported partial migration; the inverse is also
valid. Saving one never commits the other. There is no combined transaction or
global migration-complete marker.

First-copy implementation needs a small amount of explicit state beyond a
filename change:

1. Preserve the exact source snapshot, including active old task, dormant
   draft copy choices, unfinished but structurally valid drafts, goals,
   names and kept plan order. Restore missing new states to fresh defaults;
   never clone an old run/goal/target into a new ID. Recent runs, Undo, Redo
   and baseline remain session-only. Supported stale challenge codes copy
   byte-for-byte but remain inactive; stale Notebook states retain today's
   whole-file protection.
2. Expose in-memory `origin` (`empty`, `legacy`, `current`) and a
   `copy_pending` flag, or equivalently bounded metadata. Legacy inputs are
   not already saved in the v2 file. Workspace/Challenges dirty and saved
   states must account for this; UI should say that the earlier workspace
   is loaded and explicit Save creates the new-format copy. Do not label a
   migrated target as saved just because its code equals an in-memory map.
   Use the existing independent Save/Retry and exit guard routes.
3. The first explicit save commits the **current proposed inputs**, including
   edits or removals since loading, not a stale original migration snapshot.
   Clear `copy_pending` and update committed/saved state only after actual
   verified replacement succeeds.
4. Guard against the existing no-op branch: both stores currently return
   success when `proposed == _committed` before writing. Simply seeding
   `_committed` with converted legacy contents could make an unchanged
   migration report success without ever creating v2. Suppress the no-op
   optimization while a first copy is pending, including a valid empty
   legacy target map. Test actual v2 file existence and exact bytes.
5. When v2 was initially missing, remember the corresponding legacy byte
   signature (including `"missing"`) until the first successful v2 commit.
   An appeared/deleted/replaced v1 source or newly appeared v2 file must
   refuse the stale proposal and preserve both originals. Check before
   no-op handling, before writing and before replacement. Otherwise the
   existing digest checks only protect v2 and would miss a newer old-format
   writer's update during copy-forward.
6. For a consistent copy from cooperative old/new writers, the first-copy
   save should acquire the old per-store lease and then the new per-store
   lease in one fixed order, recheck both identities, and release both on
   every result. This does not change either v1 payload. Use the current
   `Lease` mechanism and exact existing legacy writer-directory convention;
   do not reuse a profile-wide lock or tie Notebook to target ownership.
   A live/unknown legacy owner means visible busy, not permission to ignore
   it. Track which of the two bounded writer paths blocked the save so
   explicit recovery acts on that path only. Recovery still never saves
   or bypasses a changed source. After first v2 commit, regular v2 writes
   require only the v2 lease/digest.
7. Existing temporary-file/open/readback/rename failure behavior carries
   forward: preserve committed payloads and the precise live proposal,
   release acquired leases, and allow an explicit identical retry where
   appropriate. Orphan or truncated `.tmp.*` files are never installed as
   committed input. Recovering a demonstrably stopped owner is separate
   from saving and must remain conservative on unsupported hosts.

The concurrency recommendation is local cooperative exclusion plus observed
byte checks; it is not arbitrary-editor CAS, a cross-file transaction or a
power-loss durability guarantee. If root chooses a simpler snapshot-only
copy-forward without the legacy lease, that weaker concurrent-old-writer
behavior must be an explicit design limitation rather than described as the
existing write protection covering both files.

Rollback to `e1e27db` then needs no data conversion: the old binary continues
using untouched v1 payloads and ignores v2; returning to the new binary resumes
v2. **Edits made after copy-forward in either version are separate histories.**
In particular, a later rollback edit to v1 must not be silently merged into
an existing v2 when upgrading again. Document that distinction plainly. Retain
both payloads; do not delete v2 during rollback or regenerate v1 from it.

The minimal API surface can stay inside the two existing stores/controllers:
fixed current/legacy filenames and versions, frozen legacy ID list, strict
legacy decode, one detached copy-forward result, origin/pending metadata,
source digest tracking and a bounded blocked-writer selector. Existing
`read/write/recover_writer`, Workspace `save`, and Challenges `retry` can remain
the action APIs. Update their snapshots from version1 to version2 and update
saved/dirty state at the real commit boundary. Avoid a generic migration
registry, arbitrary source paths, background rewrite or dual-write framework.

Tests that already constrain the implementation are useful and should be
extended rather than weakened:

- NotebookStore roundtrip/bounds/protection includes exact dormant choices,
  all32 retained plans, malformed later entries, stale tasks, and whole-file
  byte preservation (`tests/test_layout_strategy_notebook_store.gd:126-318`).
  Its unfinished serial draft with group8 is intentionally preserved while
  the same illegal kept plan is refused (`:183-187`).
- Workspace tests preserve drafts versus selected measured recipes, require
  actual remeasurement after reopen, retain failed proposals, and reject
  stale writers (`tests/test_layout_strategy_workspace.gd:35-125`).
- ChallengeStore tests retain supported stale codes, refuse partial-valid
  malformed maps, protect external appearance/deletion/update, and use actual
  temporary-open/rename/readback failures (`tests/test_layout_strategy_challenge_store.gd:176-379`).
- Controller tests preserve separate Notebook/target saves, exact pending
  clear/replacement, inactive stale codes and truthful saved status after
  conflicts (`tests/test_layout_strategy_challenges.gd:80-161`).
- Both real process probes already establish isolated profiles, separate
  writers and deliberate owned-process crash recovery. Extend them for
  the old-source/current-destination first-copy path, not just another
  same-process object roundtrip.

Root should freeze and execute these additional gates before acceptance:

1. **Old identity gate.** Freeze four full task dictionaries, condition IDs,
   representative canonical codes, plans, expected outputs, every metric
   and complete Trace hashes from `e1e27db` before changing model content.
   Use original golden inputs/results, not expectations regenerated from
   the edited implementation. Verify original four codes re-export exactly
   for both objectives/caps and retain code SHA/challenge IDs.
2. **New isolation gate.** Six distinct conditions; old/new target attempts
   reject cross-condition comparisons; each has independent drafts, goals,
   kept plans, target, transient history/Undo and active-workload restore.
   New 2-job or serial constraints must not clamp preserved old drafts.
3. **Copy gate.** Valid maximal and sparse v1 inputs, dormant choices,
   multilingual names, unfinished drafts, and stale supported target codes
   copy without any v1 byte change. Read creates no payload. First explicit
   unchanged copy, changed copy and clear-to-empty each produce actual v2.
   Reopen reproduces exact inputs and fresh Trace evidence.
4. **Precedence gate.** All startup matrix combinations above, including
   v2 empty after a target clear, only one side migrated, and protected v2
   beside valid v1. One malformed later legacy entry rejects the complete
   legacy proposal; unknown new ID in a v1 file remains unsupported.
5. **Failure gate.** First-copy and later-save open/readback/rename failures,
   exact retries, stale caches, source appearance/deletion/replacement,
   destination appearance/replacement, source change during temporary
   preparation, and no-op conflict detection. Original v1/v2 bytes and
   committed state remain intact.
6. **Writer gate.** Real independent old-source lease contention, current
   destination contention, release/retry, unknown/live/dead owner recovery,
   and unchanged source hash after recovery. Holding either Notebook lease
   must not block a target save, and vice versa. An orphan temporary file
   remains untouched and is never adopted.
7. **Rollback gate.** In one isolated profile, seed strict v1, run new
   copy/save, reopen with the frozen old store/binary, then reopen with new.
   Both versions recover their own correct histories; every v1 payload
   hash is unchanged by new-version operations. Do not use real player data.
8. **Bounds/UI gate.** Verify all48 named plans with40-character Unicode
   names fit128KiB and six maximum supported target envelopes fit32KiB;
   do not raise byte budgets without a measured need. Exercise bilingual
   migration-pending/protected-source statuses, explicit saving/retry,
   correct exit guard and no false saved claims. Existing original/formal
   save and Trace compatibility checks remain required.

An already committed, inspectable legacy fixture exists in
`docs/verification/20261104-layout-replay-challenges/native/20261105T043946Z/`.
Its Notebook contains all four old conditions but no kept recipes, so it is a
useful real-format seed and not sufficient by itself for maximal migration
coverage. Its recorded condition IDs are:

| ID | Archived condition |
| --- | --- |
| `scan_batch` | `d64064a4d64f811516676cf8bc7745e2d81cefe0dc5659be366baafef0ab3e93` |
| `scan_serial` | `81aaabf3e8d0a0e6a12ccea525f8465658af88877c91701098c3b00a298e9311` |
| `mixed_batch` | `9fd4663fc4fe45169065a0b75b6882fb03f82a905b22a8d4403b0a84b93d3c2f` |
| `mixed_serial` | `89ff90bef1d39d8494061d179a9dd7a7fd97696e39e4bc46fddfb713dfe32e5b` |

The same archived target contains a364-byte `scan_batch` starter code with
SHA256 `ffac377a3154bbfba301a4db149edcf4a28f582ae4b476a1659018fa9acb5c6e`.
These values were read from committed evidence, not freshly executed in this
audit. Root remains responsible for the frozen implementation plan, final
policy choice, test execution and evidence.
