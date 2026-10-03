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

Run `python3 scripts/run-experiment.py representation_region --godot <Godot-4.7.1> --profile my-trial` to keep a separate candidate session across launches. Profile names accept 1–40 ASCII letters, digits or hyphens. Profiles are never allowed with automated replays or other experiments. The default launcher still creates disposable isolated sessions.

Use **Save drafts and comparisons** before quitting. Unsaved exit offers Save and quit, Keep editing, or Quit without saving. Each task's draft and the most recent 100 comparison plans are retained; undo/redo is session-local. Candidate checkmarks are recomputed from retained comparison plans, not trusted saved flags. Old successes outside the retained history are not permanent campaign achievements. On restore, traces are recomputed under the exact matching model and public contract fingerprint, and the UI says so.

Storage is `representation-session.json` inside the explicitly separate `VonNeumannBottleneckCandidates/representation/<profile>` user directory. Ordinary player directories are not used. Malformed, future/unknown-schema, changed-contract or oversized files are preserved and not overwritten. A stale writer is rejected against its loaded content digest; this is not an interprocess lock, so only one running window should write a profile. A prior successful save is retained as `.bak`; write/rename failures leave a visible error. No automatic migration, recovery or deletion is attempted.

Focused checks: `test_representation_session` and `test_representation_region`. Native Linux input confirmed draft edits, two actual comparisons, save, exit, restart into the same task/draft/history, then cancel and retry unsaved exit and save-and-quit. Known-objective agent testing does not establish novice understanding. Native Mac/Windows and audio acceptance remain unverified.

## Iterate from your own evidence

Select a performed run and choose **Try a variation of this plan** to copy that owned plan into its task draft. Older traces remain immutable; the displaced draft can be restored with Undo. Cross-task reuse preserves the departing draft and opens the recorded task. Reusing an identical draft adds no fake undo step. No reference answer is provided and no run/completion is granted by the copy.
