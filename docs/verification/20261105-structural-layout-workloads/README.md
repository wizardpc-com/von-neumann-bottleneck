# Structural workloads and retained history — Round7

Base `e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8` on
`codex/gameplay-systems-20261104`. Root integrated three disjoint implementation
lines and independent reviews. This increment is local experimental gameplay;
it does not add campaign tasks, change awards, publish a release or adopt online
scores. The user authorized significant verified commits/pushes to this branch.

## Playable result

The scheduling lab now has six fixed conditions. Two new serial workloads give
players different decisions using unchanged operations and costs:

- **Two temperature scans:** direct307/614/544/0 versus copied557/672/500/80.
  With Q1≤600/copy≤80, direct wins cycles and copy wins RAM by44B.
- **Temperature then alarm:** record-major two-field copy791/2044/1560/144
  versus field-major727/1516/1032/144. The latter answers Q1 sooner and spends
  less total time and traffic at the same allocation.

Numbers above are Q1/total cycles/RAM bytes/allocated copy bytes. They come from
actual simulation, not target metadata. Each condition has independent drafts,
goals, history, named plans and replayable challenges. One contextual starter
previews the current condition; pair binds traffic600/80, phased cycles800/144.
The original two starter codes and four conditions remain exact.

Valid retained unfinished drafts remain visible and reject truthfully when
invalid for a condition. The player can explicitly repair and undo them;
rendering no longer silently presents a clamped grouping as the original value.
No additional simulation rule or fake cost was introduced.

The standard prepared playable copy is
`.godot/experiments/03ed0345d47c/project`. The executable launcher is
`.godot/structural-layout-preview-20261105.command`, using dedicated profile
`VonNeumannBottleneckChecks/layout_strategy/codex-round7-preview-20261105`.
No test recipes were injected into that profile. From another checkout:

```sh
python3 scripts/run-experiment.py layout_strategy \
  --godot /path/to/Godot-4.7.1 --profile my-notebook
```

## Compatibility and rollback

`layout_strategy_notebook_v2.json` remains bounded to128KiB and8 named recipes
per each of six conditions; `layout_strategy_challenges_v2.json` is an independent
32KiB file with up to six targets. Both store inputs only. Strict v1 decoders
freeze the original four IDs and never rewrite either v1 payload.

Each sidecar independently prefers existing v2, including an empty target map.
Protected v2 does not fall back. Only missing v2 reads valid v1 into detached
memory and marks an explicit pending copy. Reads create neither payload nor
lease; protected v1 adopts no partial inputs. Explicit normal save/accept/clear/
retry creates v2, even for unchanged or empty legacy inputs.

Until first commit, both source and destination signatures are watched,
including a missing legacy source. First-copy writes acquire the legacy lease
then current lease, recheck ownership and bytes, and release all owned leases
on every outcome. Recovery addresses the exact blocked writer and does not save.
Subsequent v2 writes ignore v1. Old-runtime rollback reads the preserved v1;
later upgrading resumes v2. Edits made on each side are independent histories.
This is cooperative local protection, not arbitrary-writer CAS or power-loss
durability.

## Fresh verification

Godot `4.7.1.stable.official.a13da4feb`, executable
`/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot`.
Final QA: `.godot/verification/20261105T051242Z-1f038f6c/project`.
All test profiles are under `VonNeumannBottleneckChecks/...`.

Twenty-one distinct related headless suites have passing latest staged
observations. This is focused staged coverage, not a final whole-repository run:

| Suite | Latest passing evidence |
| --- | --- |
| Strategy model |3449 checks,223 measurements|
| New structures |1247 checks,88 measurements|
| Strategy challenge code |516 checks|
| Frozen scheduling catalog |680 checks,56 measurements,112 exact code outcomes|
| Notebook store / target store |414 /292 checks|
| Store upgrade |410 checks|
| Workspace / challenge controller |52 /65 checks|
| Controller upgrade |56 checks|
| Goals / Session |75 /72 checks|
| Formal legacy parity |3810 checks,141 designs,282 cases|
| Formal challenge code / store |288 /166 checks|
| Original UI / Notebook UI / challenge UI |218 /159 /250 checks|
| New structures UI |302 checks|
| GlobalSave / localization |Both suites pass|

Initial import/profile and baseline tests are in `logs/baseline/`.
Integrated batches are `logs/headless/20261105T060756Z`,
`20261105T061037Z` and `20261105T061249Z`. Their result manifests retain exact
commands, profiles, exits and all initial failures.

GPU batch `logs/gpu/20261105T061535Z` passes structures346, original246,
Notebook177 and challenge282 checks, all0 failures, on Apple M2 OpenGL.
Forty-two raw frames cover both locales,1280×720/960×640 root views and
720×540 minimum popups; ordinary popup captures are820×580. Suffixes describe
the root scenario, not necessarily popup size. `frame-sha256.json` records
actual dimensions and hashes. Root inspected seven new Chinese originals;
independent reviewers inspected fourteen original Chinese and all21 English
frames. No actionable visual issue remained.

`process/20261105T061409Z` contains twelve normal exit0 phases and two deliberately
SIGKILLed owned lease holders. The frozen old runtime was byte-checked against
e1e27db before use. Actual old-target source and new-Notebook destination
contention refused live recovery; explicit stopped-owner recovery itself wrote
nothing. Changed proposals then committed and reopened with exact inputs,
kept metrics and full Trace identities. The old runtime read unchanged v1,
edited and reopened its own history, and new v2 subsequently remained unchanged
and authoritative. Both sidecars and a separate empty profile were checked.
Formal progression stayed unchanged in each phase. These are the two named
process/store combinations; unit suites cover broader path combinations.

[Strategy research](strategy/README.md) executes442 declared candidates plus
10 repeat/JSON replays,7100 checks,0 failures in4348.020ms. The finite frontier
has two metric classes for pair and three for phased. No global-optimality claim.

## Initial failures and review repairs

- Baseline producer initially assigned an untyped conditional array to
  `Array[int]`; root stopped its owned process, corrected the fixture and
  captured the unchanged old runtime successfully. Both logs remain.
- Store-upgrade fixture initially compared parsed integral floats with canonical
  integer JSON. Five assertions failed. Semantic comparison and normalization
  repaired the fixture while exact old/new canonical-byte assertions remained.
- New UI fixture initially spelled an empty legacy map in unsorted JSON.
  Storage correctly protected it; eight UI assertions failed. The valid fixture
  now uses canonical JSON, retaining the same empty-copy and byte checks.
- Independent review caught missing writer parent creation in the process
  holder before its first execution. The fixture now creates only that isolated
  parent, preserving the missing-payload first-copy condition.

No production simulation/storage rule was weakened to satisfy these tests.
Implementation, controller, storage, UI, process and raw-frame review reports
are archived in `reviews/`.

## Acceptance boundary and delivery

[Fresh native observation](native/README.md) is NOT_RUN: Mac was locked and
CUA could not unlock it. No click/key was sent; owned process cleanup exited−15.
No previous native result is inherited. Exported builds, other platforms,
newcomers, long-session/audio behavior and online server replay remain unverified.

`source-sha256.json` binds1218 source/test/support files byte-for-byte across
checkout, QA and playable copy. Only the experimental README was synchronized
after the GPU run; runtime code did not change. All six new script UIDs came
from actual import. Project settings differ only by isolated user-directory
entries, plus the experimental main scene in the playable copy.
Ordinary playable startup with `--headless --quit-after 8` exits0 without
diagnostics; launcher `zsh -n` also exits0. See [startup.json](startup.json)
and its unedited raw log.

[Final static checks](static-checks.json) recheck all1218 source bindings,
the project-setting differences and all42 frame dimensions/hashes. All three
complete import logs contain no error/warning diagnostics. The latest21 headless
and four GPU result/log observations pass; the original failed fixtures remain
separate. Tracked authored `git diff --check` passes. All47 raw `.log` files
(26377 bytes) are visible to Git. Four retain a final empty line exactly as
emitted: startup, native startup and the two interrupted holders; these are
recorded raw-evidence whitespace exceptions.

The [independent static review](reviews/static-links-review.md) checked all291
local references in24 then-current Markdown files,82 authored/support/data text
files and53 raw `.log`/`.txt` outputs, with no actionable defect. Its exact
timestamped scope excludes reports archived afterward; root checks final
additions before staging.

The [independent final evidence review](reviews/evidence-review.md) found no
remaining substantive mismatch. It additionally checked all281 old-runtime
files against the base Git objects and independently recomputed the finite
strategy maps, frontiers and goal winners. All implementation/review ownership
is released to root.

Main and ordinary player data remain protected. The reviewable
milestone is committed and pushed only after final evidence/diff checks;
the local push receipt independently records the resulting task SHA and main.
