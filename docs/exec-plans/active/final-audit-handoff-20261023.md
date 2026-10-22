# Final audit and Claude handoff

Goal: reproduce remaining navigation/input failures, fix concrete bugs, verify the final component/lab/mode/CG/save boundaries, and provide a current Claude handoff with the game map and acceptance limits.

Scope: focused bug fixes and useful local verification; update the stale shared task entry and durable handoff. Keep the user's current visual reference, real port/model/provenance/save contracts and Game/Test isolation. No speculative redesign, public Release or game window. Root owns Git/Godot and affected files; auxiliary review is read-only.

Steps: inspect live main and authority; reproduce the two historically failing cross-scene lab tests; review modal and CG input/lifecycle; implement the smallest proven corrections and regression checks; run relevant isolated suites; document changes, current 60-task game, code entrypoints, outstanding visual/content work, package/source identities and exact next steps. Refresh the user-authorized main delivery if runtime changes require it.

Baseline: clean main 6dae9ec; prior package source 597813e, ModeDebug20261023 ZIP. Previous twenty relevant suites and actual exported mode/CG checks passed; cross-scene lab failures remained separately recorded and native audiovisual acceptance remained deferred.
