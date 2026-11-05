# Round9 — measured computation optimization

2026-11-05, task branch `codex/gameplay-systems-20261104`, based on
`2748138d166855e86a5496ce60ca37a8389d4ce7`. This is a source milestone, not a
release or a main merge. Three agents audited the simulator families; root
selected and integrated a measured GDScript optimization, owned all engine/Git
execution and reviewed the full observations.

## Playable result

[Local isolated preview](../../../.godot/computation-preview-20261105.command)
opens the normal laboratory from the verified candidate:
`.godot/verification/20261105T095516Z-05af4f51/project`.
Its independent profile is
`VonNeumannBottleneckChecks/round9/playable-preview-20261105`.
Choose Test at the laboratory to visit the Creation workbench directly through
the journey. Ordinary player data and the Round8 scheduling preview are separate.
This local launcher requires the installed pinned engine and is not a portable
download. [Final ordinary startup](checks/preview-startup.json) exits0 without
diagnostics; the launcher passes `zsh -n`.

Creation generation and encoding now validate their complete inputs once per
synchronous operation and read only the needed bounded context. Decoding still
validates the carried packet/model before its trusted loop. Public prediction
continues to validate the whole model and history on every call. Local canonical
bytes/identity are reused without global caches or mutable shared results.
The original linear scan, all decisions/events, PRNG, packet/recipe bytes,
errors, memory formulas and modeled costs remain. No format/model/condition/
completion version, old score interpretation or formal60-task content changed.
See the [runtime contract](../../../experiments/creation/CONTRACT.md).

## Actual performance and equality

Godot `4.7.1.stable.official.a13da4feb`, macOS arm64, Apple M2, headless.
The reference and candidate use identical six benchmark scripts, complete
inputs, fixed iterations and seven samples. Actual outer engine commands match
apart from project path and role label. Each table row is one complete API
workflow including fresh input/state setup and API-owned serialization.

| Measured workflow | Reference median | Candidate median | Ratio | Time reduction |
| --- | ---: | ---: | ---: | ---: |
| Generation64max +1024weighted +1024max +4096weighted | 1589.433ms | 401.527ms | 3.96× | 74.7% |
|1536-symbol RAW and predictive public transport, both encode/decode |395.804ms|146.000ms|2.71×|63.1%|
| Complete committed Creation Session workflow |43.118ms|34.588ms|1.25×|19.8%|

Generation workflow ranges are1583.893–1593.903ms versus401.018–402.461ms;
transport394.613–399.567ms versus144.983–148.773ms;
Session42.937–44.276ms versus34.321–37.861ms.
The Session scenario includes54 transitions,22 commit/reveal pairs, generation
and strict packet decoding. These are not single-kernel, UI frame or FPS claims.

All **35 accepted scenarios** have exact complete typed inputs/results/state/
costs/events between the independently frozen reference and candidate:
11 circuit,12 memory and12 workload scenarios. Comparisons inspect every
captured field, not only signatures or final totals. Their full raw and sealed
JSON, logs and actual invocation records are retained:

- [Workload comparison](benchmarks/20261105T100802Z-candidate-final/workload.comparison.json)
  and [memory comparison](benchmarks/20261105T100802Z-candidate-final/memory.comparison.json),
  against `20261105T100056Z-reference-final`.
- [Circuit comparison](benchmarks/20261105T101623Z-candidate-circuit-final/circuit.comparison.json),
  against `20261105T101607Z-reference-circuit-final`.
- [Final comparator commands and invocation checks](benchmarks/final-comparisons.json)
  use the final strict parser. [Fixed counts](invocation-tools/round9-iterations.json)
  and [measured script hashes](invocation-tools/round9-measured-gd-sha256.json)
  bind both sides.

Unchanged controls are retained rather than averaged into a speed claim.
The short Overlap failure/reuse case is5.2% slower in this observation
(0.771→0.811ms median, overlapping ranges); its runtime path is source-identical
and no change-specific cause was established. No universal non-regression or
whole-game speedup is claimed.

A [separate three-sample profile](profiles/comparison.json) measures weighted
generation64 at11.845→4.271ms,1024 at206.432→69.670ms, and4096 at
1183.029→279.781ms median. Output digests, counts and all costs match.
The4096 run retains71680 events and338593 modeled cycles; its complete
old/new event equality is independently covered by the workload corpus.
Separately timing model validation/prefix validation/public prediction over
actual generated prefixes diagnoses redundancy; those times are not additive
profiler attribution.

## Method and limits

The runner independently validates intended success/rejection, compares
JSON-restored inputs and three individual repeats, then checks the final result
and unchanged input of each timed batch. Earlier actual results stay alive
through later distinct cases in the same process. Intermediate timed calls
are not all separately snapshotted; separately launched groups do not establish
cross-group alias behavior.

Snapshots retain every script-variable field, integer64 decimal value, explicit
float64 bits, typed-container metadata and complete packed values/events.
Dictionary insertion order and reference alias topology are normalized away.
Unsupported/cyclic evidence fails closed. Mutation checks cover the declared
workflows, not arbitrary alias graphs or native engine internal state.
Harness snapshot/hash/export work is excluded from timings; normal model-owned
serialization and complete events remain timed. Host heap peaks were not measured.

The actual process log and returncode are mandatory evidence. Sealing preserves
the original JSON and adds raw/log SHA256 and diagnostics. The comparator rejects
failed/incomplete runs, malformed schema, duplicate JSON fields, unsupported
values, differing inputs/evidence/environments or unequal batch counts before
publishing ratios. It checks supplied metadata, not external authenticity.
Root independently checked actual invocation/raw/log/source bindings.
The [independent artifact review](reviews/artifact-review.md) rehashed all eight
raw/sealed/log/invocation sets, recomputed72 original snapshot byte hashes and
reproduced all three accepted comparisons. Its [script](reviews/artifact-review.py)
and [actual results](reviews/artifact-review.json) are archived. This review
preceded the final test-helper correction below; root subsequently refreshed
and rechecked the complete source/playable binding.
See [reproduction instructions](../../../scripts/benchmarks/computation/README.md).

## Confirmed existing correctness defect

`circuit.prologue.diagnostics` remains an explicit **failed36th scenario**.
A register first writes3, then two drivers conflict at5/6, then both return to0
with HOLD. Whole and incremental execution still fail the third step before
applying its new inputs. The prior failed output map is reused as the initial
resolution seed. This is not caused by the Creation change.

Both final diagnostic runs exit1 with the same11 semantic failures. Their
complete captured evidence is identical, but
[strict comparison rejects them](benchmarks/20261105T101644Z-candidate-circuit-known-failure/known-failure-comparison.json)
with no timing ratios. Their validator was not weakened.
[Independent recovery analysis](reviews/circuit-recovery-analysis.md)
recommends retaining the last electrically valid output carry while preserving
the failed observation. A separate correction must preserve every previously
successful full Trace and test the actual Debug/Step path; post-commit storage
rollback and global source initialization order are outside that narrow repair.

The [computation audit](../../development/COMPUTATION_AUDIT_20261105.md) retains
raw/sealed latch differences, missing-input contracts, the64-tick ceiling,
invalid Region residual metrics and other correctness/performance hypotheses.
After recovery, address consistent rejected Region evidence, then profile
remaining duplicate work. No C++/Rust module was selected. Native entry/adoption
thresholds in the independent priority report are proposals for a later plan,
not measured native benefits or adopted product rules.

## Checks, initial failures and source binding

- Frozen reference import/isolation and15 existing model suites pass:
  [reference suite results](checks/reference-suites/results.json).
  All556 tracked `src`/`experiments` files were checked against2748138 and the
  frozen QA before timing: [reference hashes](runtime-base-sha256.json).
- Candidate16 Creation suites have passing latest observations, including
  kernel1602, contract162, state20, cost40, comparison89, draft Undo68 and
  writer retry95. [Initial candidate results](checks/candidate-suites/results.json)
  retain the snapshot verifier's missing-PASS-marker failure despite exit0 and
  10 successful assertions. The corrected
  [snapshot rerun](checks/20261105T101819Z/test_computation_snapshot.log)
  passes10/0.
- Final [GPU checks](checks/20261105T105418Z/results.json) pass playable198
  and workbench449 with real viewport mouse activation, both locales, save,
  reopen and exact recipe replay. The changed shared test helper's
  [three headless dependents](checks/20261105T105552Z/results.json)
  pass playable98/workbench385/choice87. These are staged latest observations,
  not a single all-repository regression or native OS input.
- [Python comparator/sealer tests](checks/python-final.txt):21/21 pass.
  Strict malformed plain/gzip fixtures and actual prior99-error evidence are
  covered in the [sealing review](reviews/process-sealing.md) and
  [final parser repair](reviews/parser-repair.md).
- Initial snapshot float/comparison fixture failures, a reserved-name circuit
  parse error,99 typed-array validator errors that printed a false PASS, and
  the first12-assertion circuit diagnostic are retained. One of those12 was
  an empty-default-map validator assumption, repaired without omitting result
  fields; the11 recovery failures remain.
- First GPU run `101950Z` clicked a hidden ledger action, then indexed missing
  results. Root deliberately stopped that owned hung fixture (exit−15).
  The [diagnostic probe](checks/20261105T102652Z/round9-creation-gpu-probe.log)
  observed Train/condition clicks activate, but the ledger button was hidden
  and received no input. Its [raw2560×1440 frame](diagnostics/hidden-ledger-click.png)
  was visually inspected. A subsequent strict fixture also exposed hidden
  Works actions. Explicit ledger/Works navigation and visible/once-activated
  checks fix the tests; production UI was unchanged. Failed attempts remain.
- The [final evidence review](reviews/evidence-review.md) found the initial
  one-shot activation counter could only prove at least one activation. Root
  retained an ordinary callback through complete mouse down/up and six settling
  frames, then disconnected and required exactly one activation. Both GPU
  routes and all three headless dependents passed again at the final paths
  above. The [follow-up review](reviews/activation-followup.md) closes this
  test-oracle defect; no production duplicate activation was observed.
- [Current source binding](source-sha256.json) checks1244 source/test/support
  files byte-for-byte against the QA/playable copy. Settings differ only by
  two isolation entries. All measured six `.gd` hashes also match the frozen
  reference. The final test-helper correction and Python/docs synchronization
  do not change timed engine code.

Native input was not attempted after the last locked-Mac observation at
2026-11-05T07:05Z in Round8; no native input was sent. Windows, exported builds,
newcomer understanding, audio/long-session experience and arbitrary-input/global
strategy correctness remain unverified. Existing historical acceptance is not
inherited. All engine runs use named QA profiles, not ordinary player data.

Rollback restores only `experiments/creation/model.gd` and `codec.gd` from
2748138; no save conversion is required. Benchmark and diagnostic evidence may
remain. The [completed plan](../../exec-plans/completed/computation-kernels-20261105.md)
records the continuing scope; the broader game-systems goal stays active.
