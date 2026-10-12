# Final pre-release engineering and playtest freeze

Date: 2026-10-12, Asia/Shanghai. Baseline: `cfdee8a`, freshly fetched
`origin/main`; the supplied reference `34aed77` is its ancestor. The shared
checkout was clean before creating `codex/pre-release-20261012`.

## Goal and scope

Make the existing sixty-task candidate suitable for informed human playtesting:
repair concrete blockers and unclear interactions, verify Windows operation and
save continuity, exercise synthetic feedback against isolated VPS staging over
HTTPS, and freeze Windows/macOS packages from one fixed commit.

No new chapters, large mechanics, simulation redesign, save migration, public
endpoint, domain configuration, production intake, main merge, or changes to
other VPS applications. Upload remains optional and statistics consent stays
separate from explicitly sending one opinion. Existing player works and saves
remain protected; tests use dedicated profiles.

## Ownership and affected areas

- Controller: baseline/provenance, execution coordination, private VPS staging,
  final verification, release documents, packages and an unmerged protected PR.
- Gameplay worker: existing `src/`, `experiments/`, localization and related
  GDScript tests; core, Representation/Service, prediction and C/P/G endings.
- Feedback worker: receiver/storage/private reports and related Python checks.
- Build worker: fixed-commit packaging and identity checks, platform portability.

Git mutations and Godot execution are serialized under the controller. Each
coherent verified modification receives a separate commit; substantial changes
are pushed to the feature branch. Exact file ownership and execution status are
tracked in the ignored collaboration handoff.

## Verification sequence

1. Reopen constitution, current state, feedback contract, deployment/runbook and
   known release gates. Run isolated Windows baseline checks and inspect failures.
2. Repair only demonstrated defects; verify affected behavior, persistence and
   deterministic results. Record automated, rendered and native input separately.
3. Windows OpenSSH preflight: permissions, resources, existing listeners/services,
   fixed receiver source. Use separate synthetic staging data and private TLS
   access via SSH. Check actual client receipt/task/build, private report, offline
   queue, retry/deduplication, deletion and tombstone-safe restore. Preserve other
   services and record cleanup; never expose an extra public listener.
4. Run final relevant/full regression, review allowlisted diffs and commit source.
   Export both platforms from that immutable commit with a stable candidate save
   profile. Verify actual identities, package file hashes and complete journey.
5. Operate the Windows EXE, edit/save/restart and exercise feedback. Publish branch
   and PR for review without merging; report external human/Mac/signing gates
   honestly. Update current state and release notes with final evidence.

## Progress and unresolved gates

- Completed within the authorized private/offline scope. Baseline fetched and
  clean branch created; all coherent changes committed and delivered through
  unmerged PR7. No main merge.
- Existing-game Windows audit155/155, code CI and affected Python checks passed.
  Concrete Windows storage, receiver, packaging and Unicode path defects fixed;
  no new mechanism or unjustified content change.
- Both sixty-task platforms frozen at `61edc8063078` with stable CloudPlaytest
  saves, verified inventory/template/file/ZIP hashes and honest package notes.
- Actual Windows EXE passed local HTTP and private VPS HTTPS feedback, same-ID
  private report, offline/retry/dedup/delete and actual tombstone-safe restored
  receiver. Temporary staging stopped; baseline services/history preserved.
- Native Windows tutorial completed through OS input; edited workbench, earned
  progress and local opinion recovered across two independent restarts.
- Public deployment still requires explicit authorization. Current Mac native,
  cross-machine/signing, extended focus/DPI, unassisted full-route and artistic
  acceptance remain open external gates, not incomplete authorized implementation.

Evidence is indexed under `docs/verification/20261012-pre-release/`;
credentials, target addresses, raw synthetic identity tokens and TLS material
stay in ignored private working directories.
