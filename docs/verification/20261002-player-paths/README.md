# Evidence-driven player paths — 2026-10-02

Baseline: `6905a0b`. Controller tests, viewport proxy runs, native OS input and human
play are separate evidence classes.

## Stage 1: known defects

ALU investigation Reset previously cleared the observation list and then called a
storage-only guard. It now uses the shared simulation reset, as does the storage
button. Debug memory, prior outputs, playback batches, current Trace and stale
result/caption are cleared. A non-committing live signal preview may be recomputed;
it cannot restart playback. Inputs, topology and earned official proof remain.
Reset during official tests/hints is ignored rather than interrupting authority.

Both working_set descriptions/objectives/second briefing pages now ask what was
fetched, without announcing the second-pass outcome. Earned explanations remain.
The worship sentence is removed from both ending translations, with no replacement
lore.

Four fresh isolated suites passed: hardware foundations/prologue UI, localization,
theme reflection. See fixes-results.json and individual logs. The first sandboxed
import could not create macOS QA user directories; the documented verifier was
rerun with filesystem permission and passed. No source parse/runtime failure was
hidden by that retry. This stage contains no human or native-path acceptance claim.


## Stage 2: targeted iteration and evidence boundaries

ALU official tests now retain all 32 cases as four expandable operation groups.
An active or failed group remains expanded; completed passing groups collapse.
Optional experiment observations retain at most 8 executed samples: the first lists
all inputs, later rows list only changes, and every row retains actual outputs.
This keeps independent RAM addresses and CPU memory readback visible together.

Bus History now displays percentages for the transfer and total-time comparison;
the bilingual question asks whether these reductions match. Capstone's actual
cycle/cost/configuration alternatives appear above its long event tree, after the
existing diagnosis gate. This is discoverability work, not a new workload or
simulation change. Audio remains unchanged and default off.

Eight targeted suites were run. Seven initially passed; locality UI caught a new
GDScript typed-array error in the compact comparison list's empty ternary branch.
The branch now initializes a typed array explicitly. Locality UI and localization
then passed in a fresh copy. Full initial and repair results/logs are in `targeted/`;
the failed initial run is deliberately retained rather than labelled PASS.

### What the proxy does

`scripts/proxy-player-paths.gd` extends the existing ordinary Game viewport replay.
It drags components/wires, types values and programs, clicks Run/Review, changes
visible options and earns prerequisites from real results. It never loads a Test
library, inserts a solution circuit, calls a judgment function, or sets completion.
State reads are assertions and recordings, not actions. Named hardware workbenches
and the Game save are written only to the harness's QA paths and are revalidated on
restart. Real player saves are not used.

For macOS menus only, the proxy sets `PopupMenu.prefer_native_menu=false` and sends
keyboard events to the actual popup window. The options/actions are unchanged;
this is Godot-rendered viewport evidence, not native macOS menu acceptance.
Engine screenshots likewise are not OS screenshots or human novice evidence.

### Intermediate diagnostics (not acceptance)

The exploratory QA copy was `20261002T135122Z-8f638c11`; earlier reset/baseline copy
was `20261002T134235Z-da6eb418`. Full logs and all captures remain under the ignored
`.godot/verification/` directories. Intermediate failures were inspected:

- The initial LOAD/STORE replay accidentally toggled its test bench closed.
- A restart exposed that the stock `--script` harness disabled workbench disk
  writes. Enabling a QA-only store allowed the UI-earned circuits to revalidate.
  This was not fixed by granting progress or accepting missing hardware.
- OptionButton events initially targeted the root viewport instead of the popup
  window. The proxy now uses window-addressed key input and Godot menus.
- System proxy checks confused disabled-but-unselected prediction controls with
  locked predictions, and attempted the hidden baseline-reuse control.
- Locality's first 113-check replay printed PASS but then accessed a freed scene
  after capstone Continue. It is NOT a clean pass. The proxy now returns immediately
  after that navigation; clean replay is reported separately below.
- Layout exploratory attempts toggled tools closed, then attempted a result button
  in a hidden panel. Navigation now uses the visible Task tree header. The v4
  relocation replay passed 38 checks, but its field baseline had inherited earlier
  edits. Only a fresh replay may serve as the fields controlled comparison.

These diagnostics distinguish harness faults from observed player-facing issues.
The observed presentation issues were ALU record verbosity and capstone comparison
being buried below Trace rows; their targeted changes require the clean rerun.


## Clean ordinary Game rerun

Chinese proxy candidate (before the subsequent failure-feedback correction):
`20261002T141807Z-1eb2c839`, QA user directory
`VonNeumannBottleneckChecks/player-paths-20261002/zh-clean`. Started empty.
The full construction → system → locality route passed **997 checks**. Two new
processes loaded that same UI-earned save: buffers passed **36**, layout passed
**32**. All three exit 0, no failed assertion or GDScript error. The macOS IMK
mach-port warning is retained in the layout log; it did not prevent menu input.
Logs, every assertion and experiment notes are retained in `proxy/`.

| Path | Decisions and observed evidence | Learning assessment / limit |
| --- | --- | --- |
| ALU | Manually hold A=1, B=0, CIN=0; change OP through four values; RESULT0/1/1/0. Reset clears observations and playback. All32 official cases pass from UI wiring | Changed-control record fits in one view. Same-input operations visible; building the selection structure remains demanding |
| RAM | Write address0=7, address1=9, overwrite0=2, read1 gives9 | Independent state can be explained from four visible samples; no preset-click sequence required |
| CPU | Wrong ALU source fails official cases; erased/redrawn wire passes | Failure is causal evidence. Agent knew the solution, so this does not prove novice diagnosis |
| LOAD/STORE | Immediate4 → STORE1; immediate13 → STORE0; LOAD1 returns4 | Own CPU changes/reads independent memory. Optional application experiment, unchanged formal goal |
| cpu_speed → ram_wait | Faster CPU aggregate268 cycles, wait252; faster RAM124, wait108. Reuse control adopts only revalidated exact observed baseline | Reduces duplicate baseline run; prediction/observation still required |
| bus_width | Transfer64→16 (-75%); total144→96 (-33%) | Both proportions visible together; unchanged time is available in Trace |
| working_set | Actual210 cycles /8 misses; wrong explanation rejected, supported explanation accepted | Objective gives question, not second-pass result |
| blocking | Baseline0 and groups4/2:210 /8miss; group1:138 /4miss | Real counterexamples retained. Agent explored them deliberately; spontaneous player comparison remains unproven |
| capstone | Wrong diagnosis rejected; larger cache alone:138/cost13; cache1+group1:138/cost4 | Both real alternatives visible above Trace. Familiar workload, not a new transfer problem |
| buffers | Typed early consume fails; two wired buffers with serial program40 cycles; revised typed schedule28 with overlap12 | Parts alone insufficient; schedule explains improvement |
| fields → relocation | Fresh fields145/217 becomes81/121. Relocation A direct307; B direct2456, copied1362=prepare442+query912+output8 | Preparation included; one-time and repeated queries keep distinct plans |

### Representative screenshots

- ALU [before](screenshots/alu-before.png), [after](screenshots/alu-experiment-evidence.png), [reset](screenshots/alu-reset.png), [formal cases](screenshots/alu-tested.png).
- [RAM independent addresses](screenshots/ram-experiment-evidence.png), [CPU wrong source](screenshots/cpu-wrong-source.png), [LOAD/STORE readback](screenshots/load_store-experiment-evidence.png).
- [CPU](screenshots/cpu_speed-evidence.png), [RAM](screenshots/ram_wait-evidence.png), [Bus percentages](screenshots/bus_width-evidence.png).
- [Working-set entry](screenshots/working_set-entry.png), [wrong explanation](screenshots/working_set-wrong-explanation.png), blocking [4](screenshots/blocking-group-4.png)/[2](screenshots/blocking-group-2.png)/[1](screenshots/blocking-group-1.png).
- Capstone [before](screenshots/capstone-before.png), [visible cost alternatives](screenshots/capstone-cost-comparison.png).
- Buffers [serial](screenshots/buffers-serial-two-parts.png), [overlap](screenshots/buffers-overlap-evidence.png).
- Fields [record](screenshots/fields-record-order.png)/[field](screenshots/fields-by-field.png); relocation [direct](screenshots/relocation-direct-both.png)/[selective preparation](screenshots/relocation-copy-repeated-only.png).

### Reproduce the proxy

Use `scripts/verify-project.py` to create/import an isolated copy (never the source
checkout). In that copy only, assign a new unique `application/config/custom_user_dir_name`
under `VonNeumannBottleneckChecks/`, with `config/use_custom_user_dir=true`.
Run Godot 4.7.1 on that copy, not headless:

```sh
Godot --path <isolated-project> --script scripts/proxy-player-paths.gd -- --locale=zh_CN --recovery-capture --evidence-dir=res://.godot/player-clean
Godot --path <same-isolated-project> --script scripts/proxy-player-paths.gd -- --locale=zh_CN --resume=overlap --recovery-capture --evidence-dir=res://.godot/player-overlap
Godot --path <same-isolated-project> --script scripts/proxy-player-paths.gd -- --locale=zh_CN --resume=layout --recovery-capture --evidence-dir=res://.godot/player-layout
```

Keep the same QA user directory for the resume processes. Full route expects an
empty save; do not reuse a prior completed save as a fresh acceptance run. Inspect
both exit status and full logs for SCRIPT ERROR, not just the final PASS marker.

## Acceptance still missing

This round adds no native OS input evidence; earlier native keyboard smoke and
mouse-interface limitation are historical. These screenshots use engine rendering.
No human beginner test, spontaneous exploration/enjoyment evidence, subjective
long listening session, Windows run or new release-package acceptance is claimed.
Audio was left default off along these paths; lifecycle/state isolation has automated
coverage, but no new sound-quality judgment. No unfamiliar capstone workload was
invented to fill the model gap.


### Further issue found during screenshot review

The Chinese working-set failure screenshot above revealed a generic response about
fetching versus compute time. That did not direct a capacity investigation to its
relevant evidence. The response now asks which line is requested and which remains
cached at the boundary between passes. It gives no miss count or second-pass result.
A focused regression checks the response and that the wrong answer grants no
completion. Locality UI and localization passed again in fresh copy
`20261002T142534Z-d70027cc`. An English ordinary Game replay uses this revised copy.
The earlier Chinese wrong-explanation screenshot is the BEFORE image, not the final
feedback. LOAD/STORE still needs scrolling for a longer five-step record; the latest
ACC/MEM values are also visible on the constructed computer.


The first English rerun passed 997 assertions but its inspected failure screenshot
showed the long status Label pushing the header/tools beyond the viewport. It is
not visual acceptance: [before](screenshots/en-feedback-overflow-before.png).
The status Label now shares available width and wraps, instead of expanding the
entire desktop horizontally. `test_bilingual_typography` now checks both long
feedback messages and navigation bounds at 1280×720 and 1600×900 in both languages.
That suite, locality UI and localization passed in `20261002T143040Z-242506bf`;
logs/results are the `feedback-*` files in `targeted/`. A final viewport rerun follows.


## Final English viewport acceptance

Fresh ordinary Game save in `VonNeumannBottleneckChecks/player-paths-20261002/en-final`,
project `20261002T143040Z-242506bf`. Final run passed **997 checks**, exit 0, no failed
assertion or script error; `proxy/proxy-final-en.txt` and the `final-en-*.json` files
retain its results. No previously completed save or injected progress was used.
This repeats construction → all five core system tasks → all seven locality tasks
after the wrapping correction. Chinese buffers/layout coverage above remains valid;
those runtime files did not change.

Inspected [English feedback after repair](screenshots/en-final-working_set-wrong-explanation.png)
shows the entire message, navigation and desktop inside 1600×900. The corresponding
[entry](screenshots/en-final-working_set-entry.png) asks the experiment question
without disclosing its result. [ALU records](screenshots/en-final-alu-experiment-evidence.png)
and [actual capstone alternatives](screenshots/en-final-capstone-cost-comparison.png)
are readable. The bilingual bounds suite separately covers 1280×720; that is automated
layout evidence, not a claim that every proxy path was replayed at both sizes.


## Final regression and handoff

Source runtime: `1dfd438`. Fresh verifier `20261002T143500Z-8429dd6a` passed import,
isolated user-directory probe and **all 43 conventional suites**. Full results and
unabridged logs are in `regression/`. Coverage includes deterministic simulation and
metrics, all chapter UI suites, bilingual catalogs/typography, baseline continuity,
workspace replay, old/future/corrupt saves, theme authority and ambience lifecycle.
The existing desktop-conventions fixture emits four anchor/size warnings; it passes.
Archived log line-end spaces are trimmed for Git hygiene; no diagnostic lines
were removed. No ERROR/FAIL was suppressed. The independent viewport runs above replace no unit
coverage and are reported separately from this headless regression.

`verify-save-restart.py` then passed **3/3 independent processes**: legacy writer,
migration reader and stable reader. `restart/` retains logs, results and stable
library digest. This synthetic compatibility fixture is distinct from the proxy's
actual UI-earned save resumes; neither uses the player's real save directory.

Commands actually used:

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot
python3 scripts/verify-save-restart.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --project .godot/verification/20261002T143500Z-8429dd6a/project
```

| Evidence class | Result / boundary |
| --- | --- |
| Automated unit/integration | 43/43; deterministic metrics, bilingual bounds and save authority included |
| Agent-authored actual viewport actions | Chinese 997+36+32; final English 997; isolated ordinary Game; selected screenshots inspected |
| Native OS actions | None added this round; viewport injection is not OS mouse input |
| Human beginner / subjective listening | Still missing; proxy knows the task and cannot validate discovery, fun or fatigue |
| Release package / Windows | Not rerun; source development only |

Local commits are authorized; no push is required or performed. The original
`project.godot` ordering change and unrelated untracked prompt/UID files are left
untouched and excluded from these commits. Final diff inspection found no changes
to task IDs, prerequisites, official cases, simulation rules or save formats.
