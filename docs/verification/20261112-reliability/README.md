# Existing player-loop reliability — 2026-11-12

Base: `main` `329a4840a17b4c2ac4f59157a09aa97ffd0e0dd9`. Its tree was identical
to the old local task branch `d4b428c`; main was fast-forwarded before edits.
This is source validation, not a new exported release or complete newcomer playtest.

## Repaired behavior

- CPU interface guidance and tutorial wiring guidance now follow topology Undo/Redo.
  Clear-all also refreshes CPU guidance. Undo does not grant tutorial removal practice.
- Successful wiring edits, clear-all and topology history discard old investigation
  observations. Presentation-only movement, rejected connections and no-op edits
  preserve valid evidence. Undo restores circuitry without resurrecting stale results.
- Topology invalidation clears the previous Debug output label. Actual committed
  RAM state is retained; only its obsolete output presentation is invalidated.
- Chapter2 Run History compares the stored data signature as well as test name.
  Two Debug runs with different values are no longer described as unchanged inputs.

No task/model/condition identity, simulation costs, save format or achievement
threshold changes. Formal Chapter4 and the optional scheduling lab stay separate.

## Actual verification

Godot `4.7.1.stable.official.a13da4feb`, macOS / Apple M2 OpenGL.
QA: `.godot/verification/20261112T165455Z-96d902b4/project`.
All engine runs used `VonNeumannBottleneckChecks/` profiles; ordinary saves untouched.

28 distinct focused headless suites have passing observations, with final affected
Hardware suites rerun after the final label correction. This is staged focused
coverage, not a full-repository regression. Import and actual user-directory probe
also passed. Exact commands, exits, expected negative controls and diagnostics are
in [results.json](results.json); raw UTF-8 logs are losslessly gzip-compressed in
`logs/`. [Source hashes](source-sha256.json) bind the final QA and workspace files.

Coverage includes:

- Prologue CPU and RAM, tutorial actions, real history, saved workbench entry,
  sealing/navigation, failure continuation and ordinary settings input.
- All seven Chapter2 progression fixtures; measured 321→105 comparison, best
  recipe restoration/Undo, scene return, different Debug data and deterministic simulation.
- Chapter4 fields/mixed ranking, real cycles/traffic/space, ties, restore/Undo,
  qualified winning/unfinished attempts, target import/replay, mode isolation,
  protected save failures and exact-objective retry. All six formal layout tasks
  are exercised by the deterministic simulation matrix.
- Optional scheduling challenge UI, independent target/notebook behavior,
  personal record conditions, global save and localization.

New tests fail against the unchanged base runtime and pass against the repair.
The original Chapter2 negative control fails two of149 checks. Initial Hardware
negative control fails8/19; expanded final controls also include clear-all and
old Debug-output assertions. Expected failures are explicitly labeled, never counted
as successful tests. Independent source review found the clear-all omission before
final integration; independent image review found the stale green Debug label.

Rendered runs use the real Apple M2 renderer: bilingual Hardware history scenes,
English Chapter2 presentation, bilingual Chapter4 rankings and portable challenges.
[Frame manifest](frames.json) records all13 final images and their dimensions/hashes.
The6 Hardware captures are1280×720; the7 rankings/challenge images are their actual
secondary-window surfaces. They are scripted fixtures, not native input evidence.

The first Hardware captures failed dimensions: without `--capture-size=1280x720`,
normal macOS minimum-window handling enlarged the surface. Those original logs are
retained; the corrected launch passes all size/save and behavior assertions. A later
visual review found the stale output label; final captures follow that repair.

### Restart and native scope

`scripts/verify-chapter-workspace-restart.py` passed a writer and two fresh reader
processes: unfinished invalid draft/applied source/empty wiring survive, without
awarding completion. `scripts/verify-save-restart.py` passed legacy writer,
migration reader and stable reader; [report](save-restart-results.json).
Both used the already-imported isolated QA copy.

A native CUA pass used [this seeded CPU fixture](native-preview.gd.txt), not campaign
progress. Observed on the Mac:4 wires / stage B; Cmd-Z removes the last wire and
returns operand guidance; redo restores4 / B; mouse Clear gives0 / A; mouse Undo
restores4 / B. Cmd-Q closed the owned process with exit0. Screenshots were observed
in the chat, not exported into this receipt. This pass preceded the final Debug-label
correction; that correction is covered by the final headless/GPU runs. Do not call it
final-build native acceptance, a complete CPU solve, or native Chapter2/4 acceptance.

## Reproduction and remaining boundaries

Run the standard isolated verifier with relevant `--suite` names in `results.json`.
For the new rendered regression, on its imported QA copy:

```sh
<Godot-4.7.1> --path <isolated-project> --windowed --resolution 1280x720 \
  --script res://tests/test_hardware_history_context.gd -- \
  --locale=zh_CN --history-capture --capture-size=1280x720
```

Repeat with `--locale=en`. The regression refuses ordinary player-data directories.
Preserve raw frames and validate their size before claiming a capture pass.

No new Windows/Mac export, online server-recomputed leaderboard, cross-platform,
full newcomer completion, long-session/audio or final art acceptance. The first
Debug run's session-baseline semantics remain unchanged: the audit did not find a
clear contract authorizing a behavior change. Visual/Logo choices are in the
[owner decision list](../../development/VISUAL_DECISIONS_20261112.md); no final art direction has been selected.
