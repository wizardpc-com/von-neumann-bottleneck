# W8 — Chapter 2 run and observe

Round 2, Godot 4.7.1 stable, 1280×720, isolated Test profiles.
Accepted behavior retained: one-click formal Run, Task/bench yielding, compact
pending replay strip, task-only capstone entry.

Wire captions now sit above the wire midpoint, measure their actual text width,
and avoid every visible node rectangle with a 6px gutter. If no free position
exists, the transient caption is omitted. Replay progress reserves space before
Handbook. The result bench fits its existing content after text wrapping settles;
its existing resize grip remains usable. Simulation, metrics, saves, catalog,
judgement, 8 Hz pacing, event durations and shared styles are unchanged.

## Captures

Original before-*.png files are retained. All nine after-*.png files were refreshed
and visually inspected. Before/after pairs: distant (pending), bench/replay/end,
cache (321 cycles / 304 waiting / 256 B), capstone. Additional frames:
`after-cpu` (CPU→Bus), `after-nearby-replay` (direct RAM read),
`after-nearby-storage` (Cache→CPU hit), `after-en` (English replay).

GODOT = E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
ROOT = this worktree; OUT = this directory. Before **each** launch set APPDATA
and LOCALAPPDATA to fresh directories under ROOT/.godot/w8/. The session sandbox
permits scratch writes here. Player profiles are never opened.

```
GODOT --headless --path ROOT --import
GODOT --path ROOT -- --test-mode --dev-enter=chapter_2/distant_reads@2 --dev-shot=OUT/after-distant.png@9 --dev-click=1160,78@10 --dev-shot=OUT/after-replay.png@12 --dev-shot=OUT/after-end.png@42 --dev-quit=43
GODOT --path ROOT -- --test-mode --dev-enter=chapter_2/nearby_storage@2 --dev-click=1020,78@10 --dev-shot=OUT/after-nearby-replay.png@12 --dev-quit=14
GODOT --path ROOT -- --test-mode --dev-enter=chapter_2/cache_failure@2 --dev-click=1097,78@9 --dev-shot=OUT/after-cache.png@12 --dev-quit=13
GODOT --path ROOT -- --test-mode --dev-enter=chapter_2/capstone@2 --dev-shot=OUT/after-capstone.png@9 --dev-quit=10
GODOT --path ROOT -- --test-mode --locale=en --dev-enter=chapter_2/distant_reads@2 --dev-click=1140,78@9 --dev-shot=OUT/after-en.png@12 --dev-quit=13
```

Two event-inspection frames use `.godot/w8/r2_event_capture.gd`: start the task,
select one cache line for nearby_storage, run the formal workload, pause, then
inspect its first bus_request (distant) / cache_hit (nearby) at the first sampled
1%-step progress outside component processing. This changes presentation only.
Capture scripts/logs: `.godot/w8/r2-{capture,final}-*`, `r2-event-capture.log`.

## Verification

```
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_locality_trace_presentation --suite test_locality_chapter_ui --suite test_ui --suite test_simulation --suite test_trace_ambience
```

Final Round 2: **5/5 headless suites PASS**, presentation **2497/0**;
import/isolation PASS, diff check PASS. Chapter UI renderer/pointer/Space
subchecks report NOT_RUN in headless mode.
Evidence: `.godot/verification/20261107T164325Z-9a018603/`;
summary `.godot/w8/r2-final-suites.log`. Presentation regression checks every
recorded event against all visible node rectangles on distant, nearby (one cache
line) and cache_failure, plus real Handbook clearance and result-content height.

Prior GPU matrix remains **unresolved**, not rerun: candidate failed 12 assertions,
untouched baseline failed 14 (including the same 12). Logs:
`.godot/w8/gpu-{baseline,final}.log`. Native input and arbitrary dragged layouts
remain unverified. No commits. Ready for Claude's visual review.
