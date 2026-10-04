# Storage captions start from the current playback's state

Baseline `fd5585c69963e0bda613156b77d6583bd5cd6f48`, existing
`ray/representation-playloop-20261003` branch. Presentation-only correction;
no simulation, official cases, reusable-component provenance, five-region / 40-task
progression or save-schema changes.

## Native construction and finding

Developer-informed Linux cloud play used Godot `4.7.1.stable.official.a13da4feb`
at 1364×1024. The existing UI-earned Tutorial → arithmetic / Latch profile was
copied into a new isolated directory, preserving the source profile. No reference,
Hint solution, completion setter or injected fixture was used in native play.

This pass built the eight-wire Register, passed five official cases and explicitly
sealed Register1. It built ten-wire RAM, used five debug observations to write 3
and 12 to separate locations, read back 3, overwrite only the first word with 5,
and confirm the second still held 12. All five official RAM cases then passed;
RAM2x4 was explicitly sealed. A 19-wire CPU connected those earned parts, passed
all seven program steps, and was explicitly sealed as TinyComputer. The sealed
LOAD/STORE bridge passed all seven steps and unlocked the following chapter.

During RAM's official restart, the Test Bench reset its initial committed state
to M0=0/M1=0, while the Register4 captions retained the preceding debug values
5/12. Reopening the saved RAM circuit and writing M0=3 reproduced this at 0.5 Hz:
paused on the first official wave, the monitor said M0=0 but the first module
still said Stored Q=3. These two displays disagreed about the same retained state.

## Correction

Playback now initializes persistent register and RAM captions from its supplied
initial runtime state. A reusable latch uses each actual prior output separately;
missing or unknown observations remain unavailable or unknown. The original
captions and storage-monitor values are retained for Replay and Step, independently
of the mutable captions updated by completed state-boundary events. CPU storage
modules share the same path. Live previews and stopped/replaced traces discard
older snapshots; explicit state reset refreshes captions without changing wiring.
TinyComputer's distinct no-boundary playback path is unchanged.

## Verification

The focused bilingual controller suite covers debug → official reset without an
intervening Reset, repeated Replay/Step, nonzero CPU register/RAM state and official
zero-state restart, independent latch outputs (including missing, Z and SHORT),
live-preview replay, reset, and real changing delay state. Fixtures are separate
from native earned progression. The final 150-check suite fails on the baseline runtime with 94 expected
readout assertions (exit 1), and passes on the correction (exit 0).

The full isolated run `20261004T212723Z-f34512a0` passed all 68 conventional
suites plus import and user-directory isolation (70 stages). A later test-only
refinement made the delay fixture assert a real 0→3 output change; that final
150-check suite passed again in `20261004T212950Z-23f55682`. Runtime SHA-256 matches
the full-suite copy and the native QA copy. All five Python CI commands and
isolated normal / Test / reset startup smokes passed. Independent read-only
review found no blocker. `git diff --check` passed.

Initial local attempts are not acceptance evidence: one import lacked writable
XDG directories, then the new test fixture needed explicit typed arrays, deferred
scene/scroll barriers, and full storage parts for the blank delay board. All final
runs use isolated writable directories and the corrected fixture.

## Native recheck

The fixed runtime reopened the same earned profile and preserved its complete
RAM circuit, CPU/bridge completion, and following-chapter unlock. In English,
writing 3 then 5 and restarting with Step restored M0=3 in both the monitor and
Register4 caption. Restarting official cases at 0.5 Hz and pausing on the first
wave showed M0=0/M1=0 in both places, correcting the reproduced mismatch.
All five official RAM cases then passed again. A Chinese language reload preserved
the same circuit and repeated the paused debug → official reset check with matching,
readable captions. Both owned QA sessions were closed through Quit Game; their
windows were confirmed absent. The original copied-from profile remains byte-identical.

## Limits

Screenshots were inspected through native computer-use history. This is informed
Linux source QA, not novice comprehension, Windows/macOS, exported-package,
HiDPI or audio acceptance. Native logs retain the environment's unsupported
V-Sync and ALSA→Dummy warnings. No merge, release or deployment.
