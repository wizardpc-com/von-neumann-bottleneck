# Candidate lifecycle protocol

Applies only to representation and service candidates. No campaign save, core40
progression, simulation model, acceptance budget or telemetry contract changes.

## Successful evidence and compatibility

Candidate schema2 adds `supports`: at most one `{task, plan}` per existing task.
A representation plan is evaluated against **every** authored order together.
Services re-evaluate the complete plan and quality/resource contract. These snapshots
are deep copies and are independent of the most recent 100/80 runs and live drafts.
The UI can restore a protected plan without editing its original evidence. Nothing
serializes an authoritative completed/unlocked boolean. Structurally legal but
unsuccessful supports grant no progress.

Schema1 remains readable. Existing retained successes populate support snapshots;
only an explicit save writes schema2. Already-evicted schema1 successes cannot be
reconstructed. Original schema1 bytes are archived before replacement. Older code
refuses schema2 rather than silently stripping supports. Unknown fields, future
schemas, changed models/contracts remain refusal, including a future main with an
older readable backup.

## File transaction and explicit recovery

Each install writes and validates an independently named `.tmp.<random>` sibling.
Before moving the main or previous backup it copies their exact bytes to a unique
partial archive, checks the hash, then installs `<save>.snapshots/<sha256>.json`.
A damaged preexisting hash-named archive is quarantined intact before retrying. Backup replacement
moves the previous backup to a unique archive name, avoiding overwrite-rename
assumptions. Main then becomes `.bak`; validated temp becomes main.

A missing main with surviving backup/temp is never a fresh profile. Corrupt main
or an unfinished temp alongside a valid main exposes explicit snapshot choices
(main, previous save, interrupted install) with task and digest. Choosing a snapshot
checks that **all** disk transaction members still match the displayed fingerprint,
preserves each original, leaves a valid recovery temp throughout cleanup, then
installs the chosen bytes. Further saves work normally. Edits made while blocked
require confirmation before recovery replaces that window's unsaved exploration.
No future main is bypassed. Unreadable/unknown candidates are never offered as valid.

Snapshots are not automatically deleted. Disk usage grows with distinct saved
versions; no unrequested retention policy is introduced. Recovery preserves raw
originals, not just parsed/re-encoded values. This protocol targets process
interruption on local filesystems. Godot flush/rename are **not** a claim of OS power-
loss durability or filesystem/directory fsync, nor network-filesystem guarantees.

## One writable instance per profile

All candidate writers in the same directory share atomic `.candidate-writer/`
creation. The owner records PID, random token and local boot/process context, holds the lease from initial
scene read through all saves/recovery, and releases it on scene exit. Store write
and recovery entry points also require a valid lease (or acquire a short lease
when used directly). A second instance may inspect/edit in memory but cannot save.
Digest conflict detection is an additional safeguard, **not** the lock.

An abrupt kill leaves the lock. Recovery is explicit, never automatic. On Linux,
only a matching boot/PID-namespace identity and absent `/proc/<pid>` permit the
recovery button; existing Linux owner records retain their exact context format.
On macOS, `/usr/sbin/sysctl -n kern.bootsessionuuid` supplies a validated UUID,
stored as `macos:<uuid>` in the same existing context field. Only that matching boot
identity and a successful `/bin/ps -axo pid=` snapshot without the owner's PID
permit recovery. The snapshot must include the querying process's own PID and
contain only canonical PID rows. These native commands run directly without a
shell, PATH lookup or privilege changes, and collect no command lines. The boot
UUID is provided by [Apple's kernel](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_sysctl.c);
the all-process flags follow [Apple's ps manual](https://github.com/apple-oss-distributions/adv_cmds/blob/main/ps/ps.1).
A failed query, live/reused PID, unknown owner or malformed token is conservatively
refused. A separate atomic
recovery gate serializes claimants. Normal acquisition checks that gate before and
after mkdir. The stopped lock is moved into a token-named abandoned directory,
retaining the old owner record. Recovery acquires its new lease before releasing
the gate, avoiding an ownerless interval and competing-reclaimer starvation. Two
independent reclaimers cannot both own it.

Windows clean acquisition/release uses the same Godot filesystem operations;
stopped-owner recovery remains disabled there. Native macOS process interruption
is covered by the lifecycle suite; running and recording it is required before
claiming verification for a particular build. A crash while creating an owner
record or recovering a lease may
leave an incomplete lock/gate; it deliberately blocks writes instead of guessing.
For such cases preserve the entire profile, close every candidate instance, and
have an operator review the lock before moving it aside. Do not delete game saves
or copy future data over an older profile. Shared-machine/network profile access
is unsupported; foreign/missing boot or process identity is refused conservatively,
including older macOS owner records with empty context and records from previous
boots. Such records require the same operator review rather than automatic recovery.

## Regression evidence

`test_candidate_lifecycle` injects each install stage for first save and overwrite
with an existing backup, retains originals, tests corrupt/future main, stale recovery,
repeat save, independent-process writer exclusion (including a sibling PID probe),
abrupt kill and two competing recovery processes on Linux/macOS. It also checks
unknown/native-query refusal and exact preservation of abandoned owner records.
If the host denies native identity or process queries, the suite verifies refusal
and byte preservation and prints an explicit `SKIP` for stopped-owner/race recovery;
a passing run with that skip does not establish native crash recovery.
`test_candidate_supports` exceeds both history caps after
successful tasks, saves/recreates scenes, verifies all supported progress and
retrievable plans, keeps unfinished drafts, and rejects forged support completion.
The two existing session suites remain required. Native UI and exported-package
acceptance are separate evidence, never inferred from these tests.

Mac lifecycle ran without a capability skip in the corrected frozen-source check;
see [exact integration evidence and limits](../../docs/verification/20261005-mac-second-act/README.md).

## Normally released writer — 2026-10-06

A refused window can explicitly Recheck writer ownership without losing its
live draft, measurements or protected successful plans. Ordinary lease creation
is retried; no owner is deleted or reclaimed. The disk must be safely readable
and its digest must still match the version originally read by this window.
Changed or unreadable files stay protected. Reload saved candidate profile uses
the existing unsaved-work confirmation and checks the new disk version while
holding ownership before replacing this window's exploration. Cancel keeps it.
This does not migrate schema, grant campaign progress or promise power-loss durability.
Focused checks: test_candidate_writer_retry and test_candidate_writer_retry_ui.

## Confirmed complete reload state — 2026-10-06

After confirming replacement, Representation and Service initialize task, draft
and selections before reading the chosen saved profile. A smaller Representation
snapshot cannot inherit a block index from the discarded larger draft. An empty
profile displays the actual initial plan rather than leaving unsaved exploration
marked clean. Service clears the discarded event/pinned comparison as well.
Normal writer retry still retains the exploration; only confirmed Reload/recovery
uses this replacement path. No schema changes or writes to empty profiles.

## Named player designs

Both second-act domains expose a collapsed My designs collection beside measured
history. Keep captures the selected actually executed plan, independent of unrun
draft edits. Up to24 task+plan identities can be named (1–48 trimmed characters,
no control characters); keeping the same identity renames it. Collections survive
the100/80 rolling-history limits. Copy restores a detached task draft with existing
Undo, never measured results or completion authority. Remove and naming are local
unsaved edits protected by the existing leave guard; use explicit Save to persist.

Candidate schema3 adds only validated designs{task,plan,name}, retaining supports.
Schema1/2 remain readable with an empty collection; saves without designs keep
schema2. Previous candidate binaries reject schema3 safely; open a new candidate
with its own profile when comparing versions. Existing transactional snapshots,
digest checks, future-format refusal and writer leases still govern all writes.
No production migration, model/version change, workshop or sharing feature.
