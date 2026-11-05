# Replayable scheduling challenges — 2026-11-04 local

The sixth bounded increment on `codex/gameplay-systems-20261104` adds an offline
challenge loop to the existing scheduling notebook: share a measured plan with
fixed conditions, remeasure and accept a target, improve a draft, then compare
and reply under those same conditions. Numeric editors now commit their visible
value before Command/Ctrl+Enter runs once. Base:
`e07b4bbba845a1046835884ecf06916930fa8b8a`. The prior five rounds remain intact.
This is source/QA evidence, not a new distributed release.

## Play the increment

The executable local launcher is:

```text
/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/layout-replay-challenges-preview-20261104.command
```

It opens the actual runner-prepared copy
`.godot/experiments/5cba0387cdfb/project`, using
`VonNeumannBottleneckChecks/layout_strategy/codex-round6-preview-20261104`.
The normal startup has no test/capture driver. No solution, score or target was
injected into this playable profile. Previous preview copies remain separate.
From another checkout:

```sh
python3 scripts/run-experiment.py layout_strategy \
  --godot /path/to/Godot --profile my-challenges
```

Choose **比较 / Compare → 挑战… / Challenges…**. Run a plan to share the selected
measurement, or explicitly try one of the two starters. Previewing and accepting
a target keep the draft, Undo, selected evidence, personal goal and Notebook.
Edit and run your own attempt; the target's objective and limits stay fixed.
**按挑战条件应战 / Share attempt with target goal** exports the current measured
attempt under the original rule. **恢复目标方案 / Restore target** is an explicit
edit recoverable with one Undo. Targets and Notebook save separately.

## Behavior and compatibility

- New `VNBSC1:` transport is bounded to4096 UTF-8 bytes including clipboard
  whitespace. Its exact canonical envelope is `v/task/model/condition/goal/plan`.
  It carries no scores, Trace, timestamps, external identity or executable data.
- Inspection requires the current full condition, complete correct execution
  and inclusive goal eligibility. The selected attempt is also remeasured and
  checked against its complete canonical Trace identity. Supplied metric numbers
  cannot become challenge authority.
- Goals choose total cycles or RAM traffic, with optional inclusive Q1/copy caps.
  Personal filters/sorting cannot weaken the accepted target. Outcomes distinguish
  unavailable, outside limits, behind, tied and improved.
- One target per existing workload, maximum4, in the independent protected
  `layout_strategy_challenges_v1.json`, maximum32KiB. Notebook v1 is unchanged.
  Exact proposed replacement/removal survives failure; retry saves that proposal.
  Full-file validation, external-change protection, a dedicated cooperative
  writer lease, validated temporary file and atomic replacement guard writes.
  Recovery of a stopped writer is explicit and separate from retry.
- Supported old model/condition codes remain copyable but inactive. Protected
  files are not overwritten; temporary target status does not hide protection.
  Detected external conflicts withdraw cached “saved” assurance.
- Four known numeric editors commit before Command/Ctrl+Enter, including keypad Enter;
  ordinary Enter remains editing. Mouse Run also commits pending numeric text.
  Other text fields, settings and modal surfaces retain their own input.
- The four workloads, experiment model/costs, official60 tasks, original layout
  model, `VNB4C1`, prior achievements and ordinary player data retain their meaning.
  Rollback can ignore the new sidecar without deleting it. This does not provide
  online ranking or protection against a modified client.

See the [runtime contract](../../../experiments/layout_strategy/README.md),
[completed implementation plan](../../exec-plans/completed/layout-replay-challenges-20261104.md)
and [design audit](../../development/GAMEPLAY_AUDIT_20261104.md).

## Fresh execution

Engine: `4.7.1.stable.official.a13da4feb`, Apple M2 OpenGL.
QA: `.godot/verification/20261105T033350Z-75462610/project`.
Every run uses an isolated `VonNeumannBottleneckChecks/...` profile.
[Logs](logs/) retain complete initial, failed, corrected and final observations.
The archived runner records exact commands, profiles and exits; it is not a new
public launcher.

**16 distinct related headless suites have passing latest staged observations.**
These are staged targeted checks, not one final full-repository regression.
Import/profile checks are additional setup gates.

| Suite | Latest result | Batch under logs/headless |
| --- | ---: | --- |
| scheduling challenge codec |397 checks /0 failures|20261105T040136Z|
| scheduling challenge store |288 /0|20261105T040604Z|
| scheduling challenge controller |65 /0|20261105T041349Z|
| scheduling challenge UI |250 /0|20261105T042615Z|
| scheduling model |2669 checks,171 measured runs /0|20261105T040136Z|
| frozen official Trace parity |3810 checks,141 designs,282 cases /0|20261105T040136Z|
| goals |75 /0|20261105T040136Z|
| session |72 /0|20261105T040136Z|
| workspace |51 /0|20261105T040136Z|
| Notebook store |414 /0|20261105T040136Z|
| formal challenge codec |288 /pass|20261105T040136Z|
| formal challenge store |166 /pass|20261105T040136Z|
| GlobalSave |pass|20261105T040136Z|
| localization |pass|20261105T040136Z|
| original scheduling UI |216 /0|20261105T042738Z|
| Notebook UI |159 /0|20261105T042738Z|

Final GPU challenge UI: **282/0**, exit0 at`20261105T043615Z`.
Original UI **244/0** and Notebook **177/0**, exit0 at`20261105T042825Z`.
The later challenge changes were two share captures and three text/selection
color overrides; no model/controller/store change followed their cited checks.
Actual clipboard checks, F8/F10, locale focus, code Undo, immutable goals,
protected-file feedback and pending-write exit guards run in these fixtures.

28 final raw frames are bound by [the frame manifest](frame-sha256.json).
Root visually inspected14 Chinese frames; an independent reviewer inspected14
English frames. Main viewports are1280×720/960×640. Secondary windows are820×580;
the minimum import window is720×540. Filename suffixes describe the parent
viewport, not necessarily the popup dimensions.18 earlier popup frames remain
in`frames-history/`. [Independent frame review](reviews/frame-review.md).

The prepared playable copy imported successfully and ordinary
`--headless --quit-after 8` startup exited0 without errors. The executable launcher
passed`zsh -n`. [Startup result](logs/startup-results.json),
[raw log](logs/startup-smoke.log), [prepare log](logs/round6-prepare-preview.log)
and [preview import](logs/preview-import.txt).

## Native play and actual process recovery

A later fresh CUA attempt succeeded after earlier lock-screen failures.
The ordinary Chinese QA scene was operated through native mouse/keyboard:
Run → Challenges → starter preview → accept → numeric Command+Enter edits →
actual improvement → reply under the target goal → Save and exit.
The gameplay process exited0; actual saved inputs retain the original350/0
target and the improved group2/tile1 notebook draft separately.
[Exact observations, limits and saved files](native/README.md).
Native English/settings/feedback/clipboard/keypad/reopen were not exercised.

Separately, the [real process matrix](process/results.json) covers seed, reopen,
live target-writer contention, controlled owned-writer SIGKILL, explicit recovery,
changed write, second reopen and a separate empty profile. Six normal processes
exit0. The identity-checked held writer PID27900 deliberately exits−9; this is
not graceful-exit acceptance.

While the target lease is held, a competing target save is refused and a
genuinely changed Notebook save succeeds independently. Recovery changes serial
Q1 cap600→601 and actual file bytes. The next process reconstructs the exact
new code/identity/metrics/full Trace. Another profile inherits neither file.
QA settings are restored byte-for-byte. This establishes cooperative local
contention/recovery, not arbitrary-writer CAS or power-loss durability.

## Actual strategy and research

For all-ready temperature scans, the starter requires Q1≤350 and copy≤0.
Direct source measures **307 Q1 /2456 total /2176 RAM B /0 copy B**.
Group2/tile1 measures **339/1368/1088/0**: a real1088-cycle improvement within
the same conditions. The serial starter allows Q1≤600/copy≤80; retained
temperature measures **557/1362/980/80**. Starters are opt-in ordinary targets;
known beating inputs are test fixtures, not default player solutions.

Fresh structural research ran1475 candidates plus48 repeat/JSON complete Traces,
with0 failures in24.229s. A separate1140-evaluation physical-copy probe reported
0 failures in18.944s. Two serial full scans produce competing observed recipes:
direct307/614/544/0 and copied557/672/500/80. Under Q1≤600/copy≤80, changing total
versus traffic objective selects different sample winners. Split temperature/
alarm requests also change the useful physical layout.

Those structures remain probe-only. They must gain independent condition
identity and Notebook/challenge compatibility before shipping. The broader
physical sample found no new combined frontier tuple; extra controls are
deferred. These finite samples prove neither global optimality nor lasting
player enjoyment. [Full scope, raw results and probes](strategy/README.md).

## Review and binding

Independent source reviews and actual observations led to bounded repairs:

1. After a detected external change/deletion, old cached codes remain copyable
   but no longer claim to be saved; controller65/0 includes real file changes.
2. Protected target state remains visible alongside pending proposals, with no
   futile Retry advice; exit retry focus survives locale rebuild.
3. The actual shared-code frame exposed low-contrast selected read-only text.
   Explicit colors now match the existing formal challenge surface. Both
   original and corrected frames are retained.

Initial test failures are preserved. Store fixtures inserted new StringName keys
through dot syntax; explicit String keys fixed the fixtures without weakening
the schema. Numeric fixtures needed to wait for SpinBox's deferred focus refresh.
Synthetic child-Window mouse events reached GUI input but did not activate
buttons, so popup tests now focus and send actual Enter events. They do not emit
button signals for normal success paths. Later native mouse activation separately
succeeded. [Source and implementation reviews](reviews/).

[Source manifest](source-sha256.json) binds1205 source/test/support files to both
final QA and playable copies byte-for-byte. QA settings differ only by two
isolation entries; the playable copy also selects the experiment main scene.
All9 new GDScript UIDs came from actual QA import. No runtime source changed
after final GPU/native acceptance. [Static checks](static-checks.json) record
authored whitespace, local links, raw-log inclusion and source/frame hashes.
[Final independent evidence review](reviews/evidence-review.md) also checked
the staged scope and all49 raw logs. Its recorded snapshot precedes archival
of that review and the separate Git delivery checks.

The user authorized significant verified task-branch commits/pushes. Git delivery
is checked separately from runtime acceptance; main remains outside this scope.
Exports, other platforms, newcomers, long-session/audio, online trust and formal
adoption remain unverified. Existing disputed Opus designs remain on the audit
list without an automatic rollback.
