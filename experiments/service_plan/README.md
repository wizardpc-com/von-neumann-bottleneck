# Editable service plan (experimental)

Goal: construct one request grouping/order and per-stream storage representation
for four persistent numerical streams. This isolated lab has no campaign save
authority. It reuses the existing recurrence weights and RLE byte codec, not a
Transformer, trained model, physical CPU, or real service benchmark.

## Contract, before implementation

All 24 requests are ready at cycle zero: A0–A5, B0–B5, C0–C5, D0–D5.
Players merge adjacent groups, split at any request boundary, move whole groups,
and choose RAW64/RLE64/RAW8/RLE8 independently for each stream. Groups are ordered
lists of requests; every request must appear exactly once, with each stream's
steps increasing. Invalid order is rejected before any simulation event. There
are no authored solution/order presets. Automatic LRU has 1–4 resident contexts.

Each context has eight values. A/B have repeated coordinates (public scalar
inputs); C/D use the older varying-coordinate formulas. Every update computes
`h = Q(0.65*h + 0.35*x)` then `score = w·h`. Weights are exact and fixed.
RAW64/RLE64 pack actual IEEE double bytes; unpack is lossless relative to
GDScript float64. RAW8/RLE8 use actual signed integer bytes on grid [-127,127].
Quantization occurs at initial preparation and every update, even while resident,
so eviction never creates an additional rounding. RLE8 reuses the real byte RLE with two-byte
length header and (count,value) pairs. RLE64 uses word runs: a two-byte element
count followed by a count byte and an actual eight-byte IEEE value per run.
Words compare bytes, preserving signed zero. Its bytes change after each update.
State backing is a fixed four-record directory, with a real two-byte length
entry per record; every state read/write includes its current directory entry.
Initial preparation is offline; every later dirty write pays online packing,
RLE encoding, transfer and replacement. No free final state discard is allowed.

## Explicit teaching costs and resources

One sequential executor; no overlap or arrival prediction. Read all group inputs,
then process requests in group order, then return all group scores. Every request
still has 24 recurrence/score accumulation units at one unit per cycle. Each score
pays one commit cycle plus ceil(8B/4) transfer cycles, without a new setup request.
Weights (64B) load once. Inputs are eight float64 values (64B per request).
Every backing read/write pays 4 request cycles plus ceil(bytes/4) transfer cycles.
RAW unpack/pack: eight conversion operations at eight operations/cycle. Q8 adds
eight round/grid operations per update (one cycle). RLE encode/decode adds
eight values plus run count operations at eight operations/cycle;
conversion base still applies. These are declared units, not hardware timings.

Decoded local contexts always consume 64B, including Q8 storage. Fixed workspace
is 64B weights plus 72B per request in the largest group (input+output). State
encode/decode temporarily needs the actual encoded record+2B length entry; peak
includes this temporary buffer and resident records. Hard scratch capacity 512B;
preflight reserves worst-case RLE size (74B payload+2B directory for float64,
18B+2B for Q8) and rejects excess before execution. Reported actual peak can be
smaller. Backing bytes and changed record sizes are measured separately.

## Three staged contracts

Calibrate from real outputs; exact alternatives must remain legal. Task 1 asks
to reduce context traffic while preserving exact quality and peak≤350B. Task 2 adds timely
first responses from every stream, exposing grouping/fairness and finite LRU.
Task 3 serves the same requests with bounded precision error and tighter traffic,
allowing a mixed per-stream representation. Goals are always visible; Hint1
points to read/write, response and byte evidence rather than prescribing a plan.
Run histories deep-copy complete plan, events and metrics. Editing never alters
an old measurement, and old runs can be restored as editable drafts.

## Acceptance and boundaries

Headless `test_service_plan` must independently verify recurrence/quality,
actual byte roundtrips, dependencies, LRU dirty eviction and flush, deterministic
trace, resource/cost accounting, distinct accepted plans, compression benefits
and failures, immutable UI history and bilingual viewport bounds. Native input,
unknown-answer proxy and screenshot inspection belong to integration verification.
The lab remains experimental: four bounded streams, known ready queue, coarse
units, offline initial preparation, fixed weights and no full allocator/parallelism.

`python3 scripts/verify-project.py --godot
/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_service_plan`

## Calibrated examples (model cycles, not hardware timing)

| Constructed plan | Cycles | State read+write | First responses | Peak |
|---|---:|---:|---|---:|
| Interleaved, 1 slot, RAW64 | 2204 | 3168B | 89/180/271/362 | 266B |
| Per-stream, 1 slot, RAW64 | 1324 | 528B | 89/415/741/1067 | 266B |
| Interleaved, 4 slots, RAW64 | 1324 | 528B | 89/158/227/296 | 458B |
| Interleaved, 4 slots, RLE64/RLE64/RAW64/RAW64 | 1280 | 316B | 78/136/205/274 | 458B |

The final mixed solution is lossless. Uniform RLE64 costs356B of state traffic,
failing the320B contract because the varied streams expand. Uniform RAW8 is another
valid final solution at1236cycles/80B, with real nonzero output/final-state error.
These are QA examples, not loaded presets or inputs to the unknown-answer policy.

## Native usability pass, 2026-10-03

The candidate now uses the game's existing instrument theme, a visible primary run action and a localized clue button. Failure feedback reports actual measured budget excess for the current contract, including scientific-notation quality errors; it does not prescribe a storage format or request order. Model.accepted remains completion authority. Final-contract success no longer promises a nonexistent next task.

Native Linux input at1280×842 verified the original interleaved baseline at2204cycles/3168B state traffic/266B peak, and the new exact784-cycle/2568B excess feedback. `test_service_plan` covers the unchanged models, bilingual1280×720 layout, peak-budget/quantization diagnostics and final-contract wording. A formatting error in the first scientific-error implementation was caught by tests and repaired before commit. This first baseline check did not establish full native completion; the subsequent end-to-end pass is recorded below. Human novice enjoyment is still unverified, and that launch was ephemeral; opt-in resume is described below.

Whole groups can now be dragged onto another visible row to occupy that index, with the same undoable edit semantics as the existing move controls. Only this list's current group payload is accepted; foreign or stale source payloads are refused. Reordering still must pass the same dependency/resource checks when run; dragging never creates a measured result. Numeric move and up/down controls remain available for distant destinations. Native Linux verified A1 moved afterA0 through a continuous pointer drag and Undo restored the original order. A short synthetic two-point drag only selected the item; the continuous desktop gesture exercised the actual drag/drop path. Tests independently cover placement, stale/foreign rejection, undo and unchanged history.

Full isolated regression after this service UI series passed58 stages (import, user-directory isolation and56 suites). Native A-only RAW8 testing also confirmed both nonzero score/state errors are shown against the1e-9 exact-quality tolerance without formatting errors. No benchmark or human playability claim follows from these checks.

### End-to-end native contracts

An informed Linux desktop playthrough subsequently completed all three contracts through actual controls. Dragging A/B/C requests into per-stream order (plus the existing distant-move control for A5) produced1324cycles/528B state traffic/266B peak, with first responses[89,415,741,1067], meeting task1. Carrying that plan into task2 failed the first-response limit by747cycles. Restoring an earlier interleaved plan, returning A to RAW64 and choosing4slots produced1324cycles/528B/458B peak and firsts[89,158,227,296], meeting task2. That same plan missed task3 state traffic by208B. Choosing lossless RLE64 forA/B and RAW64 forC/D produced1280cycles/316B state traffic, firsts[78,136,205,274], zero reported score/state error and task3 success. These are performed comparisons, not scripted presets or a claim about human discovery. Six runs remained in this temporary native session.

## Opt-in service profiles

Run `python3 scripts/run-experiment.py service_plan --godot <Godot-4.7.1> --profile my-service`. Profiles use the separate `VonNeumannBottleneckCandidates/service/<profile>` directory and `service-session.json`; the representation profile directory is not reused. Without this option the launcher still starts a disposable trial. No profile is allowed with automated replays or unrelated experiments.

Save explicitly or choose Save and quit at the unsaved-exit prompt. The draft, selected contract, latest80 recorded plans and one protected successful plan per contract are retained; measurements and unlocks are recomputed under matching model-version/public-contract identity. Selection is clamped to recomputed availability. Undo/redo stays session-local. An unfinished draft may still violate request order or resource limits; saving it grants no success, and Run continues to reject it.

Strict schema/262144-byte bounds reject unknown fields, versions and malformed plans. Future/unknown-version and changed-contract files are preserved and refused. Candidate schema1 remains readable; explicit save writes schema2 with independent successful support plans. A filesystem profile lease enforces one writable instance; digest checks additionally reject stale snapshots. Interrupted installs/corrupt mains expose explicit recovery choices and retain original bytes. See [candidate lifecycle protocol and limits](../candidate_session/README.md).

Native Linux verified two performed comparisons, save, additional unrun draft change, cancel exit, save-and-quit and restart with the exact draft and two recomputed records. An actual Alt+F4 test exposed GlobalSave preempting the candidate's dialog; a scoped close-owner guard fixed this for both service and representation profiles. Fresh native Alt+F4 now opens the correct prompt in both, and cancel/undo/save preserves their drafts. The global campaign close path is unchanged when no persistent candidate owns it. Final full regression:59 stages (import, isolated user directory,57 suites), including global-save and both session suites. Native Mac/Windows and human enjoyment remain unverified.

## Readable response evidence

The Overview tab plots the four measured first-response times. Task1 explicitly has no first-response deadline; later contracts show their actual320-cycle limit and mark only measured over-limit streams. Invalid or unperformed runs never appear as zero-latency success. Values come from the selected recorded metrics, not a new execution or prediction.

Overview, Events and Public data now have separate tabs. The public-data action opens its visible full-height tab, while actual event details remain accessible without shrinking text. An initial stacked chart layout failed minimum-viewport checks; the tabbed layout passed active-panel checks for both languages, including hints and profile save controls. Native Linux verified the restored four-stream plot and switching to complete events and public data. Full regression59 stages passed, followed by focused footer/deadline checks; this is evidence readability, not a human enjoyment result.

First-response evidence can also be replayed or stepped to the next actual response. The replay uses copied measured cycles at an explicitly scaled presentation speed; it never reruns the model, changes history or generates new results. Pausing, hiding the overview tab or losing window focus stops animation. Reduced-motion mode disables continuous playback while manual steps remain available. Replay controls keep a stable width so switching Play/Pause does not move the adjacent step button; the representation event player uses the same minimum-width rule.

Native Linux observed step to78cycles, continuous progress to105, and a tab-switch pause at40 without changing the2072-cycle recorded result. Full59-stage regression passed; final focused checks additionally cover the stable controls, hidden-tab pause, reduced-motion steps and unchanged metrics. No sound or hardware-time claim is made.

Public data defaults to readable per-stream initial-state/request rows, with an explicit full-JSON toggle. A vector is abbreviated as value ×8 only when all eight RAW64 byte words are identical; equal numeric values with different signed-zero encodings are not collapsed. Costs, weights and complete arrays remain available without running or modifying a plan. Native Linux verified A/B compact rows, C's expanded vector and raw JSON switching. Focused service and session suites passed, including a byte-constructed negative-zero fixture; this changes presentation only.

Measured Overview now names the source plan's group count, slot count and per-stream storage, and warns when the editable draft differs. Editing or undoing changes only that warning, never the recorded metrics. Native profile restoration verified the saved A/B-RLE64 draft alongside its earlier A-only-RLE64 measurement without confusing the two. Focused service/session checks cover source identity, edit/undo and bilingual minimum-viewport layout.

## Pinned comparisons

The Compare tab can pin a valid measured record, then show selected-minus-pinned cycle, state-traffic, peak-memory and latest-first-response differences. Both score and final-state errors remain visible; a faster approximate run is not declared universally better. The baseline is a deep-copied, window-only view and does not change save formats, measurements or progression. Rejected runs cannot replace it or appear as zero-cost successes. Clear removes only the comparison.

The first stacked layout failed minimum-window regression and was replaced with a separate tab. Focused service/session suites now pass all four active tabs in both languages. Native Linux selected the2204-cycle baseline and compared the2072-cycle A-only RLE64 record: -132cycles, -636B state traffic, +0B peak and -22cycles latest first response, both quality errors remaining zero. This is verified evidence presentation, not proof of human enjoyment.

Comparison presentation now uses four instrument cards with paired measured bars: pinned grey above current cyan/amber, exact values and signed differences, independent per-metric scales, and both quality errors retained separately. No combined score or inferred winner is introduced. The initial typed-array assignment and crowded minimum-window layout were caught by focused tests and repaired before publication. Focused service/session checks and native Linux pin/select inspection passed; the chart remains a read-only view of copied measurements.

Service groups also carry four fixed-position A/B/C/D colour marks for the streams actually present, while retaining the complete text tokens. Mixed groups light every included stream rather than taking only the first request's colour. Native merge A0+B0 and undo/save verified the marks and original draft return; focused service/session tests passed. Colours are supplementary, never the sole identity cue.

During further native trial, increasing A/B-RLE64 context slots from1 to4 reduced1940→1280cycles and1896→316B state traffic, but raised266→458B peak, correctly failing task1's memory budget. A deliberately misplaced A0 then triggered dependency rejection. Rejection now identifies the first offending group/request and the prerequisite in both languages; Overview and history say not run rather than advertise zero-cost/zero-error results. Restored histories scroll to the selected record. Native undo/save/restart preserved the valid draft and rejected attempt; focused service/session checks passed. The final explicit rejection explanation is also retained in Overview after session-status messages.

## Readable recorded events, 2026-10-04

Events now show localized A/B/C/D and request identities, with a short explanation
before optional complete raw event JSON. State transfers report the recorded byte
count (including the two-byte directory entry), event cycles and representation;
writeback distinguishes eviction from final flush. Resident reuse explains the
avoided state read without calling later computation free. Missing/unknown fields
remain unknown. The Events source caption names the measured plan and flags a
changed draft; translation and raw-view changes never recalculate a record.

Focused isolated `test_service_plan` and `test_service_session` passed on Godot
4.7.1. Formatter checks cover both languages, actual trace fields, unknown/missing
identities, raw evidence and history immutability; active-tab bounds remain tested
at 1280×720 with Hint1. Actual cloud Linux mouse/key QA in a separate candidate
profile confirmed A's eviction writeback at114 (66B/17cycles), B's read at135,
A's resident reuse at316, final-flush writes, raw toggle, language retention,
and changed-draft source. One-slot→four-slot results remain2204→1324cycles,
3168→528B state traffic,266→458B peak; the latter still fails task1 by108B.
Native screenshots were inspected in the tool record at1364×1024 and1280×842;
minimum720-height bounds are automated, not native evidence. This is informed
presentation QA, not novice understanding, exported-platform or audio acceptance.

## Candidate service journey, 2026-10-05

The shared candidate launcher accepts `service_plan --profile NAME --journey`.
It opens the existing candidate hub; service and representation keep independent
files under their original sibling profile directories. The lab recognizes
`--candidate-journey`, exposing Home (`CandidateHome`) through the same unsaved
Save / Keep editing / Discard guard as Quit. A failed or blocked save leaves the
workbench open. Standalone disposable and persistent service launches remain available.

The three unchanged contracts now carry compact observation guidance: where
history resides and how grouping changes transfers; who waits for a first answer;
and how storage changes bytes, codec work and quality. These observations expose
existing rules and evidence without installing solution presets or extra gates.

Service review (`ServiceClosure`, modal `ServiceReview`) opens only when all three
protected successful plans still meet their own contracts under the current
model. Review recomputes those plans and shows cycles, state traffic, peak bytes,
all four first responses, and both quality errors. Current drafts, recent-history
retention and the last unlocked task cannot stand in for completion evidence.
The review closes this candidate journey with measured work and the existing
“A Thought Within the World” theme; it adds no campaign progress or save fields.
Unsaved and disposable sessions are explicitly identified in the review.

Implementation verification is pending integration: `test_service_session`
adds Home cancel/save/discard/blocked-save destination checks and bilingual,
protected-plan-based closure checks; `test_service_plan` retains the existing
model, valid-alternative and minimum-window presentation checks. Native Mac,
exported-app and novice acceptance require separate evidence.
