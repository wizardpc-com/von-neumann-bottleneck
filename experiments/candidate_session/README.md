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
creation. The owner records PID, random token and local Linux boot/PID-namespace identity, holds the lease from initial
scene read through all saves/recovery, and releases it on scene exit. Store write
and recovery entry points also require a valid lease (or acquire a short lease
when used directly). A second instance may inspect/edit in memory but cannot save.
Digest conflict detection is an additional safeguard, **not** the lock.

An abrupt kill leaves the lock. Recovery is explicit, never automatic. On Linux,
only a matching boot/PID-namespace identity and absent `/proc/<pid>` permit the recovery button; a live/reused PID,
unknown owner or malformed token is conservatively refused. A separate atomic
recovery gate serializes claimants. Normal acquisition checks that gate before and
after mkdir. The stopped lock is moved into a token-named abandoned directory,
retaining the old owner record. Recovery acquires its new lease before releasing
the gate, avoiding an ownerless interval and competing-reclaimer starvation. Two
independent reclaimers cannot both own it.

Windows/macOS clean acquisition/release use the same Godot filesystem operations,
but this milestone has not verified them natively. Stopped-owner recovery is not
enabled there. A crash while creating an owner record or recovering a lease may
leave an incomplete lock/gate; it deliberately blocks writes instead of guessing.
For such cases preserve the entire profile, close every candidate instance, and
have an operator review the lock before moving it aside. Do not delete game saves
or copy future data over an older profile. Shared-machine/network profile access
is unsupported; foreign/missing boot or PID-namespace identity is refused conservatively, including older owner records.

## Regression evidence

`test_candidate_lifecycle` injects each install stage for first save and overwrite
with an existing backup, retains originals, tests corrupt/future main, stale recovery,
repeat save, independent-process writer exclusion, abrupt kill and two competing
recovery processes. `test_candidate_supports` exceeds both history caps after
successful tasks, saves/recreates scenes, verifies all supported progress and
retrievable plans, keeps unfinished drafts, and rejects forged support completion.
The two existing session suites remain required. Native UI and exported-package
acceptance are separate evidence, never inferred from these tests.
