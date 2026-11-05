# Round5 independent notebook Store review

Reviewer: `audit_polish`. Read-only review requested by
`.godot/collaboration/round5-implementation.md`. No production/test edits,
Godot executions, Git mutations, ordinary player-profile access or new runtime
acceptance were performed.

**Conclusion: no actionable blocking defect found in the agreed Store contract.**
The implementation protects complete malformed/stale files, separates pending
proposals from committed inputs, serializes cooperating writers, and keeps its
lease separate from the other candidate stores. The remaining limits below are
acceptance boundaries rather than claims of broader durability.

## Source and evidence examined

Read the complete current versions of:

- `experiments/layout_strategy/notebook_store.gd`
- `tests/test_layout_strategy_notebook_store.gd`
- `experiments/candidate_session/writer_lease.gd`
- `experiments/layout_strategy/workspace.gd`
- Relevant task/plan validators in `experiments/layout_strategy/model.gd`
- `scripts/run-experiment.py`, `tests/test_layout_strategy_runner.py`
- `tests/recovery/layout_notebook_process_probe.gd`
- The frozen implementation contract and
  `docs/exec-plans/active/layout-notebook-20261104.md`

Read the complete Store log and the accompanying result manifest:

`.godot/verification/20261105T021829Z-18f99d78/headless/20261105T024509Z/test_layout_strategy_notebook_store.log`

`.godot/verification/20261105T021829Z-18f99d78/headless/20261105T024509Z/results.json`

That root-run observation is **414 checks, 0 failures, exit0**, with no diagnostics
in the Store log. It used the manifest's isolated
`VonNeumannBottleneckChecks/20261104-round5/20261105T024509Z/test_layout_strategy_notebook_store`
profile. The full batch also records the initial Workspace fixture failure;
the Store pass is not a claim that that entire batch passed.

Current source and current QA copy match by SHA-256 for all five checked files:

```text
2d982321c70a0a1b4b89e418b14cfb3d1154636b9a95556f11eea1b45e40bdca  experiments/layout_strategy/notebook_store.gd
f4db2cff45b39d3dfee96cbbe7669fa6607e224bf386ca3797bd2d93ce4b8a6c  tests/test_layout_strategy_notebook_store.gd
91e52933869024d37c3a7361599a2040b78689b37f073da9f319b0039410f1bc  experiments/candidate_session/writer_lease.gd
8c980ac8a9e09fd4a491d3cf392a267cd64108550af77cf54bd95a0f2b36b23f  experiments/layout_strategy/model.gd
61dc805b8cec1fd4bc19a16cd1191021f0b467cb2f6c40ad972471a75e174abb  experiments/layout_strategy/goals.gd
```

This identity check binds the reviewed files to the current QA copy; the full
original Store log/result supplies the test observation. `git diff --check`
also returned exit0; no diff or status was changed by this review.

## Whole-file validation and preservation

Store lines114–166 validate the exact root/state/kept schemas and delegate full
bounded task/plan/goal validation to their authoritative pure helpers. Unknown
score fields, nested extras, malformed types, duplicate names, unsupported
versions, excessive collections and invalid names are refused. Drafts preserve
structurally valid unfinished choices by design; kept plans additionally pass
condition-level `Model.validate`. The Store does not promote their output to a
valid score. Workspace remeasures before keeping and whenever constructing kept
rows (`workspace.gd:90–108,120–141`).

The full task snapshot, model and condition are checked against the current fixed
scenario. One stale state rejects the whole proposal/file rather than adopting
unrelated valid states (`notebook_store.gd:121–131,157–166`). Loading commits only
after complete decoding succeeds (169–187). A failed initial load leaves the
snapshot empty, and protected state blocks both write and recovery (24–27,85–88).

The 128KiB byte cap, complete-byte-read check and explicit UTF-8 validation run
before parsing (190–207,263–283). Exact canonical equality after normalization
(210–216) additionally prevents duplicate-key acceptance, silently discarded
fields/defaults and alternate JSON spellings from being overwritten as though
they had been originally authored in the supported format.

Tests exercise whole-file partial-valid/malformed/stale cases, duplicate keys,
Unicode boundaries, actual directory targets, injected read denial and six bad
UTF-8 classes. They assert old bytes and lack of a newly created lease directory,
not merely a returned error.

## Commit, retry and concurrency ordering

The write ordering is coherent (`notebook_store.gd:24–82`):

1. Require the originally loaded path and disk digest, validate the full proposal.
2. Acquire the dedicated cooperative lease and recheck the digest.
3. Permit the identical-committed-state no-op only after those checks.
4. Create a unique sibling temporary file, write/flush/close, reopen and validate
   its exact canonical bytes.
5. Recheck lease ownership and disk digest before replacement.
6. Update `_committed` and `_disk_signature` only after replacement succeeds.

Failure exits release their lease and return the detached old committed state.
Write/busy/replace failures remain retryable with the caller's current proposal;
an external byte change or storage-path change becomes protected read-only
(219–227,316–333). Workspace retains its live pending draft/goals/kept inputs and
only advances its own committed comparison snapshot on success
(`workspace.gd:67–77,105–108,110–117`).

Cleanup is constrained to the generated temporary prefix and 32-hex token
(`notebook_store.gd:236–245`). Existing orphan temporary files are not read as
authority or cleaned up opportunistically. Tests verify this and use actual
open-on-directory/rename-to-nonempty-directory failures, exact retries, lease
release, a late external update during temporary preparation, stale readers,
ordinary contention and the recovery gate.

## Namespace and stopped-owner recovery

`_writer_path()` places the shared helper's `.candidate-writer` inside
`<notebook-file>.writer/`, rather than sharing the surrounding candidate profile
lock (`notebook_store.gd:230–233`; `writer_lease.gd:44–45`). The Store test holds
an unrelated candidate lock while successfully saving the notebook and checks
that the unrelated lock survives.

The launcher validates names, assigns
`VonNeumannBottleneckChecks/layout_strategy/<safe-name>` in the copied
`project.godot` before import/startup, and avoids candidate flags/settings on this
route (`scripts/run-experiment.py:22–27,47–68,95–101`). The lab refuses an ordinary
profile before `workspace.setup()` (`lab.gd:79–100`). Store itself remains a
path-injectable storage component; the launcher and lab are the product-level
profile boundary. Its current production call path respects that boundary.

Recovery checks the original digest before inspecting ownership, uses the shared
gate/token/context/PID protocol, verifies the recovered lease, rechecks the digest,
then releases ownership without saving (`notebook_store.gd:85–106`). Live/unknown
owners remain untouched; abandoned owner evidence is retained by the helper.
The Store log contains no recovery SKIP line, so its synthetic stopped-PID
supported-host branch ran. That is narrower than a real killed-process check.

## Remaining evidence boundaries

- Root's corrected separate-process probe now changes Q1 from557 to558 and checks
  changed disk bytes before the following reopen. That previously reported
  no-op-fixture gap is fixed in source and is **not an unresolved finding**.
  I did not read a completed current-round process result during this review and
  therefore do not claim real-process restart/contention/recovery acceptance.
- Read-denial is injection-based. Temporary flush/short-write corruption and
  ownership-loss-after-temp-validation branches were statically reviewed, not
  directly fault-injected by the Store suite.
- The lease is cooperative. Digest checks do not provide an atomic compare-and-
  swap against an arbitrary external writer racing after the final check.
  No power-loss/directory-fsync durability guarantee is established.
- The shared helper intentionally refuses unknown/incomplete ownership and
  unavailable platform checks. A lock with missing metadata or an unsupported
  context is protected rather than silently reclaimed. The supported same-boot
  recovery observed here does not establish recovery on Windows or after reboot.
- No native-input, exported-build or other-platform acceptance follows from this
  Store review or the macOS isolated headless result.

All production and test ownership remains with root. No further change is
requested from this independent review before root's planned integration checks.
