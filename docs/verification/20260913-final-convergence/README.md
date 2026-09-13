# Final pre-public convergence — implementation and candidate evidence

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
This was the intermediate stage. Final suite/restart/export results appear below;
final native checks remain open, and this file does not claim release acceptance.

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

## Final source checks

`20260913T153717Z-afafba18`: all 37 conventional Godot suites pass after the
singleton lookup fix. Import and isolated-user-directory probe also pass. The
previous English ordinary Game replay was 633/0; that was before the final
singleton/optional-brand wiring, so it is not a final native acceptance claim.
Python branding contract passes. Source compilation of the packaging scripts passes
with an isolated Python cache (the default macOS cache was sandbox-restricted).

Final native recheck is blocked at the Mac lock screen. CUA reported automatic
unlock paused due physical input; user was asked to unlock. No tool bypass or
fabricated screenshot is used. Post-fix editing/restart and final candidate mouse
checks remain visible acceptance items.

## Frozen candidate

Content commit: `6c5c59df6c26ab3831b00c661c7d9992404fca4e`.
Candidate: `free-alpha-6c5c59df6c26`; subsequent documentation and non-content merge
commits do not rename this immutable content. Both exports use Godot
`4.7.1.stable.official.a13da4feb`. Numeric native versions: Windows `0.5.0.86`, Mac `1.0.86`.

| Platform | ZIP | SHA-256 |
|---|---|---|
| Mac | `Von-Neumann-Bottleneck-macOS-free-alpha-6c5c59df6c26.zip` | `2ad2a649f0b8c3ecdfeb581ba02a57c999ed7aeb6d1b91917969fd5761fcc6f9` |
| Windows | `Von-Neumann-Bottleneck-Windows-free-alpha-6c5c59df6c26.zip` | `a7a73386065ec7f21f427f37c87a727d303c96a60f1de436b9ec161eabd307c6` |

Output directory: `build/free-alpha-6c5c59df6c26/`. Both complete archives pass
`check-candidate-identity.py`: names, full source commit, adjacent manifests, every
file digest and packaged README/change/known-issue notes agree.
`verify-mac-candidate.py` passes against the actual release binary/PCK in an isolated
copy (`.godot/package-qa/19e325ac6511/`). It confirms Game-only operation, no capture
backdoor, 40 tasks, empty/off receiver, excluded development files and exact packaged
Chapter 1/2 workspace fingerprints matching the source build manifest. This is a
release-runtime probe, not a mouse playthrough. Original binary/PCK hashes unchanged.

Final source restart repeated successfully against the final imported project:
writer plus two independent reader processes retain invalid drafts, applied source
and empty wiring without awarding completion.

## Remaining acceptance queue

1. Unlock this Mac, then recheck the fixed completed Chapter 2 capstone with actual
   typing, Apply separation, map/home/restart recovery, pinned Mission footer and
   Chinese/English in-level settings at the minimum window size.
2. Operate the new candidate's tree, Tutorial palette/wires/delete/undo/Hint, quit and
   Continue. Old `47a59d3` candidate mouse evidence does not close this new gate.
3. Run the Windows EXE on actual Windows; another Mac first launch/signing decision,
   external beginners and extended focus/Retina/mixed-DPI sessions remain external.
4. No online endpoint, public release, purchase or identity setup has been performed.

The implementation phases are complete; M5 native acceptance is explicitly open.
Do not interpret suite counts or candidate integrity as proof of newcomer clarity.

## Remote integration record

Git rejected workflow creation with the existing terminal token (`workflow` scope
absent). The already-authorized GitHub connector created the same workflow without
credential changes. Main requires linear history; the rejected local merge and original
stage commits remain on local preservation branches. The three changes were replayed
in order onto remote main and pushed normally. `6c5c59d` has exactly the same Git tree
as previously tested `0758388`; the final candidate was freshly exported with the
new source identity. The earlier local candidate is historical and unchanged.

The initial workflow-only commit ran before implementation files were present and
failed; this is not the final runtime CI result. Final content workflow run:
https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/34766506031

The final content CI run above completed successfully: both Python and Godot jobs
passed on Ubuntu. This closes the first hosted-run check, not native Windows or Mac
input acceptance. All 18 original player-data files still match their pre-update
SHA-256 hashes; no player save was replaced by QA data.
