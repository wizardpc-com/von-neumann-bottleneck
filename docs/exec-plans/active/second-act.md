# Second act framework and isolated playable slices

Baseline: cd17d98, fetched main with zero divergence, 2026-10-02.
User authorizes experiments, targeted fixes, verification and stage commits; no push.

## Scope
Keep all 40 production tasks, gates, legal solutions and save authority. Remove
Capstone's duplicated alternatives section. Build a bounded observation-only policy
separate from its UI actuator; report stalls, do not substitute known solutions.
Develop three connected representation experiments and a hidden inference workload.
No official new chapter, general DSL extension, production save change, lore or audio.

## Model decision before implementation
Production DSL cannot express independent compressed streams or approximate outputs.
Use isolated pure GDScript simulators in experiments/, returning existing
SimulationTrace/SimulationEvent. Explicit synchronous request/transfer/decode/consume
costs, real reversible RLE blocks, counted headers/directory, finite decoded-block
cache and actual decoded outputs. No claimed real hardware timings. Encoding happens
offline for an immutable stored asset and is displayed separately, never hidden in
an online preparation claim. Three tasks: scan; machine/data counterexamples; sparse
access/block size. Optional in-memory experiment progress only; no GlobalSave hooks.
Inference uses a fixed tiny linear classifier, actual rounded weights/output scores,
full-precision labels and absolute score error. Fixed deterministic evaluation set,
weight precision/batch/reuse decisions and finite scratch. No pretrained service,
real intelligence benchmark or neural training claim. Quality is measured, not a knob.

## Files and stages
1. src/ui/main.gd + locality tests: remove duplicate alternatives; retain detailed
   before/after evidence. Read complete conversation/context and record framework.
2. experiments/representation/{model,lab,scene,tests}: real codecs, three stages,
   Trace-driven inspection and actual run comparison. Calibrate before freezing gates.
3. experiments/intelligent_workload/: hidden launch, real numerical model and tests;
   bounded precision/memory/quality and batching counterexamples.
4. experiments/evidence_proxy/: policy receives only visible Mission/Hint1/evidence
   and available UI actions, finite trials, evidence/action journal. No reference
   circuit, solution routines, hidden target results or policy reads of scene objects.
   Actuator/fixture boundary declared; test policy against poisoned secret fields.
5. Actual viewport interaction/captures in isolated QA. Iterate on observed failures.
   Targeted and full regression, docs, disposition, staged commits.

## Acceptance / limits
Check round-trip, exact outputs, deterministic Trace signatures, sum of event costs,
content-sensitive compression, bandwidth/decoder crossover, sparse access and cache
capacity, quality computed from actual inference, memory rejection and batch latency.
UI replay must use controls, not simulation calls masquerading as play. Proxy may
fail to solve; known-answer GUI tests remain separately labelled. Native OS/human
beginner/subjective audio/release validation remain separate and are not presumed.

## Progress
- Current main and repository instructions inspected. Attached conversation and old
  setting are background; latest user scope controls lore and expansion decisions.
- Research anchors: Zstandard independent/seekable frames and Jacob et al. 2018
  integer quantization. These motivate tradeoffs, not our toy cycle constants.
