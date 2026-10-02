# Second-act depth verification

Date: 2026-10-03 Asia/Shanghai; evidence identifiers use UTC 2026-10-02.
Baseline: `637bcd9`. Godot `4.7.1.stable.official.a13da4feb` on macOS Apple M2.
All new gameplay is isolated in experiments; official five regions / 40 tasks,
prerequisites, progression, receipt/save authority and default-off audio are unchanged.

## Ownership and review

Three GPT-6.1 Sol High agents owned cache correctness, editable representation and
persistent state. A GPT-6.1 Sol Medium governance agent ran after the correctness
slot finished. Root reviewed source/diffs, independently checked algebra/costs,
operated viewport replay, integrated launch/docs and verifies the frozen commit.
Agents did not commit or push; root makes staged local commits. No push authorized
for this round.

## Audit correction

The alleged missing LRU insertion is **not present** in baseline `637bcd9`: its
touch line executes after either branch. Old QA source bytes match the committed
model and test. Do not describe the shared cache extraction as fixing that alleged
bug. [Cache audit](cache-audit.md) records hashes, 1,395 checks, clean baseline
reproduction and five deliberately broken cache variants rejected by the tests.
[Governance audit](governance-audit.md) records preserved archived bodies, valid
UID references and semantically unchanged project settings.

## Models and independent checks

- Representation target suite: 10,403 checks after layout repair. Exact coverage,
  actual directory/payload bytes, automatic finite LRU, alternate solutions,
  immutable histories, authored-spec/same-plan acceptance, bilingual UI.
- State target suite: 16,860 checks. All 864 declared configurations either match
  separately computed represented recurrence or reject capacity before events.
  Reads, dirty evictions, final flush, response ordering and error are audited.
- Root integration oracle computes recurrence in closed form and independently
  sums traffic/cycles: baseline state1496/2432B; grouped/resident1016/1152B;
  mixed plan134 scan and36 hotspot/16B. Fast link/slow decoder retains a real loss.
- State UI bounds at1280×720 are programmatic assertions, not graphical acceptance.

## Actual viewport input and iteration

`experiments/play_depth.gd` uses visible controls and injected Godot viewport
input. It is a known-objective acceptance route, **not unknown-answer, native OS
input, ordinary Game progression or human novice validation**. Unique QA save
names come from `scripts/run-experiment.py`; ordinary saves were not used.

Actions: raw baseline; split16 and chooseRLE; observe scan135/60B; observe failing
hotspots189; split48 and choose endpointRLE; pass36/16B; merge/undo/redo; one plan
serves both orders. Then state round-robin thrashing24reads/24writes; grouping4/4;
observe delayed other contexts; exact four-slot prompt service; over-capacity batch;
2-bit quality loss and measured8-bit recovery; select event evidence.

First replay `.godot/experiments/f84fb7d16b21` passed84checks but visual review
found split-address text wrapped vertically. The label now has an unwrapped80px
minimum, with Chinese/English row-height assertions≤44px. Subsequent run
`9c9ef90c0fa4` exposed intermittent injected popup-key focus failures: two intended
selector choices were not applied, causing four checks to fail. It is retained as
failed automation evidence, not attributed to simulation. A direct popup push_input attempt (`fc88911171b3`) failed, and embedded-window
mode (`fb5fc3dda92d`) remained unreliable. The final helper explicitly focuses
the visible popup, waits for focus, and retries only public UI keys (up to three
attempts); it never assigns selection or emits item_selected. English
`63a292a22001` and Chinese `4f157ed85580` passed75 checks with all menus accepting
the first attempt. Visual review then caught the fixed asset RichTextLabel blank
after navigation in the English ending; the read-only four-line asset panel is
now a normal non-scrolling Label, with all four rows verified in both languages and the final replay is recorded below. Logs and
before screenshots are retained in `intermediate/`. The smaller final check count
reflects removal of one redundant popup-visible assertion per selector, not fewer
scenario steps.

## Disposition and gaps

**INCORPORATE:** invariant/provenance tools and historical instruction archive.
**KEEP EXPERIMENTAL:** editable representation puzzles, persistent-context service
experiment and the two preserved older labs. **DEFER:** formal registration,
receipt/save migration, Prediction, full AI chapter, lore and music expansion.

No new native OS play or human beginner evidence. The earlier bounded
unknown-answer proxy is unchanged and was not rerun as new cognitive evidence.
The state lab remains a parameter experiment; numerical quality covers these24
requests only. Representation has one authored asset, offline encoding and
synchronous teaching costs; controller/accessibility and spontaneous strategy
formation remain unverified. See [framework](../../design/second-act-framework.md)
and [launch commands](../../../experiments/README.md).

## Final viewport evidence

English `c918f8f20ff7` and Chinese `6b86ec7858ad`: **75 checks each, PASS**, at
1600×900. Every menu accepted the first attempt. Screens were visually inspected
for readable asset rows, controls, results and event details. macOS logged
`IMKCFRunLoopWakeUpReliable` once per launch; no Godot script error occurred.
[Source identity](viewport/source-identity.json) compares each replay's actual
GDScript, scenes, resources, Python and project settings against `52f1a79` with
zero mismatches (only two save-isolation lines normalized). This supplements the
full committed-source regression and does not assert screenshot files came from
native mouse input.

- [Chinese observations](viewport/zh_CN-checks.json) / [step metrics](viewport/zh_CN-depth-steps.json)
- [English observations](viewport/en-checks.json) / [step metrics](viewport/en-depth-steps.json)
- [Chinese paired plan](screenshots/zh_CN-plan-paired-final.png)
- [English paired plan](screenshots/en-plan-paired-final.png)
- [Locality delays other streams](screenshots/zh_CN-state-grouped-latency.png)
- [Exact resident solution](screenshots/en-state-resident-exact.png)
- [Actual low-precision loss](screenshots/en-state-low-precision-loss.png)
- [Inspect a numerical state update](screenshots/en-state-event-inspection.png)

The receiver's2 Python tests and all3 playtest-report calibration groups also
passed. No new live feedback submission or exported-package acceptance is claimed.

## Final committed full regression

Frozen implementation **`52f1a79`** was tested from a clean detached local clone:
`.godot/committed-verification/20261002T162737Z-6021b7d4`.
**49 conventional suites plus import and isolated-user checks passed**. All
1370 tracked files were compared to the actual test copy; zero mismatches,
clean checkout before and after. Only the two save-isolation settings are normalized.
[Receipt](regression/receipt.json), [full source manifest](regression/source-manifest.json),
[all results](regression/results.json), [summary log](regression/verification.txt)
and every full suite log are retained in `regression/`.

Logs contain four existing anchor-size warnings in `test_desktop_conventions`;
no script errors/failures. The earlier full pass on `969c540` remains separately in
`regression-preliminary/`; it precedes the final plain-label repair and is not the
final acceptance source. The final documentation/evidence commit follows the
frozen implementation; it does not change executable files. No export, native OS
or human acceptance is implied by the conventional regression.

## Local stage commits

- `7e2cebc`: cache provenance, invariants and committed-source verifier.
- `cc90828`: historical archive and UID/settings audit.
- `7ae54b0`: editable mixed-representation puzzles.
- `969c540`: persistent-state workload and independent integration oracle.
- `52f1a79`: launch/replay integration, UI stabilization and updated framework.
- Final evidence/plan completion is a subsequent documentation-only commit.

No push was performed. Next priority: human unfamiliar-player trials of boundary
construction and locality/response tradeoffs before new assets or formal registration.
