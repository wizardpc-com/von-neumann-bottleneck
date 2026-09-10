# Chapter 4: explicit layouts and relocation

Implementation contract for M1/M2; measured thresholds and evidence are recorded separately. This domain is additive and does not change any old circuit, system, locality or overlap simulator.

## Values and mapping

Records have temperature, identity, battery and alarm fields, each a 4 B nonnegative integer. Logical identity is `(record, field)`. All native layouts contain each identity exactly once; groups are ordered and partition all four fields. Each group has ordered fields and record-major or field-major expansion. A block size of zero means the entire record set; otherwise split into finite record blocks, packing the actual tail without dropping records. Each group starts at the next 16 B boundary; padding is address space, not an extra logical value.

4-1–3 choose a long-lived source format. Initialization is explicitly free and performs no query or cache warmup. 4-4 onward always import the same record-major source; the user selects direct access, a complete selected-field copy, or batches. An unselected field is read from source. Scratch has a distinct aligned region; every initialized destination word comes from an actual read and write of its corresponding source identity. Source is immutable. Batch queries contribute to the same logical output, preserving the public sparse-index order. The final partial batch uses its actual length. All output is compared with an independent logical-record computation.

## Memory and time

One sequential channel, 16 B lines, fully associative LRU with two lines. Each read costs 1 lookup cycle. Misses additionally cost 12 RAM-service and 4 transfer cycles and account 16 B RAM read traffic. Writes are 4 B write-through/no-write-allocate operations costing 9 cycles; any resident target line is updated. Preparing and querying share this cache without secret reset or warmup. Each case begins cold. Freeing scratch invalidates its cached lines before reuse. Failed uninitialized/out-of-range access is explicit.

Arithmetic costs 1 cycle per consumed query value; writing a logical result to the output sink costs 1 cycle per result. This sink is distinct from the 9-cycle RAM write. Prepare/query/output cycles sum to total cycles. Read/write traffic and requests belong to actual operations. Peak extra bytes come from allocated address extent including padding, not the user-entered capacity. Scratch allocation itself adds no timing cost. No overlap, DMA, prefetch, TLB or SIMD is simulated.

## Evidence and persistence

Runs use `SimulationTrace`/`SimulationEvent`, with a layout-specific result carrying ordered outputs and mappings. Events bind logical identity, physical address, cache line, stage and actual bytes. Recipe and strategy signatures bind model and cases; window locations, playback, names and map coordinates are excluded. Restore replays accepted designs; draft/named schemes remain available even when evidence no longer qualifies. New state uses a versioned optional global-save field and never rewrites old-domain progress.
