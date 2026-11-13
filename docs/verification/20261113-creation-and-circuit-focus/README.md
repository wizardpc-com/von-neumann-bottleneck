# Creation continuation and circuit framing — 2026-11-13

Base main `dd24ee55a3c2b535ae52c2f96e87941d8993d9de`. This block repairs three
observable interaction obstacles without changing simulation, task gates, stored
formats, dependencies or final visual direction.

## Behavior

- A minimized instrument dragged to the bottom no longer makes Focus frame the
  circuit below the canvas. Framing chooses a usable side within the current
  view, retaining player window geometry, circuit topology, history and evidence.
- G3 Edit this work / Fork returns the main guide to generation and then Keep.
  Historical completion no longer overrides the explicit new draft. Reopening
  an untouched new fork or changed recipe retains that draft; ordinary saved
  work still opens its protected snapshot and existing closing action.
- G2 Keep with an empty name reveals and focuses the name field inside its real
  scroll viewport. Typing can start immediately without searching or scrolling.

## Verification

Engine: Godot `4.7.1.stable.official.a13da4feb`, Apple M2 / OpenGL Compatibility.
QA copies use isolated `VonNeumannBottleneckChecks` profiles; ordinary player data
is untouched. Candidate `.godot/verification/20261113T175149Z-73394026/project`;
frozen old code `.godot/verification/20261113T174105Z-5d8c7863/project`.

| Check | Result | Evidence |
| --- | --- | --- |
| Candidate import / profile isolation | Pass | `logs/candidate-initial` |
| 16 affected candidate suites | All pass | `logs/candidate-initial` |
| Final Focus, including two minimized titles | 196 checks, 0 failures | `logs/final-headless` |
| Final Creation continuation | 114 checks, 0 failures | `logs/final-headless` |
| Future workbench / RAW readonly / evidence identity | 79 / 11 / 26 checks, all pass | `logs/final-headless` |
| Same final behavioral tests on old code | Focus 196 / 32 expected failures; Creation 114 / 16 expected failures | `logs/final-negative` |
| Focus GPU | 204 checks, 0 failures; 4 frames | `logs/gpu-initial` |
| Final Creation GPU, size stable before input | 129 checks, 0 failures; 6 frames | `logs/creation-gpu-final` |

There are 19 distinct affected suites with passing staged headless evidence,
not a full-repository regression. The original 16 comprise the two new tests,
Creation workbench/choice completion/pending learning/navigation/save input/work
focus/profile navigation/draft undo/lab return, and hardware foundations UI,
prologue UI/workspace entry/history context/drag Escape. Runtime source remained
unchanged during final verification; later changes only extended the Focus test,
corrected the Creation result label and stabilized actual screenshot dimensions.

The negative checks report repeated assertions across locales and window sizes,
not 48 independent defects. They have no parse/runtime script failure. Creation
uses actual learned/transported/predicted model preparation through controller
calls, then viewport input for the tested Continue/Fork/Generate/Keep lifecycle;
it is not a full ordinary Game playthrough. Focus builds reference wiring for
its CPU fixture, runs real Debug, then uses actual title drag and Home/Shift-Home.

Initial GPU Creation failed six actual-size checks: native window transitions
left captures at a different physical size. Behavioral assertions passed, but
that run is not a visual pass. The driver now explicitly synchronizes the native
window size and requires five real 1280×720 frames before saving. Original logs
and six original images remain in `logs/gpu-initial` and
`images/initial-size-failure`. The first size-corrected run passed126 assertions,
but visual review found the Chinese name field outside the scroll viewport:
resizing inside the screenshot helper had invalidated the earlier visibility
assertion. That intermediate run/images remain in `logs/creation-gpu-corrected`
and `images/first-sized-attempt`. The final driver stabilizes size before any
interaction, never resizes during capture, and repeats the focused-name visibility
assertion at capture. No runtime correction or weaker assertion was used.
No screenshot is resized or composited.

## Native macOS operation

After the user unlocked the Mac, both old and candidate ordinary entry points
were launched without test scripts/capture flags in the same isolated profile.
The existing idle Project Manager was closed to let CUA bind the actual game;
it was visible again after each game exited. No editor document was involved.

Old code: wake terminal → enable Test mode → journey map → CPU → drag minimized
Components to the bottom → click Focus. The CPU disappeared below the graph at
23% view. Candidate: the same visible actions retained the bottom title and
framed the CPU inside the canvas at 90% view. These are visual observations,
not a claim of universal optimal framing.

Candidate continued through map → Chapter10 G2 → Learn → exact restoration →
P1 connect sealed input → Practice → Commit → Reveal → Run remainder → G2 connect
feedback → Generate → empty-name Keep. The name field was visible/focused;
native typing `Native QA work` and Keep saved it. Next entered G3; Edit this work
changed the primary action to Generate. Native keyboard changed length64→65;
Generate then naming `Native QA child` and Keep left both works in the list and
returned to the saved-work action. Cmd+Q exited normally (0).

Native process commands, profile IDs and raw logs are in `logs/native-baseline`
and `logs/native-candidate`. CUA screenshots were inspected in the conversation;
no filesystem screenshot export is claimed. GPU images are separate durable
scripted evidence. This checks English native Test-mode representative operation,
not ordinary Game unlocking, every task, or native cross-process draft restoration.

## Limits and next scope

The unchanged save format cannot distinguish a repeated identical fork of parent
B from an already-kept child C with exactly that parent and recipe. After reopening
that ambiguous state, the saved-work action can appear; explicit Fork remains
available and protected works are intact. The current session always honors
explicit Continue/Fork. Exact persistent intent would require a separately scoped
format decision; it is not silently introduced here.

Framing greedily chooses a usable side for minimized titles. It does not promise
optimal packing with arbitrary overlapping windows, nor that a dense CPU entirely
fits at the existing minimum zoom. The960px Focus frames retain some existing peripheral toolbar clipping; they
prove circuit framing, not an entirely unclipped minimum-size interface.
Full native/novice, Windows/export, long-session
and audio acceptance are not established. The whole-chapter basic-interaction goal
remains active: next targeted gaps are Ch1 Apply/run/retry/return, Ch2 observation
and judgment, and C2/C3 and P2/P3 comparison/check entry paths. Existing scoped
chapter evidence is reused rather than requiring unlimited polish.

The visual and historical Logo decisions remain with the user/team in
[the existing checklist](../../development/VISUAL_DECISIONS_20261112.md).

## Reproduction

Use `scripts/verify-project.py --godot <pinned engine> --suite <name>` for the
listed headless suites. After its isolated import, `run-boundary-checks.py` in this
receipt accepts `--project <QA copy> --out <logs> --suite <name>`; add `--gpu` and
`--flag=--circuit-focus-capture` or `--flag=--recovery-capture` for raw captures.
Never point that runner at the shared development checkout: it sets the QA
project's custom user directory for each run. Exact calls/profiles are retained
in per-stage results JSON. Source/evidence hashes are recorded alongside this file. The1328 candidate
source/test/support files match QA;546 baseline runtime files match the base commit.
