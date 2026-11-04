# F1 feel — 2026-11-04

Reviewable uncommitted additions to the lead's nine-task integration. No commits, branch changes, simulation/judgement/task/save changes or P1-file edits.

Changes:
- `src/ui/ui_cue.gd`: reusable 120 ms synthesized Effects-bus cues and a compact, non-blocking first/repeat target cue.
- `src/ui/level_completion_overlay.gd`: 0.88 modal backdrop; compact verified-seal actions without an earned emblem/melody; restores the full earned card for completion.
- `src/hardware_foundations/hardware_foundations.gd`: actual connection/rejection, official-sequence and result cues; first earned seal card, light repeat-seal feedback.
- `src/system_lab/system_lab.gd`: first Game completion card, repeat feedback, actual wire/failure/improvement cues and instrument reveal.
- `src/ui/main.gd`: capstone completion card and official measured-result cues.
- `src/overlap_chapter/overlap_chapter.gd`: run/failure/repeat cues and instrument reveal.
- `src/layout_chapter/layout_chapter.gd`: first Game completion card, actual comparison improvement/save/run/result cues and instrument reveal.
- `experiments/representation_region/region.gd`: accepted-result/first/repeat/save cues.
- `experiments/service_plan/lab.gd`: accepted-result/first/repeat/save cues.
- `experiments/prediction/lab.gd`: cues from real accumulated evidence transitions.
- `experiments/creation/workbench.gd`: result/save and actual support first/repeat cues; transient loaded-support snapshot only.
- `src/ui/cycle_budget_bar.gd`: instant reduced-motion measurement, cancelling a preceding reveal.
- `src/lab/lab_home.gd`: instant reduced-motion subtitle appearance/disappearance, preserving reading time.
- `localization/game.{zh_CN,en}.po`: appended F1-only repeat cue key.
- `tests/test_f1_cues.gd`: readiness versus earned-card and interrupted/reduced-motion budget checks.
- `tests/captures/f1_earned_machine.gd`: genuinely earn tutorial, every sealed dependency and LOAD/STORE, then call the source-validated post-film card directly.
- `tests/captures/f1_covering.gd`: repeatable real 720p entry/run/Hint/Settings captures.

Evidence (23 chosen PNGs):
- `before-N.png` / `after-N.png`: identical entry routes. N=0 half_adder, 1 chapter_1/assembly, 3 chapter_3/arrival, 4 chapter_4/fields, 5 representation/mixed_scan, 6 service/move_state, 7 prediction/regular, 8 creation/C1_restore. Chapter-two entry pair is scratch in `.godot/f1/`.
- `before-ready.png` / `after-ready.png`: actual officially passing HalfAdder before sealing. The full ceremony is replaced by compact verified actions. Both captures use real tutorial and construction, not injected awards.
- `earned-machine.png`: actual Game prologue machine; 73 checks, 0 failures, production source signatures accepted. No film played or cinematic history consumed.
- `english-settings.png`: supported `--locale=en`, chapter-four 1280x720 Settings.
- `audit-run.png` / `audit-settings.png`: nine real workbenches, numbered as above plus N=2 chapter_2/distant_reads. Each tile retains the original 1280x720 frame.
- `audit-hint.png`: actual Hint layers for prologue, chapter three and chapter four.

Baseline entries were captured before editing. The initially mistyped representation/service routes were replaced using the untouched integrated QA copy `.godot/verification/20261104T112954Z-0ee278d6/project` and the corrected identical keys; baseline ready capture also uses that copy. Other scratch frames/logs remain under `.godot/f1/`. Every Godot invocation used isolated APPDATA/LOCALAPPDATA. Settings covers and dims the workspace intentionally; the inspected frames retain the modal's own controls within the viewport. No entry floating panels overlap one another in these routes; run views retain their primary result/action. Existing reduced-motion guards were inspected in S1 waves/seal, S2 trace/budget consumers, S3/S4 views and L1 dust/lights; existing guards were preserved.

Verification:
- Exact three verifier commands: `commands.txt` (broad requested list + requested cinematic/input neighbours; corrected affected scope; dedicated cue suite).
- Broad first snapshot: **35 PASS / 5 FAIL** out of 40 suites. The five failures were an F1 fourth-chapter parse error, not pre-existing failures.
- Corrected affected scope: **15 PASS / 1 FAIL** out of 16. All five preceding failures pass here. The one failure was the new test preloading an autoload-dependent overlay too early; the test now loads it at runtime.
- Dedicated corrected cue suite: **1 PASS / 0 FAIL**, **5 checks / 0 failures**. Combined applicable evidence: **41 unique suites passed**, including the original 40. Import and isolated-user-directory probes pass in each run. Machine GPU capture: **73 checks / 0 failures**. Covering script exits 0 without script errors.
- Machine-readable receipts: `broad-results.json`, `corrected-results.json`, `cue-results.json`. Full per-suite output remains in the corresponding `.godot/verification/<stamp>/` directories. `git diff --check` passes.

Limits and remaining review:
- This is representative workbench coverage, not every state of all 60 tasks. Full first-completion Game screenshots for each other chapter were not earned in this capture pass; production transition regression is automated. Hint coverage outside the three explicit layers is not established.
- Fourth-chapter Hint screenshot retains a native hover tooltip over its return area. Recheck pointer movement/tooltip dismissal with the lead; it is not evidence that every guide/tooltip is clear. Shared tooltip/theme handling and Settings are P1-owned (`src/ui/instrument_theme.gd`, `src/ui/window_mode.gd`) and were left untouched. Settings backdrop remains P1-owned; F1-owned completion backdrop matches the artifact's 0.88.
- Audio is source/bus checked and exercised in GPU runs, not independently recorded or human-listened. Immediate synchronous results can supersede a run cue on the scene's single cue voice. This pass wires the listed actual sites; it does not claim exhaustive place/delete/refused-action/save cues at every possible workbench site.
- Existing seal reduced-motion behavior completes on the next process frame; no timer, sealing-step or reward-order change was made. Other pre-existing animations were inspected, not exhaustively toggled during each playback.
- Physical keyboard/mouse, human pacing/understanding and export/package acceptance remain unverified. GPU logs contain the environment's root-certificate-store warning; no network operation was needed.

Proposals needing impact analysis: none; remaining work above concerns presentation coverage and validation, not simulation or progression changes.
