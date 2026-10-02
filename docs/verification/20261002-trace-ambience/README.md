# Trace ambience prototype — 2026-10-02

Opt-in, default-off prototype for Chapter 1 `cpu_speed` and Chapter 3 `buffers`.
Enable Run ambience in Settings. Effects and Ambience have independent volume/mute;
Reduce sound dynamics reduces gain variation without treating reduced motion as
mute. Preferences live in presentation.cfg and do not alter savegame progression.

The profile owns positive-duration interval copies, merges duplicate coverage and
measures the true compute/transfer intersection. The player consumes that profile
and existing playback position, using a trailing eight-cycle window and one-second
gain smoothing. Only windows containing actual overlap allow both activity targets;
sequential activity selects its dominant voice. Soft release tails remain musical
presentation, not an exact resource indicator. UI numbers/timeline remain authority.
Seek resets envelopes. Pause/end/stale results fade; focus loss/exit stop immediately.
Players belong to scenes; repeated runs reuse one player. Pitch is independent of
playback speed. No hit/miss beep, simulation callback, new global event bus or judgement.

Three small generated four-second harmonic loops are placeholder pads, not finished
music or a claim of listener comfort. The [listening sample](buffers-preview.wav)
uses the same tones/profile/smoothing at default gain: 28 simulated cycles, 12 cycles
of overlap, 6.2 seconds including fade, absolute peak 0.01854. `preview.gd` reproduces
it on an isolated project. No third-party audio assets are included.

Verification:

- `test_trace_ambience`: merged intervals, real overlap-metric agreement, copied
  evidence, seek/pause/focus/mute/cleanup, actual System and Overlap scene integration,
  single-player reuse, stale/empty trace paths and unchanged Trace/receipt signatures.
- `test_system_lab_ui`, `test_overlap_ui`: existing progression/playback/editing pass.
- `test_prelaunch_settings`: independent audio preference persistence, actual bus
  mute, reset and unchanged progression; existing bilingual bounds/focus checks pass.
- `test_localization`: both catalogs pass.
- Normal macOS audio/rendering backend execution of the ambience suite passes without
  resource warnings. This is automated backend coverage, not human/native mouse play.
- `capture.gd`: both languages render at 1280×720; controls remain within the scroll
  viewport, with fixed close action. English image visually inspected.

Run conventional suites through `scripts/verify-project.py --godot <Godot 4.7.1>`
with repeatable `--suite` arguments. Run this directory's capture/preview helpers on
that isolated project. Final logs and rendered output are retained here.

Earlier diagnostics: one new test used exact float equality; corrected to approximate
comparison. Headless has no audio mixer and left started WAV playbacks awaiting cleanup;
that mode now tests the same envelope without starting streams. Normal backend testing
separately exercises actual playback. Subjective earphone/speaker comfort, longer listening
sessions and final soundtrack quality remain unverified; keep the prototype optional.
