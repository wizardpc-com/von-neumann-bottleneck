# 0016 — Bounded system-performance domain after the prologue

## Status

Accepted for the Chapter 1 prototype on 2026-08-19.

## Context

The gate campaign evaluates player-built one-/four-bit circuits, while the preserved locality prototype owns a Cache-specific 4×4 workload and cost model. Chapter 1 needs an 8-bit CPU/RAM/Bus performance investigation, player provenance, editable programs, visible topology, and trace-derived progression. Widening every prologue component or generalizing the Cache simulator would couple unrelated mechanics before either design has earned a universal abstraction.

## Decision

Chapter 1 uses a separate bounded `src/system_lab/` domain:

- opaque CPU8 and RAM64x8 parts retain source signatures derived from verified prologue rewards;
- one CPU, Bus, and RAM expose six typed request/write/read routes;
- the displayed routes and selected part specifications are authoritative;
- a small Python-shaped parser produces deterministic instructions;
- `SystemSimulationCore` executes sequential requests with authored CPU/RAM/Bus cycle ownership;
- complete `SystemTrace` objects are aggregated into immutable evidence receipts; and
- progression and final diagnosis read those receipts rather than UI state or playback.

The existing circuit and locality simulators remain unchanged in purpose. Shared UI helpers are reused only where their semantics already match, such as floating windows and fullscreen control.

## Consequences

- Simulation remains deterministic, geometry-independent, and independent from animation.
- Chapter 1 can validate latency/bottleneck play without a speculative HDL, arbitrary-width circuit rewrite, or universal memory hierarchy.
- Prologue provenance is meaningful but the wrapper does not claim that the four-bit circuit directly implements a production 8-bit CPU.
- Cache, concurrency, arbitration, queues, and later performance mechanisms require explicit future design rather than appearing accidentally in this model.
- If later chapters demonstrate stable shared concepts across domains, extraction can follow measured duplication instead of preceding it.
