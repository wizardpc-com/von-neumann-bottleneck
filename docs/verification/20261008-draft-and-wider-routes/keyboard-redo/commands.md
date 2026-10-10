# Exact commands and isolated run provenance

Root-only serial engines from repository root:

```sh
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_chapter_redo_shortcuts --suite test_overlap_ui --suite test_layout_ui --suite test_layout_navigation --suite test_layout_recipe_sources --suite test_desktop_conventions
python3 .godot/verification/20261008T212445Z-5398544c/redo-final.py
python3 scripts/build-free-candidate.py --godot /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit ade587d --platform macOS --mac-template /Users/ray/Documents/von-neumann-bottleneck/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Redo-ade587d --creation-journey
python3 scripts/check-candidate-identity.py build/free-alpha-ade587d50e02
codesign --verify --deep --strict build/free-alpha-ade587d50e02/macOS/Von-Neumann-Bottleneck.app
python3 scripts/verify-mac-candidate.py --app build/free-alpha-ade587d50e02/macOS/Von-Neumann-Bottleneck.app
```

Initial verifier imports and isolates then completes all six suites. Only the new
shortcut suite fails due to test CtrlZ/Meta mismatch. Corrected test copied into
same imported project; final runner uses two unique profiles, no repeated import.
checks/redo-final.py is a provenance copy requiring its original .godot location
for root resolution. Full final commands/profiles in redo-final-results.json.
Export is the frozen git archive, not working-tree data. Binary check uses
unchanged copied binary/pack under production-denying sandbox; identity and codesign
actual exit0 results are manually recorded. No production player files copied.
