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

Each ordinary level completion adds three optional 1–5 ratings for fun, clarity, and desire to continue plus one optional short note. Continue is always available, so incomplete ratings or an empty note never block progression. Each chapter ends with one compact best/worst/confusion/surprise/pace form. The Chapter 2 ending then shows one compact Demo-wide satisfaction/difficulty/length/favorite/change/continue form. Every form has an explicit Skip action. Submitting or skipping the final Demo form opens a dedicated export handoff before returning to chapter selection.

Questionnaires are disabled automatically for script, headless, and `--capture...` launches. `--disable-playtest-feedback` and `--disable-playtest-telemetry` disable the two concerns independently. Focused test or capture work may explicitly use `--enable-playtest-feedback` or `--enable-playtest-telemetry`.

## Storage, recovery, and export

The crash-tolerant authority is `user://playtest_data/session_<session_id>.jsonl`. Each accepted event is one schema-versioned JSON object and is flushed immediately. `active_session.json` identifies an unfinished session; the next launch resumes it, marks the recovery, preserves readable prior events, ignores a malformed trailing record, and closes any interrupted active level. A clean shutdown closes the session and removes only the active marker.

The final Demo handoff and chapter-selection Options panel both expose **Export Playtest Data**. It writes `user://playtest_data/exports/playtest_<session_id>_<timestamp>.json`, a single versioned JSON document containing session metadata, events, normalized level summaries, feedback, and the privacy contract. Success shows the exact path and an **Open Folder** action; failure is shown locally and does not affect play.

On the normal Windows Godot layout these files are under `%APPDATA%\Godot\app_userdata\Von Neumann Bottleneck\playtest_data`. The runtime resolves `user://` through Godot, so the operating-system location may differ on another platform.

## Starting a clean internal playtest

1. Close the game, then launch `Von-Neumann-Bottleneck.exe --test-mode --reset-local-test-state` (or `godot --path . -- --test-mode --reset-local-test-state` from the repository).
2. The reset removes the global Game save, active anonymous session streams, and all Hardware workbenches, including named local test designs. Existing files under `playtest_data/exports/` remain intact.
3. Play from the prologue through Chapter 2 without `--disable-playtest-telemetry`. Answer or skip each compact feedback surface.
4. At the final Demo handoff, choose **Export Playtest Data**, note the displayed path, and use **Open Folder** if desired.

Telemetry remains separate from the minimal Game Save/Continue service and is never authoritative progression input. Cross-session aggregation, cohort analysis, account identity, remote collection, and deletion/retention policy UI remain out of scope.
