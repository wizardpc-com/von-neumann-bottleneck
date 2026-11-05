# Round 4 implementation and result identity audit — 2026-11-04

Owner: `/root/audit_scores`. Read-only source/test review. No Godot, Git
mutation, player-file access or runtime implementation performed. This report
incorporates the sibling model/UX audits, but their strategy hypotheses still
require root-run measurements.

## Recommendation

Start with the sibling model audit's **source only versus one retained full
copy**, independently scheduled through public query groups/record tiles. This
can reuse virtually all current memory and Trace machinery through two small
mechanical seams. Defer bounded copy windows until the retained-copy experiment
demonstrates useful measured tradeoffs. A second copy-size field without an
explicit lifetime contract would recreate the original coupling.

Keep a pure experiment API in `experiments/layout_strategy/model.gd`. The public
entry accepts only a bounded scenario and explicit plan and returns validation
status plus an authoritative `LayoutRun` when execution occurred. It has no
autoload, FileAccess, UI, progression or telemetry dependency. Internal execution
can be a small `LayoutSimulator` subclass; production must never preload the
experiment.

## Critical reuse defect found in the initial proof

At `src/layout_chapter/layout_simulator.gd:176`, scratch addressing uses
`(record-first)*4+field`, where `first` is the query batch argument. That is correct
under the official orchestration: every query batch shares the just-copied
window's origin. It is incorrect when a retained full copy is queried through
smaller independently sized record tiles.

The initially reviewed proof's
`super._query_batch([query],tile_first,tile_length)` at
`.godot/collaboration/round4-model-probe.gd:72` therefore reads earlier scratch
records after the first tile. Its correctness check should detect this, but
discarding those failed plans would create a misleading apparent dominance
result. A separate urgent note was sent:
`/private/tmp/vnb-round4-implementation-blocker.md`. The proof owner should repair
its probe-local consumption loop before root accepts any strategy conclusion.
No official source change is required merely to run the proof.

Before this audit closed, the probe owner replaced that call with a probe-local
`_consume_tile()` using `(record-current_copy.first_record)` and updated the
model audit. The corrected source was statically inspected at probe lines76–95.
Root's initial failure is recorded in `round4-tasks.md:68–83`; a fresh root-run
measurement remains required. The shared implementation still needs the
decoupled-origin extraction described below.

## Smallest shared extraction

For the accepted none/full first version, prefer these two seams over copying
the simulator or reimplementing initialization:

1. Extract the existing `_query_batch()` read/compute/output-slot update
   (`layout_simulator.gd:174–182`) into
   `_consume_query_value(record, field, output_index, additive) -> void`.
   Resolve copied addresses relative to `current_copy.first_record`, not the
   caller's query tile. The official caller retains its exact query/repetition/
   index/field iteration and computes the same output index and additive flag.
   For the official legal call graph the origins are always identical, so this
   is behavior preserving rather than a new official rule.
2. Extract the final output emission (`layout_simulator.gd:66–68`) into
   `_emit_outputs()`. The official implementation keeps the exact stage change
   and one-cycle-per-value loop. The experimental subclass overrides this hook
   because it has already emitted those same output costs at job completion.
   Do not suppress all `output` events in a generic `_event()` override; an
   explicit final-output hook is easier to review.

The experimental subclass overrides `_query_batch()` to schedule calls to the
shared consumption helper and emit real responses. Base `run()` still performs
initialization, imported record-major source construction, exact scratch
preparation/release, cache accounting and `_finish()` once. The first version
maps only experiment `none/full` policies to base `direct/full`, so the
scheduler is invoked once across the whole dataset. This deliberately does not
promise compatibility with the base `batch` path.

The outer pure API validates before translating a plan into the base design,
and rewrites `model_version`, `case_signature` and `recipe_signature` on every
returned run, including space failures. A rejected schema can return
`{"valid":false,"error":<stable-code>,"run":null}`; it should not manufacture a
successful zero-cycle trace. A structurally valid plan that exceeds scratch
space returns a real failed run, with its actual failure event.

If root instead chooses a fully independent scheduler entry, extracting
`_begin(task,design)` from lines25–52 is a reasonable second option. It is not
needed for the smaller none/full implementation and should not be added merely
for hypothetical future copying policies.

## Query and response contract

Expand each repetition into one logical job, preserving query order then
repetition order. Give every job a stable integer ID, original query/repetition
indices, immutable logical output span, original indices array, fields, kind,
remaining value count, admission cycle and response cycle.

Schedule contiguous groups of already admitted jobs. Within a group, iterate
record tiles in ascending source-record range; within a tile, iterate jobs in
public order, and each job's original index/field positions. The original
output slots remain fixed even when physical consumption order changes.
Duplicate record indices and duplicate query fields are legal under the
current oracle and must retain their independent output positions and actual
read/compute work. They must not be deduplicated for convenience.

After a job consumes its last required value, emit its ordered output span at
the existing one cycle per value, followed by a zero-duration `response` event.
A sparse job may finish before the group's final record tile; do not postpone
its response until all group tiles finish. A complete sum is not available
after a partial tile. Do not charge a second output pass at run end.

Use **response of public job0** for `first_request_cycles`, not the minimum
response over all jobs. The batch contract may permit later sparse jobs to
respond earlier; the response list must preserve job identity. Define that
permission explicitly rather than imposing an unannounced in-order sink.
Initial/unfinished response entries are `-1` or absent, never0. Failed work can
retain already completed responses for diagnosis but cannot rank as a complete
solution.

For serial requests, group size must be1; reject larger groups rather than
clamping them. Admit job0 at0 and job j+1 only after job j's response. Full-copy
preparation may happen once before job0 because that is explicitly the player's
chosen data preparation; later jobs must not consume query values or compute
before admission. Publish this distinction: the contract prohibits future
query execution, not all advance reads of the immutable dataset.

No artificial delay, dispatch cost, cache reset or first-response estimate is
needed. Reads/writes/compute/output already advance the authoritative clock.
Expose “peak copy scratch,” since accumulators and logical output buffering are
not costed by the current model. Bound those structures honestly.

One subtle UI implication: with one job, record tiling is a no-op for the
delivered monotone dense/sparse cases, but need not be for every possible
nonmonotone indices array. For `[16,0,16]`, record tiles can change read order
while fixed output slots preserve output order. Disable a no-op control based
on the delivered scenario contract rather than claiming it can never matter.

## Copy lifetime and future bounded windows

The retained full copy is prepared once before queries and released after all
jobs. `current_copy.first_record` is0, but the consumption helper should still
use that explicit origin. Every copied word must come from an existing source
`_read()` followed by `_write()`; selecting cold fields therefore has real
preparation cost even when no query reads their scratch addresses.

If bounded windows are added later, first choose one published contract:

- Window outer loop per query group: copy a record window, consume only jobs'
  values inside it, then release. Subsequent groups must copy their windows
  again. Query tiles cannot pretend the freed windows remain available.
- Demand window: maintain one independently sized scratch window, and
  release/recopy when scheduled query access moves to another window. This can
  revisit/recreate windows and must charge each real preparation. Decide
  whether preparation occurs at every visited record or only when a copied
  field is consumed; those are observably different mechanisms.

Neither contract follows automatically from a `copy_batch` integer. If chosen,
copy and query tile origins must remain independent, tails must use actual
lengths, stale scratch must be inaccessible after release, and source lines
must not be flushed merely to make a result look balanced.

## Bounds, validation and deterministic failure

The generic official validator permits64 records,8 query specs,16 repeats,
64 indices and4 fields. Expanding that directly can create128 jobs and32768
query-value operations before any repeated copying. Do not inherit that whole
Cartesian product accidentally.

For the first public experiment, use authored scenarios with17 records and at
most16 logical jobs as declared by the model probe. Recommend explicit
`MAX_JOBS`, `MAX_QUERY_VALUES`, `MAX_OUTPUT_VALUES` and bounded trace/event
budgets, with values derived from the accepted workloads. A conservative
4096-query-value/32768-event ceiling is sufficient for the proposed small
none/full workload domain; verify a worst legal plan before freezing it.
Do not silently truncate a trace or call a capped result complete.

Require exact scenario/plan keys and types before calling normalizers. Normalize
finite integral numbers to integers once; reject booleans, fractions, NaN,
infinity, unknown enums and extra fields. Validate query/copy tile sizes against
the declared scenario, job group against actual job count, copied fields as a
unique subset, and recipes with exact nested keys. Existing `Recipe.error()`
and `normalized_design()` intentionally default/drop fields, so they are not a
strict external contract by themselves.

Keep UI raw drafts separate from the effective semantic plan. Inactive copy
controls can survive switching to source-only in the draft, while the measured
plan identity need not include ignored copy fields or a meaningless base
`batch=4`. Under serial readiness the effective query group is explicitly1.
Reject unsupported requests, do not silently reinterpret them.

All execution order derives from arrays and explicit ranges. Do not depend on
wall time, frame callbacks, locale, randomized iteration, hash-map insertion
history or asynchronous UI scheduling. Repeated calls on the same engine object
must reset jobs, response lists, active job, outputs and subclass state as well
as the base memory/cache state.

## Identity, challenge rejection and authority

Use a new explicit model ID, e.g. `layout-schedule-experiment-1`, with the base
memory-model ID/version recorded separately. Condition identity includes the
experimental model, full public data/query contract, admission rule, scratch
limit and immutable memory constants. A plan hash includes this model and the
effective normalized schedule/copy plan. Local labels, timestamps, selected UI
event, locale and user-visible attempt names are not metric identity.

Trace `metrics` plus event details must bind response/admission/job execution.
**Do not use only `pass_index` or `work_group_index`:**
`SimulationEvent.to_dictionary()` at46–51 intentionally removes those
presentation fields. Use signature-bearing keys such as `job_id`,
`query_tile_first`, `admitted_cycle`, `response_cycle` and `output_index`.
The canonical `LayoutRun` signature already binds base Trace, output vector,
expected vector and model/recipe/case identities (`layout_run.gd:11–13`).

Keep `LayoutScoreboard`, `LayoutChallengeCode` and their existing sidecar
unchanged. Old VNB4C1 binds `layout-memory-1` and official cases, and only
accepts cycles/traffic/space objectives. The new lab should have no VNB4C1
import/export route. Its plan/schema validator must reject an old envelope and
official `strategy/batch` design masquerading as an experimental plan.
Likewise, current VNB4C1 `inspect()` must continue rejecting a code carrying the
new experimental model even if its syntax decodes. Do not teach the old
scoreboard to “accept compatible” new runs.

No call to GlobalSave completion, chapter `record_pass`, chapter draft/named
design mutation, PersonalRecords, or
`PlaytestData.record_official_run(chapter_4,...)` is allowed. The last call emits
`official_result` even when telemetry transport is disabled
(`playtest_data.gd:200–211`), so “offline” is not an authority boundary.
Comparisons are only between complete correct remeasured runs with the exact
same experimental condition ID.

Use the existing isolated launcher before autoload initialization.
`run-experiment.py:45–58` sets the QA custom directory before import/run. A
scene-level profile check is a useful second guard, but cannot undo an ordinary
profile already read by autoloads. Do not add candidate `--profile`, journey or
campaign registration in this first slice. A resumable dedicated preview may
reuse an explicitly isolated copied project; any later persistence belongs in
a separately versioned protected experiment sidecar, never the old score store.

## Decisive checks for root

1. Capture old official canonical traces, full events, outputs/expected, metrics,
   source/scratch maps and identities from the frozen round3 source for every
   case and representative direct/full/batch recipes, including tails/failure.
   After shared extraction require exact equality, not only pass/metric equality.
2. Run existing layout simulation/recipe-source/trace-storage/navigation,
   scoreboard and portable-code/controller suites. Verify old challenges and
   named designs remain unchanged.
3. Direct plans have zero allocations/writes/copy peak. Full plans have exactly
   the mapper-sized copy allocation and real source reads/writes. Confirm
   `cycles=2Q+O+10M+16F`, `traffic=4M+16F`, counting actual consumed query
   values Q, outputs O, copied words M and line fills F.
4. Specifically test full copy with query tiles1,2,4,8 and nonzero tile origins;
   each must read the correct scratch record. This catches the proof defect.
5. Dense, sparse, nonmonotone and duplicate indices/fields produce the exact
   logical oracle vector and output event positions. Include partial final
   tiles and a sparse job finishing before its group's last tile.
6. Every completed job has exactly one response after its real output costs;
   no double final-output pass. Job0 metric equals its response event cycle.
   Serial event order proves no future query consume/compute before admission.
7. Known batch and serial have different condition identities even with equal
   outputs. Same condition/plan runs repeat exactly, including JSON round trips,
   locale changes and reuse of one simulator instance after failed/success runs.
8. Reject malformed/oversized plans and old challenge envelopes cleanly.
   Resource failure preserves accurate partial trace, lacks complete eligibility
   and never supplies a false zero response time.
9. Snapshot isolated old save/record files before/after the experiment and assert
   no experimental action changes official progression, attempts or challenge
   bytes. A fresh-process test is needed if any experiment sidecar is added.

No runtime claim is made by this audit. The probe addressing defect has a
statically reviewed repair awaiting root-run acceptance; broader implementation
ownership still belongs to root.
