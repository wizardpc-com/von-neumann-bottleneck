# Demo redesign — M0 through M5

Status: active, 2026-09-05. Approved product contract: `docs/design/DEMO_REDESIGN_BLUEPRINT.md`.

## Goal and boundaries

Deliver eight playable mainline tasks, with the existing deep hardware campaign available as an optional workshop. First deliver the CPU comparison and cache/access-order slice. Reuse the circuit, system and locality simulators; preserve deterministic Trace authority, visible player solutions, independent workshop provenance, Game/Test isolation and old named workbenches. No engine rewrite, answer injection, save deletion, commits, merges or pushes.

## Sequence and verification

- M0: inspect HEAD, rules, current code and prior fixes; record original regressions and protect live save files.
- M1: operational CPU comparison and cache/access-order tasks in a stable workspace; engine-derived baselines, one-action draft validation/run, immediate completion, usable Game entry and fresh UI captures.
- M2: eight-task mainline navigation, optional workshop, explicit standard-component identity, independent recoverable mainline save; verify legacy files and mode isolation.
- M3: behavior-checked P-1 and staged P-2, two upgrade scenarios, reuse/grouping/capstone; calibrate allowed solutions and counterexamples through unchanged engines.
- M4: consistent Chinese/English copy, contextual specifications/help, visible state and event inspection, shortcuts and responsive layout.
- M5: complete regression, ordinary Game traversal, visual captures, Windows playtest export, documentation and diff review.

Affected areas: new `src/demo/` content/controller/state/presentation, startup hub, localization, relevant tests and design/status/ADR documentation. Existing workshop editor and simulation domains remain the reusable foundation.

## Decisions

- New mainline IDs and persistence are separate from legacy workshop/chapter IDs. Old completions are retained as history, not fabricated as passes under a new contract.
- A focused new mainline host will reuse existing deterministic models. This avoids coupling new behavior to the legacy investigation controllers' prediction and playback locks. The historical chapter scenes remain available for regression and old saves.
- Standard parts will carry authored identity and behavior version; they will not impersonate player-sealed components or unlock workshop achievements.
- Current blueprint supersedes mandatory gate-building, 21-node routing, default floating tools, required predictions/diagnoses, separate Apply and playback/review completion locks for the new mainline. Prior plans retain their historical evidence.

## Progress

- 2026-09-05 M0: repository HEAD is `d7aa2f1788c133a6f8f35233bbc6ee7e89f0b932`; initial worktree clean. Reopened AGENTS, PLANS, architecture, status, prior repair plan, tests and controllers. Confirmed existing Inspector/hints, signal encoding, transactional editor and persistence must be reused, not represented as missing.
- Blueprint import preserves the supplied content. Downloaded source SHA-256: `4705CD34E638D8B1E4452416BB8390F05103ABA6BBCF205C9423E9A9BBA460D5`. The repository copy changes only nine Markdown hard breaks from trailing spaces to equivalent backslashes so whitespace checks pass; the Downloads source remains untouched. Its statement about remote `main` is the supplied document's historical claim, not a new remote verification in this implementation.
- 2026-09-05 M0: all 14 original suites passed; logs in `.godot/redesign/baseline/`. Tests use a repository-local APPDATA directory; no live saves are deleted or rewritten.
- 2026-09-05 M1: two real Game-mode tasks run in the new fixed workspace. Existing engines reproduce CPU 158→134 cycles with unchanged 126 wait cycles, and access-order 321→105 cycles / 256→64 RAM bytes. New model/UI suites pass, including renamed equivalent programs, constant-output rejection, workload checks, one-action Run, invalid-draft result isolation and completion without playback/review. Inspected four normal Windows captures at 1600×900 under `.godot/redesign/m1-*.png`. These are rendered-window and automated-controller evidence, not human mouse or comprehension acceptance.
- 2026-09-05 M2: default Start/Continue and near-neighbor map use eight independent mainline IDs. Standard parts are normal Game supplies; workshop remains optional. New progress saves drafts/stages/accepted designs through temporary and backup replacement; replay, future/corrupt protection, missing provenance and Game/Test isolation pass. The legacy hub has an explicit return to the mainline; its save controls and progression retain their historical scope.
- 2026-09-05 M3: ordinary Game traversal completes all eight tasks and every storage/upgrade stage. P-1 checks 512 behaviors; P-2 checks five sequences per stage; locality checks 18 numerical cases and actual per-pass work. Calibration covers 27 hardware combinations per upgrade scenario and 24 final capacity/group/program combinations. RAM and Bus upgrades win in different scenarios; capstone solutions include costs 4 and 13. Full-route save/load replays every accepted design. Signatures normalize JSON integer-valued options before replay.
- 2026-09-05 M4: mainline uses 179 matching Chinese/English keys, fixed specifications, inputs/stored values, code/address preview, context inspection and baseline/current/best results. Read-only Handbook entries combine replayed mainline experiences with separately labeled legacy Notebook records. Playback offers pause/seek/1×/2×/4×; edits or comparison changes stop the prior snapshot, and graphics never mutate results. The secondary record area scrolls within a bounded height. Native Godot input tests exercise Start/Run, zoom/pan port wiring, dragging, Esc, legacy return, and 1280×720, 1600×900, 1920×1080 and 1920×1200. Shared term/cycle/model-boundary and workshop identity text was updated; full optional-tool layout/copy conversion remains open.
- 2026-09-05 M5: all 19 suites pass (14 retained plus five new); affected suites rerun after final edits. Fresh Chinese/English mainline, optional workshop and legacy-menu captures are inspected. Mainline screenshots are in `docs/images/demo-*.png`; raw logs/captures are in `.godot/redesign/`. Windows package and smoke evidence is recorded in the status/testing documents. No simulation engine edits, commits, pushes or old save cleanup.

## Remaining / human evidence

The eight-task playable route and integration build are delivered. M4 remains partial across the full optional legacy-tool surface: the workshop retains its existing floating task/tools and deep tutorial presentation; historical lab copy and investigation controls retain their own contract. These are explicit remaining conversion work, not empty mainline tasks. Full floating/detached mainline tools are optional under blueprint §6.2 and are not an acceptance prerequisite.

Next engineering step: convert the workshop's initial task/Test Bench/context arrangement within its existing controller, preserving its transactional input, sealed-component provenance and named-workbench tests; then review reachable legacy-lab copy against the shared dictionary. Do not rewrite its simulator or make this work a prerequisite for the mainline.

Physical mouse comfort, novice independent solving without Hint 3, high-DPI readability, pacing and willingness to keep optimizing require human playtests. Automated and rendered evidence does not establish comprehension or enjoyment. Keep this plan active until the remaining full-surface M4 work and human acceptance are explicitly resolved.
