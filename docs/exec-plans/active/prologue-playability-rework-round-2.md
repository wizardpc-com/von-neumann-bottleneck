# Prologue Playability Rework Round 2

Status: implementation, automated regression, and normal-Windows capture audit complete 2026-08-28; physical-mouse and novice-comprehension acceptance remains active. The prior completed plan and automated results are historical evidence only; no Round 2 item is accepted from those results alone.

## Goal

Make the prologue genuinely understandable and operable for a first-time player: precise editor gestures, unmistakable signal state, concise mission-led teaching, useful component inspection, progressive hints, legible data flow, and an immediate post-pass route forward. The final kill gate is a player deriving the CPU path from Mission, Inspector, and Hint 1/2 without Hint 3.

## Scope and non-goals

In scope: Tutorial, Half Adder, Full Adder, ALU, SR Latch, Register, RAM, CPU, shared Hardware Foundations editor/UI, Mission, Inspector, Handbook links, hints, playback, completion, localization, layouts, save/reload, and focused regressions.

Out of scope: Chapter 3, new architecture topics, a simulation rewrite, general HDL, automatic solution wiring, copied Turing Complete assets/text, or treating a reference-topology pass as usability evidence.

## Hard invariants

- Deterministic simulation, official evidence, `SimulationTrace`, reusable provenance, and displayed player topology remain authoritative.
- Playback frequency, camera motion, inspection, and floating-window movement remain presentation-only.
- Hint topology stays read-only and cannot enter workbench snapshots, receipts, completion, or save authority.
- Crossings do not connect; explicit junctions do. Ordinary compatible wiring remains zero-latency.
- Game/Test progression isolation, Save/Continue, workbench reconciliation, telemetry, and palette exploration remain intact.
- Existing uncommitted Round 1 work is preserved and audited in place.

## Evidence rules

Each item is tracked separately as:

- `R`: reproduced with real Windows Game-mode mouse/keyboard input;
- `F`: implementation inspected and, where required, fixed;
- `G`: rechecked in real Game mode with a fresh visual capture;
- `A`: covered by a fresh automated regression.

Source presence, a checked historical plan, a synthetic event, and a reference solution do not satisfy `R` or `G`.

## Round 2 issue and acceptance checklist

### 1. Editor interaction — P0

- [ ] R [x] F [ ] G [x] A Component-body left click reliably selects seeded, palette-placed, and save-loaded components.
- [ ] R [x] F [ ] G [x] A Component-body left drag reliably moves all three origins without a port-wiring race.
- [ ] R [x] F [x] G [x] A Palette preview and committed component anchor agree in windowed/fullscreen, zoom/pan, and Windows high-DPI paths.
- [ ] R [x] F [ ] G [x] A Right-drag erases only visually contacted components/wires; near misses survive at all tested zooms.
- [ ] R [x] F [ ] G [x] A Wiring can continue naturally from segments, junctions, and endpoints.
- [ ] R [x] F [ ] G [x] A Existing compatible nets can fan out to further inputs without restarting at the source.
- [ ] R [x] F [ ] G [x] A Crossings remain disconnected and junctions connect deliberately.
- [ ] R [x] F [ ] G [x] A Only direction, bit-width, or electrical conflicts reject; every rejection names the concrete cause.
- [ ] R [x] F [x] G [x] A Hint/Official/Trace locks topology but permits WASD, middle-drag, zoom, component inspection, and floating-window movement.

### 2. Signal input/output visual — P0

- [ ] R [x] F [x] G [x] A Low is an unmistakable red `0`; high is an unmistakable green `1` on the dark workbench.
- [ ] R [x] F [x] G [x] A Input/output direction is encoded by shape/flow in addition to color and text.
- [ ] R [x] F [x] G [x] A The clickable input-switch target is obvious, generous, and distinct from ports, selection, and wiring guides.
- [ ] R [x] F [x] G [x] A Procedural visuals follow the supplied reference's clarity and scale without copying assets or text.

### 3. Mission and onboarding — P0

- [ ] R [x] F [x] G [x] A The first minute states `Half Adder → Full Adder → ALU`, `SR Latch → Register → RAM`, and their convergence into a small computer.
- [ ] R [x] F [x] G [x] A Mission copy is short, task-led, natural, and uses light engineering context instead of textbook/AI phrasing.
- [ ] R [x] F [x] G [x] A Test Bench and shared editor controls are taught fully once and not repeated across branches.
- [ ] R [x] F [x] G [x] A Arithmetic/Storage remain order-independent while learned shared onboarding is de-duplicated.
- [ ] R [x] F [x] G [x] A After briefing dismissal, Mission reopens the full content and Previous/Next continue to work.
- [ ] R [x] F [x] G [x] A Tutorial explicitly teaches that highlighted/clickable terms open the Handbook.

### 4. Component Inspector and terminology — P0

- [ ] R [x] F [x] G [x] A Every player-visible key component has a one-line hover tooltip.
- [ ] R [x] F [x] G [x] A Click opens name, bilingual binding, function, typed ports, widths, behavior, stateful/combinational class, provenance, and Handbook entry.
- [ ] R [x] F [x] G [x] A Ownership is a separate `Built by you / 由你构建` label; formal names never use `Your ...`.
- [ ] R [x] F [x] G [x] A Mission, component, Inspector, Handbook, and Test Bench terminology is consistent.
- [ ] R [x] F [x] G [x] A Critical labels visibly include `OP [2]`, `ARG [4]`, `DATA [4]`, `ADDR [1]`, and `LOAD [1]` where applicable.

### 5. Level playability — P0

- [ ] R [x] F [x] G [x] A Tutorial desktop is clean and teaches signal, wiring, Test Bench, Handbook, and Hz once.
- [ ] R [x] F [x] G [x] A Half Adder supports truth-table-to-SUM/CARRY reasoning, inspectable gates, clean layout, and post-pass XOR unlock without answer injection.
- [ ] R [x] F [x] G [x] A Full Adder foregrounds the owned Half Adder abstraction, keeps a clean layout, and does not repeat Test Bench onboarding.
- [ ] R [x] F [x] G [x] A ALU clearly explains owned parts, MUX, OP mapping, and the selection/organization decision while preserving a real puzzle.
- [ ] R [x] F [x] G [x] A SR Latch builds the chain combinational-no-memory → feedback → state → SET/RESET/HOLD → Q/NQ → two NORs; Hint 1/2 unlock reasoning.
- [ ] R [x] F [x] G [x] A Register explicitly gives the D/LOAD behavior table and leads to `S = D AND LOAD`, `R = NOT(D) AND LOAD`.
- [ ] R [x] F [x] G [x] A RAM layout and teaching make DATA/ADDR/WRITE/OUT, Decoder/MUX/Register roles, bus width, and legal topology clear.
- [ ] R [x] F [x] G [x] A CPU stages have clear goals, visible opcode/control tables, legible SOURCE MUX/RESULT MUX/ALU/ACC/RAM flow, and progressive Hint 1/2 reasoning.
- [ ] R [x] F [x] G [x] A CPU does not reduce to author-specific wire guessing or instruction-following; Hint 3 is unnecessary for a viable solution model.

### 6. Playback, success, layout, and persistence — P0

- [ ] R [x] F [x] G [x] A Player speed uses a broad, understandable Hz range and never changes simulation results.
- [ ] R [x] F [x] G [x] A Official success is immediate and visibly offers Seal, Continue, and Return to Map as appropriate.
- [ ] R [x] F [x] G [x] A Palette tiles align symbol/text with adequate spacing.
- [ ] R [x] F [x] G [x] A All default layouts pass manual visual review: input left, processing center, output right, feedback separated, minimal crossings, no meaningless seeded clutter.
- [ ] R [x] F [ ] G [x] A Save/reload preserves topology, positions, names/provenance, and interaction behavior.

## Actual Game-mode matrix

- [ ] Clean Game-mode route: Tutorial → Half Adder → Full Adder → ALU → SR Latch → Register → RAM → CPU.
- [x] Normal Windows build, windowed mode.
- [x] Normal Windows build, fullscreen mode.
- [x] Zoomed and panned workbench.
- [x] Windows high-DPI behavior (current display scale: 144 DPI / 150%; no OS scale change performed).
- [ ] Real body click/drag and palette drag/place.
- [ ] Real right-button eraser and near-miss.
- [ ] Real segment/junction/endpoint branching and incompatible-wire message.
- [ ] Mission reopen and Previous/Next.
- [ ] Inspector/Handbook from component and highlighted term.
- [ ] Hint 1/2/3 read-only behavior and navigation.
- [ ] Official/Trace playback controls and observation navigation.
- [ ] Immediate success actions.
- [ ] Save/close/relaunch/Continue recovery.
- [x] Visual captures inspected for every level plus signal states, Inspector, hints, transformed canvas, and success.

## Implementation and verification sequence

1. Record baseline Git diff and reopen Round 1 implementation, content, tests, and visual-capture hooks.
2. Run the current working tree in a normal Windows Game-mode build; reproduce interaction and UI issues with real input before editing.
3. Fix P0 editor and signal-visual defects first; add focused regressions only after the real failure is understood.
4. Rework shared Mission/Inspector/Hint/success infrastructure, then level content and layouts from Tutorial through CPU.
5. Repeat the complete real Game-mode matrix and inspect fresh captures.
6. Run focused suites, all documented regressions, startup smokes, localization parity, log scan, `git diff --check`, final diff/status review.
7. Move this plan to `completed/` only when all implemented items carry honest `R/F/G/A` evidence or are explicitly left open.

## Decisions and rationale

- The supplied red/green reference establishes the primary state language. Text (`0/1`) and directional shape are added for accessibility and semantics.
- A headless test may prove coordinate math or reachability, but only injected real mouse input against a visible Windows window counts as gesture acceptance.
- CPU stages may reduce simultaneous scope but may not reveal a wire recipe; each stage must communicate a data/control relationship the player can reason about.
- Changing Windows display scale is an OS setting and is not required for safe automation. The current scale will be tested directly; other scales use Godot/runtime-scale or a user-run follow-up unless the user explicitly authorizes an OS setting change.
- The player's saved pre-CPU workbenches are the topology, component-supply, position, and Hint 3 standard. The partially built CPU workbench is excluded from that authority and is audited independently.
- Per the player's follow-up, Windows Computer Use is not used for the remaining work. Normal Godot Windows runs and captured frames count as `G`; they do not count as physical-mouse `R` evidence.
- Components starts closed in playable levels because the former right-side window covered the player's accepted output positions. The toolbar menu and bottom Components action remain available without changing any accepted circuit coordinate.

## Progress and evidence

- 2026-08-28: Reopened the dirty Round 1 worktree, repository guidance, completed plan, current diff, tests, prior rollout evidence, and supplied reference image. No Round 1 checkbox was carried forward as accepted.
- 2026-08-28: Created this fresh evidence-separated checklist before Round 2 implementation.
- 2026-08-28: Backed up the live Game save/workbenches, parsed the saved pre-CPU designs, and aligned Half Adder, Full Adder, ALU, SR Latch, Register, and RAM seed/reference/Hint topology and exact coordinates to those designs. The three player-authority files were restored after clean-state checks and SHA-256 verified.
- 2026-08-28: Reproduced right-click air deletion to whole-GraphNode rectangle picking. Component and module erasing now use zoom-adjusted procedural-surface hit tests; a transparent corner and a wire ten pixels away survive, while direct cursor contact and continuous sweeps erase transactionally.
- 2026-08-28: Replaced the previous terminal language with saturated red low `0`, green high `1`, opposing directional tags, an explicit lamp surface, and matching large Test Bench switches. Selection cyan, guide green, port state, and cable hue remain separate channels.
- 2026-08-28: Reduced hover to one line and expanded Inspector click content to formal bilingual names, class, function, input/output port names and widths, behavior, provenance, a separate `Built by you / 由你构建` label, and Handbook navigation. Controller and role-specific MUX/ACC terminology now matches the actual ports and simulation.
- 2026-08-28: Rewrote map/Mission/level/hint copy around the two construction routes, truth-table reasoning, feedback-to-state, Register equations, RAM roles, and the CPU data/control model. The CPU pins a complete opcode/control table and uses four relationship-led stages instead of per-wire instructions.
- 2026-08-28: Official success now exposes Seal, Continue, and Return to Map together. Continue preserves sealing/provenance and then opens the next unlocked Mission.
- 2026-08-28: Inspected fresh normal Windows 1600×900 captures for map, Tutorial, all seven construction levels, signal state, Mission, Inspector, Hint, CPU default/staged view, success, zoom/pan placement, and fullscreen. Current Windows `AppliedDPI` was 144 (150%). Capture evidence is under `.godot/round2-captures/` and is not committed product state.
- 2026-08-28: All fourteen current Godot suites passed in the final source state. A stale prologue UI assertion expecting generic `Control / Word Mux` names was corrected to the actual `Controller / SOURCE MUX / RESULT MUX / ACC Register` contract before the final pass.
- 2026-08-28: Restricted Godot processes without full `user://` access produced native Windows crash dialogs. All later runs used one process at a time, an explicit project-local log, and an unsandboxed Godot invocation; no subsequent crash dialog occurred.

## Unresolved questions and limitations

- Fresh-player comprehension cannot be established by the implementing agent alone. The final report must reserve subjective comfort, clarity, and the novice CPU kill gate for another human playtest after the normal-Windows capture audit.
- A second physical monitor/DPI configuration may be unavailable. Report exactly which Windows scale/window modes were actually exercised.
- Physical click/drag/erase feel was not re-executed through Computer Use after the player's explicit request to avoid it. Synthetic coordinate regressions and normal-window visual captures are complete, but all `R` boxes remain a human Game-mode acceptance gate.
