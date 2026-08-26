# Playtest instrumentation

The frozen prologue, Chapter 1, and Chapter 2 Demo can now produce one anonymous local session containing behavior events, per-level ratings, chapter feedback, and final Demo feedback. This system is observational only; it does not change simulation, official evidence, completion, progression, scoring, Trace, Profiler, or playback.

## Recorded behavior

- session start, recovery, end, and a unique anonymous session ID;
- level start, completion, exit, elapsed time, official attempts, retries, and failed attempts;
- progressive Hint use; player-opened Trace, Profiler, Notebook, and other existing investigation tools; and key Trace/Profiler actions;
- bounded counters for Program, hardware topology/parts, Cache, Work Group, and relevant test-input changes;
- Chapter 2 capstone first modification direction, final configuration, cycles/cost/wait metrics, and whether another official optimization run occurred after completion; and
- Game or Test mode on every event and response.

The event payload allowlist excludes complete Program source, Notebook contents, free-form control contents, machine identity, accounts, network identifiers, and other unnecessary personal data. Only the explicitly optional feedback note fields store player text, capped at 240 characters.

## Feedback flow

Each ordinary level completion adds three optional 1–5 ratings for fun, clarity, and desire to continue plus one optional short note. Continue is always available, so incomplete ratings or an empty note never block progression. Each chapter ends with one compact best/worst/confusion/surprise/pace form. The Chapter 2 ending then shows one compact Demo-wide satisfaction/difficulty/length/favorite/change/continue form. Every form has an explicit Skip action.

Questionnaires are disabled automatically for script, headless, and `--capture...` launches. `--disable-playtest-feedback` and `--disable-playtest-telemetry` disable the two concerns independently. Focused test or capture work may explicitly use `--enable-playtest-feedback` or `--enable-playtest-telemetry`.

## Storage, recovery, and export

The crash-tolerant authority is `user://playtest_data/session_<session_id>.jsonl`. Each accepted event is one schema-versioned JSON object and is flushed immediately. `active_session.json` identifies an unfinished session; the next launch resumes it, marks the recovery, preserves readable prior events, ignores a malformed trailing record, and closes any interrupted active level. A clean shutdown closes the session and removes only the active marker.

The chapter-selection Options panel exposes **Export Playtest Data**. It writes `user://playtest_data/exports/playtest_<session_id>_<timestamp>.json`, a single versioned JSON document containing session metadata, events, normalized level summaries, feedback, and the privacy contract. The player can send that one file to the developer. Export failure is shown locally and does not affect play.

On the normal Windows Godot layout these files are under `%APPDATA%\Godot\app_userdata\Von Neumann Bottleneck\playtest_data`. The runtime resolves `user://` through Godot, so the operating-system location may differ on another platform.

## Starting a clean internal playtest

1. Close the game cleanly and relaunch in the default Game mode. Campaign completion, Chapter 1/2 receipts, Notebook unlocks, and chapter progress are session-local and therefore start clean.
2. For completely blank Hardware named layouts as well, first back up or remove only `user://hardware_workbenches_v1.json`; this existing version-1 topology store is deliberately separate from progression and telemetry.
3. Play from the prologue through Chapter 2 without `--disable-playtest-telemetry`. Answer or skip each compact feedback surface.
4. At the end, open Options from chapter selection and choose **Export Playtest Data**. Keep the JSONL directory only when raw recovery evidence is also wanted.

This is not a general save-game or analytics-upload system. Cross-session aggregation, cohort analysis, account identity, remote collection, and deletion/retention policy UI remain out of scope.
