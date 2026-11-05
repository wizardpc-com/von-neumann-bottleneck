# Round7 strategy/content audit

Owner `/root/audit_scores`; read-only audit at clean task-branch milestone
`e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8`. No project file, save, engine process or
Git state was changed. This report recommends a scope for root to approve and
freeze; it is not an implementation or a new runtime acceptance claim.

**Recommend exactly two additional fixed serial workloads: `scan_pair_serial`
and `split_fields_serial`.** They expose different existing strategic decisions
without changing any simulation operation, score formula, model version or
existing workload. Preserve the four current IDs in their current order, append
the two IDs, and give each a separately persisted condition context.

## Evidence checked

Read the complete committed Round6 structural/copy-block probe sources, logs,
raw structural results and strategy audit, together with current Model, Session,
Goals, challenge codec, output/Trace types and the relevant model/legacy tests.
The structural log reports 1475 candidates, 48 repeat/JSON executions, no failed
assertions; the independent copy-block log reports 1140 executions, no failures.
The raw structural records contain the exact task data, actual metrics,
admission/response arrays, condition IDs and full-Trace hashes cited below.

Current source SHA256 values still equal the probe's `model-sha256.json` bindings:

| File | SHA256 |
| --- | --- |
| `experiments/layout_strategy/model.gd` | `8c980ac8a9e09fd4a491d3cf392a267cd64108550af77cf54bd95a0f2b36b23f` |
| `experiments/layout_strategy/goals.gd` | `61dc805b8cec1fd4bc19a16cd1191021f0b467cb2f6c40ad972471a75e174abb` |
| `src/layout_chapter/layout_recipe.gd` | `37a85a9e58ceddd4ac417aea0b0a1bd9ee8de1edee487e142b3d66727237627a` |
| `src/layout_chapter/layout_simulator.gd` | `a8941642055d2e968817921115fb7b3387ea17c1582bcd272bbf2dfecee46387` |

Principal evidence:

- `docs/verification/20261104-layout-replay-challenges/strategy/structural-results.json`
- `docs/verification/20261104-layout-replay-challenges/strategy/structural-probe.gd`
- `docs/verification/20261104-layout-replay-challenges/strategy/structural-probe.log`
- `docs/verification/20261104-layout-replay-challenges/strategy/README.md`

The evidence is a finite sampled search. Neither the 17-plan structural sample
nor the broader 220-map probe certifies all legal layouts or global optima.
The new-ID executions still need to run after root freezes the definitions.

## Exact proposed task definitions

Both use the unchanged 17-record salt0 dataset, record-major immutable source,
four 4-byte fields, existing 2-line/16-byte fully associative LRU cache, serial
admission and 160-byte maximum copy allocation. No new dependencies, costs,
arrival-time parameters, data mutations, dynamic job creation or score weights.

For record index `i` in `0..16`, the existing records are exactly:

```text
[10 + (7*i)%23, 100+i, 30 + (11*i)%70, i%2]
```

This formula describes the already measured fixed values; it is not a new
random seed. Their temperature sum is 363 and alarm sum is 8.

| New fixed ID | Suggested Chinese / English label | Exact normalized queries | Ordered expected outputs |
| --- | --- | --- | --- |
| `scan_pair_serial` | 两次温度扫描 / Two temperature scans | `[{"kind":"sum","fields":[0],"repeat":2,"indices":[]}]` | `[363,363]` |
| `split_fields_serial` | 分阶段字段扫描 / Phased field scans | `[{"kind":"sum","fields":[0],"repeat":4,"indices":[]},{"kind":"sum","fields":[3],"repeat":4,"indices":[]}]` | `[363,363,363,363,8,8,8,8]` |

Each task also has exact keys `id`, `records`, `queries`, `release:"serial"` and
`scratch_limit:160`. Keep the empty `indices` and explicit `repeat` canonical
normalization used by current `Model.scenario()`.

Declared sizes are34 query values/2 output values/2 jobs for the pair and136
query values/8 output values/8 jobs for phased fields. Current conservative
event-bound arithmetic gives519 and1047 events respectively, both far below
the unchanged32768 limit. No MAX_JOBS/MAX_QUERY_VALUES/MAX_OUTPUT_VALUES
increase is needed.

The expected vectors above were independently recalculated from the actual
stored task records using ordinary arithmetic during this audit. Prior Godot
probe assertions checked each actual run against `Simulator.expected(task)`;
this audit itself did not rerun Godot.

Public description should list Q1–Q2 or Q1–Q8 in authored order. “Phase” means
the first four admitted requests ask only for temperature, followed by four
requests for alarm. It does not mean later source data is hidden or arrives
later. The source is known and immutable; preparing an alarm copy before its
first request remains legal and its real preparation cost belongs to Q1.

Both new workloads are serial by design, so only `query_group=1` executes.
The two-job workload has an actual count of 2, the phased one 8; current mixed
tasks still have 9. Derive counts from expanded queries, not names or fixed
8/9 assumptions. `record_tile` remains a preserved plan choice, but with one
job per group and these ascending full scans it does not improve metrics.
Keep the existing UI explanation/disabled control rather than imply a
productive scheduling choice.

## Why two serial scans add a real decision

Committed probe label `full_scan_serial_r2` used the same structure temporarily
under `scan_serial`; it must become the new ID above before being playable.
Metrics are **Q1 / total cycles / RAM bytes / peak copy allocation bytes**:

| Actual recipe | Metrics | Responses | Admissions |
| --- | --- | --- | --- |
| Source only; group1/tile17 | `307 / 614 / 544 / 0` | `[307,614]` | `[0,307]` |
| Retained field0 copy; record-major; group1/tile17 | `557 / 672 / 500 / 80` | `[557,672]` | `[0,557]` |

The copied run saves **44 RAM bytes** but spends **58 more total cycles**,
answers Q1 **250 cycles later**, and needs **80 bytes of scratch**. The 80-byte
value is padded allocation; actual copied payload is 17 words / 68 written
bytes. These must not be conflated in explanations or caps.

The raw probe's actual `Goals.rank` selected the direct recipe for total cycles
and the copied recipe for RAM traffic under the same inclusive Q1≤600/copy≤80
envelope. This is the missing objective distinction in the shipped finite
frontiers, where lower total work and lower RAM traffic largely move together.
It gives the player a reason to change the goal and keep more than one recipe.

The measured accounting explains the trade without an artificial penalty.
Here Q=34 values and O=2 outputs. Source: M=0/F=34 gives
`2*34+2+16*34=614` cycles and `16*34=544` RAM bytes. Copy: M=17/F=27 gives
`2*34+2+10*17+16*27=672` cycles and `4*17+16*27=500` RAM bytes.

Existing one- and three-scan probe controls locate the amortization boundary:
one direct scan is307/307/272/0; three direct scans are307/921/816/0 versus
copied557/787/580/80. These are useful regression/research controls, not a
reason to add repeat-count sliders or three more menu entries this round.

Start with the usual source-only draft and unchanged uncapped default personal
goal. Do not prefill the copied answer or silently select a different objective.
If root chooses one optional new starter challenge, a source target with RAM
objective, Q1≤600/copy≤80 makes the demonstrated44-byte improvement discoverable
through the existing genuine codec. Do not advertise the default direct recipe
as necessarily beatable under total cycles.

## Why phased fields add a layout decision

Committed probe label `split_fields_serial` used the same structure temporarily
under `mixed_serial`. Results with group1/tile17:

| Actual recipe | Q1 / total / RAM / peak | Response cycles |
| --- | --- | --- |
| Source only | `307 / 2456 / 2176 / 0` | `[307,614,921,1228,1535,1842,2149,2456]` |
| Retained temperature only | `557 / 2130 / 1748 / 80` | `[557,672,787,902,1209,1516,1823,2130]` |
| Retained alarm only | `749 / 2130 / 1748 / 80` | `[749,1056,1363,1670,1785,1900,2015,2130]` |
| Retained temperature+alarm, record-major | `791 / 2044 / 1560 / 144` | `[791,970,1149,1328,1507,1686,1865,2044]` |
| Retained temperature+alarm, field-major | `727 / 1516 / 1032 / 144` | `[727,842,957,1072,1171,1286,1401,1516]` |

For every row, admissions equal `[0] + responses[:-1]`. Exact output is the
eight-value vector above. There is no trailing sparse record inspection.

The sample retains three four-metric frontier classes: direct, temperature only,
and both fields with field-major layout. The extra space and Q1 preparation
remain real costs. Temperature-only versus alarm-only also makes request order
observable: total/traffic/space tie but Q1 differs by192 cycles.

Against the both-field record-major recipe, field-major reduces Q1 by64 cycles,
total by528 cycles and RAM by528 bytes at the same144-byte allocation.
This reverses the corresponding observed comparison in current `mixed_serial`:
record-major825/2404/1624/144 beats field-major841/2564/1784/144. That existing
task reads fields0+3 together eight times and then inspects sparse full records;
the new task asks for one field at a time. “A layout depends on what is requested
together” is the concrete exploration purpose.

Do not describe a universal best layout. Goals can expose different useful
choices with the existing inclusive caps:

- Q1≤556 excludes the temperature copy;557 includes it exactly.
- Copy≤79 excludes an80-byte single-field allocation;80 includes it.
- Q1≤726 excludes the727-cycle field-major pair;727 includes it.
- Copy≤143 excludes the144-byte pair;144 includes it.

These are verification boundaries and optional user goals, not imposed task
completion gates. Preserve source-only freedom, complete output checking, and
uncapped goals. Existing public request and evidence views already explain the
causes; no artificial “layout quality” bonus is needed.

## Batch versus serial scope

Keep both additions serial only for this increment. This admission contract is
essential to the measured copying/amortization and field-layout comparisons:
future request execution cannot be fused into a source-only tile before the
previous response. Copying known immutable input remains permitted.

Adding all-ready duplicates would be valid model input but is not yet supported
by the cited new-structure measurements. It would reopen query grouping as the
major source of cache reuse, already taught by the current `scan_batch` and
`mixed_batch`. A two-job all-ready version should be measured before claiming
the serial objective distinction survives grouping. A phased all-ready version
would also allow grouping across the temperature/alarm boundary; the wording
“then” must not imply serial admission there. Neither duplicate is necessary
for the smallest coherent two-task extension.

The current four workloads and their scheduling controls remain available.
Adding two tasks where some controls are intentionally inactive is preferable
to altering the actual release rule to make every knob appear useful.

## Identity and compatibility gates

Keep `MODEL_VERSION="layout-schedule-experiment-1"`, all operation costs,
Executor methods, `plan_id()`, normalization and `Goals` semantics unchanged.
This is an additive catalog-content change; full conditions already bind task
ID, data, ordered query definitions, release, scratch and memory contract.
Do not broaden `evaluate()` into a persisted arbitrary-task authoring feature.

Current exact condition IDs must remain:

| Existing ID | Condition |
| --- | --- |
| `scan_batch` | `d64064a4d64f811516676cf8bc7745e2d81cefe0dc5659be366baafef0ab3e93` |
| `scan_serial` | `81aaabf3e8d0a0e6a12ccea525f8465658af88877c91701098c3b00a298e9311` |
| `mixed_batch` | `9fd4663fc4fe45169065a0b75b6882fb03f82a905b22a8d4403b0a84b93d3c2f` |
| `mixed_serial` | `89ff90bef1d39d8494061d179a9dd7a7fd97696e39e4bc46fddfb713dfe32e5b` |

Use explicit task branches for the new queries before the existing fallback;
current name-based `scenario()` logic at model.gd150–156 cannot infer either
new structure. Keep all four old normalized dictionaries exact and prove their
canonical serialized form, conditions, output vectors and observed full Traces
are unchanged. Existing test `_public_contract()` assumes every ID is original
`batches` or `mixed`; split the legacy assertion from explicit new task contracts,
do not weaken it to a generic shape-only check.

New IDs deliberately change `condition_id` and `trace.test_name`; therefore
their full Trace hashes must not equal the old probe-only hashes. A valid
new-vs-probe parity gate compares complete event dictionaries, all metrics,
ordered output/expected values, source/scratch maps and plan identity; only
the explicitly changed task name/case identity is excluded for that comparison.
Then freeze and repeatedly verify the full new-ID Trace. Never rewrite an old
probe record's hash and describe it as freshly measured evidence.

For existing tasks, no exclusions are allowed: their full Trace hashes must be
exact. The committed physical results already contain1339 old-condition rows
(448/221/449/221) with plan, condition, metrics and `trace_id`, allowing a frozen
historical gate without recalculating expected hashes from modified code.
Root may choose a declared representative subset for focused runtime, but the
full bounded replay is preferable if execution time remains reasonable.

Existing `VNBSC1:` canonical strings must remain byte-identical for old
task/plan/goal triples, including dormant no-copy canonicalization. New codes
can use the same envelope grammar with the new task IDs and freshly computed
conditions. An old binary rejecting unknown new IDs is appropriate; silently
mapping new codes to `scan_serial`/`mixed_serial` is not. Existing code decoding,
stale-condition behavior, formal `VNB4C1:` isolation and score authenticity must
be rechecked. The persistence audit owns the sidecar/version/rollback decision;
do not put six-task content into existing files before that decision is frozen.

Session already keys drafts, Undo, runs, goals and baseline by exact task ID.
Verify two new IDs stay isolated from the old tasks and from each other,
including invalid task-specific drafts. Validation order is meaningful:
pair/group2 returns `serial_group`; pair/group3 returns `query_group`.
Phased/group2 returns `serial_group`; phased/group9 returns `query_group`.
Do not silently clamp imported incompatible plans or transfer an old task's
selected run/history merely because the first output matches.

## Required fresh remeasurement and test scope

After definitions are accepted, root should execute:

1. **Fresh new-ID structural grid:** the same17 plans per new workload:
   direct, all four one-field copies, all six two-field subsets in both existing
   destination layouts. This34-run gate is the minimum exact transplant check.
   Remeasure the seven rows singled out above (pair2, phased5) after JSON task/
   plan roundtrip and repeated execution, checking full new-ID Trace equality.
2. **Bounded extended map study:** reuse the already defined220 distinct
   one/two-field mappings plus direct for each new serial condition:
   442 candidates at group1/tile17. It covers reversed selected-field order,
   effective copy blocks and separate aligned groups under the existing portable
   recipe grammar. Report the actual new frontier, including any improved
   recipes, instead of assuming the17-plan sample remains the complete frontier.
   This is research/acceptance, not a new UI control.
3. **Exact logic and timing:** expected vectors `[363,363]` and
   `[363,363,363,363,8,8,8,8]`; correct2/8 job counts; one response after each
   actual output; admissions `[0]+previous responses`; no later-job event before
   admission; Q1=`responses[0]`; total=`max(responses)`; source immutable.
   Check Q/O/M/F event accounting and stage sums, not just displayed totals.
4. **Plan/boundary cases:** tile1/4/17/64 metric parity under serial full scans
   while preserving correct tile metadata/Trace identity; three/four-field selections produce
   genuine `space_limit` failed traces under160 bytes, unfinished responses stay
   −1 and never qualify. Serial group errors above; immutable caller inputs;
   changed query order changes condition/output order and response behavior.
5. **Goal realism:** actual `Goals.rank` on pair direct/copy chooses different
   winners for cycles and traffic under600/80. Test tight and inclusive caps;
   equal objective values tie even when Q1 differs. For phased, verify direct,
   single-field and pair-copy caps using the concrete boundaries above.
   Challenge comparison must continue using target conditions, not current
   Notebook filters.
6. **Compatibility:** old four exact task/condition/full-Trace replay; existing
   model/Goals/Session/Notebook/challenge suites; official141-design/282-case
   frozen gate. New task-specific notebook/target isolation and rollback tests
   come from the separate persistence plan. No formal completion or telemetry
   authority is introduced.

For actual play acceptance, run the pair direct and copied recipes, switch
between total/RAM goals and see the rankings reverse without changing input;
then compare both destination layouts on phased and current mixed serial.
Switch among old/new tasks and recover independent drafts/goals/retained plans/
targets after explicit save and restart. UI/GPU/native evidence should remain
separate from model tests, and no unmeasured global-optimum claim should appear.

## Scope boundary

The pair adds an objective tradeoff; phased fields adds a layout-choice reversal.
Together they are a coherent gameplay increment using current mechanisms.
Sparse locality pairs, daily seeds, online rankings, copy-block editing,
additional task sliders and altered cache/copy rules can remain future work.
This recommendation does not change source or authorize a migration; root must
combine it with the UI and persistence audits and freeze the implementation plan.
