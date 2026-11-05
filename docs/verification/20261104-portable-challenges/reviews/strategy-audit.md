# Round 3 strategy measurement audit

Date: 2026-11-04. Owner: `/root/review_records_final`. Read-only source audit; no Godot execution, Git mutation, production runtime/test edit, or player-data access.

## Conclusion

The current Chapter 4 model already supports replayable, condition-bound challenges, especially `batches` and `mixed`. It has real copying and working-set tradeoffs, and its existing strict all-case qualification remains suitable for ranking. However, three independent-looking scoreboard columns do not imply three independent optimization dimensions in every task. Do not describe a finite sample frontier as the best possible design, and do not promise that every accepted target can still be beaten.

A bounded probe is ready at `.godot/collaboration/round3-strategy-probe.gd`. Root must execute it in an isolated QA project/profile. It reports actual scoreboard measurements and eligibility, objective minima/ties, sampled Pareto classes, invalid/target-unmet classes, accounting identities, and repeat/JSON trace checks. No new strategy measurements have been made by this reviewer.

## Verified source contracts

- `layout_recipe.gd:15-35`: four fields partitioned into at most four ordered groups; each group has field order and record/field expansion. Recipe block is an integer 0..64. Mapping aligns each group to 16 B, packs real tails, and preserves every logical identity (`:37-65`).
- `layout_simulator.gd:24-70`: native tasks initialize chosen layouts freely; later tasks always start from record-major source. Every case is cold. Full/batch copy incurs real reads and writes; uncopied fields still read source. `:164-180` executes all repetitions/queries for one batch before advancing, then releases scratch.
- `layout_catalog.gd:48-80`: two exact public cases per task; both output and each case's original traffic/cycle/scratch constraints must qualify. Relocation has two independent order recipes; other tasks share one design.
- UI blocks are `[0,1,2,4,8,16]`, hidden for `fields`/`records`; batch UI permits 1..64; relocation UI offers direct/full only (`layout_chapter.gd:179-227`). Model validation is broader: it also accepts other block integers and relocation batch strategies. A challenge envelope should preserve its declared model contract and should not silently redefine this boundary.

## Metrics are related by an exact model identity

For a correct complete run let Q be query values consumed, O be output values, M be copied words, F be RAM line fills. The event costs in `layout_simulator.gd:193-237` give:

- cycles = 2Q + O + 10M + 16F
- RAM traffic = 4M + 16F
- therefore cycles - traffic = 2Q + O + 6M.

Q and O are fixed by the official workload. For a fixed copied-field count, every record is copied once, even with tails, so M is also fixed. Thus cycle and traffic rankings coincide within that subset. In the first three native tasks M=0 and scratch=0 for every legal design: cycles and traffic are affine copies, and the space objective is a universal tie at zero. This is a consequence of the explicit simplified model, not a newly observed bug.

For `mixed`, the two cases have Q=280/126 and O=16/27, giving fixed 2Q+O=855 across both. Copying two fields once per case yields M=68 and cycles=traffic+1263. Existing dated first-increment evidence matches: batch4 `(2495,1232,32)`, batch1 `(2623,1360,16)`, full `(3919,2656,144)`. These are **historical verified fixtures**, not fresh measurements from this audit; see `docs/verification/20261104-gameplay-systems/README.md`. The new probe independently checks the identity against every correct measured sample.

Consequences for replayability:

1. `mixed` has a demonstrated time/traffic-versus-space choice. Its full-copy fixture is dominated by batch4; not every different strategy is a Pareto alternative.
2. Do not present space challenges in native tasks as beatable: zero cannot be strictly improved. The existing field-major `fields` fixture also reaches the cold-line lower bound (2/3 fills for 8/12 words); matching such a target is meaningful evidence, but strict-beat semantics naturally make it unbeatable.
3. Cycle/traffic divergence can only come from changing copied-word count in the present model. The probe includes different field sets to test whether this actually creates qualified Pareto points; source inspection alone does not establish that it does.
4. All cases are fixed and small. Sharing authentic recipes improves local replay but does not itself create an unlimited challenge space. New workloads would need their own condition identities and separate product/model review.

## One modeling question to investigate without changing rules

Batching changes query scheduling as well as storage. Because unselected fields still read source, a batch can copy fields that the main query never consumes and still gain source-cache locality from completing all repetitions within the batch. For `batches`, `[3]` and `[1,2]` are such cold-copy probes. They pay real copying cost, so they are not fake scores. If they compete strongly, the design question is whether forcing a dummy copy to obtain loop tiling is desirable, or whether an explicit source-only tiled strategy deserves later review. No change is proposed as an automatic correction; the probe reports these candidates normally under the current rules.

## Bounded enumeration supplied

Four layout families: all-record, all-field, record-major hot `[0,3]` with cold `[1,2]`, and field-major hot `[0,3]` with record-major cold `[1,2]`. Six UI blocks. Five sorted copy sets: `[0]`, `[3]`, `[0,3]`, `[1,2]`, all four. Nine batch sizes: 1,2,3,4,5,6,8,12,17. Imported direct uses one representative because recipe/copy/batch settings do not execute on that path.

| Task | Complete candidates within this declared sample |
| --- | ---: |
| fields | 4 |
| records | 4 |
| hot_cold | 24 |
| relocation | 121 |
| batches | 1201 |
| mixed | 1201 |
| All six | 2555 |

Relocation A stays direct; B explores direct/full. A has a 307-cycle target. In a cold 17-record source, any full copy has at least 17 source fills and 17 read/write pairs, i.e. at least 442 preparation cycles before querying; direct A is therefore the only qualifying UI strategy. This restriction preserves all UI-qualifying A choices while leaving B's measured choice open.

The probe intentionally preserves distinct recipe descriptions even when their physical mappings or metrics tie. Metric classes retain multiplicity and representative designs. It excludes unsampled groupings, field permutations, copy-field orders, batch sizes 7/9-11/13-16, non-UI block values, and relocation batch strategies. It cannot certify global optimality or absence of a better strategy.

For later full search: 24 field permutations × 54 ordered-cut/group-order variants = 1296 syntactic recipe shapes per block. Canonicalizing singleton group orientation reduces this to 408, still before physical-map equivalence. A full UI-shaped imported search with 408 shapes × 6 blocks × 64 nonempty ordered field subsets × (full + 17 effective batch lengths), plus one direct representative, is 2,820,097 candidates per late task. Do not run that naively with full trace allocation. A separate performance-equivalence proof and address-map deduplication would be needed before a larger exhaustive probe. Within the current 17-record workloads, batch lengths >=17 have the same execution partition as 17, but normalized recipe/trace signatures still differ.

## Root execution and estimated cost

Copy this probe to the same relative location in the already isolated verification project. Its startup guard requires `application/config/use_custom_user_dir=true` and a `VonNeumannBottleneckChecks/` profile name. Root should still verify isolation before launching; ordinary autoload startup is outside the probe's pure evaluator.

```sh
<Godot-4.7.1> --headless --path <isolated-project> --script res://.godot/collaboration/round3-strategy-probe.gd -- --strategy-level=mixed
<Godot-4.7.1> --headless --path <isolated-project> --script res://.godot/collaboration/round3-strategy-probe.gd -- --strategy-all
```

Default is mixed only: 1201 candidates / 2402 official case runs, plus a few repeated/JSON checks. All-six is 2555 candidates / 5110 official case runs plus checks. A hard 2600 candidate bound prevents unintended expansion. It prints progress every 100 candidates and final JSON lines; redirect stdout to an evidence log rather than displaying the entire measurement object in the chat.

The historical capacity benchmark was at most 612.281 ms per 26 candidates on this Mac. Linear extrapolation gives roughly 28 seconds for mixed or 60 seconds for all-six, **only an estimate from a different fixture distribution**, not a measured duration, upper bound, UI-frame claim, or regression threshold. The probe records its actual elapsed time. Sampled objective winners and the initial candidate are independently replayed and JSON-round-tripped; their exact canonical Trace hashes must agree or the probe exits nonzero. Unexpected legal-candidate failures and cycle/traffic-accounting mismatch also exit nonzero.

Static check: `git diff --no-index --check -- /dev/null .godot/collaboration/round3-strategy-probe.gd` produced no whitespace diagnostics (exit1 denotes the new-file diff). GDScript compilation and execution remain unverified until root runs it.

Probe SHA-256: `834a270beb3ba6e871c9ae37cf494c9179c9363ccc2d10ccf11f3d7098545180`.
