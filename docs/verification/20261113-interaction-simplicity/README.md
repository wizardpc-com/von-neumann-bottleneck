# Interaction simplicity, first milestone — 2026-11-13

Base: `main` `239de25be911d44dc0daddf63e698b60e0bbc61b`.
This is an incremental source improvement. The
[whole-chapter goal](../../exec-plans/completed/chapter-interaction-simplicity-20261113.md)
remains active; it is not whole-product or novice acceptance.

## Behavior

- During official prologue playback, unmodified F5 performs the advertised Step.
  Explicit **Show all results** skips presentation waits, still evaluating every
  original case and revealing its actual verdict. Cancellation invalidates deferred
  callbacks, so an old run cannot consume a replacement run. No automatic sealing.
- Layout preserves an entered, unsaved scheme name through edits, Undo/Redo, Run
  and A/B inspection. Rebuilding a focused editor retains caret/selection without
  taking another control's focus. Successful Save or changing tasks clears it.
- Compression/prediction guidance distinguishes changed examples/history from
  learned rules. Learn remains explicit. Still-valid unsaved generation takes
  priority: return to creation and Keep before learning. Old measurements, saved
  works and closure remain available; invalidated generation is never resurrected.

No simulation model, cost, progression threshold, persistent format, dependency,
or final visual direction changed.

## Verification

Godot `4.7.1.stable.official.a13da4feb`, macOS / Apple M2 OpenGL.
Candidate: `.godot/verification/20261113T115407Z-03a544bc/project`.
All engine runs use separate `VonNeumannBottleneckChecks/` profiles.

The [initial candidate](candidate-initial-results.json) imported successfully and
passed19 of20 selected suites; the new Hardware test helper failed, as documented
below. Its corrected test and final runtime passed the
[final three-suite run](final-headless-results.json): Hardware531 checks,
Creation124, Layout50. The [adjacent rerun](final-controls-guidance-results.json)
also passed prologue/settings/sealing and Creation resume/workbench/future/ending
checks, except its superseded Hardware helper. Across these runs, all20 distinct
selected candidate suites have passing evidence; this is not a full regression.

GPU results: [Hardware Chinese](gpu-final-zh-results.json),
[Hardware English](gpu-final-en-results.json),
[final bilingual Creation](gpu-final-guidance-results.json), and Layout's passing
entry in [the first GPU batch](gpu-zh-results.json). Hardware536 checks per locale,
Creation180, Layout50. Ten final1280×720 frames are in [the image manifest](images.json),
inspected by root and an independent reviewer. Creation waits for the real opening
line to retire normally; no layer is hidden or image resized. This is fixture-driven
GPU/viewport evidence, not native mouse or keyboard acceptance.
Three Creation frames still show the short completion notice over chapter chips
(Chinese history, English examples/history); it does not cover Learn/Keep guidance.
These are verification frames, not cleaned promotional screenshots.

Five [baseline audit suites](baseline-results.json) separately passed: laboratory
modes/routing, completed-task detail, Prediction record sources and Service undo
context. Historical documented Prediction/Service failures did not reproduce.
They are not newly fixed defects or final-candidate acceptance for those chapters.

Three old-runtime negative controls reproduced F5 (1 failure), name loss
(18 failures) and stale learning guidance (8 failures). Original minimal tests and
their complete logs are retained. The final tests subsequently gained broader
state, focus, output-priority and rendering assertions.

## Failed attempts retained, not counted as passes

- The initial Hardware helper accessed `error_specs` on `DigitalValue`. A later
  helper read inactive freed label arrays. Both failed, even when a PASS line or
  exit0 appeared. Explicit typed snapshots and current-level row collection fixed
  the helpers; final531/536-check runs contain no script diagnostics.
- Initial Hardware/Creation GPU captures failed exact1280×720 checks because macOS
  resized during native startup. Fixtures now require consecutive actual rendered
  frames at the requested size. Dimensions were not weakened.
- The baseline instrument audit's first run printed PASS despite size assertions;
  its retry had one wrong-size frame. Neither is accepted as a full suite. One
  independently observed valid English frame shows Run covered by other windows.
  Current code already recalls a covered instrument in one click; the screenshot
  alone does not prove broken recall. A real host click loop remains pending.

[Log inspection](log-inspection.json) and [uncompressed log hashes](log-sha256.json)
retain55 complete log/input artifacts, including failures. The
[sequential runner](run-simplicity-checks.py.txt) records exact commands and checks
diagnostics as well as exit/PASS. [Source hashes](source-sha256.json) bind1222
runtime/test/asset/localization files exactly between workspace and final QA;
`project.godot` differs only by its two QA profile settings.
[Baseline hashes](baseline-source-sha256.json) bind558 production files to Git.
Branding and final diff whitespace checks passed. Code and pixel cross-reviews
reported no remaining blocker for these three changes.

## Reproduction and remaining acceptance

Run `scripts/verify-project.py --godot <4.7.1> --suite <name>` for each selected
suite. Use the GPU flags in [testing.md](../../development/testing.md) on an imported
isolated project and inspect the complete results and actual pixels.

No new package was exported. Native final-source interaction, Windows, newcomer
completion, long sessions, audio and server-recomputed online rankings remain
unverified. Whole-chapter entry/edit/run/compare/save/navigation coverage remains
open. Existing circuit occlusion, truncated Trace summaries, Creation tab discovery,
and repeated Keep entrances are follow-up audit items, not resolved by this receipt.
