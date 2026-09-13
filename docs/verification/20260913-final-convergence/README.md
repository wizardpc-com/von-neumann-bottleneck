# Final pre-public convergence — in progress

Baseline: `eec34c4`. Godot 4.7.1 stable, local Mac. No public release or live receiver.
The supplied audit is a queue of findings, not proof that every proposal is a defect.
Real player data was copied and hashed before work; all runs use isolated userdata.

## Verified so far

- Separate Chapter 1/2 draft, applied source and configuration survive scene recreation
  and JSON round trips. An intentionally unwired system stays unwired. Test-mode work
  cannot replace Game drafts. Missing legacy workspace fields remain genuinely empty.
- Observations persist as bounded recipes and are recomputed against current model
  fingerprints; drafts do not execute or grant completion. Old model drafts remain
  recoverable and show a review warning. Current models are bound into export metadata.
- Continue skips a locked last-visited task. Existing save migration/downgrade tests pass.
- Real filesystem replacement failure returns failure; an independent recovery JSON
  can be written while protecting normal-save and backup destinations.
- Shared settings preserve local progress, use same-language logo fallback, keep a
  visible footer and reuse existing presentation/consent controls.
- Synthetic report tests consume a 120000 ms summary with 7 connections, 2 wire
  deletes, 1 component delete, 3 debug runs and 2 formal runs. Summary and detail
  coexist without adding the totals twice. Missing measurements remain null; task,
  model, case, build, source batch and background cohort have separate rows.
- Synthetic queue tests reserve opinion space, bound eviction, keep retrying after
  twelve transient failures, and isolate individually rejected records.
- Local community/receiver tests: 5 passing tests, synthetic loopback data only.

Targeted logs: `.godot/prepublic-audit/targeted-1789311506/` and later reruns.
Full final suites, process-restart fixture, export identity and final native checks
are still pending; this file does not claim release acceptance.

## Native source observation

Ordinary Game, copied previously earned QA profile, unique copied engine identity
`local.vnb.finalqa`. Entered Chapter 2 from the normal hub, opened its capstone and
in-level settings, switched to English and returned to the same task with an explicit
restored-workspace status. Settings fit with pinned Resume/Quit controls.

This exposed a real old-save issue: a completed capstone still locked its editor when
no baseline receipt survived restart. Corrected only the already-completed path;
uncompleted first-experiment gates remain. Also moved Chapter 2 Mission actions outside
the scrolling explanation, where the completion button was clipped. Recheck pending.

One CUA app-discovery call stalled for about ten minutes. Mouse navigation subsequently
worked; that stall is tool evidence, not gameplay acceptance. The initial fresh import
hit the documented pre-import font boundary; re-import after font generation succeeded.
Earlier failed tests and corrected expectations remain in ignored diagnostic directories.

## Integrated checks and local lifecycle

Full imported run `20260913T152408Z-c0866939`: 36/37 conventional suites passed,
plus English ordinary Game replay 633/0. The remaining release-convergence suite
exposed a settings script's direct singleton preload dependency; changed it to node
lookup. Targeted rerun `targeted-1789313245` passes release convergence, final UI,
prelaunch settings and transport/summary checks. This intermediate full run is not
reported as an all-green final freeze.

`targeted-1789313414` passes the final queue/summary tests. Three independent Godot
processes preserve invalid draft/applied sources and empty wiring without granting
completion (`workspace-process/0.txt`–`2.txt` in the imported QA directory).

Real synthetic local integrations completed:
- `.godot/community-integration/f3f7481c-14ae-426d-b7f7-b625eba5bc13/`:
  queue/resume, exact duplicate ACK, community and experimental board reads,
  withdrawal, offline deletion and confirmed tombstone after restart.
- `.godot/feedback-integration/f0076aa9-caa0-4954-83df-da23cb2b8a3e/`:
  Godot queue → HTTP → SQLite → private report; one duplicate stays one row;
  a separately sent opinion works with automatic sharing off.
- Python storage: 3 tests; community/receiver: 5 tests, all passing.

All integration identities, notes and metrics are synthetic. No public endpoint,
real player logs, credentials or production database were used.
