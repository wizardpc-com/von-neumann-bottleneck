# Eight-task Demo redesign

> Superseded product direction, 2026-09-05: the user withdrew replacement of the original mainline by eight tasks, demotion of construction to an optional workshop, and replacement of the floating desktop by a fixed workspace. The original Game route is restored. This document is retained as historical comparison evidence; simulation, provenance, save protection, and Git safety still apply. See [recovery status](../status/in-place-recovery.md).

Implemented on the `d7aa2f1` baseline, 2026-09-05. [Blueprint](../design/DEMO_REDESIGN_BLUEPRINT.md), [decision](../decisions/0019-eight-task-mainline-and-standard-modules.md), [execution plan](../exec-plans/active/demo-redesign.md).

## Playable path

Run the project normally in Godot 4.7.1. **Start game** enters P-1; **Continue game** restores the current mainline task/stage and draft. The optional Hardware workshop retains its existing independent construction branches and named workbenches. **Legacy records and labs** opens the historical hub without mapping old achievements to new contracts. Starting P-1 again does not reset either old or new progress.

| Task | Implemented player decision and completion evidence |
|---|---|
| P-1 / `dp_select` | Wire the standard two-input selector. All 512 four-bit input/select combinations are behavior-checked. Only direction/width restrict connections. |
| P-2 / `dp_store` | Three stages: register write/hold; independent RAM addresses; actual register/RAM LOAD/STORE return path. Five independent sequences per stage cover zero, complementary and mixed values. Earlier accepted stages remain separate snapshots. |
| 1-1 / `d1_cpu` | Replace only CPU on a fixed sum task. Two input cases, controlled baseline comparison, immediate completion. |
| 1-2 / `d1_upgrade` | Choose one changed part in each of two scenarios. Sum target ≤100 cycles; copy target ≤96 cycles. RAM and Bus are respectively useful. Both scenarios use two numerical cases. |
| 2-1 / `d2_cache` | Enable one cache line; correct workload plus actual misses and hits qualifies. |
| 2-2 / `d2_order` | Edit the program with one cache line and ≤110-cycle target. Behavior/workload/time, not reference text or a traversal label, determine acceptance. |
| 2-3 / `d2_group` | Schedule two independent sum passes with a fixed one-line cache; ≤145 cycles. Each pass reads every element once and stores its own sum. |
| 2-4 / `d2_final` | Start with two cache lines; combine access order, capacity and grouping. ≤145 cycles; optional cost≤4. More cache and low-cost grouping both work. |

No workshop completion, prediction, diagnosis, manual Apply, forced replay or finding review gates the new mainline. Run validates and applies a source snapshot in one action. Invalid drafts keep the previous result explicitly labeled. Passing records completion immediately and leaves the workbench open for optimization. Best accepted performance designs persist and are recomputed on re-entry; the fresh draft remains marked unrun.

## Model and evidence

The existing simulation files are unchanged. Small digital components are authored standards (`standard-digital-v1`); system parts carry `standard-system-v1`; locality configuration uses `standard-locality-v1`. Standard modules grant no player-built provenance or workshop rewards. Ordinary wires have no latency. System CPU wait already includes RAM service, bus transfer and control. Grouping uses the existing independent-pass workload, not arbitrary reordering or summing both pass outputs together.

| Reference / tested solution | Cycles | RAM bytes or wait | Cost |
|---|---:|---:|---:|
| CPU initial → faster | 158 → 134 | wait 126 → 126 | 21 → 30 |
| RAM scenario initial → fast RAM | 158 → 86 | RAM service 108 → 36 | 21 → 30 |
| Bus scenario initial → wide Bus | 144 → 96 | transfer 64 → 16 | 30 → 39 |
| Direct → one-line contiguous reuse | 257 → 105 | RAM bytes 64 → 64 | 0 → 4 |
| Ineffective cache → changed order | 321 → 105 | RAM bytes 256 → 64 | 4 → 4 |
| Two passes whole table → one-line groups | 210 → 138 | RAM bytes 128 → 64 | 4 → 4 |
| Final two-line initial → four-line / one-line groups | 642 → 138 | RAM bytes 512 → 64 | 7 → 13 / 4 |

Each locality run validates the displayed data, negative values and 16 basis inputs, along with per-address/per-pass request counts and every output store. Calibration enumerates all 27 hardware combinations in each upgrade scenario (rejecting disallowed multiple changes) and 24 capacity/group/two-reference-program combinations in the capstone. This is bounded enumeration, not a claim of global optimality over arbitrary programs. The generated table is `.godot/redesign/calibration.json`.

## UI and save boundaries

Mainline task/specifications, editable program plus actual IR/schedule-derived addresses, circuit inputs/stored values, Run/Undo/Redo and results share a fixed workspace. Optional event inspection shows actual source lines, cache residency/requested data, groups/passes and system wait breakdown. Playback, pause, seeking and 1×/2×/4× change only the observation pace. Editing or switching comparison cancels the previous playback; source/device focus is cleared when it no longer matches. The secondary record area scrolls within a bounded height. The circuit board reuses the existing procedural module renderer and GraphEdit with visible standard supplies, fit/zoom/pan, connection/disconnection and transactional history. Step commits one debugging state boundary; official checks preserve that debugging state.

The unified mainline Handbook opens a relevant term, appends saved mainline experiences only after independent replay, and retains unlocked legacy Notebook entries under an explicit historical label. These notes do not grant completion. Shared definitions explain the three model layers, CPU wait overlap, cold initial state, one-action Run, optional predictions and observation-only playback. The workshop identifies itself as optional and does not claim gate count implies performance.

The new save uses `.tmp` and `.bak` replacement and replays accepted designs. Unknown or corrupt data is not overwritten; missing standard origin never becomes fabricated evidence. New Game progress has no writer into the old named workshop format. See ADR 0019 for the persistence contract.

## Verification and remaining acceptance

The final playable package is `build/Von-Neumann-Bottleneck-Demo-Redesign-20260905.zip` (43,022,970 bytes), containing the standalone Windows EXE and bilingual readme. SHA-256: `4BC435A0ACD4BC942E348AFBFBB3524954B149F56E5BA3DBE251662998565397`. Export and packaged Game/Test/rendered Game starts exited 0. The known nonfatal Windows certificate-store warning remains. Unzip and open `Von-Neumann-Bottleneck.exe`, then choose Start game; Godot source entry is the default project scene.

All 19 suites passed: 14 original suites plus five focused Demo suites. The complete eight-task UI traversal runs in ordinary Game, then serializes and independently replays every accepted stage. Fresh suite commands are in [testing](../development/testing.md). Logs and normal Windows screenshots are under `.godot/redesign/`; new screenshots in `docs/images/demo-*.png` show the implemented mainline. Input dispatch covers Start/Run, real GraphEdit port hit tests after zoom/pan, component dragging, Esc and the legacy-hub return. Mainline controls were checked at 1280×720, 1600×900, 1920×1080 and 1920×1200; Chinese and English rendered frames were inspected. This is automated input, not a human physical-mouse playtest.

Remaining: human novice/expert playtests, pacing, comprehension without Hint 3, mouse comfort, high-DPI readability and willingness to optimize. The workshop and legacy lab tool layouts/copy retain substantial earlier presentation; they have not received the full M4 redesign. Mainline playback synchronizes key events, source lines, addresses and device/residency highlighting; it does not animate packets continuously along wires. Full floating/detached mainline tools are optional under blueprint §6.2. These distinctions are not a claim that every M0–M5 acceptance criterion is complete.
