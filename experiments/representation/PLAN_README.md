# Editable representation workshop (isolated experimental route)

`puzzle.tscn` / `puzzle.gd` are separate from the preserved `lab.tscn` selector
experiment. `plan_model.gd` reuses its actual raw/RLE codec and sequential
`SimulationTrace` event emitter, plus the shared automatic `decoded_cache.gd`.
It never calls the campaign registry, saves, receipts, Notebook or telemetry.
A run starts from a freshly encoded, immutable stored asset and an empty cache.
Asset preparation is offline; no online encoding/migration performance is claimed.

## Constructible design

The public 64-byte asset has a 16-byte run, 32 changing bytes and another 16-byte
run. Players can split any selected block at an integer byte address, merge it
with its right neighbor, and independently choose raw or RLE for each block.
There are at most eight blocks. Merge retains the left codec and reencodes the
combined interval. Undo/redo owns copies of complete partitions. There are no
preset solution buttons. Exact ordered coverage, integral nonempty intervals,
byte values, codec, scratch size and request bounds are checked before any event.

Each variable-boundary block pays a **4-byte directory**, including raw blocks:
little-endian 16-bit start and exclusive end. RLE payload additionally contains a
2-byte decoded length and actual (count,value) pairs. Trace publishes directory
and payload bytes separately, and storage/transfer charge both. The directory
is an explicit teaching abstraction, not a simulation of an allocator or physical
seek table; per-block lookup/addressing is included in the fixed request cost.
Raw implicit addressing in the old uniform-block experiment does not apply here.

Requests are synchronous: 4-cycle request, transfer at 1 B/cycle, RLE recovery
at 8 ops/cycle, and one-cycle consumption of each requested value. RLE operations
are output bytes plus run count, rounded up separately for each block. Raw recovery
copies bytes with no additional decode cycles. Scratch can restore at most 64B.
The decoded LRU cache has a 64B budget for a scan and 32B for hotspots. All slots
are automatic; touching a hit makes it newest. A block larger than the cache can
be consumed from scratch but is discarded without evicting useful entries.

`overfetch_values` counts **distinct byte addresses** restored on any miss but
never requested by that order; repeated transfer is independently reflected in
traffic and misses. `decoded_values` counts every full block restoration, including
raw copies. Each consume event records hit/miss, output, actual membership/LRU
before and after, evictions and whether the block could remain cached.

## Three measured tasks

| Task | Actual request order | Public acceptance |
| --- | --- | --- |
| Mixed scan | 0 through 63 | exact outputs, ≤136 cycles, stored ≤60B |
| Two hotspots | 0,63,0,63,0,63 | exact outputs, ≤36 cycles, traffic ≤16B, stored ≤68B |
| One plan, two orders | both orders separately, caches initially empty | same immutable plan, scan ≤136 cycles, hotspots ≤36 cycles/16B traffic, stored ≤60B |

Task evaluation checks the authored workload/machine and, for the paired task,
the same partition as well as metrics. It never requires a named codec/solution.
Passing one task makes the next locally available; draft and previous results
remain intact. A foresighted mixed partition may already pass all three; no
artificial mandatory edit is imposed.

The UI publishes data, ranges, actual encoded sizes, machine costs and acceptance.
History keeps successful and unsuccessful immutable runs with original partitions
and full specs; draft edits cannot change them. An order selector exposes both
paired traces. Event details are bilingual readable text; cache membership, exact
encoded bytes, restored values and consumption are inspectable. Comparison shows
cycle/traffic/storage differences from the immediately preceding same-order run.

## Calibrated causal examples

These are QA references, not buttons in the player UI.

| Plan | Scan cycles | Stored B | Hotspot cycles | Hotspot traffic B |
| --- | ---: | ---: | ---: | ---: |
| raw [0,64) | 136 | 68 | 438 | 408 |
| RLE [0,64) | 155 | 74 | 552 | 444 |
| RLE [0,16), raw [16,64) | 135 | 60 | 189 | 164 |
| RLE [0,16), raw [16,48), RLE [48,64) | 134 | 52 | 36 | 16 |
| RLE [0,14), raw [14,48), RLE [48,64) | 135 | 54 | 35 | 16 |
| RLE [0,16), raw [16,50), RLE [50,64) | 135 | 54 | 35 | 16 |

The two-block scan solution introduces a real next constraint: its raw48B block
cannot stay in the hotspot cache. Splitting the changing center from the trailing
run removes that repeated transfer. Whole-asset RLE expands the changing center;
on a faster link and slower decoder it can also lose to raw through actual work.
A five-block plan with raw one-byte endpoints, RLE fifteen-byte runs and raw32B
center serves hotspots in 24 cycles with 10B traffic but takes 150 scan cycles and
stores 62B, so it is a legal second-task alternative that fails the paired budget.
Different shifted boundaries satisfy the paired task; exact authored endpoints
are not part of acceptance.

## Test and viewport interfaces

Run the conventional isolated verifier with `--suite test_representation_plan`.
It covers malformed coverage, metadata, independently restored payloads, event
cost sums, full outputs, finite LRU, oversized-block bypass, determinism, several
alternative solutions, counterexamples, evidence/spec binding, undo/redo,
record immutability, bilingual rebuilding and campaign isolation. This includes
programmatic UI assertions, not novice play evidence.

Public controls for input replay: `blocks` (Tree; row metadata is block index),
`split_at` (SpinBox), `split_button`, `merge_button`, `raw_button`, `rle_button`,
`undo_button`, `redo_button`, `run_button`, `task_buttons[0..2]`, `history_list`,
`order_choice`, `events`, `details`. Named handles are `Blocks`, `SplitAt`,
`Split`, `Merge`, `Raw`, `RLE`, `Undo`, `Redo`, `Run`, `Task0..2`, `History`,
`RecordedOrder`, `Events`, `TraceDetails`.

Known-objective acceptance path: run raw64; split at16; select first block and
choose RLE; run (scan135/60B); open task2 and run (hotspot failure); select second
block and split at48; select third block and choose RLE; run (36 cycles/16B);
open task3 and run (134/36 cycles); inspect history, transfer/decode/consume events,
edit and undo a boundary/codec, and confirm recorded runs remain unchanged.
Use viewport input rather than direct method calls when claiming playable input
acceptance. Human understanding, smaller windows, controller support, durable
receipt/save/version migration and formal task registration remain separate gates.
