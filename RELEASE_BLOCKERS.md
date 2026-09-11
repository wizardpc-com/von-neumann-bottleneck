# Release blockers

Current scope and artifact pointer: [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md).
These are acceptance gates, not promised new features.

| Gate | Status | Required evidence |
| --- | --- | --- |
| Frozen candidate identity | In verification | Same source/build ID in game, project, archive and all manifests/notes; Mac/Windows from that commit |
| Latest Windows native | **Pending** | Actual EXE start, tree/Continue, editing, keyboard/focus, DPI, save/restart |
| Another Mac install | **Pending** | Download/unzip/first launch and save; signature/notarization decision and clean-machine checks |
| External beginner play | **Pending** | Unassisted entry, Tutorial, branch selection, Hint understanding and concrete feedback |
| Remaining window/focus | **Pending** | Small display, Retina/mixed DPI, repeated focus loss during palette/wire drags, long sessions |
| Public distribution | **Not authorized** | Owner chooses channel and validates installation/support/privacy information |

No server, purchase, account or store submission is required for offline internal
QA. Public remote sharing has its own owner deployment checklist. Automatic suites
and agent native observations do not close external gates.
