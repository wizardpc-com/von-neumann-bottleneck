# CPU Building Prologue status

The CPU Building Prologue is the current Hardware Foundations gameplay-validation slice. It starts with the previously validated wiring tutorial and Half Adder, then asks the player to grow that owned abstraction into a small working computer. It is still a prototype: automated coverage establishes correctness and causality, while playtesting must establish whether the construction sequence is enjoyable.

## Playable progression

The campaign opens on a central graphical prerequisite map. Real button nodes show completed/replayable, currently unlocked, and locked states; drawn dependency curves visibly fork into arithmetic/storage lanes and merge at CPU. Titles, descriptions, dependency edges, state, and click routing are derived from the validated campaign registry rather than maintained as a second level list. The map itself has no Test Bench or Test Bench reopen action. Its movable, focusable, closable/reopenable Mission window receives a reserved left lane that does not overlap any level node. Only the wiring tutorial is initially available. Completing its five interaction checks independently unlocks the Half Adder at the start of the CPU/arithmetic lane and the SR latch at the start of the storage lane. Every construction level starts with a readable automatic component layout and no solution wires. Entering one first centers a two-to-four-page Mission briefing whose page count follows the actual teaching load: the wiring tutorial, Half Adder, and SR Latch use four pages, the LOAD/STORE observation uses two, and the remaining construction levels use three. Previous returns one page, Continue remains centered, and Continue on the last page moves the readable Mission content into a lower-left compact window matching Test Bench width. Beginner-facing copy introduces unfamiliar concepts in context, uses small text diagrams only where they clarify wiring or data flow, and links every marked technical term directly to the shared Handbook. The title-bar action performs the same compact/restore transition at any point, while the taskbar entry toggles close/open and preserves the current geometry. Inside a playable level, Test Bench inputs/outputs remain visually external to player hardware. Single-bit Test Bench controls use a red circle for low `0` and green diamond for high `1` as an intentionally replaceable asymmetric placeholder. An unwired challenge is a neutral incomplete design; genuine shorts and cycles remain explicit live errors.

The global selector defaults to Game mode, where those prerequisites remain authoritative. Test mode makes every valid registered node enterable and supplies a separate temporary library for level factories that require earlier abstractions. It does not mark levels complete, does not replace official circuit evaluation, and never writes helper definitions or test completions into the Game-mode `PlayerContentState`.

Every playable level now owns named workbenches. Entering a level creates `default` when needed; the toolbar selector can create a clean named alternative or switch between existing designs. Component specifications, stable IDs, positions, route nodes, and wires persist locally per Game/Test mode and level. Switching never restores undo/redo, selection, trace, test receipts, debug inputs, or runtime memory.

The top-right Hint button enters a separate read-only workbench and progressively reveals three stages: conceptual questions with fixed ports, a curated partial subcircuit capped near forty percent of the reference wires, then the full reference topology. The Half Adder's second stage now shows only its small CARRY branch rather than completing SUM. Closing it reconstructs the exact active player workbench. Hint graphs cannot run official tests or sealing, so even the complete answer is inspectable evidence rather than a hidden completion shortcut.

| branch | level | player decision and completion evidence | reusable result |
| --- | --- | --- | --- |
| foundation | Wiring tutorial | create, test, remove, and reconnect a visible route with basic gates | unlock Half Adder |
| arithmetic / CPU | Half Adder | wire AND/OR/NOT gates; pass all 4 truth-table cases | `HalfAdder`, then XOR becomes available in later arithmetic palettes |
| arithmetic | Full Adder | compose two owned Half Adders plus carry logic; pass all 8 input cases | `FullAdder` |
| arithmetic | 1-bit ALU | route AND, OR, ADD, and NOT-A through a selected result; pass 32 exhaustive cases | `ALU1`, then generated `ALU4` |
| storage | SR latch | discover legal cross-coupled NOR feedback; pass reset/hold/set/hold/reset sequence | `SRLatch` |
| storage | 1-bit register | gate `D` into the owned latch with `LOAD`; pass write/hold sequence | `Register1`, then generated `Register4` |
| storage | 2×4 RAM | combine two owned word registers, write decoder, and read mux; retain both addresses across 5 steps | `RAM2x4` |
| integration | 4-bit accumulator CPU | connect control, source/result muxes, owned ALU/register/RAM, and probes; run the 7-step program | `TinyComputer` |
| bridge | LOAD/STORE | observe the same 7-step program through the already sealed computer; no repeated construction | prologue completion and Chapter 1 CPU/RAM provenance handoff |

The dependency graph is intentionally branched at the tutorial. Tutorial completion unlocks Half Adder and SR Latch independently. The sealed `HalfAdder` unlocks Full Adder and the XOR primitive offered by later arithmetic palettes; it is not a storage prerequisite. CPU unlocks only when both `ALU4` and `RAM2x4` exist. Branches, levels, prerequisites, copy keys, component supplies, and reward ownership come from validated content packs rather than a second hard-coded campaign UI list. Resealing a changed Half Adder invalidates only its registered CPU/arithmetic descendants and never erases the independent storage branch.

## CPU contract and official program

The prologue computer is a four-bit accumulator machine with two four-bit memory words. The fixed external Test Bench supplies `OP` (2 bits), `ARG` (4 bits), and `ADDR` (1 bit). Its four instruction contracts are:

- `0`: `LOAD_IMM ARG`
- `1`: `ADD_IMM ARG`
- `2`: `LOAD_MEM ADDR`
- `3`: `STORE_MEM ADDR`

The official sequence loads `3`, stores it to address `0`, loads `5`, adds `2`, stores `7` to address `1`, reloads address `0`, and adds `4`. Both the graph-built CPU challenge and the sealed-component bridge must expose the expected accumulator and addressed-memory value after every step.

This external instruction stream is deliberate scope control. Instruction memory, fetch, program counter, general decoding, assembly editing, pipeline, and a realistic ISA are not claimed as implemented.

## Simulation and ownership contract

```text
displayed component catalog + GraphEdit connections
  -> LogicCircuit canonical topology
  -> deterministic combinational/temporal PrologueSimulator
  -> complete values, runtime state, errors, and causal events
  -> parallel component effects + exact rendered wire paths

official Test Bench pass + unchanged topology signature
  -> cloned source circuit/signature and named interface
  -> session ReusableComponent
  -> dependent campaign unlocks
```

- Actual challenge outputs always come from the player's visible wiring. Catalog reference wires exist only for automated tests and deterministic capture hooks; player-facing construction levels do not load them.
- Named input/output ports carry fixed widths. Incompatible widths fail rather than truncate or extend silently.
- Unconnected inputs are low. Connected `Z` remains high impedance; matching active drivers agree, opposite active values short, and illegal combinational feedback reports a cycle.
- Basic gates have a uniform one-tick delay. Ordinary wires and every explicit routing junction have zero latency regardless of geometry or junction count.
- SR-latch feedback is the only raw gate-feedback exception. `S=R=1` is invalid. Register, RAM, and computer state changes only at a Test Bench sequence boundary.
- Storage Test Benches separate live preview from committed state. Editing `S/R`, `D/LOAD`, or address/data/write inputs updates port previews; **Run Current** advances one boundary, while **Reset storage state** clears only the current level's temporal debug state and preserves its topology.
- Every state boundary emits explicit set/reset/write/hold/read evidence, including unchanged HOLD/READ operations. Official storage rows show the requested action and simulator-derived state before and after the step; both RAM word registers commit/hold in one parallel wave.
- Each official case computes immediately before its own animation, but later cases and the aggregate verdict remain unpublished. Components ready in the same causal wave animate together; all segments of a zero-delay routed net move together along their exact current connection curves. The editable Clock Period sets each visible wave's duration without changing evidence. Stateful reusable components retain a compact stored-value readout between transient effects.
- Sealed components keep the player's source topology signature and snapshot. Generated `ALU4`/`Register4` wrappers record the verified one-bit source signature rather than pretending the repeated word implementation was separately built.
- `PlayerContentState` owns completion and reusable rewards, including replacement-driven dependent invalidation. It exposes deterministic identity and a versioned in-memory manifest for future save/assisted-design integration.

## Interaction and presentation

The editor also exposes a compact named-workbench selector and a top-right Hint action. Workbench switching reconstructs saved components, positions, route nodes, and wires with an intentionally empty operation history. Hint stages reconstruct separate read-only graphs and never enter the player's snapshot or official evidence. The application starts in resizable fullscreen; the visible toggle, `F11`, or `Alt+Enter` switches modes. Mission, Test Bench, and Components pages retain their desktop-style position and size across incidental canvas relayouts, shrinking or moving only when required to stay completely reachable after a real viewport/aspect-ratio change. `Esc` cancels an active editor gesture first; otherwise it returns from a level to the campaign map, and a second press returns to chapter selection. Chapter 1 and Chapter 2 follow the same level/map/chapter hierarchy.

The prologue retains the Turing Complete-inspired editor outcomes established in Hardware Foundations 01 and extends them with an explicit per-level component supply. A movable/resizable/closable Components window shows a scaled copy of each real canvas component beside its name instead of a separately drawn approximation: dragging places one real snapped instance, while clicking arms repeated placement. Palette thumbnails, low-opacity pointer-follow previews, and committed nodes share the same procedural symbol/row, port, and state-label construction, so multi-row parts such as SRLatch retain identical geometry and state presentation at every stage. The default task/test pages are wide enough for their controls but use compact content-based heights; the wider, shorter Components page stays at the right edge, leaving a large unobstructed center workspace. The armed component appears at the exact snapped position without a substitute card. Arming, repeating, or cancelling placement does not resize the toolbar, circuit desktop, or any floating page. Each empty-canvas left click commits one undoable instance and keeps placement armed. Right click cancels without erasing; interacting with an existing component, port, wire, or another editor action cancels before that normal action continues; choosing a different palette item replaces the preview. The fallback toolbar menu uses the same supply and transaction. Unique Test Bench terminals remain external and cannot be spawned. AND, OR, XOR, NOR, and NOT use distinct schematic symbols; the one-input `not` is shorter than two-input gates. Level input/output tags face opposite directions; encapsulated adders, muxes, ALUs, control/decoder fan-out, registers, RAM, and CPU use distinct public-function diagrams. Advanced modules reserve separate port-label, function-icon, and full-name regions inside a slightly wider readable footprint. Processing strokes stop at those regions instead of passing through characters, while a surface-colored name plate and dark text outline preserve contrast during selection and playback. Left-drag moves or wires; a source and its exact compatible targets receive separate cyan/green guide rings without overwriting live electrical colors, and rendered wires show exact-path hover feedback. A 12-pixel visible port sits inside the unchanged generous interaction target. Each settled connection is one custom exact-curve cable; its hue is player metadata selected with `1`–`9`, applied to a hovered segment/net with `Ctrl+F`/`Ctrl+E`, and sampled with `Ctrl+R`. Empty-canvas drag replacement-selects; selected hardware recolors its entire procedural symbol cyan with no extra circle, while Shift-click/drag toggles selection or intentionally moves an existing endpoint. Ports, segments, and junctions can start routes; crossings stay disconnected without a visible node; a cursor-tip right-button sweep erases continuously. `Ctrl+A/X/C/V/Z/Y`, press/release-driven WASD with immediate canvas-focus recovery, component-plus-wire-node double-click selection, transactional history, a movable/closable Mission window, and movable/resizable/closable Test Bench and Components windows complete the current desktop-editor loop. Test Bench and Components intentionally omit minimization; their taskbar actions still close and reopen them without losing geometry.

The first authoritative completion of each of the nine levels presents a localized modal summary of the concept just established. A short low-volume procedural cue plays as presentation only. **Continue** dismisses the summary and returns to the same graphical campaign map; it does not skip prerequisites or alter the circuit evidence that produced completion.

Ports remain red for low, green for high, and gray for explicit high impedance/unresolved, independently of the player's cable hue. Valid input changes automatically replay the completed trace: one-bit cable and component strokes update causal wave by causal wave with same-wave branches in parallel, and no detached data point is drawn. Wider transfers add one dark-backed word badge (for example `0x3`) moving on the exact cable. RAM highlights the addressed one of its two displayed four-bit word rows. These effects are presentation only.

## Intentional temporary limitations

- Named workbench topology and component positions persist locally in a version-1 file. Campaign completion, reusable components, window placement, history, clipboard, debug values, and runtime storage state remain session-local; there is no coordinated whole-game save or persistent component library yet.
- Workbenches can be created and switched but not renamed/deleted/shared. Unknown future snapshot schemas are rejected rather than guessed.
- Only the fixed component kinds and one-/two-/four-bit widths required by this sequence exist. The user-set Clock Period is presentation-only; there is no player-authored general clock, HDL, arbitrary component authoring, arbitrary word width, or level editor.
- `ALU4` and `Register4` are generated wrappers after their one-bit concepts pass; the player cannot open their four slices as a separately editable nested graph in this iteration.
- Sequential behavior is a deterministic teaching model at Test Bench step boundaries. There is no free-running clock, edge timing diagram, propagation hazard exercise, analog voltage, metastability, or clock skew.
- RAM is exactly two words × four bits. The CPU has an accumulator and external instructions, not a complete stored-program architecture.
- The final bridge captures opaque source signatures from the player's verified `TinyComputer`/ALU/Register and `RAM2x4`, then opens Chapter 1 with compatible CPU8/RAM64x8 system wrappers. Cache and performance optimization are still not part of these construction levels; the preserved Cache Locality Lab remains a separate hub entry.
- Layouts and procedural art are functional prototypes. Dense player circuits may still need manual routing nodes for visual clarity. The completion cue is a replaceable procedural placeholder; no production art, authored music, or broader audio pass is included.
- Components cannot yet rotate. The current Godot graph carrier fixes input ports on the left and outputs on the right; rotation is deferred until symbol geometry, port hit targets, and rendered/simulated endpoints can rotate as one truthful interaction.

## Manual validation questions

Automated tests cannot answer whether the prologue is fun. Playtesting should specifically determine:

- whether free wiring, branching, endpoint movement, erasing, and undo feel predictable;
- whether the truthful low-opacity preview makes repeated placement fast, and whether right-click/other-content cancellation ever surprises the player;
- whether the map's dedicated Mission lane keeps every level node readable while the panel still feels like an operable desktop window;
- whether simultaneous causal waves and distinct component effects make signal propagation understandable;
- whether Full Adder/ALU and latch/register/RAM feel like two meaningful lines of discovery rather than longer wiring checklists;
- whether generated word wrappers remove repetition without weakening ownership;
- whether joining the two branches into the CPU feels like a genuine integration problem;
- whether sealing each design and seeing it reappear downstream feels satisfying;
- whether keeping named alternative workbenches encourages experimentation without confusing players about which design is active;
- whether the three hint stages provide useful escalation without making stage 2 or 3 feel like involuntary spoilers;
- whether the final LOAD/STORE sequence makes the CPU/RAM boundary clear and creates curiosity about waiting time in Chapter 1.
- whether each localized completion summary accurately states the lesson, the cue feels rewarding rather than intrusive, and Continue returns to the map at the right moment.

Do not extend this prototype into a larger CPU, Full ALU, Cache prologue, or production progression until those questions have playtest evidence.
