# Five-chapter free alpha implementation

2026-09-10. Adopted specification: [downloaded development plan](../../design/FIVE_CHAPTER_FREE_ALPHA_DEVELOPMENT_PLAN.md). Baseline `24d5c22`. The original downloaded Markdown and prompt at repository root are user files and remain untouched. Existing commit/push authorization continues; public deployment, payment, identity submission and release are excluded.

## Scope / invariants

Complete M0–M5: six layout tasks; five-region map; existing 34-task/input review; v2 operation/feedback coverage; optional remote client and loopback server integration; reproducible free candidate packages and distribution documents. M1's first two tasks are a playable checkpoint, not a stopping boundary. After this scope, converge on polishing rather than another chapter.

Preserve existing simulator semantics, official old cases/prerequisites, named schemes and save provenance; zero-latency ordinary wires, free construction and transactional edits, floating tools, independently confirmed read-only hints. The layout domain owns its explicit logical-to-physical mapping, reads, writes, capacity and cost; no score lookup by recipe name. UI and playback only inspect authoritative traces. Existing telemetry is observational. Default upload off; no historical player data in integration tests or public repository.

## Files / stages

- M0: current docs/checks and old QA recovery diagnosis; retain baseline evidence. Read `AGENTS`, `PLANS`, architecture/testing/handoff and both supplied files. Baseline GUI replay underway.
- M1: `src/layout_chapter/` recipe, memory and run model; independent oracle; first two tasks and floating layout editor; existing hub/navigation and save integration. Check real address/flow reversal and alternate recipes in Game.
- M2: remaining four tasks, explicit conversion/batch constraints, measured targets and alternatives, named solution restore, independent H1–H3 and diagrams.
- M3: extend `TaskNavigation` / canvas metadata and semantic zoom; teaching cards for 40 nodes; fix actual old input/window/feedback failures.
- M4: extend current `playtest` transaction counters and task ratings/report; optional upload queue and `server/` loopback HTTP/SQLite receiver, bounded retry/dedup/withdrawal/retention and private report. No cloud deployment.
- M5: full current suites, CN/EN input replay, native computer-use, cross-process saves; build Mac/Windows candidates from one commit with manifests and honest support limits; update public-alpha docs and Steam preparation.

## Model decisions to implement and calibrate

Four fields, 4-byte nonnegative bounded integers, up to 64 records; exact integer sum / ordered record output. Groups partition all logical fields, ordered within each group, record/field expansion and finite record blocks; group bases align to 16 B and tail blocks keep all records. Ordinary initialization is free only in native-layout tasks 4-1–3. Runtime tasks import immutable record-major source; selected fields may be copied to an actual bounded scratch allocation.

A single sequential memory path: fully associative two-line LRU, 16 B lines, cold each case, lookup 1 cycle, RAM line fill 12 service + 4 transfer cycles; write-through/no-write-allocate 4 B stores cost 9 cycles and update any resident line. Source/target share cache throughout a case. Copies use real source reads + target stores; uninitialized read/out-of-bounds fail. Query arithmetic and final output each cost 1 cycle per operation. Scratch allocation/free has no invented timing benefit and releases associated cached lines; peak includes group padding. Runtime conversion/query cannot overlap.

Recipe, policy, input/case/model versions bind receipts; geometry and view speed do not. Targets selected only after actual engine enumeration. Independent Python address/cost oracle checks selected traces, not used at runtime. Native comparison cases include sparse record queries, hot/cold fields, single/repeated orders, a non-divisible tail and at least two valid strategy structures.

## Evidence / open items

Prior 24-suite totals and parity native completion are historical only. Previous Chinese replay had 4 failures from coordinates covered by the default toolbox; its fix needs fresh replay. One old QA CPU design failed restoration; analyze read-only, never loosen validation. Windows execution depends on available actual environment. Newbie comprehension cannot be inferred from tests or agent operation.

References checked this run: Intel memory layout transformations (access-pattern tradeoffs and copy cost); OWASP REST security (receiver bounds/access); Steamworks Playtest (free testing and separate public release). These guide implementation, not gameplay performance constants or a legal conclusion.

## M1 checkpoint update

M0 baseline: 24 suites and Chinese ordinary Game 602/602 checks passed. M1 native Game 4-1 and 4-2 completed with player-created non-reference recipes; see [actual evidence](../../verification/20260910-five-chapter/README.md). Fixed native drag release, emitting-widget lifetime and JSON-restored integer field IDs. Six-task catalog/model/UI scaffolding is present, but M2 native completion and M3–M5 remain open. Do not stop at this checkpoint.

## M2–M4 update, 2026-09-11

M2 all six tasks earned in native ordinary Game, with distinct non-reference layouts and full/batched alternatives; committed `a4cbb98`. M3 current task tree is a true prerequisite DAG with automatic task/region layout, full selected details and compact overview, plus first-use/trace/manual/feedback visual fixes. Forty-task playability review separates new native observations from historical and still-open human evidence. M4 optional transport, loopback receiver and private report are implemented; synthetic cross-process integration, transactional counts and revised/absent ratings pass. Latest all-suite/English Game run and three-process migration pass. See the verification record for exact identifiers and remaining gates.

M5 proceeds with same-commit Mac/Windows candidates, default Game/offline behavior, licenses/manifests and distribution notes. Native final artifact checks remain separate from export success. No further chapter or platform service is being added.

## Candidate checkpoint / convergence queue

M5 candidate content frozen at `435d10f`, Mac and Windows archives with licenses/hash manifests delivered locally. Mac actual release binary and source-native full six-task/old representative checks passed within their documented scopes. Full candidate-native walkthrough, focus/Retina minimum-window follow-up, Windows execution and external novice acceptance remain open; see the exact evidence. CUA candidate input was handed back when user-interaction guards appeared. This plan remains active for that bounded convergence queue; no sixth chapter or remote deployment is authorized implicitly.
