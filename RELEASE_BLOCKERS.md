# Release blockers

Current scope and artifact pointer: [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md).
These are acceptance gates, not promised new features.

| Gate | Status | Required evidence |
| --- | --- | --- |
| Frozen candidate identity | **Verified** | `free-alpha-47a59d385103`, content `47a59d3`; both archives and actual Mac release identity checked |
| Latest Windows native | **Pending** | Actual EXE start, tree/Continue, editing, keyboard/focus, DPI, save/restart |
| Another Mac install | **Pending** | Download/unzip/first launch and save; signature/notarization decision and clean-machine checks |
| External beginner play | **Pending** | Unassisted entry, Tutorial, branch selection, Hint understanding and concrete feedback |
| Candidate mouse navigation | **Verified (this Mac)** | Actual candidate binary/PCK in an isolated QA copy: mouse tree pan/zoom/entry, palette drag, wires/delete/undo, Tutorial completion and restart/Continue; [evidence](docs/verification/20260913-spatial-candidate/README.md). Earlier noWindowsAvailable is historical. |
| Final reset-dialog visual recheck | **Verified (source native)** | English/Chinese title/body and final localized buttons inspected; reset restored defaults, cancel and export Tab navigation operated |
| Remaining window/focus | **Pending** | Source-native tree pan, CPU Hint return and resized Chapter 1 time display checked on this Mac; extended small-display/Retina/mixed-DPI sessions and repeated focus loss during palette/wire drags still pending |
| Public distribution | **Not authorized** | Owner chooses channel and validates installation/support/privacy information |

No server, purchase, account or store submission is required for offline internal
QA. Public remote sharing has its own owner deployment checklist. Automatic suites
and agent native observations do not close external gates.
