# Final audit and Claude handoff

Goal: reproduce remaining navigation/input failures, fix concrete bugs, verify the final component/lab/mode/CG/save boundaries, and provide a current Claude handoff with the game map and acceptance limits.

Scope: focused bug fixes and useful local verification; update the stale shared task entry and durable handoff. Keep the user's current visual reference, real port/model/provenance/save contracts and Game/Test isolation. No speculative redesign, public Release or game window. Root owns Git/Godot and affected files; auxiliary review is read-only.

Steps: inspect live main and authority; reproduce the two historically failing cross-scene lab tests; review modal and CG input/lifecycle; implement the smallest proven corrections and regression checks; run relevant isolated suites; document changes, current 60-task game, code entrypoints, outstanding visual/content work, package/source identities and exact next steps. Refresh the user-authorized main delivery if runtime changes require it.

Baseline: clean main 6dae9ec; prior package source 597813e, ModeDebug20261023 ZIP. Previous twenty relevant suites and actual exported mode/CG checks passed; cross-scene lab failures remained separately recorded and native audiovisual acceptance remained deferred.

2026-10-23 complete: three runtime corrections cover Layout Escape before native tooltip handling, CG/autosave recovery ordering, and interactive nested rescue export. Twenty-eight relevant Godot suites plus import/isolation have passing latest results; CG/recovery37, navigation39 and language65. Fixed source commit1479c452bd1d954a2b5d4012935d0c5f158b0363 produced a new ZIP whose actual release EXE passes mode14, CG/recovery37 and navigation39 headlessly; archive/PE/PCK and identity checks pass. ZIP115818327 bytes SHA25690826c91a01ea80ff1a6b57f6ad56f2098ae82668045f2e2b3cddb3358e2ded8. Full evidence docs/verification/20261023-final-audit/README.md.

Claude handoff and shared task entry cover current content, code map, invariants, concrete follow-up UI/content work and short prompt. Native rendering/input/audio acceptance remains deferred; no all-bugs-cleared or full-regression claim. The user-authorized main synchronization includes only documentation after the frozen runtime commit.
