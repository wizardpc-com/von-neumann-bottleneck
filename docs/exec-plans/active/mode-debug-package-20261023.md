# Game/Test selection and Windows debugging ZIP

Goal: ordinary players can choose Game or Test from the normal UI, including exported builds. Integrate the current component/lab/CG changes into main and supply a Windows ZIP from a fixed source commit, as explicitly authorized by the user.

Scope: mode permission, shared selector/settings, regressions, existing packaging guide and fixed-commit Windows export. Keep Game as startup default, preserve temporary Test libraries and separate Game progression/workspaces; do not enable unrelated developer controls. Retain all earlier pending changes. Correct the cinematic's audio routing to the existing Effects volume bus before distribution.

Steps: inspect mode/save boundaries; expose selectors; verify ordinary UI round trips and progression isolation; run component/CG/mode/save/UI regressions without a game window; review and commit the integrated diff; build using the existing fixed-commit builder and matching Godot 4.7.1 Windows template; inspect actual exported pack and modes headlessly; verify archive inventory/hashes, push main and deliver the ZIP.

Packaging: full sixty-task journey, separate stable ModeDebug20261023 profile, normal Game prerequisites plus explicitly selected Test access, no bundled QA saves and no configured feedback receiver. No public Release. Native graphical/audio acceptance stays deferred under the user's no-window instruction.

2026-10-23: origin/main fetched and matches local main 30a92f8. Root owns Git/Godot and all changes in scope. Existing mode restriction is the free_candidate export guard plus developer-only selector visibility. Existing domain mode callbacks already preserve separate Game/Test workspaces.

Mode selection in settings is limited to the actual laboratory/home. Generic workbench settings retain their existing departure guards; players return home to switch. Hardware and Chapters 1/2 retain supported in-place selectors and their existing mode callbacks. Chapters 3/4 lack such callbacks and dynamically choose the draft namespace, so exposing a generic in-place switch there would cross-contaminate drafts; the home entry avoids that path without adding a new scene lifecycle.
