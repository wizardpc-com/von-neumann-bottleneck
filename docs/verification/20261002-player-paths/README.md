# Evidence-driven player paths — 2026-10-02

Baseline: `6905a0b`. Work in progress; do not treat controller tests as player paths.

## Stage 1: known defects

ALU investigation Reset previously cleared the observation list and then called a
storage-only guard. It now uses the shared simulation reset, as does the storage
button. Debug memory, prior outputs, playback batches, current Trace and stale
result/caption are cleared. A non-committing live signal preview may be recomputed;
it cannot restart playback. Inputs, topology and earned official proof remain.
Reset during official tests/hints is ignored rather than interrupting authority.

Both working_set descriptions/objectives/second briefing pages now ask what was
fetched, without announcing the second-pass outcome. Earned explanations remain.
The worship sentence is removed from both ending translations, with no replacement
lore.

Four fresh isolated suites passed: hardware foundations/prologue UI, localization,
theme reflection. See fixes-results.json and individual logs. The first sandboxed
import could not create macOS QA user directories; the documented verifier was
rerun with filesystem permission and passed. No source parse/runtime failure was
hidden by that retry. This stage contains no human or native-path acceptance claim.
