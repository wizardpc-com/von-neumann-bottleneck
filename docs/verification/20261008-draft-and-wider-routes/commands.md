# Commands and identities

All commands were run by root, serially, with pinned original-resource imported
projects. Raw result JSON in routes includes exact engine/project/arguments.
Frozen conventional passes and repair failures are in focused-first and
focused-repair; their results name every suite and isolated QA user directory.

```
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite <each of the 28 affected suite names>
python3 .godot/wider-paths-20261008/run.py
python3 .godot/wider-paths-20261008/run-next.py layout
python3 .godot/wider-paths-20261008/run-next.py layout closeout
python3 .godot/wider-paths-20261008/run-next.py layout restart canonical
python3 .godot/wider-paths-20261008/run-next.py overlap
python3 .godot/wider-paths-20261008/run-next.py overlap restart
python3 .godot/wider-paths-20261008/render-creation.py v3
python3 .godot/wider-paths-20261008/render-creation.py v6 after-workbench
python3 scripts/verify-creation-restart.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --project .godot/verification/20261008T191635Z-60214908/project
python3 .godot/wider-paths-20261008/run-journeys.py representation_region fresh v3
python3 .godot/wider-paths-20261008/run-journeys.py representation_region restart v3
python3 .godot/wider-paths-20261008/run-journeys.py service_plan fresh v3
python3 .godot/wider-paths-20261008/run-journeys.py service_plan restart v3
```

Do not rerun against these stopped/used QA profiles. Create a new own profile and
new evidence directory; preserve actual earned QA origin bytes for branch checks.
The recorded runner scripts are invocation receipts, not reusable production paths.
The core route ran runtime563acb8 plus the new proxy; Layout/Overlap used QA416;
final Creation/Representation/Service used QA602 with released current files copied.
Source-sha256 records each actually verified copy. No final full119-suite repetition
was needed; unrelated core/model source has not changed.

```
python3 scripts/build-free-candidate.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --commit db104d3 --platform macOS --mac-template .godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip --second-act-profile Drafts-db104d3 --creation-journey
python3 scripts/check-candidate-identity.py build/free-alpha-db104d3688d1
codesign --verify --deep --strict build/free-alpha-db104d3688d1/macOS/Von-Neumann-Bottleneck.app
python3 scripts/verify-mac-candidate.py --app build/free-alpha-db104d3688d1/macOS/Von-Neumann-Bottleneck.app
```

Final headless repair uses verify-project.py with exactly test_creation_workbench,
test_creation_measured_closure, test_creation_draft_undo and test_creation_causal_panel.
No engine or GUI was running during final Git integration.
