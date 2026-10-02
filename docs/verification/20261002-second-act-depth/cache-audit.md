# Decoded-cache audit, 2026-10-02

## Finding and source provenance

The alleged missing LRU insertion on a cache miss is **not reproduced** in baseline
`637bcd9`. In the committed `experiments/representation/model.gd`, line 99 has two
leading tabs: `lru.erase(block); lru.append(block)` is outside the one-line `else`
at line 98 and executes after both hits and misses. No behavioral fix for that
allegation was made.

The following exact bytes agree across the baseline Git blob, the initial working
tree, and the earlier isolated QA copy
`.godot/verification/20261002T153423Z-cf53e2bb/project`. Thus no source-provenance
mismatch explains the allegation for these two files.

| File | Git blob | SHA-256 |
| --- | --- | --- |
| `experiments/representation/model.gd` | `6590aae8cf93ba6eccf0aaf8bbbbb7a05c4945e7` | `1ee95b46bb926bd0b83cbb2e0d5fef010b0301660ebcc42f0226ead707089968` |
| `tests/test_second_act_experiments.gd` | `e7b493f4c90f86bb9d6f5f8b75d3ae54f67706c5` | `ff7c2e832fbec271c60ce4f79cd249f96a0b3e57180af4cb592fc80764677d54` |

An independent clean `git archive 637bcd9` extraction was verified at
`/private/tmp/representation-cache-baseline-637bcd9`. Its unmodified legacy suite
passes with Godot `4.7.1.stable.official.a13da4feb` in isolated run
`20261002T160208Z-5751c5b1` (import, user-directory probe, legacy suite all exit 0).
Root also retains a separate committed-source receipt at
`.godot/committed-verification/20261002T160214Z-9aa62265/receipt.json`.

## Deliberate changes

The existing cache is extracted into a pure shared `decoded_cache.gd` helper for
both the fixed-block experiment and the new variable-block representation model.
The legacy model keeps the same codec, cost calculation, outputs, and automatic
replacement policy. Its consume events now include authoritative per-access
`cache_before`, `cache_after`, `cache_hit`, `block`, and `evicted` evidence. The
canonical Trace signature therefore includes these new snapshots.

Helper API:

- `configure(slot_capacity, byte_budget = -1)` resets state. Every resident block
  consumes one slot; a negative byte budget disables only the byte constraint.
- `has(key)` observes membership without changing recency.
- `fetch(key)` returns a detached value array and promotes an existing entry.
  A missing key returns an empty array and leaves state unchanged. `fetch` avoids
  Godot's inherited `Object.get` method name.
- `put(key, values, size_bytes)` stores a detached array, evicts oldest entries
  until **both** constraints fit, and returns eviction keys in order. Replacement
  first removes its old byte reservation, then makes the replacement newest.
  Zero slots, nonpositive sizes, and blocks larger than the byte budget are
  rejected transactionally, preserving all existing entries and recency. Callers
  can check `has` when an insertion might be uncacheable.
- `snapshot()` returns detached sorted resident keys, oldest-to-newest LRU keys,
  per-key sizes, used bytes, slot capacity, and byte budget.

The base experiment reserves scratch space by its existing nominal slot rule;
snapshot byte accounting reports actual resident decoded values, including short
tail blocks. Neither UI state nor playback time participates in these operations.

## Verification

Fresh working-source verifier run
`.godot/verification/20261002T160457Z-e69f3df6` passes import, user-directory probe,
`test_representation_cache` (**1,395 checks**) and the unchanged
`test_second_act_experiments`, each exit 0. All 60 printed legacy representation
configuration cost/traffic rows are byte-identical to the clean baseline run.

The dedicated suite checks resident/LRU membership agreement, unique LRU keys,
slot bounds, byte bounds and exact size sums before/after model accesses. It also
checks literal independent hit/LRU/victim sequences, a separate timestamp-based
reference replacement algorithm, multi-victim variable-size insertion, rejected
insertion, replacement accounting, detached values/snapshots, one/two-slot
behavior, short tails, exact traffic/costs, sequential event clocks, and repeatable
canonical signatures.

Actual implementation mutations were run only in the already imported isolated
QA copy; original helper bytes were restored afterward. Each was rejected with
exit 1. `mutation-results.json` and individual logs live in that run directory.

| Deliberate fault | Detection |
| --- | --- |
| Omit miss insertion into LRU | Dedicated first-insertion probe fails (avoids subsequently exercising intentionally invalid eviction state); the conventional suite also contains a missing-membership detector check. |
| Omit hit promotion | Conventional cache suite fails literal order and subsequent victim/hit checks (20 failure lines). |
| Evict newest instead of oldest | Conventional cache suite fails victim/order and byte-budget sequences (275 failure lines). |
| Allow one extra slot | Conventional cache suite fails per-access slot/membership/behavior checks (546 failure lines). |
| Ignore resident byte budget | Conventional cache suite fails multi-eviction, byte bounds and costs (181 failure lines). |

The initial restricted baseline import failed because macOS denied its isolated
Application Support directory/editor-settings writes; the successful runs used
approved test execution outside the filesystem restriction. An intermediate
helper API named `get` failed Godot script resolution; it was renamed to `fetch`
before the passing final run. These failed runs remain diagnostic evidence rather
than acceptance.

This audit verifies cache behavior and provenance. It makes no novice-playability,
native UI, production campaign, packaged-build or platform acceptance claim.
The root task owns final committed-source regression across the full depth change.
