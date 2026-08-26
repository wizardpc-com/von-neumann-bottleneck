# 0017 — Local offline playtest observability

## Status

Accepted for the first internal/friends Demo playtest on 2026-08-26.

## Context

The prologue, Chapter 1, and Chapter 2 core content is stable enough for a complete ordinary-player run, but automated correctness tests cannot establish pacing, comprehension, enjoyment, or actual investigation behavior. The Demo needs recoverable evidence without accounts, a network service, simulation coupling, or a general save system.

## Decision

One autoloaded `PlaytestData` observer owns a random anonymous session ID and an immediately flushed, schema-versioned JSONL stream under `user://`. Chapter controllers report narrow semantic events only after or beside their existing authoritative actions. The observer derives export summaries but never returns values consumed by simulation, Trace, official completion, progression, or scoring.

Optional localized feedback appears only at natural level/chapter/Demo completion boundaries. Continue and Skip remain independent from response completeness. Script, headless, and capture launches suppress questionnaires by default. Every event records Game/Test mode, and event payloads exclude full Program/Notebook text and unnecessary identity data.

An active marker permits interrupted-session recovery. A player-facing Options action exports the current session, events, normalized summaries, and feedback as one versioned JSON file. Submitting or skipping the final Demo form leads directly to the same prominent export action, reports the successful path, and offers to open the containing folder.

`--reset-local-test-state` is the bounded developer clean-playtest entry: the telemetry service removes the active marker, local session JSONL streams, and Hardware workbench manifest; the independent global-save service removes Game progression. Already exported JSON files and unrelated local data remain preserved.

## Alternatives considered

- A remote analytics SDK would add network, consent, identity, service availability, and deployment concerns before the questions justify them.
- Reusing progression or receipt objects would couple subjective observation to authoritative gameplay evidence and would not survive abnormal exit.
- One rewritten session JSON document would risk losing the whole run on interruption; JSONL limits damage to at most a malformed tail record.
- Full Program or Notebook capture would provide more content but violate data minimization and make casual sharing less safe.

## Consequences

- A complete offline run can be analyzed from one export while raw append-only evidence remains available for recovery/audit.
- A first-time player does not need to discover the chapter-selection Options menu after finishing the Demo, while developers can repeat a clean local run without hand-deleting paths.
- Telemetry or questionnaire failures cannot block play or change results.
- The first schema intentionally favors stable counts and semantic actions over detailed editor replay.
- Cross-session aggregation, uploads, retention controls, and a general persistent campaign remain future decisions rather than implicit features.
