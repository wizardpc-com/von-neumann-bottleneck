# Retained scheduling notebook — 2026-11-04 local

The fifth bounded increment on `codex/gameplay-systems-20261104` turns the
independent scheduling lab into a resumable exploration loop: measure a recipe,
keep it with a name, choose response/space requirements, compare measured plans,
restore one for editing, save and reopen the workspace. Base commit:
`3182a469fc3c222854f6976d8f251b6489f7030c`. The prior four rounds remain intact.
The user authorized significant commits/pushes to this task branch, not main or
a release. This receipt is source/QA evidence, not a new distributed package.

## Play the increment

On the current Mac, open the executable local launcher:

```text
/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/layout-notebook-preview-20261104.command
```

It starts the actual runner-prepared copy
`.godot/experiments/0c8288dacf9e/project`, synchronized to the verified source,
with normal lab startup and no test/capture flags. It uses the stable isolated
profile `VonNeumannBottleneckChecks/layout_strategy/codex-round5-preview-20261104`.
No test recipe or score was inserted into this playable profile.

From another checkout, with Godot4.7.1 stable:

```sh
python3 scripts/run-experiment.py layout_strategy \
  --godot /path/to/Godot --profile my-notebook
```

Use the same profile name next time. An unnamed invocation still creates a
separate fresh profile. Choose a workload, run a draft, and use **方案笔记 /
Notebook** to keep the selected measured recipe and set optional inclusive Q1
and copy-space caps. Rank by total cycles or RAM bytes. Selecting a kept plan
remeasures it without replacing the draft; **载入改进 / Continue improving** is an
explicit undoable edit. Save workspace explicitly before leaving. Keeping or
removing a named plan also saves the whole current workspace.

## Implemented contract

- Four existing workloads and `layout-schedule-experiment-1` are unchanged.
  Q1 remains public job0 completion. No score weights, simulator penalties,
  new workload generator, campaign registration or award changes.
- At most8 named plans per workload, four workloads and128KiB canonical notebook.
  Store task/model/condition, exact drafts including dormant choices, goals,
  names/recipes and active workload. Do not persist authoritative metrics/Trace.
  Reopened/viewed kept plans are calculated again in the current process.
- Optional limits are inclusive;0 is a real cap and unlimited is separate.
  Wrong-condition, invalid, incomplete or over-limit measurements cannot rank.
  Objective ties share competition rank1,1,3 without a hidden secondary score.
  Rankings describe the displayed recent or kept set, not a global optimum.
- Saving has separate proposed/committed state. Failure leaves proposed work in
  memory for explicit retry, preserves previous file bytes and does not claim
  success. Missing-file defaults are distinguished from a saved workspace.
- Entire-file validation protects unknown, stale, malformed and invalid UTF-8
  data. A dedicated cooperative writer lease, unique temporary file,
  flush/reopen/validation, digest recheck and atomic rename protect writes.
  Explicit recovery reclaims only a demonstrably stopped owner.
- The notebook is a new isolated sidecar, not a formal-save migration.
  Rollback can ignore the sidecar without deleting it. Old60 tasks,
  `layout-memory-1`, VNB4C1 challenges and valid achievements keep their meaning.
  Recent24 runs, Undo64 and comparison baselines remain process-only.

See [rules and operation](../../../experiments/layout_strategy/README.md),
[completed plan](../../exec-plans/completed/layout-notebook-20261104.md) and
[design audit](../../development/GAMEPLAY_AUDIT_20261104.md).

## Fresh execution

Engine: `/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot`,
`4.7.1.stable.official.a13da4feb`; GPU Apple M2 OpenGL.
QA copy: `.godot/verification/20261105T021829Z-18f99d78/project`.
All processes used isolated `VonNeumannBottleneckChecks/...` directories.

The standard verifier imported a fresh copy, checked the user directory and ran
the initial model/session baseline. Root subsequently synchronized the released
sources and ran related suites sequentially with a fresh profile for each suite.
All commands, exits, profiles and complete logs are in [logs](logs/).
The archived `run-round5-checks.py` records the orchestration used at
`.godot/collaboration/`; it is not a new public launcher.

**12 distinct related headless suites have passing latest staged observations.**
This is not one final full-repository regression. Import/profile checks are
additional setup checks, not included in12.

| Suite | Latest checks/result | Batch under logs/headless |
| --- | ---: | --- |
| strategy goals | 75 /0 failures | 20261105T024509Z |
| strategy session | 72 /0 | 20261105T024509Z |
| notebook store | 414 /0 | 20261105T024509Z |
| strategy model | 2669 checks,171 measured runs /0 | 20261105T024509Z |
| workspace | 51 /0 | 20261105T024724Z |
| legacy parity | 3810 checks,141 designs,282 cases /0 | 20261105T024724Z |
| formal challenge codec | 288 /pass | 20261105T024724Z |
| formal challenge store | 166 /pass | 20261105T024724Z |
| GlobalSave | pass | 20261105T024724Z |
| localization | pass | 20261105T024724Z |
| original strategy UI | 216 /0 | 20261105T030001Z |
| notebook UI | 159 /0 | 20261105T030001Z |

Final GPU checks at `logs/gpu/20261105T030026Z`: original UI244/0,
notebook UI177/0. They exercise actual model measurements, kept-plan selection
versus draft restore, goal caps/ranking, name TextEdit Undo, saved/dirty status,
write-failure retry, exit guards, locales and modal focus.18 raw final frames
have actual1280×720 or960×640 image-size assertions and checked PNG saves.
Root visually inspected all9 final Chinese frames; an independent reviewer
inspected all9 final English frames. [Frame manifest](frame-sha256.json).

The actual runner prepared the playable copy successfully; the final updated
copy then completed ordinary `--headless --quit-after 8` startup with exit0 and
no diagnostics. The executable launcher passed `zsh -n`.
[Startup result](logs/startup-results.json), [raw log](logs/startup-smoke.log),
[prepare log](logs/round5-prepare-preview.log), [import](logs/preview-import.txt).
The separate Python runner-routing test passed4 checks using mocked engine
execution; it is not itself runtime acceptance. [Log](logs/runner-tests.log).

## Real restart and writer recovery

The [process receipt](process/results.json) and complete logs cover seed, reopen,
a concurrently held writer, rejected competing write, explicit recovery after
the owned writer was deliberately stopped, another reopen and a separate empty
profile. Six normal phases exited0. The held writer's identity-checked PID90743
was deliberately SIGKILLed and exited-9; this is a crash scenario, not graceful
exit acceptance.

Recovery changes the saved serial Q1 cap557→558, asserts changed notebook bytes
and only the intended input change, then writes. The next fresh process restores
the exact new snapshot and reproduces retained metrics and complete Trace hashes.
The separate `-other` profile stays empty; no official completion changes.
The orchestration restored QA project settings byte-for-byte.
This covers same-host cooperative contention and stopped-owner recovery, not
arbitrary external-writer synchronization or power-loss durability.

## Strategy findings

The unchanged production model was evaluated by two fresh bounded probes:
root's1292-candidate goal-envelope probe and an independent2046-candidate probe.
The latter includes1995 shipped combinations,40 expected allocation failures,
51 unshipped structural probes,56 repeat/JSON executions and16 value-change
pairs, for2134 total evaluations. It reported no assertion failures.

With copying forbidden, scan Q1 caps350/400/450/600 select sampled groups2/3/4/8,
with total cycles1368/1096/824/552 respectively. A tighter response requirement
therefore changes which measured plan qualifies. In serial scan, direct is
307 Q1 /2456 total /2176 RAM B /0 copy B; retained temperature is
557 /1362 /980 /80. Values-only changes did not change performance in the16
tested pairs, so they do not support a meaningful randomized challenge alone.
All sampled winners/frontiers are finite observations, not global optima.
[Full scope, raw data and probe](strategy/README.md).

## Review, corrections and evidence binding

The original failed fixtures and first GPU frames are retained:

1. The first Workspace conflict fixture restored identical old bytes before
   expecting a stale-reader failure. It now commits a genuinely different goal;
   the corrected51 checks pass.
2. The first notebook UI fixture compared parsed JSON arrays/numbers with typed
   normalized recipes. It now normalizes through the model before comparison;
   the later159 checks preserve the behavioral assertion.
3. Independent review found recovery had only tested an unchanged save.
   The real changed-write/reopen sequence above closes that evidence gap.
4. The final UI distinguishes a different selected run from an unmeasured draft,
   and the recent-run table names its actual total/RAM ranking objective.

[Reviews](reviews/) retain the original findings and their final closure.
[Final source review](reviews/source-final.md) found no remaining actionable
defect; [final English frames](reviews/final-frame-review.md) confirm the wording
and minimum-size layout. The initial18 images remain in
`frames-before-wording/`, separate from final `frames/`.
The [independent evidence review](reviews/evidence-final.md) confirmed the
logs/manifests and identified premature delivery wording in the completed plan.
That header now separates completed runtime acceptance from actual Git delivery.
No source change or engine rerun was required.

[Source manifest](source-sha256.json) binds1187 current source/test/support files
to both QA and playable copies byte-for-byte. QA project settings differ only
by two isolated-user-directory entries; playable settings also select the
experiment main scene. Only the experiment README was resynchronized into QA
after the final tests; no runtime change followed them. All8 new GDScript UIDs
were copied from the actual imported QA project, not synthesized.
[Final static checks](static-checks.json) cover authored whitespace, local
Markdown links, raw-log inclusion and every source/frame hash. Raw engine text
is preserved verbatim. The complete staged whitespace check has exactly two
`new blank line at EOF` diagnostics, both at line2 of the unchanged raw
`logs/startup-smoke.log` and `process/hold.log`. Authored files pass; these
documented raw-log exceptions are not removed from the evidence.

## Acceptance boundaries

A fresh CUA attempt found the Mac locked and automatic unlock failed. No native
click/key was sent: **Round5 native input is NOT_RUN**. Earlier Round4 native
observations do not verify this notebook. [Exact blocker](native/README.md).

New exports, other platforms, newcomer understanding, long-session use and audio
remain unverified. Numeric editors retain the existing Cmd/Ctrl+Enter friction
noted by the playloop audit. Experimental sharing and online verified rankings
are not implemented; local remeasurement is not server-side anti-cheat.
