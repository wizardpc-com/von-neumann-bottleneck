# CPU Building Prologue status

The CPU Building Prologue is the current Hardware Foundations gameplay-validation slice. It starts with the previously validated wiring tutorial and Half Adder, then asks the player to grow that owned abstraction into a small working computer. It is still a prototype: automated coverage establishes correctness and causality, while playtesting must establish whether the construction sequence is enjoyable.

## Playable progression

The campaign opens on a central graphical prerequisite map. Real button nodes show completed/replayable, currently unlocked, and locked states; drawn dependency curves visibly fork into arithmetic/storage lanes and merge at CPU. Titles, descriptions, dependency edges, state, and click routing are derived from the validated campaign registry rather than maintained as a second level list. Only the wiring tutorial is initially available; completing its five interaction checks unlocks Half Adder. Half Adder must pass all four official cases and be sealed before either later branch unlocks. Every construction level starts with a readable automatic component layout and no solution wires. Test Bench inputs/outputs remain visually external to player hardware. An unwired challenge is a neutral incomplete design; genuine shorts and cycles remain explicit live errors.

The global selector defaults to Game mode, where those prerequisites remain authoritative. Test mode makes every valid registered node enterable and supplies a separate temporary library for level factories that require earlier abstractions. It does not mark levels complete, does not replace official circuit evaluation, and never writes helper definitions or test completions into the Game-mode `PlayerContentState`.

| branch | level | player decision and completion evidence | reusable result |
| --- | --- | --- | --- |
| foundation | Wiring tutorial | create, test, remove, and reconnect a visible route with basic gates | unlock Half Adder |
| foundation | Half Adder | wire basic gates; pass all 4 truth-table cases | `HalfAdder` |
| arithmetic | Full Adder | compose two owned Half Adders plus carry logic; pass all 8 input cases | `FullAdder` |
| arithmetic | 1-bit ALU | route AND, OR, ADD, and NOT-A through a selected result; pass 32 exhaustive cases | `ALU1`, then generated `ALU4` |
| storage | SR latch | discover legal cross-coupled NOR feedback; pass reset/hold/set/hold/reset sequence | `SRLatch` |
| storage | 1-bit register | gate `D` into the owned latch with `LOAD`; pass write/hold sequence | `Register1`, then generated `Register4` |
| storage | 2×4 RAM | combine two owned word registers, write decoder, and read mux; retain both addresses across 5 steps | `RAM2x4` |
| integration | 4-bit accumulator CPU | connect control, source/result muxes, owned ALU/register/RAM, and probes; run the 7-step program | `TinyComputer` |
| bridge | LOAD/STORE | observe the same 7-step program through the already sealed computer; no repeated construction | prologue completion and locality-lab handoff |

The dependency graph is intentionally branched. Tutorial completion unlocks Half Adder; the sealed `HalfAdder` unlocks Full Adder and latch independently; CPU unlocks only when both `ALU4` and `RAM2x4` exist. Branches, levels, prerequisites, copy keys, and reward ownership now come from validated content packs rather than a second hard-coded campaign UI list. Resealing a changed upstream design, including Half Adder, invalidates its registered dependent session entries without erasing an independent branch.

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
- A simulation completes before animation starts. Components ready in the same causal wave animate together; all segments of a zero-delay routed net move together along their exact current connection curves. Stateful reusable components retain a compact stored-value readout between transient effects.
- Sealed components keep the player's source topology signature and snapshot. Generated `ALU4`/`Register4` wrappers record the verified one-bit source signature rather than pretending the repeated word implementation was separately built.
- `PlayerContentState` owns completion and reusable rewards, including replacement-driven dependent invalidation. It exposes deterministic identity and a versioned in-memory manifest for future save/assisted-design integration.

## Interaction and presentation

The prologue retains the Turing Complete-inspired editor outcomes established in Hardware Foundations 01 and extends them with a level-aware component menu. The menu deduplicates the hardware types allowed by the current level, excludes unique Test Bench terminals, and lets the player repeatedly place real snapped instances. The one-input `not` is shorter than two-input gates. Left-drag moves or wires; a source and its exact compatible targets receive separate cyan/green guide rings without overwriting live electrical colors, and rendered wires show exact-path hover feedback. Empty-canvas drag replacement-selects; selected hardware recolors its entire procedural symbol cyan with no extra circle, while Shift-click/drag toggles selection or intentionally moves an existing endpoint. Ports, segments, and junctions can start routes; crossings stay disconnected without a visible node; a cursor-tip right-button sweep erases continuously. `Ctrl+A/X/C/V/Z/Y`, WASD view movement, component-plus-wire-node double-click selection, transactional history, and movable/minimizable Mission and Test Bench windows complete the current desktop-editor loop.

One-bit ports are red for low, green for high, and gray for explicit high impedance/unresolved. Multi-bit wire pulses include their word value (for example `0x3`). Gate and high-level components use different procedural processing effects, while terminal bodies remain neutral. These effects are presentation only.

## Intentional temporary limitations

- Campaign completion, window placement, history, clipboard, and reusable components are session-local. Player progress now has a save-ready manifest boundary, but there is no disk serializer, topology restoration, migration policy, or persistent component library.
- Only the fixed component kinds and one-/two-/four-bit widths required by this sequence exist. There is no general HDL, arbitrary component authoring, arbitrary word width, or level editor.
- `ALU4` and `Register4` are generated wrappers after their one-bit concepts pass; the player cannot open their four slices as a separately editable nested graph in this iteration.
- Sequential behavior is a deterministic teaching model at Test Bench step boundaries. There is no free-running clock, edge timing diagram, propagation hazard exercise, analog voltage, metastability, or clock skew.
- RAM is exactly two words × four bits. The CPU has an accumulator and external instructions, not a complete stored-program architecture.
- The final bridge opens the preserved Cache Locality Lab; Cache, Profiler, cache capacity, and software optimization are not part of these construction levels.
- Layouts and procedural art are functional prototypes. Dense player circuits may still need manual routing nodes for visual clarity, and no production art/audio pass is included.
- Components cannot yet rotate. The current Godot graph carrier fixes input ports on the left and outputs on the right; rotation is deferred until symbol geometry, port hit targets, and rendered/simulated endpoints can rotate as one truthful interaction.

## Manual validation questions

Automated tests cannot answer whether the prologue is fun. Playtesting should specifically determine:

- whether free wiring, branching, endpoint movement, erasing, and undo feel predictable;
- whether simultaneous causal waves and distinct component effects make signal propagation understandable;
- whether Full Adder/ALU and latch/register/RAM feel like two meaningful lines of discovery rather than longer wiring checklists;
- whether generated word wrappers remove repetition without weakening ownership;
- whether joining the two branches into the CPU feels like a genuine integration problem;
- whether sealing each design and seeing it reappear downstream feels satisfying;
- whether the final LOAD/STORE sequence makes the CPU/RAM boundary clear and creates curiosity about Cache locality.

Do not extend this prototype into a larger CPU, Full ALU, Cache prologue, or production progression until those questions have playtest evidence.
