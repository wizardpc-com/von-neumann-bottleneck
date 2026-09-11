# Prelaunch settings and UI verification

Baseline 12b695d. Scope excludes narrative/Mimo rewriting, new content, simulation
changes, public deployment and distribution. Player data and the two downloaded
planning files are preserved. Runtime stage: 5672953.

## Changes and review coverage

| Surface | Repair / retained behavior | Evidence boundary |
| --- | --- | --- |
| Chapter hub / settings | Shared instrument styling, language persistence, grouped scroll, fixed Resume/Quit, bounded focus traversal | Both locales, 1280×720 layout contract; native observations below |
| Audio | Persistent Effects bus volume/mute; completion cue uses that bus | Actual AudioServer bus state checked; hearing/comfort needs player feedback |
| Preferences | Reset language/frame/motion/audio only | Unknown preference keys, progression and consent retained |
| Feedback | Live translated labels/choices preserve ratings and draft opinion | UI tests; existing independent consent/queue rules retained |
| First receiver choice | Explicit local/basic choices and data inventory; endpoint/notice-specific acknowledgement | Empty endpoint never prompts; no backfill; no score consent implied |
| Support | Build label, explicit local diagnostics and folder/export access | Whitelist excludes raw logs, designs, notes, identities, endpoints and paths |
| Circuit workbench | Cancel transient gestures before fullscreen transition and on focus loss | Ordinary Game input replay; no topology/simulator edits |
| Task tree / personal board | Existing tree and completion-only regional board retained | Metadata/locale/geometry suites; no new unlocks |
| Remaining chapters / Hint / floating instruments | Existing behavior retained | Conventional chapter/UI/provenance suites and ordinary Game route; not a new forty-task human playthrough |

## Automated evidence

Initial integration 20260911T133058Z-2f2e7eb1 exposed missing newly-added translation
keys and an early script-preload dependency on the Localization global. Both were
fixed, then rerun; that first failed run is not acceptance.

Chinese 20260911T133447Z-229cabc0: all suites and ordinary Game input replay pass
(602 checks, zero failures). The new settings test was then tightened to keep its
actual viewport at 1280×720, avoiding anchor resizing masking the small-size test.
Final English 20260911T133814Z-637bbe48: all suites and 602 input checks pass
([English results](en-results.json), [Chinese results](zh-results.json)). Both preserve
original editing, Hint, formal test and restart paths. Native focus review then found
that Tab selected offscreen controls without scrolling. Settings and feedback now use
follow_focus; [final targeted check](final-focus-contract.txt) verifies actual 1280×720
bounds and scrolling to the reset action. A first targeted rerun accidentally reused
an already-acknowledged QA profile; its first-choice assertion failed as expected and
was rerun in a fresh dedicated profile. It is not included as acceptance.

[Loopback integration](loopback-results.json) passes cross-process offline queue,
restart send, HTTP/SQLite deduplication and explicit opinion with automatic sharing off.
Only synthetic data was used, and the receiver was stopped after the test.

## Native Game observations

Mac M2, Godot 4.7.1; source-run QA profiles only. Configured a loopback endpoint only
in the ignored QA copy to expose the first-choice UI. Opened the inventory, chose
local, and entered settings normally. Chinese/English grouping, fixed footer, volume
slider and mute were operated; diagnostics exported successfully ([sanitized content](native-diagnostics.json)).
In the final dedicated profile, Escape declined the first prompt, then opened settings.
Changed language to English, set 33 percent volume and muted sound. Tab now scrolled
to the Feedback button. Quit normally, restarted without a locale override or any
intervening fixture, and observed English, mute and 33 percent restored. The declined
first prompt did not recur. This verifies settings, not sound pleasantness.

Reset confirmation exposed text behind its title strip. Shared embedded-window title
background and bounded/wrapped reset text were adjusted. Final targeted tests pass;
before the final native visual recheck the Mac locked. That last confirmation-frame
visual observation remains pending, explicitly not counted as passed. The cancellation
before this fix was operated; reset semantics are covered by the isolated test.

No engine errors occurred in the observed native source sessions. Native candidate
and owner-platform gates remain separate. New frozen candidate evidence follows.

## External limits

No Windows machine or external beginner was used. Another Mac installation,
notarization, mixed DPI and long focus/drag stress remain owner acceptance gates.
This audit does not claim the absence of every possible defect or prove fun/difficulty.
No domain, secret, payment, server deployment or public release is part of this work.
