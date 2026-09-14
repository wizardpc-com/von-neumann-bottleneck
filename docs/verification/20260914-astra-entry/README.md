# Competition entry follow-up — 2026-09-14

Scope: international newcomer entry and observed palette clipping. Five regions /
40 tasks, simulator, progression, persistence formats and Hint rules unchanged.

## Changes

- Always-recognizable `简体中文 / English` homepage menu; existing locale preference
  and safe workspace flush/reload. It returns to the hub, not an unexpected Settings
  overlay. Existing in-level Settings reload behavior remains the default.
- First-open Components minimum 360×420 logical units, clamped to available desktop;
  search/filters and the first full card stay readable through initial Retina layout.
- Existing GUI helper now recalls a covered tool before clicking its exposed close
  control. The old one-click-to-hide assumption was stale after covered-tool recall.
- Bilingual first-session instructions, low-friction playtest issue form and local
  contest materials. No public launch/download, server or invented model attribution.

## Automated evidence

- `.godot/verification/20260914T010156Z-9165dcdd`: first four affected suites passed.
- `.godot/verification/20260914T011056Z-8a029137`: all 38 conventional Godot suites
  passed. Initial English GUI run had 7 failures from the stale close helper and its
  cascading drag setup; retained as failed evidence, not a passing run.
- `.godot/verification/20260914T011318Z-159b3b58`: isolated import, hardware UI suite
  and corrected English ordinary Game tutorial replay pass, **220 checks, 0 failures**.
  Added first-card viewport containment assertion. Scope is tutorial interaction,
  not a fresh whole-game playthrough.

## Native source observations

Ordinary Game, separate `astra-entry-20260914` profile on this Mac:

1. Changed Chinese → English from the hub; returned to the English hub with no
   Settings overlay and no extra unlocks.
2. Entered Task tree → Wiring tutorial; read Mission and Start building.
3. Connected A→NOT→LAMP, changed A to 1 and ran practice: LAMP=0, 3/5 actions.
4. Erased and reconnected the output wire: 5/5 complete, then entered Half Adder.
5. F10 → Quit Game. Relaunched final code: English retained; Continue locates
   Half Adder; Tutorial remains completed and SR Latch available.
6. Reentered Tutorial: the final palette shows the full NOT card, purpose and port
   summary. A later native drag attempt lost CUA window access (`noWindowsAvailable`)
   after a state-change warning. **Final native drag is not claimed passed.**

All actions are source-native, not exported-candidate acceptance. Fullscreen was
observed; minimum-window bounds are covered by automated tests. Real Windows,
another Mac installation, mixed-DPI/long-session behavior and external beginner
understanding remain unverified. See [release gates](../../../RELEASE_BLOCKERS.md).

New gallery and candidate identity are recorded separately after freezing content.

## Window / platform follow-up

Owner requested freely draggable windows and familiar OS controls. Existing
instruments remain freely movable/resizable. Settings and Handbook now support
bounded title dragging; text fields and buttons retain their own input. Focus loss,
release, Escape and hidden surfaces cancel the gesture. Mac supports ⌘, for
Settings and ⌃⌘F for fullscreen; F10/F11 and prior Windows shortcuts remain.

- `.godot/verification/20260914T012010Z-4edb7b66`: six affected suites pass.
- `.godot/verification/20260914T012210Z-348949ec`: desktop convention, save/settings,
  handbook and localization checks pass, including dragging/clamping/cancellation.
- Native final source: ⌘, opens English Settings; title drag moves it by the actual
  pointer displacement; ⌃⌘F changes fullscreen to a 1280×720 content window.
  Resume/Quit remain inside. Esc closes Settings; Handbook opens, its heading moves
  the full panel and Close remains visible. Switched to Chinese, repeated ⌘, and
  Settings title drag, then clicked Quit. Observed results, not only key dispatch.
- Sources for conventions: [Apple](https://support.apple.com/en-ca/102650) and
  [Microsoft](https://support.microsoft.com/en-us/windows/keyboard-shortcuts-in-windows-dcc61a57-8ff0-cffe-9796-cb9706c75eec).
  Windows actual OS interaction is still pending.

Final full run `.godot/verification/20260914T012605Z-580b799f` passes all 39 conventional suites plus the Chinese tutorial input replay (220 checks, zero failures). The later display-only byte-unit nonbreaking-space fix passes layout UI and bilingual typography in `.godot/verification/20260914T013408Z-98620c29`. Original player files: all 18 baseline hashes unchanged.

## Frozen candidate and gallery

- Candidate `free-alpha-60de5e54c95d`, full content commit `60de5e54c95dac4e928487fbb5f9bb80bc23e7d8`; no public release.
- Both exports and `check-candidate-identity.py` pass: source/build IDs, archive names, file hashes and packaged notes agree.
- `verify-mac-candidate.py` passes using the actual copied release binary/PCK, isolated userdata and explicit protection of original player data: `.godot/package-qa/296e9381cc3b`. Includes Game-only behavior, 40 tasks, remote off, workspace identities and exclusion of development files. The first attempt failed because nested sandbox setup was denied, before running the app; rerun with approved execution succeeded.
- Mac ZIP SHA-256: `5d368add98ed71d839e0bad9c4011676ca6295c5a7d03a0b471536260c8f5aac`.
- Windows ZIP SHA-256: `c1c0747506d3ae31b79c4580e24242eab069b4d2b7bdb8161a8cc8fd24ef24ae`. Windows actual execution remains pending.
- Six fresh bilingual scene captures succeeded in isolated `astra-gallery-20260914`. Visually inspected all; selected tree/tutorial views plus the real layout rerun for the [six-image gallery](../../distribution/astra-challenge/gallery/manifest.json). No retouched gameplay or injected completion. These are source renders, not native package playthroughs.
- Both GitHub READMEs now lead with the bilingual Chapter 4 capstone screenshot, published in documentation commit `60de5e5`; existing chapter artwork remains below.

Final candidate mouse/focus checks, another Mac installation, Windows native, external players, competition eligibility and public download/submission remain owner gates. No gameplay content was added merely for contest eligibility.

Local launch-kit ZIP: `build/VNB-Astra-launch-kit-60de5e54c95d.zip`; SHA-256 `81c6aba05703786865b1b944ccb93bb4b920e6c665ceb51a996459287cd17e38`. Validated six image hashes/dimensions, submission lengths (49/249), ZIP CRC and repository-local documentation links. Prepared only; download URL remains empty.
