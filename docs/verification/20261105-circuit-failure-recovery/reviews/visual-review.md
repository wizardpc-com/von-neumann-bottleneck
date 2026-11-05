# Round10 failed-playback caption — independent review

Reviewer: `review_records_final`, 2026-11-05.
Read-only follow-up to `.godot/collaboration/round10-recovery.md`.
No production/test/document edits, Godot/native execution, Git operation or
player-data access were performed. Reports and evidence verification helpers
were written only under `/private/tmp`.

## Result

No actionable source defect found in the bounded caption patch or revised
host regression. Fresh headless evidence confirms the targeted regression
changes from two failures to zero. Final GPU execution and replacement
captures have not yet been independently inspected at this report point.
The earlier bilingual 144-check runs and their six frames are explicitly
pre-caption-fix evidence.

Current reviewed source:

- `src/hardware_foundations/hardware_foundations.gd`:
  `abb7d470271ebadd80618c183c31cb15e537b9771e94666754065939bf273ba3`.
- `tests/test_hardware_failure_recovery.gd`:
  `88170ef898b86d36d012996463782c381a3610c0f99dadeb0ece5e28bbf46b4c`.
- Shared simulator remains:
  `3ed8eb32b91b9b7b00fcd9a5b8fa7c25f0095e9c561389632b448e2b51723462`.

All three currently match the candidate QA project at
`.godot/verification/20261105T112607Z-5880555a/project`.

## Observed pixels and their meaning

Actually viewed all six original 1280×720 captures, three each in Chinese and
English: failed conflicting drivers, corrected live HOLD, recovered Debug
HOLD. Independently hashed them and confirmed exact byte matches to the copies
preserved under
`docs/verification/20261105-circuit-failure-recovery/diagnostics/initial-frames`.
The original-frame hashes and dimensions are retained in
`/private/tmp/vnb-round10-frames-before-caption-fix.json`.

The failed Debug frames show observed Q3 alongside `Stored Q=0x0` / `已存 Q=0x0`.
The real register already holds3, and the failed step has no storage boundary
that could legitimately change it. This is a stale presentation caption left
when a previous WRITE animation was interrupted before showing its boundary.
It is an actual presentation defect, not a failure of the newly repaired
simulation carry.

The early corrected-preview frames also show source B6 while the editor has
been changed to0. At that exact capture point, the new preview animation is
still at its first wave and has not yet displayed the source event. That
initial frame does not prove a second stale-state defect. The right test is to
advance the genuine source batch and then require the displayed sources to be0,
while preserving actual storage3 and the authoritative preview result.

The recovered Debug frames show inputs0, Q3 and stored Q0x3, consistent with
the new HOLD. Header/footer long text uses the existing clipped/ellipsis
layout; these captures do not establish broader layout, native-input or
newcomer acceptance.

## Patch and regression reasoning

The entire production host diff against the frozen Round10 reference is the
condition and explanatory comments at `_play_prologue_events()`, currently
lines8360–8363. Component captions are now prepared when the event list has a
state transition **or the final result is electrically invalid**.

The added branch uses the report's real `initial_runtime_state` and
`initial_prior_outputs`. Both Debug and incremental official-case callers
already provide these maps. The only caller using default empty maps is the
valid live-preview animation path; it cannot enter the new invalid-result
branch. Therefore the correction cannot erase established storage or latch
captions during an ordinary valid preview.

`_prepare_component_playback_state()` modifies presentation dictionaries and
labels only. It does not write simulator runtime, carry, result/error/event
objects, completion or saved content. Its previous state-transition behavior
is unchanged, including post-commit failure playback. Current valid/invalid
result authority remains with the simulator.

The revised test first verifies the failed Debug caption and its idle copy
against the localized representation of real register value3. It then uses
the actual Pause/Step controls on the corrected preview and requires one
existing batch advancement, unchanged runtime/carry/full result/events,
displayed A0/B0 and retained caption3. This checks a completed source-wave
state rather than manufacturing source pixels or requiring zero animation
delay. The original failure, recovery, isolation and no-completion assertions
remain intact.

## Fresh regression evidence

Independently read the recorded invocations and complete logs and recomputed
every log SHA256:

- `.godot/circuit-recovery-checks/20261105T113442Z`:
  strengthened host test hash `88170ef8…`, repaired simulator `3ed8eb32…`,
  **142 checks / 2 failures**, exit1. The two failures are exactly the failed
  storage caption and the caption beside the completed corrected source wave.
  No script/parse error or warning is present.
- `.godot/circuit-recovery-checks/20261105T113619Z`:
  the same strengthened host test reports **142 checks / 0 failures**, exit0.
  Six related suites also exit0 with PASS markers and no diagnostics:
  Hardware foundations UI, Hardware prologue UI, prologue continuation,
  Hardware workspace entry, Hardware seal navigation and GlobalSave.
  All seven complete logs match their recorded hashes.

The full earlier candidate verification contains **13 distinct test suites**,
plus import and user-directory isolation checks, not14 test suites. Its pure
recovery suite reports308/0; its earlier host suite reports128/0. Those earlier
host results do not substitute for the strengthened test above.

Separately, the read-only artifact verifier at
`/private/tmp/vnb-round10-evidence-verify.py` reproduced the successful
eleven-scenario comparison and checked four raw/sealed benchmark sets,
24 original serialized snapshots, raw/log hashes and process outcomes.
Its saved JSON records that earlier source binding; the current host/test
revision above is subsequent and is covered by this follow-up. The simulator
and benchmark harness hashes did not change. Changed failed/recovered
diagnostics are rejected as a timing comparison; no speed claim is made.

## Remaining acceptance boundary

Root owns the final GPU reruns and current source manifest. Fresh bilingual
GPU logs and final frames must show the corrected captions and completed
preview source wave before closing visual acceptance. Neither source review
nor headless/GPU automation establishes native OS input, exported packages,
Windows, ordinary player data, long sessions or player comprehension.
