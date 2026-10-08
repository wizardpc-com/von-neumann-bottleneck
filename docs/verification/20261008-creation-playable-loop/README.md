# Mac creation playable loop — 2026-10-08

Local parent `bf0299f` on `codex/mac-second-act-20261005`; fetched remote baseline
`e46f866`. Applied the reviewed two-commit additive diff (preserving the locally
edited documentation index), then the handoff cumulative v2 after clean apply
checks. No branch switch, reset, stash, main merge or public release. Original
AGENTS/index/night-brief/collaboration changes remain outside this delivery.

## What can be played

Nine candidate C/P/G units remain in one continuous workbench. Integrated v2 adds
real sequential cost bars, paired codec observations, causal counts/contexts,
controlled A/B and full saved-work focus. This follow-up adds C3's single-variable
machine intervention, safe prediction continuation and stop-at-mismatch, correct
prediction-event provenance, and guards against visible invalid initial text
executing or saving an old recipe. Model, codec, save schema and completion gates
are preserved. G2's old completion mark still only proves different consecutive
outputs; the separate controlled report is stronger observational evidence.

The actual UI source has 1536 symbols, four exceptions. Default two selected samples,
order1, same model/source/cache/bus/overhead/RAM: CPU1 gives RAW235928 versus
predictive258602 cycles; CPU64 gives RAW225601 versus predictive220899. Packet bytes
remain436/430. This is a measured single-parameter reversal, not a scripted winner.
With single ABAC/order2 the smaller predictive packet369B reverses too.

The rendered route removes only ABAD while holding seed17, initialAB, length64 and
sampling fixed. A retains its D branch; B loses it and differs visibly. Both actual
works were named, chosen and saved, full B shown, recipe reproduced, forked and
host-reopened without modifying the saved work. [Chosen Chinese work](chosen-work-zh_CN.json)
and [chosen English work](chosen-work-en.json) are known-answer QA examples, not
human-player data. The recipe includes complete rules/examples/machine/version IDs.

## Run and review

Original-resource imported local Mac checkpoint:
`/Users/ray/Documents/von-neumann-bottleneck/.godot/experiments/51753e9acde6/project`.
Engine: `.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot`.
Profile: `CreationReview-20261008`, independent from production saves.

From the repository:

```sh
python3 scripts/run-experiment.py creation --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --profile CreationReview-20261008 --journey
```

This prepares a fresh imported copy of current source; the same explicit profile
resumes its own draft. Locate Compression · candidate in the journey. Omit
`--journey` to open the workbench directly. The saved QA artifacts above can be
inspected without running. No exported package or public distribution is claimed.

Team/Claude: inspect C3 A→B cost bars, P1 first committed guess→revealed mismatch,
and G2 sample removal→first difference→G3 saved full output. Rendering/copy can
improve, but never change packet truth, prediction timing, recipe provenance or
immutable saved snapshots. Ask an uninformed player what changed and why they
kept a work; no such learning/artistic result is claimed here.

## Fresh evidence

Godot `4.7.1.stable.official.a13da4feb`; original bundled Noto Sans SC and assets.
All commands use isolated copies and QA data. Logs are checked for ERROR/FAIL as
well as exits. Nineteen distinct suites passed across these runs, rather than a
repeated full regression:

- `baseline/results.json`: 13 C/P/G suites plus import/user-directory PASS.
- `iteration/results.json`: new condition/prediction/input and old closure/journey
  suites PASS; workbench geometry FAIL because an autowrapped Label in Flow made
  controls too tall. This was a real presentation regression, not a changed gate.
- `layout-final/results.json`: affected prediction/workbench suites PASS after
  moving that explanation to tooltips.
- `discovery/results.json`: new full-route suite passes standard headless discovery.
- `layout-final/playable-render-final.txt`: bilingual actual rendered viewport-input
  route, **162 checks PASS**, exit0, no script errors. Reviewed cost, mismatch,
  A/B first difference and saved-work screenshots. Minimum logical bounds are
  separately checked by workbench; Mac captures are Retina-scaled.
- `restart/results.json`: separate write/fork/read processes all PASS, unchanged
  protected outputs and reproducible recipes. Branding checker PASS.

Commands:

```sh
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_creation_condition_examples --suite test_creation_prediction_flow --suite test_creation_input_validation --suite test_creation_workbench
# Renderer uses the imported isolated project's custom QA user-directory setting:
.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --path .godot/verification/20261008T174207Z-d76ad4a2/project --script res://tests/test_creation_playable_loop.gd -- --creation-capture
python3 scripts/verify-creation-restart.py --godot /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --project .godot/verification/20261008T174207Z-d76ad4a2/project
```

`source-sha256.json` identifies the integrated domain/test/navigation source.
A replay of an already-used QA profile must choose a fresh profile, not delete
backups. Retained first `playable-render.txt` failed on English because its QA script
moved main away while leaving backups, correctly triggering read-only recovery.
Final script uses per-locale paths and succeeds. That old log is not acceptance.
Initial sandbox import failed only because macOS QA/editor settings directories
were unwritable; authorized execution fixed it. CUA initial discovery took~703s,
next native key call returned timeout; no OS mouse/keyboard walkthrough claimed.

## Remaining boundaries

No blind beginner test, emotional/artistic assessment, listening, other-Mac/Windows
native acceptance, package export or whole-project regression rerun. Core40 and old
closure/journey are covered by focused invariants; historic cloud4.6.3 logs remain
historical. No gameplay support was inserted or lowered to obtain the route. No
production save was read, migrated or erased.
