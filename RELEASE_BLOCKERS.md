# Release blockers

Current scope and artifact pointer: [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md).
These are acceptance gates, not promised new features.

| Gate | Status | Required evidence |
| --- | --- | --- |
| Frozen candidate identity | **Verified** | `free-alpha-80105a7f5ea6`, content `80105a7`; both archives and actual Mac release identity checked |
| Latest Windows native | **Pending** | Actual EXE start, tree/Continue, editing, keyboard/focus, DPI, save/restart |
| Another Mac install | **Pending** | Download/unzip/first launch and save; signature/notarization decision and clean-machine checks |
| External beginner play | **Pending** | Unassisted entry, Tutorial, branch selection, Hint understanding and concrete feedback |
| Candidate mouse navigation | **Pending** | Recheck exported Mac board/Continue with reliable native mouse access; CUA returned noWindowsAvailable, source native route passed |
| Final reset-dialog visual recheck | **Verified (source native)** | English/Chinese title/body and final localized buttons inspected; reset restored defaults, cancel and export Tab navigation operated |
| Remaining window/focus | **Pending** | Small display, Retina/mixed DPI, repeated focus loss during palette/wire drags, long sessions |
| Public distribution | **Not authorized** | Owner chooses channel and validates installation/support/privacy information |

No server, purchase, account or store submission is required for offline internal
QA. Public remote sharing has its own owner deployment checklist. Automatic suites
and agent native observations do not close external gates.
