# Continuous edit focus follow-up — 2026-10-09

Current runtime `f90597bf999a9fa09b08ac89fa0b4512f5835de6`. Root/worker continued
from e486 availability repair after a concrete target-engine probe showed RLE
activation disabled itself, cleared focus, and next Tab restarted at Language.
`find_next_valid_focus()` from that disabled control correctly found Undo.
Both probe outputs retained; no native-input claim.

Disable synchronization now remembers prior focus and defers continuation until
all action states settle. It continues only for an existing, visible, still-disabled
origin when no other control has taken focus. WeakRef avoids a freed rebuild origin.
Undo/Redo prefers its enabled reverse operation; other actions follow Godot's next
valid control. Hidden/disabled targets are refused. No automatic action/run,
geometry, simulation, model, save schema or gate changes.

First continuation version failed one assertion headless/rendered: Redo followed
the ordinary chain to Run instead of Undo. Its full logs/results retained. Edit
context39, Service undo96 and commission27 all passed at that version. The final
change explicitly keeps Undo/Redo continuation within the history pair and extends
the focused fixture to both hosts, including unchanged measured records/supports/
unlocked state. Final focus22 PASS headless and actual Apple M2/OpenGL rendering,
no errors/warnings. Only affected focused cases rerun after this small final change.
Initial e486 seven-suite354 result remains separately attributed in the parent.

Imported QA project reused; three scripts copied in. Headless/rendered use separate
QA directories. Final focused runs reuse their immediately preceding failed focused
case directories; these hosts are nonpersistent fresh scene fixtures, with no saved
candidate drafts/supports loaded. This does not establish save/restart. Exact commands,
data-directory names and source hashes in continuation-results.json/continuation-final.py.
Three scripts equal QA copy, final runtime commit and exported source.

Matching internal Mac `build/free-alpha-f90597bf999a/macOS/Von-Neumann-Bottleneck.app`,
isolated profile `Continuity-f90597b`, Creation journey enabled. Import/licenses/
export passed; full logs retained. Identity verifier passed; strict/deep codesign
exit0; actual copied binary/PCK unchanged, all16 binary checks true. ZIP78,567,825B
SHA256 `02d412d5f9f30d799d2d5183f528692a4b9635f095565c87f2e7631826a5c9e8`.
Official4.7.1 matching template/original resources; embedded text-server/ICU advisory
retained, raw license blankEOF preserved. This candidate supersedes e486's incomplete
continuation behavior. No identical package rebuild was done.

After package QA terminal, CUA attempted this exact app: Mac still locked/automatic
unlock unavailable. Native interaction NOT_RUN; earlier f144/ade native evidence
is not promoted to this runtime. Wider Representation2–5/Service/original40 and
independent beginner/artistic/listening/device/Windows/distribution acceptance remain
open. Goal active; root sole Git/engine, worker files released, originalfour untouched.
No main merge/public release or production profile access.

Build: `python3 scripts/build-free-candidate.py --godot /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit f90597b --platform macOS --mac-template /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Continuity-f90597b --creation-journey`.
Identity: `python3 scripts/check-candidate-identity.py build/free-alpha-f90597bf999a`.
Signature: `codesign --verify --deep --strict build/free-alpha-f90597bf999a/macOS/Von-Neumann-Bottleneck.app`.
Binary: `python3 scripts/verify-mac-candidate.py --app build/free-alpha-f90597bf999a/macOS/Von-Neumann-Bottleneck.app`.
