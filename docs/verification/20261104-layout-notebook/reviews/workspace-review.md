# Round 5 independent Workspace / runner review

Reviewer: `/root/audit_scores`; read-only source review after releasing
Goals/Session. Scope: root Workspace, runner, behavioral tests, separate-process
probe, and the Store interaction. No source edits, Godot execution, Git mutation,
or player-profile access occurred.

## Finding

**P2 — the stopped-writer process phase currently verifies a no-op save, not a
post-recovery data write.** At
`tests/recovery/layout_notebook_process_probe.gd:95-97`, the fresh process loads
the existing notebook, recovers the stopped lease, and immediately calls
`book.save()` without changing any input. `NotebookStore.write()` then takes the
`proposed == _committed` branch at `notebook_store.gd:44`. It does reacquire and
release the cooperative lease, but it never writes/reopens a temporary file or
atomically replaces the notebook. The current assertion wording overstates what
the process test proves.

Before recording actual post-recovery write acceptance, change a meaningful goal
or draft in that recovery process, assert dirty state, save, and assert changed
canonical bytes/clean state. A subsequent fresh read should observe that exact
changed input. If the unchanged-save branch is intentional, label this result
only as ownership reacquisition and retain separate actual-write acceptance.
This is a verification gap, not evidence of a production data-loss defect.

## Source conclusions

No other actionable blocker was found in the reviewed implementation.

- Workspace keeps committed input state separate from its proposal. A failed
  keep/remove save retains the proposal for explicit retry and leaves the Store's
  committed snapshot authoritative for prior disk content.
- Keeping uses the selected measured recipe, even when the live draft differs,
  and reruns the model before retaining it. Named entries survive transient
  history eviction. Remove does not alter draft, selection, Undo, or baseline.
- Reopened/kept rows are real model executions, cached by exact retained recipes
  and full condition. Goal sorting does not create synthetic runs or values.
  Full actual metrics remain available to Goals' completion validation.
- Startup restoration goes through whole-file Store validation and Session's
  atomic checkpoint gate. No saved metrics or Trace become authoritative.
- New/dirty/saved status is explicit: `_has_saved` becomes true only following a
  validated existing file or successful Workspace save. The Store's missing-file
  empty no-op cannot accidentally mark a normal Workspace saved because
  Workspace proposals always contain all four states.
- Snapshot construction temporarily switches only the pure Session selector and
  restores it synchronously; no external UI callback or model execution occurs
  during those switches.
- Root runner inserts the custom QA user directory before engine import and
  starts the notebook scene in the isolated copy. Named layout profiles have
  neither candidate settings nor candidate save/journey flags. Existing named
  candidate routes retain their prior configuration branches.
- The runner rejects malformed profile names, journey use, and legacy replay
  routes before invoking the engine; unnamed runs still receive independent
  UUID-based directories.
- Store digest/lease/temporary-file ordering and Workspace retry separation
  match the stated cooperative-writer contract. No arbitrary external-writer
  CAS, power-loss durability, or unsupported-platform recovery claim follows.

## Verification reviewed / performed

Ran freshly, without an engine:

```text
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_layout_strategy_runner.py
Ran 4 tests in 0.033s
OK
```

The four tests route the actual runner module with mocked engine calls and
temporary source trees. They establish configuration/command routing and leave
the source project untouched; they do not prove Godot startup or real profile
acceptance.

Reviewed the complete Workspace behavioral suite, Store failure/recovery tests,
process probe, runner diff, and QA execution helper. The relevant Godot suites and
actual process phases had not yet produced Round 5 runtime results at this review
snapshot, so no runtime acceptance is claimed here.

## Reviewed fingerprints

```text
ad17a98736147bf9e8db9e420554cecbdd93fa71f5b11d6924e83ed56b25a333  experiments/layout_strategy/workspace.gd
e80cb57a835b86bdb49de1e19bef46278be0ac968a824efe9d232b749bbf35b3  scripts/run-experiment.py
0217bdc5abc3d3d2bcc340877817ef6f270a78f6b67e69dc1a3c9803f4c971d2  tests/test_layout_strategy_workspace.gd
2055b598138ef04198992965cd68479305a5322c2d89b6f5b52af5a363b10701  tests/test_layout_strategy_runner.py
596d2c2d252befafdfeff3985dc52985624b4cbae85e9d27cedc5edfb53dc98f  tests/recovery/layout_notebook_process_probe.gd
2d982321c70a0a1b4b89e418b14cfb3d1154636b9a95556f11eea1b45e40bdca  experiments/layout_strategy/notebook_store.gd
```
