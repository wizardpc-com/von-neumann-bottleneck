# Exact scoped commands

Root-only serial engine, from repository root:

```sh
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_creation_prediction_work_view --suite test_creation_workbench --suite test_creation_prediction_flow --suite test_creation_measured_closure --suite test_system_trace_source_binding --suite test_system_cost_evidence --suite test_system_chapter_ui
python3 .godot/verification/20261008T205231Z-4f944f95/run-focused.py
python3 .godot/verification/20261008T205231Z-4f944f95/run-display-final.py
python3 .godot/verification/20261008T205231Z-4f944f95/run-system-fixed.py
python3 scripts/build-free-candidate.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit 7c7f8f06f8e281021f835454251164c7ca334710 --platform macOS --mac-template /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Sources-7c7f8f0 --creation-journey
python3 scripts/check-candidate-identity.py build/free-alpha-7c7f8f06f8e2
codesign --verify --deep --strict build/free-alpha-7c7f8f06f8e2/macOS/Von-Neumann-Bottleneck.app
python3 scripts/verify-mac-candidate.py --app build/free-alpha-7c7f8f06f8e2/macOS/Von-Neumann-Bottleneck.app
```

The first command exited2 on unknown suite after successful import/isolation;
run-focused.py uses the existing test_system_lab_ui. Scripts under checks/ are
provenance copies; their root resolution assumes the original .godot path, not
execution from this documentation directory. Each rerun asserts a new profile
is absent. Corrected test changes/then System runtime copied into the imported
project before affected runs; final four-source parity recorded. Initial insertion
failure is retained alongside the repaired run. Export uses the committed archive
and separate QA import/license profiles. Binary probe uses unchanged copied app,
QA-only settings and production-denying sandbox. No production data was copied.
