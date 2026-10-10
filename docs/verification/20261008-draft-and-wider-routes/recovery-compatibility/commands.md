# Exact serial commands and run provenance

From repository root, root is the only engine/Git runner:

```sh
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_creation_future_workbench --suite test_creation_work_focus --suite test_creation_state_regressions --suite test_creation_workbench --suite test_layout_preview_selection --suite test_layout_trace_storage --suite test_layout_ui --suite test_workbench_interrupted_recovery --suite test_workbench_write_failure --suite test_global_save --suite test_save_signature_migration
.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --headless --path .godot/verification/20261008T211409Z-f89106f7/project --check-only --script res://src/hardware_foundations/circuit_workbench_store.gd
python3 .godot/verification/20261008T211409Z-f89106f7/retry.py
python3 .godot/verification/20261008T211409Z-f89106f7/final.py
python3 scripts/build-free-candidate.py --godot /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit 6027e25 --platform macOS --mac-template /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Recovery-6027e25 --creation-journey
python3 scripts/check-candidate-identity.py build/free-alpha-6027e25626d4
codesign --verify --deep --strict build/free-alpha-6027e25626d4/macOS/Von-Neumann-Bottleneck.app
python3 scripts/verify-mac-candidate.py --app build/free-alpha-6027e25626d4/macOS/Von-Neumann-Bottleneck.app
```

Initial import returned engine0 but script errors, so verifier correctly exited1.
Check-only ran before and after the reserved-name correction; its tool output is
manually described in README, not claimed as a retained raw log. The same imported
QA project received the repaired store and only affected tests, no repeat copy.
retry.py imports after the correction, runs eleven suites and four-view renderer;
final.py reruns only Layout preview/Core/save neighbors with fresh unique profiles.
The runner files in checks/ are provenance copies whose path resolution assumes
original .godot placement. Full per-run commands/profiles appear in result JSON.
Six final scripts are hash-bound to commit and imported copy. Production data was
not copied; export is from git archive and actual binary probe denies production
access. Identity/codesign tool results are manually recorded with their exact exits.
