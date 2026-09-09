# Chapter 3: bounded overlap model

Implemented for the user-approved 2026-09-09 expansion. This is an additional
simulation domain; original electrical circuits and Chapter 1/2 timing do not change.
Native Chapter 3 acceptance is still pending in the active execution plan.

## Resources and authority

`src/overlap_chapter/overlap_simulator.gd` produces the existing `SimulationTrace`
and `SimulationEvent` types. The UI consumes their intervals, metrics and per-cycle
resource-state snapshots. Scrubbing, playback frequency, window arrangement and
rendering cannot change a result. Repeated runs start empty and have identical traces.

There is one transfer engine, one compute engine and a FIFO holding two requests
including the active transfer. Workload tables specify transfer time and per-batch
compute time in integer cycles. Issuing an instruction costs zero; waiting or device
work advances time. At a simultaneous boundary: finish transfer, finish compute,
start the next FIFO transfer, then publish state. Maximum run length is 4096 cycles.
Program end drains already issued work; it never supplies missing requests.

The common fixture is four batches, transfer 6 and compute 4. Serial is 40 cycles;
two-buffer overlap is 28, with transfer busy 24, compute busy 16 and overlap 12.
Elapsed time is not the sum of busy time after overlap. Compute wait is elapsed minus
compute busy. The arrival lesson additionally requires exactly four cycles of real
independent work on the same compute engine, yielding 10 elapsed / 8 compute / 6
transfer / 4 overlap / 2 wait.

## Explicit storage and connectivity

Buffers transition empty → filling → ready → in-use → empty. `fetch A 0` requires
an empty A; `ready A` waits on its ready feedback; `consume A` asynchronously starts
compute; `free A` waits for reuse. Compute completion releases the buffer.
Early reads, overwrites, duplicate requests, out-of-order consumption and deadlocks
are errors. `idle` waits for compute; fixed `tick N` is deliberately unsafe as a
substitute for state on variable workloads. All output batches must appear exactly
once in order, with the specified `2 × value + 1` result.

Data ports are eight-bit, state ports one-bit. Wires have zero latency. Multiple
buffers connected to the same engine port represent named batch routes selected by
the program, not electrically shorted voltage sources. A transfer data connection
and free feedback are required to request a buffer; its data route is needed to
consume it and ready feedback to wait for readiness. Topology and program are both
authoritative. This intentionally simplified component protocol is taught publicly.

## Hardware-managed Cache

Cache is distinct from a player-addressed buffer. Each line holds one batch tagged
by batch number. Fills and demand reads update LRU; full caches evict the least
recently used line. A read latches the value when computation starts, so subsequent
eviction cannot change an active computation. Players cannot choose slots or fill
contents directly. `prefetch N` requests a batch; `read N` waits for presence and
starts computation. Both use the same transfer engine. Cached/pending prefetches
coalesce; queue-full issue blocks while already active engines continue.

A read whose data is still in flight is a miss even if prefetch shortened its wait.
The timeline shows this distinction. Over-eager prefetch in the distance starter
causes genuine eviction and refetch: 56 cycles, transfer busy 32 versus the measured
30-cycle schedule with transfer busy 16. There is no artificial prefetch penalty.

## Content and progression

`overlap_catalog.gd` owns six nodes:

```
arrival → buffers → backpressure ─┐
        → prefetch → distance ────┴→ synthesis
```

Chapter 2 capstone opens the common root. Optional hardware applications never gate
it. Arrival is a repair/ordering lesson. Buffers and synthesis start with public
engines and an empty interior. Backpressure supplies an intentionally brittle
schedule on a connected two-buffer machine. Cache lessons retain the unrelated
base machine and ask the player to change scheduling. All workloads and budgets
are public. Backpressure uses two duration patterns; synthesis includes a genuinely
bandwidth-bound case. Both a two-buffer design and a one-line Cache design meet its
28/33-cycle targets. Extra storage cannot increase the single transfer bandwidth.

The editor reuses CircuitGraphEdit, the existing drag palette and floating panels;
blank construction, deletion, undo/redo, direct/branched connections, program text,
independent gated hints, and diagrams remain player-controlled. H1 gives direction,
H2 partial structure, H3 the complete reference after explicit spoiler confirmation.
Hint viewing never changes the player board or earns completion.

## Persistence

The existing atomic global save adds `game.overlap` schema 1 with independent
`solutions` and `drafts`. It never consumes retired eight-task progress. Restoring
completion validates shapes, reruns every saved solution against all current tasks,
and checks prerequisites in order. Invalid solutions lose only their dependent
unlocks; drafts are retained for repair. JSON port indices are normalized to ints.
Old workbench seeds and signed reusable-component provenance are unchanged.

New Game clears completions. Without the optional workbench-clear checkbox, overlap
drafts remain on disk but do not count as resume progress. Selecting that checkbox
also clears these drafts. Tests cover global JSON round-trip and both reset paths.

## Research boundary

The design uses the distinction between issue and completion, and producer/consumer
free/ready handoff described in NVIDIA's primary documentation:
[asynchronous copies](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/async-copies.html),
[asynchronous barriers](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/async-barriers.html).
This game is a small explicit teaching model, not a CUDA or physical-memory emulator.
No real-hardware performance numbers are used as game timing constants.
