# B2 bridges — 2026-11-04

Yi reads existing Game records at chapter return: exact capstone baseline/accepted cycles, Chapter 3's retained no-repeat-transfer bonus, and Chapter 4's retained space/traffic bonuses. Missing records and Test mode retain the original reflections. Separate bonus layouts are described separately. No progress, simulation, result, or save schema changed.

Terminal uses an instrument title strip and shared UiMotion reveal. Dialogue replies expand into readable buttons (the baseline rendered narrow vertical strips). Completion uses the same restrained reveal, retaining its existing result, sound and emblem.

## Comparison captures

All ten selected PNGs are real 1280×720 Chinese GPU frames. Terminal, journal, completion and dialogue were captured before production edits and after the final change. The initial map capture mistakenly opened the optional observatory; its replacement baseline was replayed in `.godot/b2-map-baseline`, restoring the five changed production text files from HEAD 0ba32e2, using the same imported assets and fresh isolated state. The corrected map route uses TaskNavigation.open_tree(), matching `--dev-enter=tree`. The final capture harness is `tests/test_b2_bridges.gd`:

| Route | Before | After |
| --- | --- | --- |
| Terminal, 4-second startup then wake | before-terminal.png | after-terminal.png |
| Journey map | before-map.png | after-map.png |
| Journey journal / growth record | before-journal.png | after-journal.png |
| Real capstone completion | before-completion.png | after-completion.png |
| Yi's capstone reflection | before-dialogue.png | after-dialogue.png |

The fixture enables the existing offline-tester task access, in an isolated Game profile; it does not inject receipts/completion. The ordinary controller runs the baseline, selects the real diagnosis, and runs cache configurations: 642 baseline cycles and 138 accepted cycles. This is a bounded controller scenario, not a player-earned campaign or a Test achievement. The map and journal are unchanged comparison references.

Capture command (set fresh APPDATA and LOCALAPPDATA under `.godot/b2-<run>-profile` in the same shell first):

```powershell
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path 'E:/VNB/temp/claude-experience-20261104/wt/b2' --script res://tests/test_b2_bridges.gd -- --evidence-dir=res://.godot/b2-final
```

English replay adds `--locale=en --evidence-dir=res://.godot/b2-en`. Scratch images and logs are under `.godot/`; they are intentionally excluded from the ten chosen comparison PNGs.

## Verification

Exact focused commands, from worktree root:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_lab_journey --suite test_immersive_lab --suite test_lab_terminal_routing --suite test_terminal_language_input --suite test_journey_journal --suite test_cinematics --suite test_chapter5_cinematic --suite test_ending_cinematic --suite test_completion_evidence --suite test_global_save --suite test_ui_convergence --suite test_unified_style --suite test_b2_bridges
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_b2_bridges --suite test_lab_journey --suite test_terminal_language_input --suite test_lab_terminal_routing --suite test_card_attribution --suite test_guide_convergence --suite test_playtest_feedback_ui
```

First run: 13 suites PASS, 0 FAIL (`.godot/verification/20261104T100330Z-f7748458/results.json`). Final incremental run after localized copy and artifact API checks: 7 suites PASS, 0 FAIL (`.godot/verification/20261104T101025Z-b4f65b97/results.json`). Their per-suite assertions and declared skips are in [suite-results.md](suite-results.md). Both import and user-directory probes passed. Windows root-certificate-store errors are pre-existing engine startup diagnostics, excluded by the repository verifier. No test failure remains.

The final B2 suite checks 14/14: missing records, exact bilingual measured numbers, detached presentation, Game/Test isolation, reply geometry, absent machine evidence, and five real accepted Representation runs opening a dismissable artifact with its temporary-session boundary. The initial suite version only captured the five routes; final results supersede that version. Existing cinematic suites decoded all four full films. The final two extra assertions check the artifact fits 720p and dismissal frees it and resumes the caller. Artifact scratch GPU frames are `.godot/b2-final/artifact.png` and `.godot/b2-en/artifact.png`. After correcting the task-tree route and adding artifact viewport/dismissal assertions, direct Chinese and English GPU replays each passed 16/16; terminal and dialogue English frames were visually inspected.

Final corrected route/artifact fixture verification also passed 1/1 suite, 16/16 assertions, 0 failures, with import and isolation probes PASS (`.godot/verification/20261104T101854Z-90feab48/results.json`):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_b2_bridges
```

Scratch output stays inside ignored `.godot/` because this session grants write access only to this worktree, not the proposed sibling sol directory.

## Proposals needing impact analysis / integration

The return display is implemented in `src/lab/cinematic_artifact.gd`. Both APIs are awaited, dismissable, read-only, and skip Test mode. Prologue validates all four library source signatures against SystemChapter's captured CPU/RAM signatures; Representation calls the region's public five-plan revalidation API and reuses the existing result formatter. Temporary/unsaved results retain their save boundary.

The two caller files belong to other implementers. Insert these exact single lines **inside `if movie != null`, immediately after `movie.queue_free()`**, before returning to the ordinary screen:

- `src/hardware_foundations/hardware_foundations.gd`, `_show_prologue_completion`:
  `await preload("res://src/lab/cinematic_artifact.gd").present_prologue(self, player_content.component_library)`
- `experiments/representation_region/region.gd`, `_present_chapter5_cinematic`:
  `await preload("res://src/lab/cinematic_artifact.gd").present_representation(self)`

These calls add player-controlled reading time, without a timer, reward, or new achievement. They are deliberately not wired into unowned files. Opening has no pre-existing player artifact; journey_complete remains with Creation.

## Limits

- Actual end-of-film → artifact → workbench continuity needs these two caller insertions and a rendered integration replay. Production triggers currently retain their original behavior.
- The accepted prologue-library display path was inspected and source-bound but not exercised with an earned hardware library; missing/Test paths were executed.
- Chapter 3/4 bonus wording reads the existing revalidated public bonus stores; their bonus-specific dialogue branches were not separately earned/replayed here.
- Journal's ThemeReflection/F8 focused-window stack explicitly remains NOT_RUN headlessly. No physical mouse/keyboard, audible synchronization, newcomer comprehension, macOS or exported-build acceptance is claimed.


## Round 2 - B2b

The post-film API now builds an instrument card with one Continue action. Enter and Esc dismiss it, with no timer. Prologue displays ALU4, Register4 and RAM2x4 using the existing CircuitModuleThumbnail, actual library port widths and validated source-bound frozen bands where available; the final line names the validated TinyComputer. All four original source-signature checks remain. Representation retains public five-plan revalidation and shows five tiles, with exact storage bytes and cycles for every order separately. Temporary and unsaved boundaries remain visible. No result, simulation, progression or save schema changed.

Yi's capstone line now says "From 642 to 138 cycles. This is your plan." (Chinese equivalent). Both numbers still come from real accepted run receipts, without rounding; missing records and Test retain the original reflection.

Chapter 3/4 public persisted state was inspected in overlap_state.gd and layout_state.gd: game_solutions contains board/program or normalized design, not measured synthesis cycles, RAM totals or peak extra bytes. Bonus stores also hold designs. Accordingly those reflections keep their existing qualitative wording. This change does not recompute metrics and present them as recorded numbers, and adds no save fields.

### Round 2 comparisons

Ten selected Round 2 PNGs are in `round2/`; the ten Round 1 PNGs above remain historical evidence. All Round 2 frames are GPU-rendered at 1280x720. Identical capture routes were executed before editing and after implementation:

- `before-machine-zh.png` / `after-machine-zh.png`
- `before-machine-en.png` / `after-machine-en.png`
- `before-dialogue-zh.png` / `after-dialogue-zh.png`
- `before-dialogue-en.png` / `after-dialogue-en.png`
- `before-representation-en.png` / `after-representation-en.png`

Machine frames use `.godot/b2b/machine.gd`, an explicitly synthetic QA library, not a player-earned machine. This scratch harness constructs ReusableComponent definitions and matching synthetic source signatures without persistence. The existing HalfAdder capture only earns HalfAdder; the prologue simulation tests validate reference circuits, rather than earning a full machine library through player flow. The fixture and all extra captures/logs remain ignored in `.godot/b2b/`. Production contains no fixture data. Final machine harness dismissal frees the card and host before quitting.

Dialogue and Representation use `tests/test_b2_bridges.gd`: real capstone controller runs and five real accepted representation plans, as in Round 1. Chinese Representation after frame is also available at `.godot/b2b/after-zh/artifact.png`.

Capture command (fresh APPDATA and LOCALAPPDATA under `.godot/b2b/` per invocation):

```powershell
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path 'E:/VNB/temp/claude-experience-20261104/wt/b2' --script res://.godot/b2b/machine.gd -- --evidence-dir=res://.godot/b2b/after-zh
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path 'E:/VNB/temp/claude-experience-20261104/wt/b2' --script res://tests/test_b2_bridges.gd -- --evidence-dir=res://.godot/b2b/after-zh
```

English adds `--locale=en` and uses `after-en`. Baselines use `before-zh` and `before-en` with Round 1 source.

### Round 2 verification and limits

The B2 suite now also checks five tile counts, exact revalidated numbers, panel/tile geometry, Enter and Escape dismissal (31 assertions). GPU captures check Chinese/English framing; native physical input, audible playback and exported/macOS builds remain unverified. The two caller insertions documented above still belong to the lead integrator; film-to-card continuity is not wired in this worktree.


Round 1 union rerun: **16 suites PASS, 0 FAIL**, import and isolation probe PASS (`.godot/verification/20261104T103049Z-a546f00b/results.json`). Exact command:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_lab_journey --suite test_immersive_lab --suite test_lab_terminal_routing --suite test_terminal_language_input --suite test_journey_journal --suite test_cinematics --suite test_chapter5_cinematic --suite test_ending_cinematic --suite test_completion_evidence --suite test_global_save --suite test_ui_convergence --suite test_unified_style --suite test_b2_bridges --suite test_card_attribution --suite test_guide_convergence --suite test_playtest_feedback_ui
```

The final localized card/buttons are additionally replayed below; unaffected suites reuse the union rerun evidence. All per-suite verdicts are in [suite-results.md](suite-results.md). The known engine root-certificate diagnostic is present in baseline and final runs; the verifier excludes it. Journal ThemeReflection/F8 focus remains its declared headless NOT_RUN.


Final localized card/input verification: **1 suite PASS, 0 FAIL; 31/31 assertions**, import and isolation probe PASS (`.godot/verification/20261104T103735Z-f3aa3698/results.json`).

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_b2_bridges
```

Final Chinese and English GPU replays each passed **31/31**, logs `.godot/b2b/after-lines-zh.log` and `after-lines-en.log`. Both machine fixture replays exited 0, with no fixture teardown leaks. All selected final images were visually inspected for text, clipping and numeric presentation. Final `git diff --check` passed. Round 2 adds no impact-analysis proposal; the existing caller integration remains outstanding.
