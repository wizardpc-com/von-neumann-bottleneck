# ADR 0003: explicit program application

- Status: Accepted
- Date: 2026-08-15

## Context

Although Test Bench already executed editor text through the DSL parser, editing, strategy selection, and execution had no explicit confirmation boundary. A player could not clearly distinguish a draft effect from the program that generated the current trace. The small language also lacked an in-context Python-shaped reference and semantic explanation.

## Decision

- Program owns three visible states: editor draft, applied source, and last-executed source.
- Typing or loading the supplied column-first/row-first strategy changes only the draft and invalidates stale trace evidence.
- A valid draft that differs from applied source disables Test Bench and enables Apply Program. Apply is the only transition that replaces `applied_program_source`.
- The column-first starter is applied at startup so the first run remains immediately available.
- Test Bench reparses and executes only applied source. Direct run calls also reject a mismatched draft.
- Traversal/address preview and line-by-line explanation are derived from the parsed draft IR. They do not execute the draft or create another simulation path.
- Last-run receipt records traversal, cycles, misses, and exact applied source ownership.

## Alternatives considered

- Run editor text directly: rejected because a player cannot tell whether an edit has taken effect.
- Apply automatically after validation: rejected because strategy selection would silently change machine behavior.
- Make each strategy button execute immediately: rejected because it bypasses inspection and confirmation.
- Implement general Python parsing: rejected because the prototype needs a teachable subset, not a second language runtime.

## Production animation follow-up

The generic PROCESS orbit remains appropriate for v0.2. Formal production should define component-specific visual profiles—for example CPU decode/ALU motion, Cache tag comparison/fill, Bus relay, RAM row activation/burst, Test Bench comparison, and Profiler sampling. Those profiles must consume the existing presentation intervals, keep only one strong focus, and never change simulated cycles.

## Consequences

- Program changes are confirmable and auditable from draft through measured trace.
- Supplying both strategies no longer creates hidden application behavior.
- More Program content requires scrolling inside its floating instrument.
- Component-specific animation is an explicit future art/interaction task rather than an unscoped v0.2 embellishment.
