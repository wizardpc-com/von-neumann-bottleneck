# Actual cloud renderer check, 2026-10-22 10:24–10:33 Beijing

Current production source f40bf89, Godot 4.7.1, Linux X11 compatibility renderer,
Mesa llvmpipe LLVM 19.1.7 software rendering, 1364 × 1024 native cloud surface.
The helper rendered 11 real screenshots per run and measured 180 post-draw wall
frame intervals after warmup for each of arrival, look-around, and terminal.
This is not a Windows native/GPU benchmark or a complete gameplay benchmark.
Audio fell back to Dummy; sound was not accepted. Two 1280 × 720 attempts failed
strict image-size assertions because the actual cloud window remained 1364 ×
1024, including with explicit windowed CLI dimensions. Failure logs retained;
no screenshot from those attempts is claimed as a 1280 × 720 result.

| Profile | Arrival FPS / p95 ms | Look FPS / p95 ms | Terminal FPS / p95 ms |
| --- | --- | --- | --- |
| Production, 2x MSAA and dynamic shadows | 2.91 / 380.59 | 2.78 / 409.65 | 60.20 / 18.51 |
| QA only: no MSAA or shadows, 1024 atlas | 16.22 / 67.71 | 16.37 / 68.83 | 59.15 / 20.87 |
| QA only: above + half-size 3D viewport | 26.9 / 44.9 | 28.3 / 40.2 | 57.7 / 19.9 |

The terminal correctly suspends 3D room rendering; room draw calls are zero
while covered. Production room calls were 431/443; the no-shadow experiment
was 119/125. These are sequential bounded observations, not controlled hardware
proofs or guaranteed speedups on another computer.

Visual inspection: inspected main terminal pages are readable at the actual cloud
resolution. The half-size experiment noticeably damages the small in-world
wall labels and introduces stair-stepping. Even that experiment does not reach
60 FPS. **Neither experiment was shipped or substituted for the tested build.**
The normal renderer and art are preserved; QA copy was restored afterwards.
Next: test target Windows GPU and add a deliberately designed optional low-cost
room or static-entry path, with readable labels and verified picking, rather
than silently forcing visibly degraded art for everyone.

Raw numeric receipts are adjacent. Screenshots and the isolated source copies
remain in local QA evidence; production code and package hashes are unchanged.
