# Readable investigations and native map gestures — 2026-09-13

Source follow-up to `9634599`, Godot 4.7.1 stable on the local Apple M2 Mac.
This is development-source evidence, not a new exported candidate or novice study.

## Player-facing changes

- Chapter 2 Program puts editable source, validation and Apply before optional syntax
  and strategy reference. Only the focused instrument receives the strong accent.
- Apply is a plain action caption; a loaded draft no longer carries a misleading
  checkmark. Chinese/English capacity, pass-count and group descriptions use clear
  quantity labels, with technical values and formal limits unchanged.
- The shared Chapter 1/2 map no longer puts its sixth and seventh task on the same
  spot. Its introduction uses wrapped, scrollable themed text rather than unwrapped
  drawing calls. All current task cards retain their state and title bounds.
- Chapter 3 uses the shared font, a named cycle axis and # batch labels. Independent
  work gets its own short localized label. Zero elapsed time displays only tick 0;
  the drawing denominator does not invent an elapsed cycle.
- Task-tree dragging follows the captured press/release lifetime even when native
  motion lacks a button mask. Release outside the canvas, focus loss and fullscreen
  changes still cancel it. Text retains its screen-size floor and rounded baselines.
- Catalog checks reject duplicate message IDs. Visual review caught a new short
  label shadowing the existing independent-work specification; the final keys are
  distinct, and the exact work-4 specification remains intact.

## Actual computer-use Game observations

No progress setter or reference solution was used for these native actions. A copied
QA profile supplied previously earned Chapter 2 access; its Chapter 3 started with
only the arrival task available. The original 18 source-profile files still match
their recorded SHA-256 hashes. Actual player storage was not used.

A uniquely named copy of the official Godot app made native control reliable. Only
this QA app has a changed bundle identity and ad-hoc signature; delivery artifacts
and the installed engine are unchanged.

| Native action | Visible result |
| --- | --- |
| Arrival: run premature consume | Error on line 3; 0 elapsed cycles |
| Enter fetch/work/ready/consume/idle using the schedule editor | 10 cycles, compute 8, transfer 6, overlap 4, wait 2, output 7/7 |
| Buffers: click-place A/B, right-click cancel, drag four data and four status wires | Separate wide data routes and thin status wires; missing feedback initially rejected |
| Run serial schedule | Correct 46/46; 40 cycles, overlap 0, target 28 not met |
| Write an alternating two-buffer schedule | 28 cycles, overlap 12, compute 16, transfer 24, wait 12; pass |
| Chapter 2 capstone: column-first, then row-first, then four cache lines | 642 → 210 → 138 cycles; output 88/88 throughout; final wait 104, RAM 64 B |
| Updated map in English, then Chinese | All seven task cards visible; previously hidden 2-6 selectable |
| Window/fullscreen switch and map introduction | Text wraps; buttons and node status remain readable |
| Native task-tree pan after final fix | Wiring card moved from roughly (397,361) to (140,207), matching the requested drag; later zoom preserved readable labels and fixed detail panel |
| Restart and enter Chapter 3 | Arrival and buffers still complete, other routes preserve their prerequisites |
| Rerun saved buffer solution and move Timeline window | Same 28/12/46 result; ruler and batch labels remain clear after movement |
| In-game language setting | English → Chinese updates the title, settings and chapter map without changing progress |

Screenshots committed here are separate rendered fixtures, **not screenshots of the
native earned solutions**. Native observations are recorded above from computer-use
screens. Chapter 3 render fixtures explicitly load reference solutions for layout
inspection and do not count as player progress.

## Verification and intermediate corrections

- `full-results.json` and adjacent full logs: all conventional isolated suites pass.
- `followup/`: bilingual locality, localization and initial render results.
- `final-drag-and-text/`: corrected unique translation keys, actual press/release
  boundaries, bilingual typography across zoom/pan, overlap UI and rendered fixtures.
- `final-captions/`: final Chinese caption cleanup, localization, rendered Chapter 2
  in both languages and shared Chapter 1 UI all pass.
- First sandboxed import was denied access to its new QA user directory. The fresh
  authorized run above passes; this was an environment failure, not a game failure.
- An intermediate zero-time screenshot helper used nonexistent task ID `request`
  and captured the chapter map. Corrected to `arrival` and visually inspected the
  actual zero-time timeline. That intermediate render success was not accepted as
  proof of the timeline condition.

## Boundaries

The template comment `Test fixture: row-first access on row-major A` remains in the
exact stored DSL source: paired evidence currently compares its source hash. It was
not silently rewritten during a text-only change. Changing it safely needs explicit
legacy-receipt compatibility coverage, not a blanket source replacement.

CPU Hint-return presentation and the Chapter 1 new proportion bar still have their
separate final native recheck queue. Windows native, another Mac install, extended
mixed-DPI/focus testing and external beginners remain release gates. No new package,
server deployment, public upload or gameplay-rule change is included here.
