# Testing

## Verified environment

- Windows PowerShell
- Godot `4.7.1.stable.official.a13da4feb`
- Console executable: `godot_console`

The commands below were run successfully from the repository root after the directory migration.

## Simulation tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-simulation.log' --script res://tests/test_simulation.gd
```

Expected success output:

```text
PASS: all cache-locality simulation tests passed
```

## UI integration tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-ui.log' --script res://tests/test_ui.gd
```

Expected success output:

```text
PASS: UI layout, exact wiring, state invalidation, profiler comparison, and playback tests passed
```

## Project startup smoke check

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/project-smoke.log' --quit-after 5
```

Success is exit code `0` with no project parse/runtime error before the automatic quit.

## Fresh migration evidence

On 2026-08-15, all three commands completed with exit code `0` both before and after the directory rename. Simulation and UI tests printed the success lines above. Each Godot launch also printed `Failed to read the root certificate store` on this Windows environment; it was a pre-existing environment warning and did not change process exit codes or test results.

## What to run after changes

- Simulation/DSL/cost/trace changes: simulation test, UI test, and smoke check.
- UI/wiring/profiler/playback changes: UI test and smoke check; also run the simulation test if trace assumptions changed.
- Godot resource moves: all three commands plus explicit `res://` and UID reference inspection.
- Documentation-only changes: inspect links, paths, whitespace, and the Git diff; runtime tests are optional unless commands or architecture claims changed.

## CI status

There is intentionally no GitHub Actions workflow yet. Local commands are reliable, but exact Godot 4.7.1 provisioning on the selected GitHub runner has not been validated in this repository. Add CI only after the runner installation method is reproducible and the same commands have passed there once; do not configure a required status check before that job exists.
