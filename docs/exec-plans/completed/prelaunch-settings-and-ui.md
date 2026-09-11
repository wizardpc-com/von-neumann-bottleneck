# Prelaunch settings and UI completion

Approved scope (2026-09-11): language persistence, sound controls, structured scrollable
settings, safe defaults reset, build/support diagnostics, endpoint-gated first choice,
and bounded bilingual/window/focus review. Exclude copy rewriting/Mimo workflow,
new gameplay, server deployment, accounts and public release. Preserve five regions,
40 tasks, saves, free editing and independent Hint.

Implementation: extend existing Localization/WindowMode preferences; keep hub settings
API and move its content into a bounded scroll with fixed close actions. Use existing
SFX and feedback transport; diagnostics are an explicit local whitelist export.
First choice delegates to existing sharing setters and never backfills events.

Verification: isolated suites and new preference/consent/UI boundary tests; ordinary
Game bilingual replay; native source and frozen candidate checks when controllable.
Rebuild uniquely identified Mac/Windows local candidates after commits. Record tool,
platform and beginner limitations rather than claiming all unknown issues fixed.

Progress: baseline 12b695d, two downloaded user plan files preserved. Existing candidate
9f8c34f remains historical once runtime changes. No simulator edits planned.

Implementation review: settings stay at the chapter hub so changing language cannot
recreate an in-progress workbench. Reload only the hub; persistent feedback labels
refresh without discarding draft/rating selections. Audio uses an Effects bus.
Window transitions explicitly cancel unfinished hardware gestures. Defaults reset
only presentation preferences, never saves, consent or networking configuration.

Both full locale runs and 602-check Game replays pass. Native settings/first-choice,
English/mute/33-percent restart and diagnostics operated. Tab offscreen focus repaired
and rechecked. Final reset title-strip fix has targeted test evidence; Mac lock blocks
its final native image. Loopback cross-process transport still passes synthetic checks.

Implementation completed; candidate free-alpha-128632418664 exported and verified
for identity/offline boundary. Final shared UI regression passes. Native visual
reset confirmation/candidate mouse, Windows and external player gates remain listed
in RELEASE_BLOCKERS; no public release or additional feature work in this scope.
