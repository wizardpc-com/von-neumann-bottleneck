# Round8 fixed-version replay and ranking audit

Reviewer `/root/review_records_final`, 2026-11-05. Read-only audit at clean
task-branch base `2893e3a93d4a1995bbd9701134089e7977b8c0cc`.
No source/doc edit, engine/test execution, network request, service change,
ordinary player-data access or Git mutation was performed. Only this report
was written. All ownership is released.

**Recommendation:** make the next playable improvement the local explanation/
comparison loop. The smallest useful online-ranking groundwork is a separate,
operator-local fixed-runtime replay command for the existing Chapter4 mixed
cycles board. It can reuse the actual Godot codec and simulator without changing
HTTP, consent, receiving storage or deployment. It requires a bounded execution
plan before implementation. Do not turn the current scalar-score intake into
a verified board merely by tightening its numerical checks.

## Current truth and reusable pieces

The existing server is honest about its limit. `server/community.py:1,26,106`
states client-reported evidence, no replay, and returns `verified:false`.
`validate_score()` at29-44 checks the supported board/rule/model/case tuple,
consent metadata, two passing-case claims, bounds, phase sums, total sums and
traffic/space alignment. Plausible totals below1000 are held for review; they
are not labelled cheating or verified. `server/test_community.py:64-80`
explicitly injects synthetic scalar metrics and asserts the unverified board
response.

There is only one authored community board:
`chapter_4/mixed`, `layout-mixed-1`, `layout-memory-1`, two official cases,
case digest `782ac833c729ff22be257dc78f6e1a6a890229f9aa43fb845201d712e58e25fc`.
The exporter at `scripts/export-community-rules.gd:18-20` supplies its case
limits2450/1550, logical floors280/126 and scratch160. These are useful
admission/plausibility constraints; they do not establish that any submitted
numbers came from a particular executable recipe.

The receiver accepts only `event`, `feedback` and `score`, with scalar field
whitelists (`server/feedback_server.py:18-30,39-83`). Its score path has no
recipe or code field. `RemoteFeedback.send_score()` at303-317 sends sanitized
context and two metric sets, then uses the existing explicit score-consent
outbox. Existing event bodies cannot be replayed retrospectively because
the necessary inputs were never retained. Recipe/program digests are not a
substitute for those inputs.

The challenge codecs now supply precisely the missing bounded input form:

| Existing mechanism | Useful authority/bounds |
| --- | --- |
| Formal `layout_challenge_code.gd` |4096 UTF-8 bytes; exact canonical envelope/nested keys; known task; explicit model, condition and objective; complete design; `inspect()` replays all authored cases and requires eligibility.|
| Formal `layout_scoreboard.gd:89-131` |Actual `Catalog.evaluate()` results; checks ordered case identities, correct outputs and target conditions; aggregates cycles/traffic/peak and records each complete canonical Trace hash.|
| Experimental `challenge_code.gd` |4096 bytes and depth16; exact canonical inputs; current model/task condition; immutable normalized goal; actual `Model.evaluate()` and `Goals.rank()` before a code becomes active.|
| Experimental model/goals |Known six task IDs; bounded plans/jobs/query values/output/Trace; condition hash includes workload and modeled memory constants; rule hash binds objective and Q1/copy caps.|
| Existing process/evidence tooling |Isolated prepared projects, fixed source manifests, exact engine identities, fresh processes and full-Trace replay checks already exist as verification patterns.|

Keep those codecs authoritative. Reimplementing the simulator or canonical
serialization in Python would introduce a second rules implementation without
adding gameplay value. `Code.compare()` is also not a substitute for replaying
untrusted data: the experimental helper expects current measured entries;
`challenges.gd:104-134` deliberately re-evaluates the attempt and reconstructs
its complete row before calling it.

## Gaps that an actual verified ranking must close

These are missing capabilities, not newly discovered defects in the explicitly
unverified current service.

1. **Input and execution authority.** No server-controlled Godot process
   executes a submitted design. The Docker image contains only Python and
   the receiving modules (`server/Dockerfile:1-8`). Client-provided `passed`,
   totals, Trace hashes, source/build labels and source/mode categories cannot
   become execution proof.
2. **Fixed verifier identity.** The model label and case hash identify rules
   semantically, but do not bind executable code. The formal condition hash
   at `layout_scoreboard.gd:23-28` includes task/model/cases, not simulator
   implementation bytes. Experimental conditions include memory constants,
   but still do not hash the algorithm. A change under an unchanged label
   must not silently inherit verified results.
3. **Comparable board identity.** Formal community `case_set_version` and
   formal challenge `condition` use different hash envelopes. They must be
   independently obtained from the same trusted runtime and explicitly
   mapped; string substitution is invalid. Experimental boards additionally
   require the immutable goal/rule identity. A challenge-code hash includes
   its target recipe, so it is not the ranking key for all recipes sharing
   the same rules.
4. **Bounded worker lifecycle.** The current receiver is a single
   `HTTPServer` (`feedback_server.py:86,287`). Starting a blocking replay
   directly in `do_POST` would also block unrelated health/deletion/intake.
   Current128KiB/32-record/12-score limits bound scalar intake, not a queue
   of engine executions, result sizes, timeouts or worker concurrency.
5. **Durable verification/deletion semantics.** Schema2 stores opaque event
   bodies and deletion tombstones (`storage.py:9-15`). It has no immutable
   verifier receipt, pending-job ownership, failed-execution state or verified
   ranking transaction. `DELETE`, retention, backup/restore and merge currently
   know only clients/events/tombstones. An added verification table or sidecar
   must participate in those rules before any online use.
6. **Consent and participant meaning.** Current documented score consent
   sends metrics; public design upload is unsupported
   (`community-feedback.md:122-137`). A replayable recipe is additional
   content, even when it is only a short layout code. Existing score consent
   must not silently authorize that upload. The random installation token
   proves control of a deletion identity, not one person, manual play or
   competition integrity.

Current community rows also assign sequential ranks to tied totals
(`community.py:98-105`), while both local rankers use competition ties.
A new verified board should choose and test a tie policy explicitly;
do not silently rewrite historical community rank semantics. Recommended new
policy: equal objective values share rank, with a stable display-only ordering.

## Bounded first implementation proposal

Suggested scope: a Python orchestrator under `server/`, one trusted headless
GDScript worker, an explicit verifier manifest and synthetic tests. **Support
only `VNB4C1:` mixed/cycles initially.** This is the existing online board's
input domain and requires only two known cases; it avoids simultaneously
designing six experimental online boards, arbitrary goals and account rules.
The experimental codec remains a well-defined second adapter.

The command accepts one operator-supplied code as data, chooses a server-owned
manifest, starts a fresh isolated worker, and returns a bounded measured
receipt. Optionally it can compare a bounded list of codes by replaying every
input through that same manifest. Any ranking is an ephemeral comparison
of these newly measured rows, not a public player leaderboard.

The proposed contract:

- Input contains only a request version and code; no claimed score, Trace,
  source path, executable path, URL, task dictionary or script. A trusted CLI
  option selects one preconfigured verifier; no job can select arbitrary code
  or a Git revision. Apply a4096-byte code bound, strict UTF-8, a shallow
  envelope and explicit nesting bound before parsing. Formal code currently
  has a byte bound but no pre-parse depth scan; the worker boundary can apply
  the existing bounded-depth pattern without changing its portable format.
- Build a private minimal project from a fixed allowlisted source closure:
  formal codec/scoreboard/catalog/recipe/simulator/run and the shared
  SimulationTrace/SimulationEvent. Import its global class cache once during
  preparation. It has a dedicated custom user directory and no autoloads.
  Running the normal project would load GlobalSave, RemoteFeedback and other
  unrelated autoloads (`project.godot:19-36`), so it is an unnecessarily broad
  execution surface for this worker.
- Bind actual file hashes, trusted worker/project settings and the actual
  pinned4.7.1 engine artifact to a verifier identity. Record the source commit
  as provenance as well. Do not rely only on `git rev-parse HEAD`, the client's
  `source_commit`, or a version string. Refuse changed assets or unknown
  manifests before replay. Preserve previous manifests through Git/artifact
  history; do not fall back automatically to another verifier.
- Pass data in a runner-created input file at a fixed private path and use
  a literal subprocess argument list, without a shell. The job does not
  supply paths, flags or environment. Use one worker and one request initially.
  A provisional prepared-worker budget can be10 seconds,64KiB result and
  256KiB diagnostics; confirm the deadline using slow supported designs and
  engine startup measurements before freezing it. These are proposed caps,
  not measured current acceptance.
- The worker calls the existing `Code.inspect(code,"mixed")`, additionally
  requires objective `cycles`, and emits only the freshly measured row/case
  summaries, executed recipe identity, ordered case/Trace hashes and trusted
  condition metadata. It never accepts the client's metrics as a shortcut.
  Do not impose the old under1000 plausibility hold on genuinely replayed
  results; eligibility comes from the fixed model and authored case rules.
- The parent requires exit0, a single complete bounded result, matching
  request/input/verifier identities and valid result types. Timeout, crash,
  missing/truncated/extra output or source mismatch produces no ranking row.
  A new empty result path per job prevents stale-file success. Child
  termination/wait and temporary cleanup must complete on failure.
- The output label is `fixed-runtime local replay` until a real receiver
  owns execution and commit. A JSON receipt or SHA digest is a reproducibility
  record, not an authenticated portable score token. Do not later accept a
  player-edited receipt as authority; replay its input again.

No HTTP listener, receiving schema migration, outbox change, new consent,
installation identity or deployment belongs in this first implementation.
No existing player save, v1/v2 Notebook, challenge target, formal result,
threshold or model changes. Python path/process handling and `res://` inputs
can remain portable; actual Mac/Windows/Linux runtime parity still needs
separate evidence. `--headless` and a different user directory alone are not
an OS security sandbox.

## Test and acceptance gates

Root should run these sequentially in isolated synthetic fixtures after a
versioned plan fixes the exact worker/protocol contract:

1. Known mixed designs replay both official cases with exact current outputs,
   cycles/traffic/peak and full-Trace identities. Fresh-process repetition and
   JSON input round trips agree. At least two distinct eligible designs and
   an objective tie exercise actual comparison.
2. Claimed scores, unknown fields/tasks, foreign objectives, stale conditions,
   duplicate keys, malformed UTF-8, excessive bytes/nesting and structurally
   invalid plans are rejected without producing a row or touching saves.
3. Change one trusted simulator byte while preserving model/case labels:
   the source binding refuses execution. Wrong engine identity and unknown
   verifier also fail. Do not rewrite the expected manifest to make this
   adversarial test pass.
4. Test timeout, crash/nonzero exit, missing/truncated/oversized result,
   wrong request/input hash and diagnostic overflow. None can reuse a prior
   successful output; owned children are reaped.
5. Ranking accepts only current worker results under the exact same verifier/
   board/condition/objective tuple. Same scalar scores from legacy intake
   remain visibly self-reported and cannot enter this result collection.
6. Confirm the minimal worker has no normal autoloads, endpoint or game-save
   side effects, and a second isolated run creates no player state. Keep the
   current community/storage/transport suites unchanged and passing.

The current codec and model suites are useful fixtures, but are not evidence
that this nonexistent minimal worker, Python boundary or timeout behavior
already works. I did not run any of these proposed checks.

## Decisions reserved for a later online plan

Before wiring the verifier to a real service, specify a separately versioned
recipe-submission protocol and renewed explicit content consent; bounded queue
and worker admission; durable idempotency and conflict rules; receipt state
transitions; timeout/retry behavior; board/tie/participant identity; source
artifact retention and verifier retirement; and tombstone/retention/backup
coverage of submissions and results. Commit acknowledgement must still mean
committed intake, while a completed replay receipt separately establishes
ranking eligibility.

Do not reuse existing `verified:false` rows as verified historical results:
they lack recipes. Keep the old route and data honestly separate. The minimal
local verifier avoids making these protocol/persistence decisions prematurely.

For this round's priority, local explanation directly helps players understand
the already measured44B-versus58-cycle tradeoff and the physical-layout result.
A verifier CLI improves future result trust but has no immediate public or
in-game loop while the normal client has no endpoint. It is a sensible bounded
next infrastructure increment, or a disjoint companion only if it does not
delay the playable explanation work. Public leaderboard deployment is a larger
follow-up and is not justified by this source audit.
