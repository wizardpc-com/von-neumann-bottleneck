# Exact scoped commands

From repository root, root-only serial engine ownership:

```sh
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_creation_preparation_binding --suite test_creation_comparison --suite test_creation_cost_ledger --suite test_creation_measured_closure --suite test_creation_workbench --suite test_locality_restored_baseline --suite test_locality_chapter_ui --suite test_hardware_seal_navigation --suite test_hardware_prologue_ui --suite test_workbench_write_failure
python3 .godot/verification/20261008T203804Z-29b9b749/run-render.py
python3 .godot/verification/20261008T203804Z-29b9b749/run-seal-final.py
python3 scripts/build-free-candidate.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit e7894522c40bb26a149101c45e6efc72dccb0a76 --platform macOS --mac-template /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Boundaries-e789452 --creation-journey
python3 scripts/check-candidate-identity.py build/free-alpha-e7894522c40b
codesign --verify --deep --strict build/free-alpha-e7894522c40b/macOS/Von-Neumann-Bottleneck.app
python3 scripts/verify-mac-candidate.py --app build/free-alpha-e7894522c40b/macOS/Von-Neumann-Bottleneck.app
```

The initial verifier imported the current original assets into its own project.
Only the corrected two new tests were copied into that imported project before
final runs; final six-source parity is recorded. The two runner scripts are retained
in checks/ as provenance; their root resolution assumes the original .godot path,
not execution from this documentation directory. Every rerun asserts its unique
QA profile is absent first. Initial failures retained, final runs PASS. Export
uses committed archive and its own QA import/license profiles. Package probe uses
an unchanged copied application and production-denying sandbox.
