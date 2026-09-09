# Approved save recovery — Mac, 2026-09-08–09

Baseline: 1948def. Godot 4.7.1.stable.official.a13da4feb, Apple M2,
OpenGL 4.1 Metal 90.5. This repairs the restart defect discovered in the
[full ordinary Game player pass](../2026-09-08-full-player/README.md).
The user approved preserving originals, stabilizing signatures and recovering
only independently reverified circuits. See [ADR 0020](../../decisions/0020-stable-signatures-and-verified-legacy-recovery.md).

## Native player evidence

Copied only our previous native QA session's global save, fallback and workbenches
from `VonNeumannBottleneckChecks/full-player-20260908` to the separate
`VonNeumannBottleneckChecks/save-recovery-20260908` user directory. These contain
actual manually built circuits and 9+5+7 earned completions. Actual user saves were
not read or modified. The QA app runs the ordinary hub without Test mode, reference
loading or progress setters. A QA-only observer writes viewport captures and reads
counts/notice state; it does not alter game state. Runtime source hashes match the
isolated tested copy and checkout. The displayed historical QA build label is not
the source identity; use the recorded hashes.

First startup revalidated all 21 completions and reported successful recovery with
backup paths. Computer use clicked Continue into Chapter 2, inspected all seven
completed nodes, entered the hardware map with all nine completed nodes, opened
the original Half Adder default and ran all four formal cases successfully. The
original 12-wire gate design was present. It then opened the 19-wire CPU default
and ran the complete seven-step formal program successfully, ending ACC=7/MEM=3.
No rewiring, reference loading or resealing was needed to recover progress.

Computer use quit the QA game normally with Command-Q; the process exited 0.
The app-control observer subsequently opened its empty project manager, which was
closed. A second ordinary Game process was launched against the same QA directory.
Continue remained enabled, no migration notice repeated, Chapter 2 still showed
all seven completed nodes and Chapter 1 showed all five completed nodes. File
checks show identical complete Game manifests before/after restart, retained
workbench topology/layout/colors/names after both construction visits, and unchanged
original backup hashes.

Screenshots were observed through computer use; durable images below are matching
read-only viewport captures. During the overnight desktop lock, native actions
paused. After the user continued on Sep 9, fullscreen/windowed switching restored
usable current screenshots. CUA still occasionally loses fullscreen window lookup;
this run does not establish that tooling/window issue is fixed.

- [Recovery notice](recovery-hub.png), [recovered hardware map](recovered-hardware.png), [recovered Chapter 2](recovered-chapter2.png).
- [Half Adder formal pass](half-adder-reverified.png), [CPU seven-step formal pass](cpu-reverified.png).
- [Second startup without repeated notice](second-start-hub.png), [Chapter 2 after restart](second-start-chapter2.png), [Chapter 1 after restart](second-start-chapter1.png).
- [Original input hashes](native-input-hashes.json), [byte-exact backup checks](native-backup-checks.json), [second-start equality checks](native-second-start-checks.json).
- Native logs: [first](save-recovery-first.txt), [second](save-recovery-second.txt). Neither contains engine/script errors.

## Automated evidence, separate from native play

Fresh isolated run `.godot/verification/20260908T142245Z-83be88e2` passes import,
user-directory isolation, all 21 conventional suites and Chinese ordinary Game
input replay **593/0**. [Results](automated-results.json), [migration suite](test_save_signature_migration.txt), [Game replay](game_gui_zh_CN.txt).
An earlier diagnostic run failed while developing the fixture and integral-JSON
normalization; it remains in `.godot` and is not represented as a passing run.

`verify-save-restart.py` then ran a legacy writer, migration reader and stable
reader as three separate Godot processes, all exit 0/PASS with the same stable
library digest. Those synthetic fixtures intentionally set chapter progress and
are not player completion evidence. They verify legacy ordering/nested lineage,
reconstruction and idempotence. The conventional migration suite also checks
invalid official circuits, different identities, missing sources, forged embedded
bindings, independent-branch survival, global backup conflict, unknown global
signature revision, interruption after workbench upgrade, named layout/color
preservation and one-time seed adoption followed by real seed reset.

[Three-process results](separate-process-results.json) and [244 matching source hashes](verified-source-hashes.json).

## Limits

This increment changes identity/recovery, not level content, prerequisites,
simulation or DSL receipts. It adds localized hub recovery status. The complete
native campaign pass belongs to the earlier source baseline; this increment's
native evidence is recovery/continuation plus Half Adder and CPU formal reruns.
Windows runtime/export, physical trackpad behavior and first-time human beginner
acceptance were not performed. No release acceptance is claimed. Earlier UI,
width notation and shortcut/Retina evidence remain in their own iteration records.
