# Candidate lifecycle and representation journey

2026-10-04; baseline `6709dda235f1d368b6d12353c4ef054cedd4380f`.

## Scope and authority
Close audit A01–A03, then the existing five-task representation entry/play/compare/save/restart/closure journey. Preserve model contracts, all valid solutions, core40 saves and endings. No new domain, release, main merge, VPS change, online collection or human-study claim. The owner's audit explicitly requests a small candidate protocol correction; the format/migration plan was reported before implementation.

## Decisions
- Candidate schema2 adds per-task supporting plans independent of bounded recent history. Recompute all support against current contracts; never trust completion booleans. Read schema1; migrate only on explicit save, keeping old bytes.
- Shared candidate file protocol reports interrupted transactions and corrupt mains with explicit recovery choices. Preserve original bytes in content-addressed local snapshots before replacement/recovery. Future/unknown main formats remain refusal. Unique temporary paths; never interpret surviving backup/temp as a new profile.
- Filesystem atomic directory lease spans scene lifetime and store read/write/recovery. Second writer refuses. Explicit stopped-owner recovery, conservative refusal for unknown owner/alive PID; no automatic stale deletion. No network listener or dependency.
- Test fixtures use isolated profiles. Desktop input is coordinated separately; no concurrent native control.

## Verification plan
Targeted schema/immutability/history-cap tests; install-stage interruptions and recovery; two-process exclusion including abrupt termination; legacy/future compatibility. Full repository Python and isolated Godot gates on final code. Freeze implementation for independent review/native input before committing; verify exact remote SHA and CI afterward.

## Progress and open bounds
- Audit and constitution read; clean checkout and remote baseline verified.
- Implementation underway. Windows/macOS filesystem behavior, power-loss durability, novice understanding and listening acceptance remain unverified unless separately tested. Deployment templates are an independent responsibility and excluded from game acceptance.

## Final implementation and review
- Candidate schema2 support snapshots, schema1 read/explicit-save migration and protected-plan retrieval implemented without model/acceptance changes.
- Explicit interrupted/corrupt snapshot choice, original-byte archives and profile-wide filesystem lease implemented. Independent reviewer reproduced partial archive and recovery-acquisition liveness counterexamples; both repaired and independently rechecked. In-window save failures now expose recovery without losing memory state.
- Opt-in `--journey` enters the normal hub's isolated representation card, returns home with an unsaved guard and closes through a five-task review using current support costs.
- Final automatic gates `20261004T112039Z-f648052f`:62/62, plus all required Python commands. Detailed source hashes and raw logs are retained under `docs/verification/20261004-candidate-lifecycle/`.
- Native cloud Linux actual-input journey completed: all five tasks, region review, save, Home, clean Exit/relaunch, six records/all five checkmarks and protected-plan recovery. No native blocker observed. Source-run build/publication identity and exact-SHA CI are checked after committing, separately from this native evidence.
