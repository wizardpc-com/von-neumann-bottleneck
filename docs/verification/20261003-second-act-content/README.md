# Second-act candidate content — 2026-10-03

Baseline `39d0441`. Godot4.7.1stable, macOS/AppleM2 Compatibility renderer.
Official five regions/40tasks, prerequisites, core simulation, save/progression and
ambience are unchanged. All new mechanics and local task completion remain isolated.
[Framework](../../design/second-act-framework.md) · [launch instructions](../../../experiments/README.md).

## Parallel work and integration

Three GPT-6.1 Sol High agents owned disjoint directories: candidate_region (five
Representation tasks), prediction_slice (causal bounded-history model/three
investigations), service_plan (editable groups, recurrence and actual state codecs).
Sol Medium policy_audit supplied adversarial policy checks; its final run hit the
usage limit. Root inspected and completed those tests, added service-policy checks,
independent analytical cost/numerical oracles, launch/replay/proxy integration,
UI repairs, documents and final verification. No agent committed independently.

The root review required explicit retained-source preparation storage/total traffic,
actual cache-fetched Prediction outputs and strict input types, word-RLE vs byte-RLE
rules, and an exact-service scratch contract that prevents a four-slot shortcut in
task1. New rules are documented in each experiment README; no production DSL changes.

## Automated evidence

- `targeted-integration/`: import/user-directory plus five suites passed: policies238,
  Representation3329, Prediction5583, service3851 and root independent oracle69checks.
- `targeted-ui-repairs/`: Prediction and service passed after screenshot-driven fixes.
- Model tests check finite resources, deterministic Trace, every relevant byte/cycle,
  malformed input, immutable measurements, bilingual geometry and multiple solutions.
  Service additionally checks all256 storage combinations across1/2/4slots against
  independent numerical recurrence. Root verifies lossless states with a closed form,
  complete hand-calculated cost bills, malformed word runs and in-flight prediction.
- Receiver2, storage3 and community5 Python tests passed (`server/`). Godot loopback
  community lifecycle (four processes) and legacy feedback restart/retransmission also
  passed their lifecycle assertions with synthetic data; isolated settings restored
  byte-for-byte. **Separate existing-code diagnostic:** community `delete_offline`
  prints `ERROR: Parse JSON failed` because unchanged `remote_feedback.gd:194` parses
  the empty failed-HTTP body before checking its result. The test exits0/PASS and
  subsequent deletion resumes correctly, but this integration log is not error-free.
  No production feedback code was changed; this cleanup remains outside this scope. Initial
  localhost binds were sandbox-blocked; the authorized localhost rerun succeeded.
- Python launcher compilation succeeded with a writable temporary bytecode cache.
  The initial default macOS cache location was sandbox-blocked; no source defect.

Full regression from frozen implementation `e4e359006d61619955551c2ca54e447077a07448`
passed **54 conventional suites + import + user-directory =56 checks**. A clean detached
checkout and actual imported copy matched1539tracked files, with zero source mismatches
and clean before/after status. [Receipt](full-regression/receipt.json),
[full log](full-regression/verification.txt), [manifest](full-regression/source-manifest.json).
No script errors; four existing anchor warnings remain in `test_desktop_conventions`,
also present in the preceding depth verification. Final follow-up commit contains
only docs/evidence; no runtime/test code changes follow this frozen implementation.

## Unknown-answer/evidence-driven viewport policy

These are bounded authored heuristics, **not a human novice, independent reasoning
agent or native OS input**. Policies receive whitelisted public mission/data, visible
controls and completed results. They import no model/catalog and cannot load QA plans,
reference answers or an unseen Prediction stream. Poison-field tests, shifted assets,
finite budgets and observed-waste response test that boundary; they do not prove a
sandbox against arbitrary hostile code. Root who wrote the policy had model knowledge.

Actions use actual Godot viewport mouse/keyboard dispatch in isolated copied projects.
Popup menus use Godot-rendered mode for injected keys on macOS. No direct select/signal
or hidden progress setter is used to enact a solution. Prediction initially reveals
exactly two requests. Full journals contain every observation, proposal and bounded stop.

| Run | Decisions | Outcome | Evidence |
|---|---:|---|---|
| b76464d6a1ea Representation EN | 28 | 4/5; fifth stalls honestly | [journal](proxy-representation/unknown-answer.json) |
| a2816aa0cf88 Prediction EN | 13 | 3/3 | [journal](proxy-prediction/unknown-answer.json) |
| 5c516b786c78 Service EN | 15 | 3/3 | [journal](proxy-service/unknown-answer.json) |

Representation's finite run-boundary/island/quarter hypotheses do not infer a successful
cross-asset compromise. This remains a design/playtest question, not grounds to lower
goals or pretend the agent discovered the QA solution. Prediction's authored strategy
is limited rule comparison with waste-driven caution, not inference of arbitrary code.
Service uses actual repeated coordinates in public input vectors, not an A/B answer map.

## Observed problems and repairs

1. Long histories left selected latest results offscreen while the summary changed.
   All three views now scroll the new selected measurement into view; Representation
   also labels each history row with its task. Added targeted checks and replayed UI.
2. Prediction's outer scroll allowed long mission text to stretch beyond the viewport.
   Disabled horizontal expansion; bilingual1280/1600 geometry tests and final replay.

Proxy runs preceded these presentation repairs. Their model/policy/actuator bytes are
compared separately in provenance; final known-objective replay validates repaired UI.
The pre-repair screenshots are explicitly diagnostic evidence, not final acceptance.

A final Chinese Prediction replay (`58b82efb78b7`) failed two QA assertions after a
macOS popup lost focus: the new rule was visible, but the Run click produced no new
receipt (history still showed Off144, result explicitly unrun). Its failure log/checks
are retained in `failed-focus-replay/`. The actuator now avoids reopening unchanged
selectors and reacquires window focus before clicks/after menus. This is a harness
repair, not a changed cost/goal or a passed run; final replay must succeed separately.

## Known-objective viewport QA

`--replay candidate` deliberately contains QA plans, in a file separate from the
unknown-answer policy. It constructs them through visible edits, checks failing and
passing measurements, selects Trace events and captures both languages. This proves
operability/observability and preserves counterexamples; it is not discovery evidence.
All six bilingual known-objective paths passed:

| Domain | Chinese run / checks | English run / checks |
|---|---|---|
| Representation5tasks | 81c9a3ffbf8e /152 | 001b019295c0 /152 |
| Prediction3investigations | 56935e722038 /66 | 1a703720f4bb /66 |
| Service3contracts | 8873315add3a /141 | a37698d72d4c /141 |

Each `known-<domain>-<locale>/` contains logs/checks and selected screenshots.
Root visually inspected both languages including cross-asset results, preparation,
prediction pollution/fallback and exact mixed service. The repaired history exposes
its latest measurement, and the final Prediction mission fits without horizontal loss.

[Viewport source provenance](viewport-source-provenance.json) compares every tracked
GDScript/scene/resource/Python file with the frozen commit (only two isolated-save
settings normalized). All three final English runs and final Chinese Prediction
have zero code differences/missing files. Earlier Chinese Representation/Service
used the same domain runtime, before unrelated Prediction geometry and input-focus
repairs. Earlier proxy runs used final domain models and their respective final
policy; listed differences are later UI/harness/test changes (Representation's copy
also predates an unrelated Prediction-policy refinement). No universal claim that
all earlier screenshots came from the final full tree is made.

## Disposition and limits

**INCORPORATE**: isolated launch/test infrastructure, public-evidence regression and
observed history/layout repairs. **KEEP EXPERIMENTAL**: Representation candidate5tasks,
Prediction3investigations, Service3contracts. **DEFER**: campaign registration/save
formats, CPU speculation, general DSL, fullML/Transformer teaching, world history,
consciousness conclusions and further music work.

Representation online preparation retains original data, rather than modeling allocator
reclamation. Prediction has two cache slots, one bus and a small rule vocabulary.
Service starts with24known-ready requests/four streams, offline initial preparation and
fixed weights; it establishes no real-world AI quality/performance claim. Native OS
menus, exported builds, controller/accessibility and human novice cognition remain
unverified. Next priority: stranger playtests of cross-asset comparison and service
first-response tradeoffs, before increasing the number of tasks or registering a region.

Archived text logs trim trailing whitespace only; diagnostics are retained verbatim otherwise.
