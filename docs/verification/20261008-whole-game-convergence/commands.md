# Recorded commands

From the repository, with engine
`.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot` (shown as `$ENGINE`
below). All Godot runs were serial and fresh profiles remained under
`VonNeumannBottleneckChecks/`; never run renderer fixtures in production userdata.

```sh
python3 scripts/verify-project.py --godot "$ENGINE"
python3 scripts/verify-project.py --godot "$ENGINE" --suite test_creation_writer_retry --suite test_creation_writer_retry_ui --suite test_creation_observation_focus --suite test_workbench_write_failure --suite test_creation_contract --suite test_creation_workbench --suite test_creation_state_regressions --suite test_creation_route_flow --suite test_creation_evidence_identity --suite test_creation_playable_loop --suite test_hardware_foundations_ui --suite test_hardware_prologue_ui --suite test_save_signature_migration
python3 scripts/verify-project.py --godot "$ENGINE" --suite test_creation_writer_retry_ui --suite test_creation_observation_focus --suite test_workbench_write_failure --suite test_creation_workbench --suite test_creation_prediction_flow --suite test_creation_evidence_reading
python3 scripts/verify-project.py --godot "$ENGINE" --suite test_creation_writer_retry_ui --suite test_workbench_write_failure --gui --locale zh_CN
python3 scripts/verify-project.py --godot "$ENGINE" --suite test_workbench_write_failure --gui --locale zh_CN
python3 scripts/verify-project.py --godot "$ENGINE" --suite test_creation_observation_focus --gui --locale en
python3 scripts/verify-creation-restart.py --godot "$ENGINE" --project .godot/verification/20261008T184627Z-aa0751a1/project
python3 scripts/build-free-candidate.py --godot "$ENGINE" --commit 563acb8 --platform macOS --mac-template "$PWD/.godot/tools/godot-4.7.1/export-templates-4.7.1/macos.zip" --second-act-profile Convergence-563acb8 --creation-journey
python3 scripts/check-candidate-identity.py build/free-alpha-563acb805042
python3 scripts/verify-mac-candidate.py --app build/free-alpha-563acb805042/macOS/Von-Neumann-Bottleneck.app
codesign --verify --deep --strict build/free-alpha-563acb805042/macOS/Von-Neumann-Bottleneck.app
```

The repair passes include retained failures; inspect results/README before treating
any command as acceptance. The old failed GUI process was terminated by exact QA
path after its script exception stalled. No unrelated Godot process was stopped.

Rendered C/P/G and writer checks used the already imported b50be1c0 QA project,
updated to the final source scripts. Before each process, its custom user directory
was replaced by a fresh unique `VonNeumannBottleneckChecks/convergence-render-*`
name. Commands then ran the pinned engine with `--path <QA project>` followed by:

```sh
--script tests/test_creation_workbench.gd -- --creation-capture
--script tests/test_creation_writer_retry_ui.gd -- --writer-capture
```

The final writer-only repeat explicitly settles1280×720 and rejects another capture
size. Results JSON records the exact QA names. The local orchestration helpers are
`.godot/convergence-render.py` and `.godot/convergence-writer1280.py`.
Python gates: `scripts/check-branding.py`, `scripts/test-report-playtests.py`,
`server/test_storage.py`, `server/test_receiver.py`, `server/test_community.py`.
Only temporary synthetic receiver/community tests used loopback ports.
