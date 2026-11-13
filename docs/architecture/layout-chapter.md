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

## Personal comparisons and challenges

`layout_scoreboard.gd` is a pure read-only evaluator. It accepts candidate recipes
from the current draft, the existing fastest passing solution and named designs,
then executes every current public case. No reference solution or telemetry score
enters the player board. Original correctness, timing, traffic and allocation
constraints determine ranking eligibility; incomplete or target-unmet attempts
remain visible without a rank. Cycles and RAM reads/writes sum the cases; scratch
uses the maximum allocation peak. These are separate objectives with no weighted
score. Equal objective values share competition ranks (1, 1, 3).

Conditions bind task, model version and all ordered cases; recipe identity binds
the per-case recipes actually executed. Normalization preserves JSON round trips.
Changing the sorting objective reorders a copied measurement snapshot while the
exclusive window is open; reopening or saving remeasures every recipe.
Viewing a comparison never grants completion. Restoring a row creates an undoable
draft and invalidates the current result. The ordinary Run all cases path remains
the completion authority.

`layout_scoreboard_window.gd` is an exclusive comparison window, using the host's
current Game/Test accessors. Existing named saves provide persistence without a
schema change. A failed Game write releases the window before showing the existing
save-recovery dialog and retains the in-memory recipe.
Same-name, identical normalized recipes may retry persistence; a different recipe
cannot overwrite a named copy through either ordinary tools or the ranking window;
the shared state rejects replacement and ordinary tools retain the rejected name
and current draft. Only a fresh fully
qualified run strictly improving the chosen metric beats a target; equal
measurements are ties. This offline board makes no online verification claim.

## Portable challenge recipes

`layout_challenge_code.gd` encodes `VNB4C1:` plus canonical JSON; the entire code
is at most4096 UTF-8 bytes. The exact fields are v/task/model/condition/objective/design.
Every nested key, type, finite integral range, field partition and strategy is
checked before normalization. Extra scores, completion flags, unknown data,
duplicate keys and noncanonical spellings reject. Relocation carries exactly
two independent A/B designs and reconstructs an inert internal root container.
The shared scoreboard condition helper binds current model and all ordered
official cases, including their constraints.

Structural decode can retain supported old conditions. Active inspect additionally
requires current task/model/condition and remeasures every official case.
Imported values never determine scores. Export, checking and pinning do not modify
the current draft, Undo/Redo, named recipes or progression. Applying the target
recipe uses the existing explicit undoable restore action. Sorting remains
independent of the pinned objective; Keep target retries the exact original code.
Native-layout scratch targets can be zero and thus cannot be strictly improved.

`layout_challenge_store.gd` is retained by LayoutChapter but excluded from its
GlobalSave snapshot. Game targets live in optional
`user://layout_challenges_v1.json`; Test targets use separate process-lifetime
memory and never read/write that Game file. One target per known task, at most6,
is stored as code/title under an exact schema1 root, with a32KiB file bound.
Titles remain local. Loading validates the entire file; malformed, unknown,
oversized or identity-mismatched content is protected read-only. Supported old
conditions remain copyable but inactive. File reads/measurements award nothing.

Game writes check original-file identity, prepare a sibling temporary file,
flush/check it, recheck the original and atomically replace it. Failure preserves
both prior saved bytes and prior store memory. The host can retain the new target
for this visit with explicit temporary wording. On revisit, it identifies the
previously persisted target or the absence of one. Identical-target retry is
supported. Older software ignores the sidecar; reverting this feature does not
require a main-save migration or deletion.

The existing exclusive ranking Window hosts a table page and a code page.
Import opens an empty editor; only explicit Check triggers parsing/replay, and
explicit confirmation pins the preview. Any text edit invalidates confirmation.
Share only writes the clipboard on Copy; selectable text provides fallback.
Back/Escape returns focus to the opening action, and ordinary feedback closes
before the code page. Host actions reject a changed Game/Test context.

The [bounded strategy measurement](../verification/20261104-portable-challenges/strategy/README.md)
found one nondominated metric triple per task in its2555-candidate sample,
including cold-field batch strategies that dominate earlier examples. It does
not establish global optimality or justify invalidating valid old work. The
separately versioned investigation below keeps those official results intact.

## Separate scheduling experiment — 2026-11-04

The optional `experiments/layout_strategy/` domain separates source-only query
grouping/record tiling from one retained full selected-field copy. It uses a
distinct model/condition identity, with causal request admission and actual
response completion for each job. Q1 measures the first submitted request.
All existing memory reads/writes/fills and output charges remain real operations;
scratch reports only copy allocation. Batch and serial admission are separate
public workloads, not changes to any official task or its targets.

The pure session provides24 measurements and64 edits per workload with explicit
comparison and undoable restoration. It writes no experimental results to player
saves, official challenge codes or progression. The two extracted original
simulator helpers preserve141 frozen recipes across282 official cases, including
complete canonical Trace signatures. The experiment runner installs its isolated
profile before autoloads start. Removal of the standalone entry requires no data
migration. See the [rules](../../experiments/layout_strategy/README.md) and
[verification](../verification/20261104-layout-scheduling/README.md).
