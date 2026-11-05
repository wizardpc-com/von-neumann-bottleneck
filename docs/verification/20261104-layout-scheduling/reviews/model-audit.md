# Round 4 model / strategy audit — 2026-11-04

Reviewer: `/root/review_records_final`. Audit/design only. Existing simulator, task catalogue, recipe mapper, round3 raw strategy evidence and experiment conventions were read. No production/test edits or Godot run.

## Main conclusion

Unconstrained source-only tiling does not by itself create several strategic axes. Under the current fixed record-major source, every 16-byte source line contains one complete record. If all jobs are available together, processing all applicable queries while that source line is resident minimizes source fills without copy writes or scratch allocation. Current consumed-value/output costs are fixed by the workload. It can therefore dominate copying on total cycles, traffic and scratch, and very small tile sizes can tie. Adding a freely available source-tile option to the old model is a useful explanation of the old coupling, but insufficient as a new optimization game.

The smallest credible extension needs **explicit request availability** and **actual per-request response times**, while retaining current memory costs. A known batch permits query fusion; a serial request contract disallows consuming the next request before the preceding response. Persistent software copies can then amortize their real preparation cost across serial requests. The first answer pays preparation, but later scans can use a denser projected copy. These are algorithmic choices, not invented penalties.

Two public contracts should be compared using identical data and logical jobs:

1. **Known batch:** all declared jobs exist at time0. Only contiguous groups in public request order may be fused; records are visited in explicit source tiles. Every response is emitted when that request's final required value and actual output costs finish. Final output vectors remain in original request/index order.
2. **Serial requests:** request j becomes executable only after response j-1. Query group is fixed at1, not a misleading adjustable control. A retained projected copy may be prepared once and reused; preparation is included in first-response time. Future source reads/compute are forbidden before their request release. The entire deterministic request list may remain visible as the scenario contract; this is a dependency boundary, not a claim of unknown input.

Use the completion time of **declared request0** for the first-response objective, not min(response_times): otherwise doing a cheap sparse later job first can game the label. Also expose the real response timeline and total makespan; all memory/output operations retain their current cost. A zero-duration response marker follows the last output event of each job. Sum requests emit one existing 1-cycle output; records requests emit all their ordered values at1 cycle each. Do not charge a second final-output pass.

## Smallest implementation scope to validate first

Keep source record-major, current cache2 ×16B/LRU, lookup1, RAM fill16, write-through word9, compute1, logical output1. Start with no copy versus one full retained selected-field copy using the existing mapper/read/write implementation. This is enough to test whether serial reuse produces a genuine frontier; copying cold unused fields should be an explanatory negative control. Keep the old official model and its scores entirely separate.

A streaming partial-copy window is a separate lifetime rule. If later added, explicitly state that a window is prepared for a query group, all that group's jobs consume the window, and it is released before the next window. It must be recopied for the next request group when the prior windows are gone. Do not accidentally retain freed words across serial requests, or let copy batch size silently determine query group width. Query tiles cannot span unavailable scratch windows. Prefer proving useful behavior of the minimal retained-copy model before exposing three coupled size controls.

Grouping and tile size may be redundant for simple repeated scans. The visible UI should expose only dimensions shown by measurements to alter total work or a response time. Tie-heavy settings are not additional strategy depth.

## Optional proof probe: exact declared scope before authoring

I will write only `.godot/collaboration/round4-model-probe.gd`; root alone may execute it under an isolated `VonNeumannBottleneckChecks/` profile. It subclasses the existing simulator to schedule a faithful small query-value loop using its existing `_read()`/`_event()` memory operations and to emit the existing output cost at actual job completion. The local query loop resolves retained scratch addresses from `current_copy.first_record`, independently of the query-tile origin. It is an unregistered proof instrument, not a new production simulator or official challenge authority.

- Six scenarios: temperature repeated8, temperature repeated16, and the original mixed-A jobs (8 hot-pair sums +1 sparse records request), each under known-batch and serial contracts. All use17 deterministic records and160B scratch; no original completion thresholds are applied.
- Query groups: known repeat8 `[1,2,4,8]`, repeat16 `[1,2,4,8,16]`, mixed9 `[1,2,4,8,9]`; serial `[1]`.
- Record tile lengths: `[1,2,4,8,17]`.
- Four physical plans: direct; full temperature projection `[0]`; full hot-pair projection `[0,3]`; full cold-pair projection `[1,2]`. Preparation uses actual existing reads/writes, full copies persist across the scenario, and source recipes are unchanged.
- Exactly **340 measured candidates** (six scenarios;17 total group choices ×5 tiles ×4 physical plans). At most three selected representatives per scenario are replayed twice for deterministic/JSON identity, adding at most36 runs. Expected workload is below the prior2555-candidate/42.610s sample; this is an estimate, not a runtime claim. Root may use a120s process timeout.
- Report correct output, total cycles, RAM traffic, peak scratch, request0 response, every response time, and finite-sample Pareto classes. Check current cost accounting, one response per logical job, no duplicate output cost, and stable repeated/JSON traces. This sample cannot prove global optimality.

Runtime results remain pending. Recommendations below should be updated from the real probe before implementation is frozen.


## Decisive matrix and interpretation gates

1. Keep old catalogue/model/challenge identities untouched. If production later extracts a small shared query-value helper, verify exact old full canonical traces/metrics for all existing task reference designs, invalid/resource-bound cases, partial tail17, and representative source/copy recipes before and after that extraction. A new experiment's response events must never be emitted by the old runner.
2. Check every logical job's complete output against the existing logical oracle, preserving unsorted/sparse index order, repeats and record-output slot positions. Include partially filled last tiles and query tiles beginning after the retained copy's origin. Exactly one response marker per completed job must occur after that job's last output cycle; no incomplete sum may respond early.
3. Verify each original output cost occurs once. The last response time must equal final makespan when remaining events are zero-duration releases. First-response means job0's recorded completion, including real copy preparation; it is never inferred from total/count or the earliest unrelated job.
4. Serial admission rejects group>1 rather than silently normalizing it. Inspect actual job-tagged read/compute events: job j cannot execute before response j-1. Batch admission may complete sparse later jobs earlier; final logical vector order remains unchanged.
5. Verify actual source reads, copy reads/writes, LRU fills and scratch lifetime. Retained full copy has M=N×selected_fields; no-copy has M=0. The existing exact identity remains `cycles=2Q+O+10M+16F` and `RAM=4M+16F`. Report scratch as projected-copy allocation, not total machine memory: accumulator/output storage is still outside this simplified model.
6. Repeated identical and JSON-round-tripped inputs must preserve full events, responses and identities. Group/tile/admission changes must bind to a new experiment identity even when headline metrics tie. UI timing must not affect any result.
7. Measure the full declared finite sample and report any dominated/no-op control honestly. Do not require copies to win in a known-batch scenario; demonstrating why they lose is itself useful. A serial source-versus-copy first-response/total tradeoff is the minimal shipping gate. If no such pair survives the actual measurements, revise the public workload, not arbitrary cost constants or previous achievements.

### Analytical expectations to verify, not newly executed results

For17 records, eight single-field sums and current costs, the following forecasts follow directly from memory accesses and already-recorded old totals. The fixed probe must confirm all new response timestamps before they are presented as measured:

| Contract / plan | First request cycles | Total cycles | RAM B | Copy scratch B |
| --- | ---: | ---: | ---: | ---: |
| serial, direct | 307 | 2456 | 2176 | 0 |
| serial, retained temperature copy | 557 | 1362 | 980 | 80 |
| known batch, direct/group4/tile1 | 403 | 824 | 544 | 0 |
| known batch, direct/group8/tile1 | 531 | 552 | 272 | 0 |

Thus copying can amortize in serial service at the cost of a later first answer and80B allocation. In known batches, grouping can remove repeated source fills more cheaply; unrestricted tiling is expected to dominate these copy examples. This distinction is explicit workload meaning, not a hidden difficulty adjustment.

## Probe defect and repair before accepted measurement

Root's first copied proof executed340 candidates in5.358s, but copied plans with tiles smaller than17 failed correctness/accounting. That initial result is **not accepted strategy evidence**; its raw failure is retained under `docs/verification/20261104-layout-scheduling/discovery`.

Independent implementation audit identified the cause: the old `_query_batch()` addresses scratch with `(record-first)*4+field`, relying on its old coupled query/copy origin. Calling it with each new query-tile origin against a full copy at0 read earlier scratch records. This was a probe integration defect, not evidence that copying loses or an error in the unchanged official model.

The ignored proof now uses a faithful small value loop with scratch address `(record-current_copy.first_record)*4+field`; real mapping, preparation, cache reads/writes and operation durations still come from the existing simulator. No production source was changed. The serial gate also examines actual lookup/read/compute/fill/evict operations, excluding zero-duration post-query scratch release. Root must rerun this fixed proof; no passing result is claimed here.
