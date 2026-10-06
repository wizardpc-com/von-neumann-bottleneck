# Prediction: bounded history, unknown next address

KEEP EXPERIMENTAL. Three freely selectable investigations; no campaign registration,
progress, receipts, DSL, saves or production simulation changes. `lab.tscn` is the
bilingual scene. Use the isolated experiment launcher after root adds its entry;
never launch this project against ordinary player saves (autoloads still exist).

## Contract and timeline (before calibration)

Demand addresses name aligned 4B lines in a read-only 128B teaching asset. The
catalog owns the deterministic streams; the causal predictor receives **only one
observed demand address at a time**, keeps the last eight, and has no catalog,
future, cache or baseline argument. Data values are `(address*7+11)%256`.
Regular, changed-pattern and alternating-hotspot workloads are authored separately.
Public task names disclose a category, not future addresses.

The player constructs a rule: Off, last stride, or a two-stride cycle; 1–3 required
repetitions; stride multiplier 1/2; mismatch pause 0/2 observed requests. Last stride
uses the latest difference. Two-stride predicts the older of the trailing two
differences. Confidence verifies repeated trailing differences in that period.
The multiplier changes address distance, **not** a free time window. No previous
guess is promoted to observed history. Mismatch is checked against the next actual
address; it starts the configured pause including the current observation. The
bounded history causes 3-cycle confidence to need seven genuine observations.
Out-of-range guesses are suppressed. Cached guesses do not generate traffic.

Each run starts with an empty automatic LRU cache: 2 slots ×4B. One Bus carries
one non-preemptive request at a time; there is no pending speculative queue.
Every fetch costs 4 request cycles plus 2 transfer cycles (4B at 2B/cycle).
Demand lookup costs 1 CPU cycle. After the true value becomes available, CPU does
8 cycles of fixed useful compute, independent of rule choice. Predictor bookkeeping
and cache fill/eviction are zero-duration teaching operations, explicitly simplified.
There are no predictor hardware-cost awards or simulated branch instructions.

Timeline for every demand:

1. The demand arrives at the end of the previous compute gap; lookup takes 1 cycle.
   A Bus job finishing during lookup fills the cache before the membership check.
2. A hit touches LRU and consumes the true value. On a miss, an in-flight matching
   speculative request waits only its remainder, without issuing duplicate traffic.
   An unrelated in-flight request must finish before a synchronous demand fallback
   fetch begins. Its wasted work can fill and evict first. These intervals are
   `inflight_wait_cycles`, `queue_wait_cycles` and `fallback_cycles` respectively.
3. The predictor observes the consumed demand, forms its history-only guess and
   may issue one speculative fetch while CPU begins the real compute gap. The Bus
   job fills at its actual completion time; the following demand can hit that line.
4. All outstanding work drains at run end, including a guess beyond the final
   request. This traffic is counted and cannot be silently abandoned. There is no
   cancel control: pause suppresses future issues, never cancels already paid work.

Elapsed total = lookup + compute + blocking + final drain. Blocking = matching
in-flight wait + queue wait + fallback fetch. Bus busy work = request + transfer;
it can overlap compute/lookup, so it is **not** added a second time to elapsed.
All issued 4B requests count as traffic. A speculative request is useful once its
line is actually consumed before eviction; otherwise its 4B is wasted. Reuse of a
line does not count the same request twice. Wrong next guesses and eventual useful
traffic are distinct: an initially wrong guess may still be consumed later.

Cache fills are automatic LRU, even for wrong guesses. Each fill records victims
and cache state. A separate Off evaluator compares per-demand cache membership:
`pollution_misses` means this run missed where Off hit. It is a counterfactual
measurement, not an input to the predictor or a claim that every extra miss has
one isolated victim. The changed timeline can compound eviction effects.

For shorter custom compute gaps the same model exposes in-flight matching waits,
wrong-job queue waits and final drain; the public catalog uses 8 cycles so initial
experiments clearly isolate caching/traffic/pattern effects.

## Information and UI boundary

Step reveals one actual demand and the resulting prediction. The scene precomputes
a deterministic Trace internally but filters event rows by the number of observed
demands; future demand events, decisions, final costs and outputs stay hidden.
Prediction evidence contains history and guess, never the actual next address.
Final cost/baseline comparison appears only after completion. Run to end reveals
the entire run. Named controls work with keyboard focus; the outer scroll handles
small windows. Full screen-reader/controller acceptance remains open.

`public_observation()` is a detached dictionary whitelist: current task,
Mission/Hint1, editable policy and ranges, observed addresses, revealed decisions,
completed measured receipts, and evidence-goal status. No active hidden Trace or
catalog is returned. Completed runs contain full measured metrics because those
demands have already been observed. Policy edits restart partial evidence but never
mutate completed receipts. Task switching is unrestricted; goals do not hide streams.

Objectives judge actual comparisons, not specific policies: regular flow needs an
Off receipt and a faster useful prediction; other tasks need a slower wasted/
polluting receipt and a non-Off safe revision. Alternating hotspots additionally
require at least two rule types, as stated in its Mission.
Hint1 gives general history/Trace inspection guidance only.

## Verification and limits

Target suite: `tests/test_prediction_slice.gd`, via documented isolated verifier.
Tests must include prefix independence across changed suffixes, output identity,
cache bounds, independently expected totals, resource cost reconciliation, wrong
guess/pollution evidence, in-flight matching/queue/final drain and public hiding.
Final isolated run passed 5583 checks, including every allowed policy on all three
streams (108 configurations). Evidence:
`.godot/verification/20261002T165851Z-378232d3/test_prediction_slice.txt`.
The first sandboxed attempt failed solely because macOS QA user directories were
outside the writable roots; the isolated authorized rerun passed import and suite.

Actual Off / eager last-stride measured comparison:

| Stream | Off cycles / bytes | Eager cycles / bytes | Useful / wasted predicted B | Pollution misses |
|---|---:|---:|---:|---:|
| Regular | 150 / 40 | 102 / 44 | 32 / 4 | 0 |
| Changed | 144 / 24 | 168 / 68 | 8 / 20 | 6 |
| Alternating | 120 / 8 | 180 / 72 | 0 / 24 | 10 |

These are teaching-model measurements, not machine benchmarks or prescribed
solutions. Rule revisions have independently verified safe alternatives; no solution
catalog is exposed by Mission, Hint1, scene controls or public observations.

This is address prediction, not CPU branch speculation, rollback, learning/AI,
physical cycle accuracy or a predictor DSL. No claim about ordinary campaign
progression, beginner comprehension, native input, gamepad or complete accessibility.

## Recorded source attribution — 2026-10-06

Selected completed evidence identifies its record, original investigation and
measured rule, and whether it matches the current task/draft. Reviewing another
investigation does not change the mission or edit the rule. Partial observation
identifies only its current task/rule; final costs stay hidden. The detached
`evidence_source` public field contains task, run_index and policy only, and is
empty before running or after an edit. No saves/progression/model changes.
