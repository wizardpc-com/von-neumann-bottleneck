# First-use guidance and illustrated lookup

This is an inventory of the current learning surface, not evidence that a first-time
player has understood it. All 29 prior playable nodes retain their behavior and prerequisites; five optional branches bring the total to 34.
The original Mission pages remain reopenable. Toolbox cards and control tooltips
explain optional actions at their point of use; reading is never a new unlock gate.

## Introduction before required use

| First need / level | Introduction and available reference |
| --- | --- |
| Tutorial: values and NOT | Goal page explains 0/1; behavior page and NOT term show inversion. |
| Tutorial: choose/place/connect | Open toolbox; place/cancel note before cards; operation page explains drag, repeat placement and matching ports. |
| Tutorial: correct mistakes | A separate erase/undo page precedes the required erase/reconnect exercise. |
| Tutorial: navigate the canvas | Separate zoom/pan and focus page; toolbar tooltips retain selection and view shortcuts. |
| Tutorial: practice and task review | Verification page introduces Test Bench, input switching, running, and reopening Mission. |
| Optional editor tools | Named-scheme menu/name dialog explains new or blank schemes; selection/editing toolbar and Inspector tooltips explain shortcuts and wire operations. These are optional, not unintroduced success requirements. |
| Hints | Hint entry and each confirmation identify increasing disclosure; H1/H2/H3 remain separate from the player board. |
| Half Adder | Binary, SUM/CARRY, gate behavior, then a separate branch/junction page. Sealing is explained in the completion action. |
| Selector (optional) | Public selection behavior and truth table; multiplexer reference is available when this branch first opens. |
| Four-way selector (optional) | Four data lines versus two control bits; full numbering table on the second Mission page; gate and MUX lookup. |
| Parity (optional) | Count odd/even ones across five 1-bit inputs; one-flip/two-flip example explains detection limits before building. |
| Alarm (optional) | First state retention, then clear-priority truth/sequence rules; SRLatch and logic lookup. |
| Full Adder | CIN/COUT and reuse before the complete formal test. |
| ALU | Width guide and opcode contract before wiring; width and MUX diagrams are available. |
| Latch | NOR and feedback, SET/RESET, then state-transition specifications. |
| Register | D/LOAD/Q and write/hold behavior before time-sequence testing. |
| Delay (optional) | Initial zero, accept/hold and previous-value behavior before the test. |
| RAM | Address, decoder, write/hold and independent words before wiring. |
| CPU | Accumulator, public opcodes, modules, stages and verification on separate pages. |
| LOAD/STORE | Memory effects and public program behavior before testing. |
| Assembly | Explicit 8-bit model transition, CPU/Bus/RAM routes, applied program and formal cases. Parts opens alongside Mission. |
| CPU speed / RAM wait | Prediction, one controlled change and wait/compute comparisons are introduced by Mission and the Profiler. |
| Bus width | Bits per transfer versus datum width and serialization; bandwidth diagram. |
| Bottleneck | Budget, comparison and diagnosis before the final verdict. |
| Read once (optional) | Fixed hardware, twice-sum modulo 256 and each-case request limit; applied program and real metrics reuse earlier system lessons. |
| Two orders (optional) | Two fixed workloads, separate saved part choices, budget 24 and each target listed before configuration. |
| Distant reads | Request round trip and CPU waiting before observation. |
| Nearby storage | Close storage behavior and first-fill/reuse before configuration; storage controls open when available. |
| Cache failure | Line, miss and eviction explained before the access-pattern comparison. |
| Access order | Spatial locality and row/column traversal before applying a program. |
| Working set | Reuse across passes and capacity before experiments. |
| Blocking | Work groups and two-pass order before the blocking control. |
| Locality capstone | Existing tools combined; no new required mechanism. |
| Arrival | Request versus arrival, independent work and wire widths; progressive command cards in the editor. |
| Buffers | Open buffer toolbox, ready/free states, two-buffer role-swap diagram and bounded queue reference. |
| Backpressure | Variable workload specification and state waits; step through ready/free states. |
| Prefetch | Hardware-managed cache and arrival-before-read; request/arrival and queue diagrams. |
| Distance | Eviction of unused A by B and fetching A again, one step at a time. |
| Synthesis | Existing buffer/cache options; both public workloads, costs and targets remain visible. |

The three optional optimization goals are shown with their existing tasks: cost 4 / 145 cycles in Locality capstone, avoid repeated transfers in Distance, and retain two actually executed routes in Synthesis. They do not add prerequisites. Compatible own-solution copying explains that the target still needs retesting.

## Pacing and lookup contract

- The shared Handbook recommends at most three topics for the current lesson.
  Recommendations expand immediately; search, category lookup and the recommendation
  toggle retain access to every already available specification. Direct Mission
  links clear filters. Future entries keep their real prerequisite and hide diagrams.
- The original 89 terms remain; bit width and six overlap concepts bring the total
  to 96. Availability is derived from campaign state, with no new saved unlock field.
- Tutorial separates placement, correction and view navigation. Third-chapter
  command cards show one line at a time, with Previous/Next for the remaining commands.
- Interactive diagrams are explicitly illustrative. Their arrows change example
  state only, never the circuit, simulation, progress or saved solutions.
- Wire length remains zero-latency connectivity. The request illustration explicitly
  attributes elapsed time to the modeled transfer engine, not screen distance.

## Limits

Optional editor shortcuts still rely partly on contextual tooltips rather than a
forced walkthrough. This is intentional to avoid making every player read a manual
before the first wire. Native checks and automated availability tests cannot prove
that all newcomers discover those hints or find the progression fun. That requires
first-time player observation; change lesson pacing from such evidence rather than
adding more mandatory pages by default.
