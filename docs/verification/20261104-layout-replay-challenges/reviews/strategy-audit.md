# Round 6 strategy audit — decision recommendation

Owner `/root/audit_scores`. Production source is read-only. Clean
`e07b4bbba845a1046835884ecf06916930fa8b8a` was verified at audit start.
No source implementation, Godot execution, or Git mutation has occurred.

**Recommendation: implement the offline replayable challenge loop over the four
current conditions next. Do not add a copy-block control solely on the present
sample. Keep two concrete structural tasks as the next strategy expansion:
two serial scans, and separate temperature/field3 scan phases.** This is a scope
recommendation to root, not authorization or an implemented product decision.

The challenge loop supplies a real repeatable objective and comparison target
without changing current model, task definitions, or notebook inputs. It does
not add new physical strategies, and must not be advertised as workload variety
or an online trusted board. The structured alternatives below supply that
different benefit but need new condition-scoped UI/state design.

## Evidence and strategic gaps

Current evidence:

- Read the actual Round5 `strategy-results.json` and both probe definitions,
  current Model/Recipe/Goals/Session/Workspace contracts, notebook README, and
  current UI recipe controls.
- The shipped sample has5/2/7/2 four-metric frontier classes. Among those sampled
  classes, lower total work and lower RAM traffic move together. Numeric
  randomization changes output/identity, not performance.
- Existing unshipped split-fields serial evidence is meaningful:4 temperature
  scans followed by4 field3 scans gives direct307/2456/2176/0; copy temperature
 557/2130/1748/80; copy both field-major727/1516/1032/144. Field-major beats
  record-major's791/2044/1560/144 there, while current mixed serial prefers
  record-major825/2404/1624/144 over field-major841/2564/1784/144.
- The smallest new workload is exactly2 repeated full scans: the new root-run
  production-model probe confirms direct307/614/544/0 versus retained
  temperature557/672/500/80. With Q1<=600 and copy<=80, actual Goals.rank chooses
  direct for cycles and retained temperature for traffic. This is new measured
  structural evidence, not a shipped task or a global optimum claim.
- Root's alternative is also being tested: all distinct effective one/two-field
  copy mappings across copy block sizes1..17, both selected-field orders, and
  same/separate field groups. Query record_tile remains a distinct control.
  Current UI already preserves a restored advanced recipe as “Retained custom
  layout”; unrelated field/tile edits preserve it. Explicitly picking one of the
  two basic destination options replaces it, which is expected but must remain
  explicit if a more capable editor is added.

Probe `.godot/collaboration/round6-probe.gd` is authored with1475 declared
candidates:136 structural candidates and1339 physical-layout/scheduling
candidates. It uses the unchanged production Model and Goals, verifies real
output/accounting/admission/response and48 selected repeated/JSON full Traces.
The physical study exhausts the stated220 distinct one/two-field mappings, but
tests copy group1/max and query tile1 only; it does not claim a full scheduling
search. Source-only controls include every legal query group for the shipped
workloads.

**Probe ownership is RELEASED to root.** Root has now executed its full declared
1475 candidates and48 repeated/JSON runs:0 failures,24229.321ms. I read the full
`.godot/collaboration/round6-probe.log` and actual
`.godot/collaboration/round6-probe-results.json`. The two-scan prediction is
confirmed by both actual Model results and actual Goals.rank selection.

Coordination update: root's later `round6-tasks.md` note says a separate copy-block
probe is already running. My combined probe had been released before that note
was read. To avoid duplicate work, root may skip/remove its physical loop and use
the original136 structural candidates with48 repeated/JSON runs (update the
expected candidate count to136). Root owns the released probe; I will not edit it
concurrently. Its full released SHA-256 is
`4dd90124a830b5ba3ed26c45069db5417d298fdd3247f4b4437dd5366c08a17e`.
Static whitespace and declared physical-map/count arithmetic passed. Root chose
to execute the full combined probe; its observed result is recorded above.

The eight structural task frontier counts are1/2/2/2/2/3/2/1. The broader
physical study also retains5/2/7/2 for the four shipped conditions, using448/221/
449/221 candidates. Its physical coverage includes reversed selected-field
order and separately aligned field groups beyond root's initial block sample,
but still only copy groups1/max and query tile1. The two sampled investigations
therefore agree without claiming an exhaustive scheduling optimum.

## Root's copy-block evidence has now been inspected

Read root's complete `.godot/collaboration/round6-copy-probe.log`, the probe
source, and the actual output at the isolated QA path printed by that log:

```text
/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261104-round6/copy-block-probe/copy-probe.json
```

Observed:1140 model executions,0 assertions failed,18943.953ms. The probe
freshly reproduced the prior frontier representatives, then measured two-field
field-major copies for13 declared copy-block choices, groups1/all, query tiles
1/4/17 in batch (17 in serial), and repeated/JSON-replayed the final frontiers.
Candidate rows per condition are473/80/475/80; final sampled frontier counts
remain5/2/7/2. Every final frontier representative is an already known one.

This is evidence against making copy blocking the next player-facing feature:
the extra recipes did not produce an additional nondominated class in that
finite sample. It is not a proof that all other field permutations, groups,
tiles, or future workloads make blocking useless. The completed broader
physical loop agrees with this result across its separately stated coverage.

The source explains important neutral choices:

- With no copying, the physical recipe and copied fields are dormant by design.
  Exposing more such controls would not affect the current run.
- With one copied field, changing copy-block size leaves the contiguous physical
  address stream unchanged. `Recipe.mapping()` aligns once per field group, not
  once per record block. This is not a second query scheduling control.
- With one query per group and ascending full indices, changing query tile size
  does not reorder the reads. Existing UI correctly disables that control.
- Source-only batch frontiers already get reuse through fine query tiling.
  Serial runs forbid that inter-job reordering; their present tradeoff is real
  copy preparation/space against later repeated source traffic.
- Numeric values do not alter the control/address path. A random-value daily
  challenge would mostly rename the same optimization problem.

## Concrete fixed-condition challenge targets

All numbers below come from the actual Round5 production-model data, not a new
score formula. Order is Q1 / total cycles / RAM bytes / peak copy bytes.

| Challenge condition and immutable goal | Replayed target recipe | Known eligible improvement in the finite sample |
| --- | --- | --- |
| `scan_batch`; cycles; Q1≤350; copy≤0 | starter direct:307 /2456 /2176 /0 | no-copy, group2, query tile1:339 /1368 /1088 /0 |
| `scan_serial`; cycles; Q1≤600; copy≤80 | starter direct:307 /2456 /2176 /0 | full temperature copy, record-major, group1:557 /1362 /980 /80 |
| `mixed_batch`; traffic; Q1≤600; copy≤0 | no-copy, group4, query tile1:533 /1152 /576 /0 | no-copy, group5, query tile1:597 /1120 /544 /0 |

The first two are useful opt-in introductory targets: one rewards query
interleaving, the other retained physical copying. The third is a narrower
refinement target with a32-byte improvement and a64-cycle later Q1 still within
the immutable cap. Do not preload the improved recipe as the player's draft.

Use the same codec/inspection path for a built-in target and a player-authored
target. The reference recipe, full condition, objective and caps define the
challenge. Recompute its actual target value locally. No pasted or saved metric
may replace this computation.

The target must itself produce complete correct output and satisfy its own
caps before export/acceptance. An attempted run must satisfy those same caps,
not the current personal Notebook filter. A strictly lower declared objective
is an improvement; equality is a tie. Keep all four metrics visible and allow
targets that are not known to be strictly beatable. Never label a finite target
or measured winner globally optimal.

Useful exact negative tests:

- Lower the first target's cap to338: group2's339 must be excluded even though
  its total is lower. With cap339 it qualifies exactly.
- The direct starter has identical displayed numbers in scan batch and serial,
  but their admission contract/full condition differs; no cross-condition win.
- A zero-cap goal is distinct from unlimited. A failed copy with zero partial
  cycles and Q1=-1 cannot become a target or beat anything.
- Changing personal sort, Q1 cap or copy cap after accepting a target must not
  alter its rule identity, required target value, retry code or verdict.
- A replay of the exact target must tie with matching complete Trace, without
  editing the current draft. Explicitly restoring it remains one Undo.

## Smallest meaningful structural extension

The preferred later pair changes request structure while keeping records17,
fields4, immutable source, cache/costs, serial admission and160B copy capacity.
It needs no new simulator mechanism.

1. **Two full temperature scans.** Exactly two `sum` jobs for field0 over all17
   records. Newly measured outcomes are direct307/614/544/0 and copied
   temperature557/672/500/80. With Q1≤600/copy≤80, total and RAM objectives select
   different recipes, as actual Goals.rank confirms. Paying
   real write/prepare work saves44 RAM bytes but costs58 additional cycles here.
   Repeat1's direct307/307/272/0 is the only sampled frontier; repeat3 gives
   direct307/921/816/0 versus copied557/787/580/80. These controls locate the
   observed amortization boundary without changing simulation rules.
2. **Four field0 scans, then four field3 scans.** Already measured in Round5.
   Direct307/2456/2176/0, copy field0 only557/2130/1748/80, and copy both in
   field-major727/1516/1032/144 form three sampled frontier classes. Copy both
   record-major yields791/2044/1560/144. Current mixed requests read both hot
   fields together and favor record-major; separated requests favor field-major.
   This creates a real layout choice, rather than a new knob with the same
   best sampled recipe.

Sparse locality is a third later option, not needed for the smallest pair:
16 requests for indices[1,2,3] give direct55/880/768/0 versus copy465/570/356/80;
changing indices to[1,8,15] keeps the direct metrics but makes that full copy
497/1322/1108/80, dominated in the17-plan sample. This teaches physical spatial
locality, but only offering the dispersed case adds a mostly one-answer task.
The paired comparison is what makes it educational and exploratory.

These probe labels are deliberately not current product IDs. `Model._task_error`
accepts altered structure under one of the four IDs, but `Session.task()`
reconstructs the fixed catalog task and NotebookStore requires its exact full
equality. Do not preview a custom `scan_serial` and then run the fixed task
through Session under the same label. Do not replace existing task contents in
place: it would protect existing complete notebooks as stale.

Before shipping these cases, choose independently identified finite contexts or
a bounded condition-keyed challenge workspace, with explicit persistence and
rollback. A full normalized task, ordered queries/repeats/indices, admission,
scratch and model must bind the condition; a seed or friendly title alone is
insufficient. Preserve old four conditions and notebook files unchanged. This
extra state/UI contract is why fixed-condition portable challenges are the
smaller coherent increment now.

## Decisive verification for root's chosen increment

- Recompute the three target/improvement pairs through production Model and
  Goals; prove cap boundary, tie and strict objective delta using actual output,
  accounting and complete Trace. Reject over-cap/incomplete/wrong-condition
  candidates and unsupported old model conditions.
- Roundtrip input-only codes; inspect/accept replays must reproduce target
  values. Preview/code edits/workload changes must not mutate draft, Undo,
  personal goal or named recipes. A target's immutable rule survives all those
  edits and save retry.
- If targets persist, keep them separate from notebook version1 and formal
  `VNB4C1`. Reopen must recompute the target, and failure must retain the exact
  proposed code with truthful temporary/protected status. No cross-file atomic
  save claim should be made.
- Numeric Cmd/Ctrl+Enter repair is independently justified by the interaction
  audit. Verify the visible numeric text is committed before exactly one real
  run, with modal/text-input ownership preserved.
- Treat codec/runtime tests, scripted GPU input, actual native input and
  cross-platform/export acceptance as separate evidence.

Only the report and released probe were authored by this agent. No production
code, project setting, player data, engine run or Git state was changed.
