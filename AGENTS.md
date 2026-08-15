# AGENTS.md

## Project

This repository is a disposable vertical-slice prototype for the game **Von Neumann Bottleneck**.

Its current purpose is to validate the core gameplay loop, not to build the full game.

Read the user-provided conversation for product context, but do not implement features outside the current milestone.

## Tech stack

* Godot 4.7.1 stable
* Strongly typed GDScript
* 2D/UI-first
* Prefer built-in Godot functionality over external addons or dependencies.

## Architecture rules

* Keep `SimulationCore` independent from rendering and UI.
* Simulation must be deterministic and reproducible.
* Rendering and animation must never change simulation results.
* Generate a `SimulationTrace` from the simulation, then let the UI play that trace.
* Ordinary wires have zero simulation latency.
* Wires describe connectivity only.
* Bandwidth, latency, queuing, and transfer cost belong to components such as Bus, Cache, and RAM.
* Cache is hardware-managed. The player must never manually insert data into Cache.
* Keep game rules/data separate from presentation where practical.
* Prefer clear, simple implementations over premature abstraction.

## Current milestone

Only implement the 4×4 cache-locality vertical slice described in the task prompt.

The prototype should validate:

1. visual hardware wiring;
2. minimal player-written program logic;
3. deterministic memory/cache simulation;
4. readable data-flow animation;
5. useful performance profiling;
6. a clear performance difference between row-first and column-first traversal.

Do not implement future systems unless they are strictly required by this slice.

## Explicitly out of scope

Do not add:

* gate-level CPU construction;
* multi-level caches;
* multicore or GPU systems;
* compression;
* blocking/tiling chapters;
* energy simulation;
* leaderboard;
* progression systems;
* full save/version-management UI;
* procedural/random challenge generation;
* polished art pipelines;
* a general-purpose programming language.

## DSL

The prototype DSL should implement only what this experiment requires.

Do not build a general parser/compiler architecture unless necessary.

Keep explicit the operations that matter to the game:

* registers;
* load;
* store;
* compute/add;
* loop order;
* array indexing.

Hide irrelevant machine-level details such as opcodes, instruction encoding, calling conventions, and stack management.

## Verification

After changing simulation behavior:

* run the relevant automated/headless tests;
* confirm identical inputs produce identical traces/results;
* verify the official row-first solution causes substantially fewer cache misses and cycles than the default column-first solution;
* confirm UI playback does not affect simulation outputs.

Before finishing a task, review the diff for accidental scope expansion.

## Working style

* Make reasonable implementation decisions autonomously.
* Do not stop for minor design questions if a simple reversible choice is available.
* Document important temporary assumptions in `README.md`.
* Do not modify files outside this workspace.
* Do not replace the chosen engine or language.
* When something is intentionally simplified for the prototype, prefer an explicit simplification over fake realism.
