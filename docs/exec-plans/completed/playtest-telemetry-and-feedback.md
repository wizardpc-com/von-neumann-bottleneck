# Playtest telemetry and feedback

## Goal

Make one clean, ordinary-player playthrough produce durable anonymous behavior events, per-level ratings, chapter feedback, and final Demo feedback that can be exported for analysis.

## Scope

- Add a versioned, local-only playtest session/event store with immediate append-only writes and recovery after an interrupted launch.
- Record level lifecycle, official attempts/failures, optional hints and investigation-tool use, relevant player edits, and Chapter 2 capstone choices/results.
- Add short localized level, chapter, and Demo feedback surfaces.
- Add a single-file export entry point and automated coverage for persistence, recovery, feedback, export, and UI behavior.
- Update architecture, testing, and current-status documentation.

## Explicit non-goals

- No new levels, mechanics, Chapter 3 content, simulation behavior, art, audio, Windows packaging, analytics upload, account identity, or general save-game system.
- Do not record complete free-form programs, notebook contents, machine identity, network identifiers, or other unnecessary personal data.
- Do not make telemetry or feedback a prerequisite for completion, progression, scoring, Trace, Profiler, or simulation.

## Affected files and subsystems

- New `src/playtest/` data service and feedback UI.
- `project.godot` autoload registration.
- The Hardware Foundations, Chapter 1, Chapter 2, and hub UI controllers at existing interaction boundaries only.
- English and Chinese localization catalogs.
- New focused data/UI tests plus relevant existing UI/localization suites.
- `ARCHITECTURE.md`, `docs/development/testing.md`, and the current status documents.

## Invariants

- Simulation and official completion remain deterministic and authoritative.
- Event-write or export failures never change gameplay state and never prevent navigation.
- Game and Test mode remain distinguishable in every stored event and response.
- Automated tests and deterministic capture launches never show feedback unless a focused test explicitly enables it.
- Each accepted event is flushed promptly; a prior active session is resumed and marked as recovered rather than silently discarded.
- Player text is optional, length-bounded, and stored only in the explicit feedback field.

## Decisions and rationale

- Use one autoloaded `PlaytestData` service so all chapters share one anonymous session identity without coupling their state objects.
- Store an append-only JSONL event stream as the crash-tolerant authority and maintain only a small active-session marker beside it.
- Export one versioned JSON document containing session metadata, events, and normalized responses so a tester can send one file.
- Present level feedback inside a reusable modal after authoritative completion. Ratings and notes are skippable; Continue remains available. Chapter/Demo prompts are separate concise forms triggered only at natural chapter boundaries.
- Treat recognized script/capture/headless command lines as telemetry- and questionnaire-disabled by default, with independent explicit enable/disable flags for focused verification. Ordinary Game/Test launches record their mode on every accepted event.

## Implementation and verification

1. Implement session creation/recovery, immediate JSONL append, response normalization, export, and shutdown events.
2. Add focused tests for unique sessions, recovery, truncated/corrupt trailing records, bounded feedback, export schema, and write-failure isolation.
3. Add localized level/chapter/Demo feedback UI and focused interaction tests, including skip and disabled-display paths.
4. Add narrow event calls at existing UI/controller action boundaries in each playable chapter and export access from the hub/end flow.
5. Run focused tests, all existing suites, startup/capture smokes, localization parity, `git diff --check`, and inspect the export artifact and at least Chinese/English feedback frames.

## Progress

- 2026-08-26: Read repository guidance, architecture, Game/Test-mode boundary, completion overlay, testing documentation, and prior gameplay constraints. Created this plan before runtime edits.
- 2026-08-26: Added the local append-only session store, recovery, summaries, export, compact localized feedback surfaces, host instrumentation, and Options export without changing simulation or progression objects.
- 2026-08-26: Added focused persistence/recovery/export/UI coverage, updated architecture/status/testing documentation, and accepted ADR 0017.
- 2026-08-26: Completed a fresh 13-suite regression matrix, six startup/route smokes, Chinese/English 1600×900 feedback inspection, localization parity, and whitespace review.

## Outcome

- One anonymous ID now follows the player across the ordinary Demo session. Accepted events are flushed immediately to versioned JSONL, an unfinished marker resumes after interruption, and the hub exports one versioned JSON with events, normalized feedback, and level summaries.
- Existing controllers report lifecycle, attempts/failures, Hints, tools, key investigation actions, and bounded edit categories. Chapter 2's capstone summary retains the first modification, final configuration/metrics, and post-completion rerun evidence.
- Level feedback is embedded in the existing completion overlay; chapter and Demo feedback use a separate concise overlay. All text is optional and bounded, every form is skippable, and automation does not display it by default.
- The observer is write-only from gameplay's perspective. No return value participates in simulation, Trace, completion, progression, scoring, or playback.

## Verification

- All 13 Godot 4.7.1 suites passed in the final source state, including the two new playtest suites and every prior simulation/UI/progression/localization suite.
- Default Game, Test-mode, English, Hardware, Chapter 1, and Chapter 2 startup/route smokes exited `0`.
- Chinese and English 1600×900 level-feedback frames showed all copy, ratings, optional note, and Continue action without clipping or obstruction.
- The persistence suite parsed the exported JSON and verified schema versions, anonymous session linkage, summaries, normalized feedback, and privacy metadata after interrupted-session and malformed-tail recovery.
- `git diff --check` passed before final plan completion.

## Limitations and follow-up work

- The first schema intentionally counts semantic controller actions rather than recording full editor replay or player-authored Program/Notebook contents.
- The first version exports the current session as one JSON file. Cross-session aggregation remains an external analysis task.
- Hardware named workbench topology remains the existing independent version-1 file; a completely blank internal run must remove or back it up separately. This work does not introduce a coordinated save/reset system.
