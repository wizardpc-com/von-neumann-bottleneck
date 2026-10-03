# Representation recorded cache evidence

Native five-task play showed that the important distinction between compressed storage and decoded cache occupancy is still buried in textual details. Add a compact before/after occupancy visualization to recorded playback, using only cache snapshots copied from the selected actual event. Block identifiers and decoded byte sizes are evidence, not speculative state. If an event lacks either snapshot, say so rather than invent it. No cost, cache policy, simulation, saved plan or completion changes.

Test copied ownership, missing snapshots, cacheable and oversized blocks, and unchanged canonical Trace signatures. Inspect the native render for a hit and a cache-budget miss. Keep animation optional and avoid new sounds without an output acceptance path. Publish only after focused checks and native inspection.

Completed: selected-event cache snapshots are visualized as before/after occupancy with actual byte budgets and block IDs in recorded LRU order. Missing snapshots are explicitly absent. The evidence pane now states the selected recorded partition and whether it differs from the current draft, preventing edited drafts from being confused with old cache evidence.

All three focused suites pass, including defensive snapshot copies, missing-after snapshots, zero retention for an oversized block, immutable signatures and source-plan labeling. Native Linux inspected the same recorded RLE64 plan with64B cache (0→64B) and32B cache (0→0B), plus restored-draft/old-record mismatch labeling. No model, source data, acceptance or audio changes.
