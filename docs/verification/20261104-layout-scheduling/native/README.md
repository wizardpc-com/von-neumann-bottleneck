# Mac native observation — 2026-11-04 local / November 5 UTC

Root used CUA against the ordinary experimental main scene in the copied QA
project. Inputs below were native mouse/keyboard actions, not a model fixture or
viewport replay. This is a bounded interaction observation, not newcomer,
minimum-window, exported-package or full-session acceptance. Screenshots were
observed in the CUA conversation; the committed `captures/` images are the
separate scripted GPU frames.

## First process: gameplay observed, capture-flag setup limitation

[Invocation and exit](20261105T011727Z/invocation.json) ·
[Actual settings](20261105T011727Z/project-settings.godot) ·
[Runtime log](20261105T011727Z/session.log).

The profile was `VonNeumannBottleneckChecks/20261104-round4/native/20261105T011727Z`.
The ordinary main scene launched without a test script, but the command
mistakenly included `--capture-size=1280x720`. The actual native view was
fullscreen; the requested capture size is not an accepted native geometry.

Observed through CUA:

1. Return ran the fresh source-only plan: Q1 **307**, total **2456**, RAM **2176 B**,
   copy **0 B**, correct.
2. Native pointer click pinned run1 as comparison; the row gained its marker.
3. Native number editing changed queries/group to8 and records/tile to1.
   Run measured Q1 **531**, total **552**, RAM **272 B**, copy **0 B**.
   The actual comparison displayed `+224` Q1, `-1904` total and RAM, and tradeoff.
4. Clicking run1 then Restore changed the draft back to1/17.
   Cmd-Z returned it to8/1 without adding a third measurement.
5. The ordinary language button changed the workbench to English and preserved
   both measured rows, the baseline and the restored draft.
6. Exit opened its session-loss guard. F10 opened Settings above it. After an
   actual settings-language change, closing Settings left the translated guard
   visible with Keep exploring focused. A final Tab/Return exited this QA process,
   exit0.

The settings-language operation also displayed the existing GlobalSave
“Writing is disabled for this save” dialog. The captured command explains this
setup problem: `_ready()` classifies `--capture*` user arguments as automated
and disables campaign writes, whereas later save-error presentation checks only
engine arguments. No campaign rule or save protection was weakened to hide it.
This process is **not** evidence of a warning-free normal Settings route.

## Second process: ordinary startup, native dropdown route unfinished

[Invocation and exit](20261105T012813Z/invocation.json) ·
[Actual settings](20261105T012813Z/project-settings.godot) ·
[Runtime log](20261105T012813Z/session.log).

This fresh profile launched without `--script`, `--capture*`, injected events or
fixture data. The actual lab, default run, exit guard and F10 Settings were
observed. Opening the language selector worked, but subsequent CUA pointer
actions returned `Computer Use server error -10005: noWindowsAvailable`.
Retried native key actions did not establish a selection change. Therefore the
normal-mode nested language route remains **NOT VERIFIED** by native input.
The corresponding scripted viewport/GPU regression passed independently.

Root stopped only the owned QA process (PID48583) with SIGTERM after the tool
route failed; exit-15 is an intentional stop, not a graceful-exit pass. Both
process helpers restored the copied project settings byte-for-byte. No ordinary
player directory was read or written. The first process's successful exit and
the later ordinary startup smoke must not be merged into a claim that this
second native sequence completed.
