# Selection controls and instrument recall — 2026-11-13

Base: `main` `fb5497d3f93aa45e9af07030a5b562f3d5564256`.
This continues the [whole-chapter interaction goal](../../exec-plans/completed/chapter-interaction-simplicity-20261113.md),
which remains active. No new package or final art direction is included.

## Delivered behavior

- Representation's pending split address follows the selected block's integer
  interior. Legal input is retained; an invalid old address is clamped without
  changing the plan. A nearby range, single-byte reason or eight-block limit explains
  availability. Multi-digit input commits on Enter or focus loss, so typing40 does
  not turn its first digit into a different address. Split remains an explicit action.
- Service's four encoding controls now expose all four choices directly. Choosing
  RLE8 takes one draft edit and one Undo, without traversing intermediate encodings.
  Same-value selection preserves Redo, measurements and save state. Language rebuild
  retains the complete group selection and its active group with the same writer lease.
- The new dropdowns open on release. During development, opening on press near the
  window bottom placed the first menu item beneath the opener; that same release
  immediately selected it. The final control prevents this double use of one click.
- Ch1/Ch2 already recall a covered Test Bench in one toolbar click. New actual
  viewport tests confirm both locales preserve three tool rectangles, draft/applied
  source, history, predictions and completion, then deliver a real Run click. No
  production recall change was needed. Ch2's third tool is Program, not Notebook.

Models, metrics, acceptance thresholds, save formats, Apply/observation gates and
font sizes are unchanged. The changed candidate input/journey callers choose the
same target representations as before.

## Verification and provenance

Engine `4.7.1.stable.official.a13da4feb`, macOS / Apple M2 OpenGL.
Candidate QA: `.godot/verification/20261113T122605Z-3c7141c0/project`.
Baseline QA: `.godot/verification/20261113T115407Z-03a544bc/project`.
All runs use isolated `VonNeumannBottleneckChecks/` profiles.

[Initial selected suites](candidate-initial-results.json) cover17 distinct tests
plus import and actual profile probing. Four initially failed; see the failure
history below. [Final click/focus reruns](final-click-and-focus-results.json) pass
keyboard focus111, Service player-input58 and undo-context136 checks. Their
superseded new encoding helper is separately completed by
[final Service controls235 checks](final-service-complete-results.json).
The other13 selected suites passed initially, including Representation split input160,
player input, presentation9303, edit context39 and session47; Service plan7268, journey input,
session63, split actions30 and design shelf48; shared language83 and closure101;
and instrument recall98. All17 selected suites have passing evidence across the
documented runs; this is not a complete repository regression.

GPU: [Representation190 checks](gpu-region-split-results.json),
[Service controls271 checks](gpu-service-complete-results.json), and
[instrument recall114 checks](gpu-recall-results.json). Service includes ordinary
mouse opening and mouse item selection, keyboard selection/reselection, complete
Space/Enter opening and Escape cancellation, both locales and temporary/persistent
sessions. These are scripted viewport inputs, not OS-native acceptance.

[Images](images.json) retain six Representation frames, eight covered/recalled
instrument frames, four Service workbench frames and four separate actual PopupMenu
viewport images. Full workbench frames must be actual1280×720; menu images retain
their own dimensions and are not composited. Scope is changed control readability,
not approval of the full visual design. Some existing task tooltips overlap the
upper Representation diagram but not the split controls; deep history actions still
require scrolling.
Service's bottom history list and one long English status line remain partly clipped;
the corresponding limit values are also fully shown above. The new selectors and
their four menu rows remain fully readable in all retained Service frames.

Baseline [Service checks](baseline-service-results.json) pass plan, session, undo
and player input. The old Region runtime reproduces the stuck boundary after a
default split and when selecting its right block (six expected failures); old
Service controls lack direct selection (16 expected failures). Their minimal
input scripts and full result logs are retained.

[Source hashes](source-sha256.json) bind1228 final workspace runtime/tests/assets/
localization exactly to the QA copy. Only two QA user-directory settings differ
in `project.godot`. [Baseline hashes](baseline-source-sha256.json) bind558 old production
files to the base Git commit. [Log hashes](log-sha256.json),
[inspection summaries](log-inspection.json) and the
[sequential runner](run-interaction-round2.py.txt) retain complete output, including
failures across48 logs. Final source and pixels received independent review. Branding and diff
whitespace checks passed.

## Failed attempts are not acceptance

- The first recall fixture incorrectly requested a nonexistent Ch2 Notebook toolbar
  entry. Its script errors and misleading partial PASS are rejected; the corrected
  fixture requires all four scenarios to complete and uses the actual Program entry.
- Four old focus-test assertions expected the replaced invalid-boundary/instant-input
  behavior. They now check legal pending input and delayed commit while retaining
  the full Tab-to-Split and Enter-at24 operation, disabled-action and earned-review tests.
- Initial Service replacement tests caught the real same-release menu selection
  described above. The corrected release behavior passes the original player-input
  and Undo scenarios. Later reselect-helper failures assumed Home alone focused the
  first row; explicit keyboard navigation now checks the actual focused item.
- Early pure-mouse diagnostic probes mixed embedded-window coordinate paths or
  mistook keyboard focus for pointer hit testing. The final root-viewport click uses
  the actual popup position and size, selects RLE8 once, and is included in the
  conventional final regression. Earlier probe failures remain in the logs.
- An initial Service GPU frame resized during macOS startup. Final captures wait
  for consecutive rendered1280×720 frames and never rescale an image.

A native-input attempt could only select the user's existing Godot Project Manager,
not the isolated game process. No native menu interaction is claimed; no existing
manager or user game was closed. The owned temporary fixture exited normally.

## Reproduction and remaining work

Use `scripts/verify-project.py --godot <4.7.1> --suite <name>` for the selected tests.
On an imported isolated QA project, add `--capture-size=1280x720` and respectively
`--representation-split-capture`, `--service-encoding-capture` or
`--instrument-recall-capture` to the new tests for GPU evidence.

The changed legacy `play_state_journey.gd` caller was inspected and imported;
its complete multi-process candidate journey was not rerun in this block. Ordinary
Service save, session, journey-input and immutable history paths were tested above.
Native mouse behavior, Windows, exports, unaided newcomer completion, full-chapter
navigation/resume, audio and long-session acceptance remain open. Scripted success
does not establish minimum cognitive load for unfamiliar players.
