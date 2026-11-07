# A3 room pages - 2026-11-08

## Round 2

Archive uses compact numbered closed tabs, vector lock marks and one unlock note; its empty reader is a ruled sheet with the existing message centred. Journal selection uses the page accent, the list fits whole rows, and saved works appear in horizontally scrollable small frames with real snapshot previews and names (three empty frames when none). Settings tabs join the panel; their height is reserved above the footer. Achievements have accent rings/arcs/filled medals driven by the original earned/total counts.

Numbering mismatch originates in the supplied titles: core `tree.region.0` through `.4` translations include ordinals, while candidate `region_title` strings do not. The achievements builder removes an existing two-digit prefix and displays region + 1 for all eleven cards. No catalog or translation data changed in Round 2.

The original before PNGs are retained; after PNGs below show Round 2. Populated QA works are generated and saved through the existing Session API, using the same bounded setup as `test_journey_journal`, not invented display data. Replay those four extra renders with `--after --populated` and a fresh profile.

Round 2: the same **10 isolated suites PASS / 0 FAIL**, import/user-directory gates PASS, all exits 0: `.godot/verification/20261107T184546Z-e2e70c01/results.json`. Repeat the Round 1 verifier command below with a fresh profile. GPU reruns: terminal pages **58**, settings/feedback **154**, journal **256** checks PASS; journal also rechecked headless (**175**) after its final selection/focus adjustment. Logs: `.godot/a3/r2-final-gpu-{terminal,settings}.log`, `r2-contrast-{headless,gpu}.log`; launch arguments match the three GPU commands below, using the Round 2 QA path and a distinct fresh profile for every launch. Final six-file source parity: `.godot/a3/r2-source-parity.json`.

An initial Round 2 settings run found two footer-fit failures after tab-height changes (`.godot/verification/20261107T183945Z-1dd0e415/`). Reserving tab-strip height fixes both; no assertions changed. Final captures: 20 empty-profile renders plus four populated-work renders, Chinese/English and room/terminal. Main pairs below retain their original before images. Extra samples: [room works](after-populated-room-works-zh_CN.png), [terminal works](after-populated-terminal-works-en.png). `git diff --check` PASS. Existing Windows certificate-store warning persists; native Godot exits are 0.

Round 2 revised only `src/lab/lab_archive.gd`, `src/ui/journey_journal.gd`, settings/achievement presentation in `src/ui/prototype_hub.gd`, this README/capture harness and after PNGs; updated ignored `.godot/collaboration/handoff.md`. Existing feedback/localization changes retained. No deleted files, commits, shared-theme, model, save-format or achievement-data changes. Native object picking/camera travel and human playtesting remain unverified; inspect those during integration.

## Candidate scope

Presentation-only candidate for owner review. Sources: `lab_archive.gd`, `journey_journal.gd`, settings/achievement builders in `prototype_hub.gd`, and feedback presentation in `playtest_moments.gd`. One appended A3 localization entry per language. No shared style source changed.

| Page | Before | After | Owner choice |
| --- | --- | --- | --- |
| Archive | [before](before-archive-zh_CN.png) | [after](after-archive-zh_CN.png) | Original open reader vs framed paper and drawer index; stronger page silhouette and locked-text contrast. |
| Works / journal | [before](before-works-zh_CN.png) | [after](after-works-zh_CN.png) | Accent selection, whole rows, and small saved-work frames. |
| Achievements | [before](before-achievements-zh_CN.png) | [after](after-achievements-zh_CN.png) | Eleven consistently numbered plaques with completion medals and original earned/total values. |
| Settings | [before](before-settings-zh_CN.png) | [after](after-settings-zh_CN.png) | Joined tab strip, 44 px instrument rows and wider card padding. |
| Feedback | [before](before-feedback-zh_CN.png) | [after](after-feedback-zh_CN.png) | Rounded cards vs square stationery cards. Also fixes the room background being overwritten after skin application. |

Original appearance is preserved by these baseline PNGs and Git base `196d08e`; no user-facing setting or private switch added. All counts, unlocks, unavailable states and saved snapshots still come from their original data sources. Empty work slot is explicitly empty, not fabricated output.

## Captures

1280x720, real NVIDIA OpenGL renderer, isolated fresh APPDATA/LOCALAPPDATA under this checkout's ignored `.godot/a3/`. Captured all five pages in both languages, light room and dark terminal variants (40 before/after PNGs). Ten Chinese room comparisons above are retained here; remaining scratch PNGs are `.godot/a3/{before,after}-{room,terminal}-{archive,works,achievements,settings,feedback}-{zh_CN,en}.png`.

The harness calls the existing page controller methods, then the room's normal dressing method for object variants. It does not synthesize mouse clicks or camera travel. Both hosts and both languages were inspected visually; terminal works/archive/feedback and English room pages have no observed clipping. Native object picking/camera transitions are not established by these captures.

Replay final (fresh disposable profile required):

```powershell
$env:APPDATA="$pwd/.godot/a3/replay-profile"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd" --script res://docs/verification/20261108b-A3/capture.gd -- --test-mode --after
```

## Round 1 verification

Focused isolated verifier: **10 suites PASS, 0 FAIL**, import and isolated-user-directory gates PASS. Run: `.godot/verification/20261107T180418Z-8b8b399a`; `results.json` records native exit 0 for all ten and no test errors. Full logs were inspected.

```powershell
$env:APPDATA="$pwd/.godot/a3/check-profile"
$env:LOCALAPPDATA=$env:APPDATA
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_lab_journey --suite test_lab_terminal_pages --suite test_journey_journal --suite test_prelaunch_settings --suite test_settings_feedback_layout --suite test_settings_language_input --suite test_playtest_feedback_ui --suite test_room_page_skin_lifecycle --suite test_room_skin_dynamic_descendants --suite test_lab_terminal_routing
```

Individual reported counts: journal 175; lab journey 52; terminal pages 52; routing 39; skin lifecycle 96; dynamic descendants 27; settings/feedback layout 154; language continuity 119. Feedback UI and prelaunch settings report PASS without numeric counts. Headless journal and terminal suites explicitly skip focused native Window stacks; GPU reruns are recorded below. `git diff --check` PASS.

GPU reruns in the same isolated copied project: terminal pages **58 checks PASS**, settings/feedback **154 checks PASS**, both native exit 0. Logs: `.godot/a3/gpu-test_lab_terminal_pages.log`, `.godot/a3/gpu-test_settings_feedback_layout.log`.

```powershell
# For each suite, use a distinct fresh APPDATA/LOCALAPPDATA under .godot/a3.
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd/.godot/verification/20261107T180418Z-8b8b399a/project" --script res://tests/test_lab_terminal_pages.gd
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd/.godot/verification/20261107T180418Z-8b8b399a/project" --script res://tests/test_settings_feedback_layout.gd
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd/.godot/verification/20261107T180418Z-8b8b399a/project" --script res://tests/test_journey_journal.gd -- --capture-size=1280x800 --journal-feedback-capture
```

An initial GPU journal invocation omitted the documented capture flag and failed its no-write inventory assertion because window resizing created `presentation.cfg`. Replacing all six changed production files in the QA copy with HEAD reproduced the identical failure (254 checks; log `.godot/a3/gpu-baseline-journal.log`); final source bytes were then restored and verified against the worktree. No assertion was weakened. Documented capture-flag rerun: **256 checks PASS**, native exit 0 (`.godot/a3/gpu-journal-capture.log`). Final GPU coverage is **3 suites PASS / 0 FAIL** with documented arguments.

## Limits and proposals

No simulation, score, judgement, task, save or achievement data code changed. No proposals needing impact analysis. Main comparison screenshots use an empty profile; the additional populated-work screenshots use explicitly generated QA works. Earned/unlocked records are exercised by existing suites; partial/full medal visual states are not separately captured. No exported package, native object clicks or human playtest. Windows certificate-store warning occurs in both baseline and final capture logs.
