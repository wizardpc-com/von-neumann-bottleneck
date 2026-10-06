# Candidate representation region

Rules recorded before implementation. This isolated five-task region reuses the
editable representation codec, directory, automatic decoded LRU and authoritative
Trace. No campaign registry, ordinary campaign save, receipt, Notebook or telemetry is involved. Optional candidate-profile storage is described below.

## New preparation rule

Offline tasks start with already stored assets, as in the retained workshop.
Task 4 instead starts with an immutable RAW source. A RAW interval references those
existing bytes and prepares only its four-byte directory (4-cycle write request,
then 4 bytes at 1 B/cycle). It neither reads nor copies its existing source payload.
An RLE interval pays a 4-cycle source request, reads its entire source interval at
1 B/cycle, performs output-length plus actual run-count encoding operations at
8 ops/cycle, then pays a 4-cycle write request and writes its real RLE payload and
four-byte directory at 1 B/cycle. Work is rounded per block. This rule describes
conversion from an existing source, not free online creation of RAW data.

Serving continues to charge every block's payload and directory, even RAW. Online final stored footprint and preparation peak count the retained 64B
immutable source plus all written directory/RLE bytes. RAW uses source references;
no source reclamation or intermediate encoding-buffer storage is modeled. Logical
representation bytes are reported separately. No allocator,
parallel conversion, write-back, update/reencoding or physical hardware timing is
claimed. Preparation is synchronous and occurs once before the first service.
Eight-client service prepares once, then executes eight independent cold-cache
scans. Each client gets exact bytes and a fresh automatic cache. The short service
and eight-client service are independent evaluations of the SAME plan, each with
its own preparation. UI reports preparation cycles, source reads, writes and
encoding work separately from service traffic, decoding and consumption.
`total_traffic_bytes` sums preparation reads, preparation writes and service
traffic. `peak_preparation_bytes` is backing-storage peak only, excluding recovery
scratch and temporary codec buffers; it is not a total RAM peak.

## Construction and progression

Every task owns its draft and undo/redo stacks. Split at any integral address,
merge with the right neighbor retaining the left codec, and select RAW/RLE per
block. Maximum eight blocks, exact ordered coverage of all 64 byte addresses.
Every variable block pays a real four-byte directory; RLE has a two-byte length
header and count/value pairs. Scratch is 64B. All requests are synchronous with
4-cycle latency, 1 B/cycle bandwidth, 8 decode ops/cycle and 1-cycle consumption.
Cache is automatic byte-budget LRU; oversized blocks bypass without evicting.

Five public tasks record completion in memory; every task is freely accessible
for candidate comparison, with numbered order recommended: mixed scan; interior hotspots with a tight
storage limit; one plan for a four-band scan and endpoint revisits; preparation
amortization; and one plan across two distinct assets/orders. Task acceptance
checks complete authored spec, same immutable plan across orders, exact outputs,
and all published budgets. No named codec or prescribed boundary is required.
A copied old three-task partition cannot clear the region: the band task and
preparation task impose different measured decisions. Hint1 identifies evidence
to inspect, and never gives boundaries or a reference solution.

## Public UI and verification interface

Scene: `res://experiments/representation_region/region.tscn`. Controls:
`Blocks`, `SplitAt`, `Split`, `Merge`, `Raw`, `RLE`, `Undo`, `Redo`, `Run`,
`Task0`…`Task4`, `History`, `RecordedOrder`, `Events`, `TraceDetails`, `Mission`,
`Hint1`, `Asset`, `Language`, `Quit`. `public_observation()` exposes visible mission,
Hint1, assets, editable draft, performed-run metrics/events and control bounds.
It contains no solutions or unperformed-run results. History records full specs,
plans, and owned traces and cannot be changed by later draft edits.

Run `python3 scripts/verify-project.py --godot <Godot-4.7.1> --suite
test_representation_region`. UI layout uses scrollable columns at 1600×900 and
1280×720; actual viewport input and captures are separate from headless contracts.
Human comprehension, controller input, campaign integration and persistent drafts
remain unverified scope boundaries.

## Published goals and measured QA

| Task | Orders and actual public acceptance |
| --- | --- |
| 1 Mixed scan | Asset0, scan0…63: ≤136 cycles, ≤60B stored |
| 2 Interior hotspots | Asset1,20/43 repeated3: ≤38 cycles, ≤16B service traffic, ≤52B stored; cache32B |
| 3 Dense and sparse | Asset2 scan≤128 cycles; endpoints0/63 repeated4≤38 cycles/16B traffic; both stored≤36B |
| 4 Prepare once, serve | Asset3 short read0≤105 cycles; eight cold scans≤930 cycles; both actual retained-source storage≤80B |
| 5 Two assets, one plan | Asset4 scan≤135 cycles; Asset5 revisits4/59 repeated3≤38 cycles/18B traffic; both stored≤50B |

Known-objective QA references (not UI hints or preset buttons): task1 RLE[0,16)
+RAW[16,64) gives135 cycles/60B, while shifted14/48 mixed gives135/54B.
Task2 five blocks ending16,24,40,48,64 (RLE,RLE,RAW,RLE,RLE) give34cycles,
16B service traffic and52B storage; shifted12/24/40/52/64 also passes. A whole
24B repeated block on either side cannot keep both decoded intervals in32B cache.
Task3 RLE16/RLE32/RLE16 gives113 scan/38 sparse cycles and26B stored; a shifted
15/32/49 four-RLE-block design gives126/36 and36B. Whole RLE64 wins the scan but
must restore an oversized block again on every sparse request.

Task4 RAW8+RLE56 gives105 short/888 eight-client cycles and76B actual stored;
RAW12+RLE52 gives104/907 and76B. RAW64 gives81/1096, RLE64 gives111/769: preparation
really reverses their ranking for short versus amortized service. Source remains64B;
logical representation bytes differ from actual retained-source storage.
Task5 has different run boundaries: AssetA runs end20/start44, AssetB runs
end18/start46. The18/46 mixed partition gives130 scan/36 revisit cycles and48B;
19/46 gives129/38 and47B/49B respectively. Optimizing only AssetA with20/44 fails
AssetB. Every paired result uses one unchanged partition.
The old RLE16+RAW32+RLE16 solution fails tasks2–5.

Fresh headless verification: `20261002T170129Z-d8de7f0d` isolated import,
user-directory check and `test_representation_region` all PASS;3327 checks,0
failures. Includes actual logical1600×900 and1280×720 layout bounds in both
languages, public controls, complete output/cost oracles, alternatives, invalid
plans, authored spec/plan binding, preparation reversal and immutable history.
These are programmatic contracts; no viewport-input or human comprehension claim
is made by this suite. Root owns separate graphical acceptance.

## Opt-in candidate profiles (2026-10-03)

Run `python3 scripts/run-experiment.py representation_region --godot <Godot-4.7.1> --profile my-trial` to keep a separate candidate session across launches. Profile names accept 1–40 ASCII letters, digits or hyphens. Profiles are supported only by representation_region and service_plan, use separate candidate directories, and are never allowed with automated replays. The default launcher still creates disposable isolated sessions.

Use **Save drafts and comparisons** before quitting. Unsaved exit offers Save and quit, Keep editing, or Quit without saving. Each task's draft and the most recent 100 comparison plans are retained; undo/redo is session-local. Candidate checkmarks are recomputed from protected successful plans and recent comparison plans, never trusted saved flags. Each task keeps a successful immutable plan outside the 100-record history cap; the protected plan can be restored to its draft. These remain candidate results, not campaign achievements. On restore, traces are recomputed under the exact matching model and public contract fingerprint, and the UI says so.

Storage is `representation-session.json` inside the explicitly separate `VonNeumannBottleneckCandidates/representation/<profile>` user directory. Ordinary player directories are not used. Future/unknown-schema and changed-contract files are preserved and refused. Interrupted installs and corrupt mains expose explicit valid snapshot choices, preserving original bytes. Candidate schema1 is read and migrated only on explicit save to schema2; no global schema changes. A filesystem lease enforces one writable window per profile, independently of the digest check. Details and platform limits: [candidate lifecycle protocol](../candidate_session/README.md).

Focused checks: `test_representation_session` and `test_representation_region`. Native Linux input confirmed draft edits, two actual comparisons, save, exit, restart into the same task/draft/history, then cancel and retry unsaved exit and save-and-quit. Known-objective agent testing does not establish novice understanding. Native Mac/Windows and audio acceptance remain unverified.

## Iterate from your own evidence

Select a performed run and choose **Try a variation of this plan** to copy that owned plan into its task draft. Older traces remain immutable; the displaced draft can be restored with Undo. Cross-task reuse preserves the departing draft and opens the recorded task. Reusing an identical draft adds no fake undo step. No reference answer is provided and no run/completion is granted by the copy.

Failed orders now identify each measured budget excess and its public limit, in both languages and in historical records. This is diagnostic feedback, not a prescribed solution.

### Keep named alternatives

Expand **My designs** beside the recorded-history actions, select a measured run,
and give that plan a name. Naming captures the selected recording even if the
current draft has changed; an unrun draft cannot be collected. Names contain
1–48 characters after trimming, with no control characters. Up to24 distinct
task/plan pairs are kept independently of the rolling100-run history; naming the
same task/plan again renames its entry. Collection plans are detached copies.

**Copy into task draft** opens the design’s original task and uses the ordinary
Undo transaction to preserve the displaced draft. It preserves history and
collection, produces no new run and grants no progress. **Remove from collection**
changes only this window’s collection until explicit **Save drafts and comparisons**.
Naming/removal share the existing unsaved-exit, reload and recovery guards. Save
retains the collection across reopening the same candidate profile; no campaign
save is involved. Older schema1/2 profiles start with an empty collection; profiles
with collections use candidate schema3, validated by the shared session codec.

`DesignName`, `RememberDesign`, `NamedDesigns`, `RestoreDesign`, `RemoveDesign`
and `ToggleDesignShelf` expose the UI to `test_representation_design_shelf`.
This suite covers selected-record ownership, rename/save/reopen, cross-task
restore/Undo, history-cap survival and removal/reload. Native input/readability
and human discovery remain separate acceptance checks.

## Byte patterns and recorded playback

Public assets are rendered as exact 16×4 byte boards: equal values share colors, borders identify RAW/RLE partitions, and selecting a byte selects its editable block. Arrow keys move between partitions; the original numeric list remains available. Different assets remain separately visible in the paired task. The board visualizes the draft, while the right-hand record explicitly identifies the performed plan.

Recorded events can be stepped or played through request, transfer, transform and consume phases. Event cycle, duration and address are copied from the actual Trace. Playback is initially paused; switching records clears playback state. Presentation speed is scaled for readability and is not a simulated clock or new execution. Reduced-motion presentation removes the animated progress line; manual stepping remains available. No sound was added in this slice.

Native Linux input verified byte/block selection, playback, exact request/transfer/decode evidence and switching between recorded plans. Automated visual coverage checks defensive copies, both public assets, reduced-motion stepping and unchanged canonical Trace signatures. These are usability/evidence checks, not a claim that human players find the candidate fun.

The optional public-order preview marks only requested byte addresses with a gold underline. Hover counts are request repetitions per client, not cache hits or predicted cost. Choose “No request markers” to clear it. In the paired task, only the corresponding asset receives markers; previews never execute a plan or create history. Native hotspot play reduced an actual failed plan from 342 cycles/312B traffic/60B storage to a five-block plan at 34 cycles/16B traffic/52B storage. This validates the evidence-to-edit loop for an informed tester, not unaided novice discovery.

The default split now gives the evidence pane comparable space instead of squeezing it to its minimum width. The divider remains adjustable. Native 1280-wide Chinese/English checks verified both sides remain usable; selected history is explicitly highlighted and scrolled into view after reopening or rebuilding the screen.

Recorded playback also shows actual decoded-cache occupancy before and after the selected event, with block IDs ordered by recorded LRU age. An absent snapshot stays explicitly absent. These bars show decoded cache bytes, not compressed storage; an oversized decoded block is not drawn as retained. The selected recorded partition stays visible above the metrics and explicitly says when it differs from the current draft.

## Complete isolated journey (2026-10-04)

Use the existing hub rather than a direct workbench launch:

```sh
python3 scripts/run-experiment.py representation_region --godot /path/to/godot --profile my-representation --journey
```

The opt-in hub card enters/resumes the same five-task region. Home, Quit and window
close protect unsaved work; return to the hub releases writer ownership. All five
verified supports enable Region review with actual per-order cycle costs. The review
is an optional local closure, not another completion requirement. Original core40
navigation/endings remain unchanged; service and prediction are not prerequisites.
No candidate is registered or advertised in an ordinary launch.

## Preparation and cross-asset evidence (2026-10-05)

The selected recording first shows preparation cycles, service cycles, their total,
actual stored footprint and service traffic. Online storage explicitly includes the
retained immutable source; logical representation bytes remain a separate detail.
An all-order comparison keeps both independent preparation services or both asset
orders visible under their one recorded plan. Selecting a row opens that order's
actual Trace; reopening a failed run selects its first unmet order.

Cost breakdowns and event details can be expanded with `ToggleTraceDetails`.
Playback remains available while details are collapsed. Expansion is presentation
only and survives language changes. `OrderComparison`, `PrimaryMetrics` and
`CostBreakdown` expose these controls to UI checks. The recording is labeled with
its run/task identity and immutable evidence ownership, including whether the
current draft differs. Task 5's draft also reports storage for both assets before
running, using each asset's real block evidence without predicting service costs.
No acceptance budget, completion rule, saved format or model version changes.

`test_representation_visual` covers both assets, authoritative preparation/service/
storage comparison, detail expansion, language rebuilding and unchanged recorded
Trace signatures after draft edits. Native readability and novice understanding
require separate play checks.

Integrated Mac viewport/save/restart outcomes and OS-native/package limitations:
[2026-10-05 evidence](../../docs/verification/20261005-mac-second-act/README.md).

## Continue the second-act candidate

In an explicitly enabled candidate journey, the earned five-task Region review
offers **Continue: history and responses**. It rechecks your protected successful
recipes and uses the existing Save/Discard/Cancel guard before entering Service.
The same named sibling candidate profile retains its own plans; Representation
recipes are not translated into Service plans. Home still has independent entries.
Home's **Review saved second-act plans** revalidates all five Representation tasks
and all three Service contracts from saved recipes. Unavailable/recovering profiles
are explicitly unconfirmed, and drafts/unsaved work do not grant completion.
Prediction and follow-up commissions are optional, outside that combined review.

## Earlier matching measurements — 2026-10-06

Cost details compare the selected recording with the nearest earlier recording
of the same task and complete order specification, even when another task was
measured in between. They name both record numbers and report preparation, service,
total cycles, actual storage, service traffic and all-phase traffic separately.
No matching earlier recording is stated explicitly. Future records and unrun
drafts never supply this comparison; historical traces remain unchanged.
