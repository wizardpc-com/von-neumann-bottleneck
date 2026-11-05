# Existing strategy sample — 2026-11-04

Root executed the supplied bounded probe with Godot
`4.7.1.stable.official.a13da4feb` on macOS. It measured **2555 candidates** across
the six existing Chapter 4 tasks, in **42.610 seconds**, with no probe failures.
This is a declared finite sample, not an exhaustive search or a global optimum.

| Task | Sampled | Eligible | Distinct eligible metric triples | Sample frontier: cycles / RAM B / peak B |
| --- | ---: | ---: | ---: | --- |
| fields | 4 | 3 | 2 | 122 / 80 / 0 |
| records | 4 | 2 | 2 | 140 / 80 / 0 |
| hot_cold | 24 | 12 | 1 | 1246 / 832 / 0 |
| relocation | 121 | 24 | 1 | 1669 / 1252 / 80 |
| batches | 1201 | 352 | 16 | 1444 / 680 / 16 |
| mixed | 1201 | 352 | 20 | 2207 / 944 / 16 |

Each row has only one nondominated metric triple within this sample. Distinct
recipes can tie that triple. The six tasks yielded 745 eligible candidates in
total. All 1991 correct complete candidates satisfied the exact model accounting
identity below. Thirteen selected initial/winning recipes reproduced their full
rows and canonical per-case Trace signatures on repeat and JSON round trip.

## What changed in our understanding

The previous full-copy versus hot-field batch examples do demonstrate a local
time/space tradeoff, but that comparison is not a Pareto frontier. In this sample:

- `batches`: record layout, copy `[3]`, batch1 gives **1444 / 680 / 16**.
- `mixed`: record layout, copy `[1,2]`, batch1 gives **2207 / 944 / 16**.
  It dominates the previously demonstrated hot-pair batch4
  **2495 / 1232 / 32**, hot-pair batch1 **2623 / 1360 / 16**, and full-copy
  **3919 / 2656 / 144** examples.

These are valid executions of the existing rules, not fabricated scores. The
batch strategy changes query scheduling: it finishes every repetition/query in
one batch before moving on. Reading the cold fields during preparation also
warms source cache lines containing nearby queried fields. The copy incurs real
time, traffic and space, but loop tiling can outweigh it.

For a correct complete execution, let Q be consumed query values, O logical
output values, M copied words, F RAM fills. Current costs imply:

```text
cycles      = 2Q + O + 10M + 16F
RAM bytes   =             4M + 16F
cycles - RAM bytes = 2Q + O + 6M
```

Thus cycles and traffic rank identically when copied-word count is fixed. In
native-layout tasks M=0 and peak scratch=0, so the three displayed metrics are
not three independent strategy axes. A zero-space target can be matched but
cannot be strictly beaten.

## Product decision and compatibility boundary

Keep these valid recipes and existing earned results. The portable challenge
feature remeasures them honestly and does not insert probe solutions into player
rankings. Do not raise targets or invalidate historic work to make rankings look
more varied.

The next model investigation should separate source-only loop tiling from
physical copying, then test whether workloads produce meaningful choices.
An explicit experimental tiled strategy would need its own model/condition
identity and side-by-side old/new evidence before any promotion. Simply adding
resource ceilings cannot create a tradeoff when one sampled design already
minimizes all three metrics. No model change, new workload or new completion
rule was made in this increment.

## Evidence and exact scope

- [Probe](strategy-probe.gd), [raw log](probe.log), [structured measurements and input hashes](results.json).
- [Exact scoreboard used](scoreboard-at-probe.gd.txt). This predates only the
  round3 extraction of its condition hash into a helper; measurements and
  original eligibility are identical. Catalog, recipe, simulator and run bytes
  were asserted equal to the current checkout before execution.
- Runtime reused the previously imported round2 QA project
  `.godot/verification/20261104T203308Z-530aab9a/project` with a fresh
  `VonNeumannBottleneckChecks/20261104-round3/strategy-sample` profile. Original
  project settings were restored byte-for-byte after execution. No player files
  were read, no completion was awarded, and no source simulation file was edited.
- Four recipe families, six UI blocks, five copy sets and nine batch lengths.
  Fields/records use block0; relocation fixes A to direct and samples B direct
  or full. The exact arrays and exclusions are recorded in the probe scope line.
  Unexamined field permutations, groupings, copy orders, intermediate batch
  sizes, non-UI blocks and relocation batch strategies remain outside this result.
