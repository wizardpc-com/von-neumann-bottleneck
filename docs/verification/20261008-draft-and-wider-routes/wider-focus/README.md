# Representation and Service keyboard availability — 2026-10-09

Current runtime `f90597bf999a`: [continuous-focus follow-up](continuation/README.md),
including a later discovered Tab restart and retained failing test.

Initial availability runtime `e48689f7edc7d3f5c0c10ae303bef1e442ec0f9c`, development branch
`codex/mac-second-act-20261005`. Godot `4.7.1.stable.official.a13da4feb`, original
resources and official matching Mac template. Root sole Git/Godot/native runner;
Sol worker owned region.gd, lab.gd and new test, then released them for integration.
The four pre-existing collaborator files were not staged, rewritten or committed.

## Concrete finding and repair

Previous native ade/Redo observation reached disabled Representation Region Review
through Tab. Source inspection confirms its disabled flag did not remove it from
Godot's focus chain. The same pattern covered Service review/locked tasks and other
unavailable edit/history/replay actions in both workbenches. Existing enablement
conditions are preserved; their updates now synchronize disabled and focus mode.
Unavailable actions leave the Tab chain and release stale focus. Available actions
retain/restore normal focus capability. No process loop or model/schema/gate change.

Integration review found that refreshing ServiceNext or commission Ack could briefly
set disabled=true before restoring an enabled state, which with the new focus policy
would unnecessarily clear legal focus. Both now apply their final state once; Ack's
unavailable early-return branches still disable it. Existing action callbacks unchanged.

## Verification

Fresh isolated import and data-directory probe PASS; seven distinct suites PASS:

| Suite | Checks |
| --- | ---: |
| candidate_disabled_focus | 18 |
| completion_service_clarity | 94 |
| representation_closure_navigation | 50 |
| representation_edit_context | 39 |
| service_commission_ui | 27 |
| service_split_actions | 30 |
| service_undo_context | 96 |

Total354 checks. Full logs/results retained. New focus suite also ran once with
actual Apple M2/OpenGL rendering,18 PASS, no script error or warning. No geometry
changes or repeated captures/baseline. Three source/test hashes match the imported
QA copy, exact committed runtime and exported source copy.

Focused script dispatches real viewport Tab/Enter: incomplete reviews skipped,
locked Service tasks skipped, Raw disabled→enabled→Tab reachable→Enter disables
and releases it, actual accepted Task1 run unlocks Task2, enabled Next retains focus
through refresh. Five Representation support plans and Service closure plans are
explicit validated fixtures, not native earned outcomes. Fixture-enabled reviews
become reachable through Tab; this does not establish natural discovery/comfort.
Neighbor suites retain protected records, edit history, split behavior, commission
acceptance and departure/save safeguards. No simulation change calls for a new
model baseline; these scopes do not prove every game requirement.

## Package and native boundary

Matching internal Mac `build/free-alpha-e48689f7edc7/macOS/Von-Neumann-Bottleneck.app`,
profile `Wider-e48689f`, Creation journey enabled. Import/licenses/export PASS; full
raw logs retained. Source identity/archive hashes verifier PASS; strict/deep codesign
exit0; actual copied release binary/PCK unchanged and all16 boundary checks true.
ZIP78,566,200B SHA256 `684f0e001476399c36d9c585f90f7c9ba4f47e5339df0ac303021a627cef84fa`.
Export retains embedded editor text-server/ICU advisory; official matching template
was used. Raw license log retains blank EOF line; whitespace check reports that
one original log issue, exact raw bytes preserved.

At turn start, CUA attempted the exact existing ade app to continue its saved native
Representation task1. It reported Mac locked/automatic unlock unavailable. No new
native input or wider earned route occurred. Subsequent escalated process inventory
found no Godot/game process, then isolated engine jobs ran serially. This new package
has no native acceptance claim. Prior f144 native focus navigation and ade C/P/G/
saved-work/restart/Representation1 observations remain separately attributed:
[previous focus checkpoint](../keyboard-focus/README.md),
[native creation journey](../native-resume/README.md).

## Exact commands

`python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_candidate_disabled_focus --suite test_representation_closure_navigation --suite test_representation_edit_context --suite test_service_undo_context --suite test_service_split_actions --suite test_service_commission_ui --suite test_completion_service_clarity`.

Renderer command and distinct isolated data directory in `rendered-disabled-focus.json`;
only the QA copy's two documented isolation settings changed between runs.

`python3 scripts/build-free-candidate.py --godot /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit e48689f --platform macOS --mac-template /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Wider-e48689f --creation-journey`.

`python3 scripts/check-candidate-identity.py build/free-alpha-e48689f7edc7`.
`codesign --verify --deep --strict build/free-alpha-e48689f7edc7/macOS/Von-Neumann-Bottleneck.app`.
`python3 scripts/verify-mac-candidate.py --app build/free-alpha-e48689f7edc7/macOS/Von-Neumann-Bottleneck.app`.

Whole-game goal remains active. Native Representation2–5/ending/save/reopen and
Service/original40, independent beginner/listening/artistic/device/Windows and formal
distribution acceptance remain unproven. When Mac is available, continue wider
native routes and repair actual findings. No main merge/public release or production
profile access. Do not repeat the same automatic suites simply to substitute for
missing native/human evidence.
