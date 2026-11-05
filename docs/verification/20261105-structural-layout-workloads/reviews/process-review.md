# Round7 process/recovery review

Owner `/root/audit_polish`; **read-only review complete, released to root**.
Reviewed current `tests/recovery/layout_structure_process_probe.gd`,
`.godot/collaboration/run-round7-process.py`, the relevant lease/store behavior,
and frozen e1 Workspace/Challenges APIs. No source edits or Godot runs.

## Actionable finding

**P1 — Fresh-profile lease holder cannot acquire its intended lock.**

`tests/recovery/layout_structure_process_probe.gd:60-66` calls `Lease.new(path)`
without creating the writer path's parent directory.
`experiments/candidate_session/writer_lease.gd:18-20` uses
`DirAccess.make_dir_absolute(lock_path)`; it deliberately does not recursively
create missing parents. Both old and current stores create that parent before
constructing a Lease in their ordinary write path.

The orchestration creates a genuinely new profile and seeds only v1 payload
files at `.godot/collaboration/run-round7-process.py:116-120`. The preceding
old/new reads correctly perform no writes. Thus the first `old-hold-target`
phase has no `layout_strategy_challenges_v1.json.writer` parent, so the lease
cannot be acquired and no ready marker is written. The same issue affects
`hold-current-book`: no Notebook write has yet created its v2 writer parent.
`hold()` will fail its line75 assertion before the intended contention checks.

Minimal fixture correction: in `hold_writer`, assert
`DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir()) == OK`
before constructing the exact Lease. This creates only the explicitly isolated
test writer directory; it should not invoke store.save() or otherwise prewrite
a payload, because doing so would defeat the first-copy conditions.

## Reviewed strengths and boundaries

- Probe uses common zero-argument setup and existing old/new APIs. New metadata
  is accessed only in current-runtime branches. Mutable task/goal values are
  explicitly Dictionary-typed; no new literal-to-typed-array assignment issue
  was identified statically.
- Both old and current code are executed in separate actual processes. Frozen
  legacy runtime sources are compared byte-for-byte against e1 before the
  injected test script. Root `project.godot` currently has no diff from e1.
- Ready marker PID is matched to the owned Popen child and its expected
  project/phase command. Deliberate termination targets that still-live owned
  process; the fixture checks SIGKILL exit and retains its log. It does not kill
  arbitrary Godot processes.
- Live source contention is exercised on the **target v1** writer. Live
  destination contention is exercised on the **Notebook v2** writer. Recovery
  first attempts a real changed save, proves stale ownership remains blocking,
  explicitly recovers, checks recovery did not save, then performs the actual
  changed retry.
- Source target recovery writes the new pair target; Notebook recovery writes
  a different new-condition goal, copied draft and kept recipe. The actual
  recovered pair measurement must improve the existing RAM target by44 bytes.
- Expected snapshots, kept metrics and target canonical full-Trace hashes are
  remeasured and compared across new-runtime restarts. Transient runs/Undo are
  expressly absent on reopen.
- Frozen old runtime then reads the untouched v1 payloads, writes genuinely
  changed v1 histories, reopens them, and the current runtime must still read
  its previously saved v2 histories unchanged. Python also checks raw original
  and current bytes at the relevant boundaries.
- The expected fourteen result entries include twelve completed verification
  phases and two deliberate owned-writer crashes; the count is correct.
- A separate empty profile verifies isolation and absence of payload creation.
  The probe checks in-memory formal progression before/after each phase.
- Python orchestration passed `ast.parse`; no execution performed.

Runtime remains necessary to establish both-runtime GDScript parsing and all
claims above. This process test covers the two explicit store/path combinations
listed, not all four combinations; store unit/upgrade suites cover broader
source/destination behavior. It does not establish exported-package,
cross-platform or power-loss acceptance.

After the parent-directory fixture correction, no additional actionable issue
was identified in this bounded static review. Please retain any first failed
attempt and run all phases freshly.
