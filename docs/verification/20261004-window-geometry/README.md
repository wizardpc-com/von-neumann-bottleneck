# Native window geometry synchronization

Baseline: `870fd123d58a18d96dd66779060ad1e01c474664`, branch `ray/representation-playloop-20261003`.

## Reproduction and diagnosis

Linux cloud desktop, X11/Xfwm4, Mesa llvmpipe, 1364×1024 screen (1364×936 usable). Official Godot `4.7.1.stable.official.a13da4feb` was downloaded from the Godot release and its archive verified against the official SHA-512 manifest. System Godot 4.6.3 was not used for verification.

At 19:05 UTC, the ordinary uninstrumented game launched with a fresh isolated profile and no capture arguments. The fullscreen window was 1364×1024, but the image occupied approximately x 0–1180 / y 212–1024. Clicking the visibly rendered Settings button did not open Settings. Both the full-desktop screenshot and app-window screenshot showed the defect. F11 to windowed, then F11 back to fullscreen, restored the complete view and native Settings input.

A second uninstrumented cold-cache/profile launch reproduced the same visible defect at 19:09 UTC. Warm launches and several diagnostic launches rendered correctly. This is a timing-sensitive native presentation problem, not a deterministic campaign/layout error. Diagnostic runs were kept separate from uninstrumented acceptance; their clean screenshots are not evidence that the baseline was repaired.

The app wrote mode, size, position and minimum directly through DisplayServer, bypassing the owning Window's cached geometry/viewport updates. The [official API](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html#class-displayserver-method-window-set-min-size) recommends Window.min_size; [Window's implementation](https://github.com/godotengine/godot/blob/4.7.1-stable/scene/main/window.cpp#L512-L527) recalculates the viewport after updating limits. An isolated minimum-only candidate exposed why mixed setters are unsafe: a saved 1280×842 window was overwritten by stale 1364×1024 root geometry. That candidate was not published.

## Change

Eight existing geometry writes now use the owning Window properties consistently. Size limits, remembered rectangles, default fullscreen, capture arguments, persistence format, simulation and gameplay remain unchanged. There is no timed fullscreen-reset workaround.

## Automated checks

- Baseline existing focused run `20261004T190345Z-aa2d3896`: import, isolation, display preferences and prelaunch settings passed.
- Changed-source focused run `20261004T191723Z-86c89d9a`: import/isolation and the same two conventional suites passed. An early native-test prototype printed a headless skip; that stage is **not native coverage** and was removed from conventional-suite discovery.
- Final standalone `scripts/verify-native-window-geometry.gd` runs on a native display and refuses headless execution. It checks the root minimum, independently calculated clamped size/position, immediate synchronization, limit reapplication, and settled fullscreen round-trip retention. Immediate assertions remain immediate; settled transitions allow one second each.
- The final standalone script failed on baseline with exit 1 and passed on the changed production source with exit 0. Complete logs are [before](native-before.txt) and [after](native-after.txt). This is a synthetic native geometry contract, not a player-input test.
- Final script import and `git diff --check` passed. No simulation code changed; unchanged full game suites were not mechanically repeated locally. Remote CI must be checked for the published commit.

Run after the normal isolated verifier, using its imported QA project and unique custom user directory:

```sh
/path/to/Godot-4.7.1 --path /path/to/isolated/project --script res://scripts/verify-native-window-geometry.gd
```

Do not run this geometry-mutating verifier against an actual player profile or alongside native QA. It intentionally changes window preferences in the isolated profile.

## Final uninstrumented native acceptance

Only owned QA windows were opened/closed; each normal close was followed by a window-inventory check. The final runtime matched the production WindowMode source; project modifications were limited to the documented custom user-directory settings. No diagnostic autoload or capture flag was used for ordinary startup checks.

- Fresh profile plus cold renderer cache: complete 1364×1024 fullscreen at startup; the upper-right Settings click opened the correct dialog before any F11 action.
- Saved fullscreen plus a separate cold cache: complete 1364×1024 view on restart; the bottom-right Handbook click opened the correct panel.
- Windowed transition and native title-bar move saved 1280×842 at (42,74). Restart restored exactly that size/position, confirmed by native window inventory. The rendered Settings target opened correctly without a fullscreen toggle.
- Explicit `--capture-size=1280x720` launched windowed 1280×720 at (42,108). On normal close, presentation.cfg retained SHA-256 `784f3f5537a6812d0a9ce3eea9c4c35656e8e85d971b45a492ffe8fc1eedf50b`, unchanged from before capture.
- Screenshots were inspected in computer-use history; no native screenshot files are claimed. The final native contract processes exited normally, and no QA game window remained.

## Limits

The app-level geometry synchronization failures are directly regression-tested. The final tested startup paths no longer showed the original visual/input offset; the precise contribution of X11/Mesa startup timing is not independently proven and this is not universal driver/platform acceptance. Windows/macOS, HiDPI/multiple monitors, packaged exports and beginner play were not tested in this iteration.

Native logs retain the environment's unsupported V-Sync warning and ALSA initialization error followed by Dummy audio fallback. The passing native contract has no game-script errors; audio acceptance is not claimed. No merge, release, deployment or credential changes.
