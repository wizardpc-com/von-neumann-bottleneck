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
