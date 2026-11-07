# W9: Chapter 3 run and observe

## Round 2 review fixes

The headline retains the verdict and deciding cycles. Correct-but-slow details
now say only "Output correct" (localized); successful details omit the repeated
verdict. The bottom status returns to the existing edit hint. Error diagnostics
and previous-run comparisons remain. The event list shows three complete rows,
sized from the current font and panel margins (94px = 3 x 26px + 16px margins).
All five after captures below were recaptured and visually inspected.
The same five suites passed again, with import/isolation PASS (`results.json`).
GPU input also passed again: 47 checks, 0 failures (`gpu-input.txt`).
Round 2 source changes only `src/overlap_chapter/overlap_chapter.gd`; existing
Round 1 timeline, localization and test edits are retained. Evidence logs and
screenshots are refreshed. No simulation, progression or save changes; no commits.

The timeline reserves a full-width band below the machine canvas and above the
bottom actions. Its first line shows the measured verdict, elapsed/target cycles
and excess; other measured counters occupy one row. Tracks and scrollable events
sit side by side. The same cycle drives the marker and machine state, including
when selecting a zero-cycle failure. The task goal shares the header line.

## Owner-review trade-offs (before -> after)

- Floating timeline covering the machine -> fixed bottom result band; Task,
  Parts and Schedule yield on opening results. Opening one of those tools closes
  results and restores editing height. Timeline remains one click away.
- Four stacked yellow metric/verdict lines -> coloured verdict with deciding
  cycles, one counter row, explanatory evidence beside the tracks.
- Separate goal strip -> goal button in the shared header. It opens Task for
  full details; long text uses ellipsis. Navigation order matches chapters 1/2.
- Tall event list -> shorter independently scrollable list beside wider tracks.

## Identical before/after captures (1280x720)

| Route | Before | After |
| --- | --- | --- |
| buffers settled entry | before-entry.png | after-entry.png |
| buffers serial run during replay | before-buffers-during.png | after-buffers-during.png |
| buffers serial run finished | before-buffers-end.png | after-buffers-end.png |
| synthesis serial run finished | before-synthesis-end.png | after-synthesis-end.png |
| buffers English run finished | Chinese baseline above | after-en-end.png |

All frames were visually inspected. The run fixtures deliberately use the public
one-buffer machine and serial program: correct output 46/46, 40 cycles against
28, excess 12. They do not install an answer or claim completion. Entry uses the
ordinary developer route. Run captures use the exact same fixture on both sides.

## Reproduction

PowerShell, from this worktree (use a fresh user directory for every launch):

```powershell
$godot = 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
$env:APPDATA = "$pwd/.godot/w9-review-user-1"
$env:LOCALAPPDATA = $env:APPDATA
& $godot --headless --path "$pwd" --import
& $godot --path "$pwd" -- --test-mode --dev-enter=chapter_3/buffers@2 "--dev-shot=$pwd/.godot/review-entry.png@9" --dev-quit=10
```

For measured run captures, copy `capture.gd.txt` to `.godot/w9-capture.gd`, choose
another fresh APPDATA/LOCALAPPDATA, then:

```powershell
& $godot --path "$pwd" --script res://.godot/w9-capture.gd -- "$pwd/.godot/review-buffers" buffers
# For synthesis: replace final argument with synthesis.
# For English: append en after buffers.
```

Fixture source is preserved next to this README. It captures 2 and 7 seconds
after the run; the first frame is during replay, the second after replay ends.

## Verification

Exact focused command:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_overlap_simulation --suite test_overlap_ui --suite test_overlap_player_input --suite test_terminal_presentation_polish --suite test_trace_ambience
```

Final receipt: `results.json`, 5/5 suites PASS, 0 failed; import and isolated
user-directory gates also PASS. Full suite output is included alongside it.
Input: 47 checks, 0 failures. General presentation: 32 checks, 0 failures.
The UI suite additionally checks that the result band intersects neither canvas
nor bottom actions, that Task yields, and that the marker matches the scrub cycle.
Input-test assertions now read detailed diagnostics from `result_details` because
`metrics` is the single-line verdict. Their semantic expectations are unchanged.

GPU command (fresh isolated APPDATA/LOCALAPPDATA):

```powershell
& $godot --path "$pwd" --script res://tests/test_overlap_player_input.gd
```

GPU: PASS, 47 checks, 0 failures (`gpu-input.txt`). A first intermediate input
run failed because Schedule was constrained by the result band; the final tool
switching behavior above fixes that failure, and both final input runs pass.
`git diff --check` passed. Windows root-certificate-store warnings occur in both
baseline and final runtime; no script/parse/assertion errors occur in final logs.

## Limits and proposals

No proposals needing simulation or persistent-format impact analysis. Simulator,
state, catalog, shared styles and part previews are unchanged. No commits.
Screenshots cover the requested representative routes; exhaustive native play,
other window sizes and exported builds are not verified. Taste and novice
comprehension remain owner review. Scratch data uses ignored `.godot/` inside
this worktree because the sandbox permits writes only inside this root; every
Godot process used isolated APPDATA/LOCALAPPDATA, never real player saves.
