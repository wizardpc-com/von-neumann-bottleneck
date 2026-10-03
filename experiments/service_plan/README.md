# Editable service plan (experimental)

Goal: construct one request grouping/order and per-stream storage representation
for four persistent numerical streams. This isolated lab has no campaign/save
authority. It reuses the existing recurrence weights and RLE byte codec, not a
Transformer, trained model, physical CPU, or real service benchmark.

## Contract, before implementation

All 24 requests are ready at cycle zero: A0–A5, B0–B5, C0–C5, D0–D5.
Players merge adjacent groups, split at any request boundary, move whole groups,
and choose RAW64/RLE64/RAW8/RLE8 independently for each stream. Groups are ordered
lists of requests; every request must appear exactly once, with each stream's
steps increasing. Invalid order is rejected before any simulation event. There
are no authored solution/order presets. Automatic LRU has 1–4 resident contexts.

Each context has eight values. A/B have repeated coordinates (public scalar
inputs); C/D use the older varying-coordinate formulas. Every update computes
`h = Q(0.65*h + 0.35*x)` then `score = w·h`. Weights are exact and fixed.
RAW64/RLE64 pack actual IEEE double bytes; unpack is lossless relative to
GDScript float64. RAW8/RLE8 use actual signed integer bytes on grid [-127,127].
Quantization occurs at initial preparation and every update, even while resident,
so eviction never creates an additional rounding. RLE8 reuses the real byte RLE with two-byte
length header and (count,value) pairs. RLE64 uses word runs: a two-byte element
count followed by a count byte and an actual eight-byte IEEE value per run.
Words compare bytes, preserving signed zero. Its bytes change after each update.
State backing is a fixed four-record directory, with a real two-byte length
entry per record; every state read/write includes its current directory entry.
Initial preparation is offline; every later dirty write pays online packing,
RLE encoding, transfer and replacement. No free final state discard is allowed.

## Explicit teaching costs and resources

One sequential executor; no overlap or arrival prediction. Read all group inputs,
then process requests in group order, then return all group scores. Every request
still has 24 recurrence/score accumulation units at one unit per cycle. Each score
pays one commit cycle plus ceil(8B/4) transfer cycles, without a new setup request.
Weights (64B) load once. Inputs are eight float64 values (64B per request).
Every backing read/write pays 4 request cycles plus ceil(bytes/4) transfer cycles.
RAW unpack/pack: eight conversion operations at eight operations/cycle. Q8 adds
eight round/grid operations per update (one cycle). RLE encode/decode adds
eight values plus run count operations at eight operations/cycle;
conversion base still applies. These are declared units, not hardware timings.

Decoded local contexts always consume 64B, including Q8 storage. Fixed workspace
is 64B weights plus 72B per request in the largest group (input+output). State
encode/decode temporarily needs the actual encoded record+2B length entry; peak
includes this temporary buffer and resident records. Hard scratch capacity 512B;
preflight reserves worst-case RLE size (74B payload+2B directory for float64,
18B+2B for Q8) and rejects excess before execution. Reported actual peak can be
smaller. Backing bytes and changed record sizes are measured separately.

## Three staged contracts

Calibrate from real outputs; exact alternatives must remain legal. Task 1 asks
to reduce context traffic while preserving exact quality and peak≤350B. Task 2 adds timely
first responses from every stream, exposing grouping/fairness and finite LRU.
Task 3 serves the same requests with bounded precision error and tighter traffic,
allowing a mixed per-stream representation. Goals are always visible; Hint1
points to read/write, response and byte evidence rather than prescribing a plan.
Run histories deep-copy complete plan, events and metrics. Editing never alters
an old measurement, and old runs can be restored as editable drafts.

## Acceptance and boundaries

Headless `test_service_plan` must independently verify recurrence/quality,
actual byte roundtrips, dependencies, LRU dirty eviction and flush, deterministic
trace, resource/cost accounting, distinct accepted plans, compression benefits
and failures, immutable UI history and bilingual viewport bounds. Native input,
unknown-answer proxy and screenshot inspection belong to integration verification.
The lab remains experimental: four bounded streams, known ready queue, coarse
units, offline initial preparation, fixed weights and no full allocator/parallelism.

`python3 scripts/verify-project.py --godot
/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_service_plan`

## Calibrated examples (model cycles, not hardware timing)

| Constructed plan | Cycles | State read+write | First responses | Peak |
|---|---:|---:|---|---:|
| Interleaved, 1 slot, RAW64 | 2204 | 3168B | 89/180/271/362 | 266B |
| Per-stream, 1 slot, RAW64 | 1324 | 528B | 89/415/741/1067 | 266B |
| Interleaved, 4 slots, RAW64 | 1324 | 528B | 89/158/227/296 | 458B |
| Interleaved, 4 slots, RLE64/RLE64/RAW64/RAW64 | 1280 | 316B | 78/136/205/274 | 458B |

The final mixed solution is lossless. Uniform RLE64 costs356B of state traffic,
failing the320B contract because the varied streams expand. Uniform RAW8 is another
valid final solution at1236cycles/80B, with real nonzero output/final-state error.
These are QA examples, not loaded presets or inputs to the unknown-answer policy.
