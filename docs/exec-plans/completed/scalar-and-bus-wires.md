# Separate scalar wires from multi-bit buses

2026-09-08; base 2195862. The user requests clearer separation of 1-bit wires
from wider wires and continued comparison with Turing Complete.

## Scope

Use a thin solid cable / round pin for one bit and a wider ribbon / square socket
for multiple bits. Carry the same shape through settled wiring, connection drafts,
branches, endpoint movement, hovering, trace playback, terminal leads and module
leads. Explain it with samples before building. Preserve freely chosen wire hues.

Only presentation changes: retain the existing GraphEdit path, picking radius,
node positions, connection transactions, simulation, save formats, official cases,
campaign and independent hints. No width auto-conversion, new components or levels.

## Work and verification

1. Inspect actual drawing paths and compare official Turing Complete material.
2. Share the cable style and pin shape; fix drafts that currently ignore width.
3. Verify mixed-width and reverse-input drafts, branches, compatibility, precise
   erase and history in fresh isolated Godot 4.7.1 tests and Game replay.
4. Native Mac mixed-width wiring and zoom/focus review, then commit the verified
   increment. Record native and automated evidence separately.

## Findings and decisions

- Existing 3.5/5.5px difference is slight; all drafts use scalar/fixed widths,
  flow and hover overwrite the distinction, and module leads are all 4px.
- A bus stays one centered curve and one connection. Its dark middle is a ribbon
  marking, not two independently connected wires. Count labels disambiguate 2/4.
- Round/scalar and square/bus pins retain the same 24px texture footprint and
  center, preserving layout, hotzones and original saved coordinates.
- Turing Complete's official July 14 update describes consistent component shapes,
  bigger non-overlapping input pins and hovered pin labels. Its store describes
  learning by constructing progressively and freedom of solutions. We borrow
  consistency and readable interfaces; this ribbon treatment is our own design.

## References

- [Official developer updates](https://steamcommunity.com/app/1444480/announcements/?l=english)
- [Official game description](https://store.steampowered.com/app/1444480/Turing_Complete/)

## Open acceptance

Native testing completed below. Windows and first-time human acceptance remain separate.
Previously pending save migration and optional level decisions stay unresolved.

## Progress

- Shared 3.5px scalar / 8px ribbon strokes now cover settled wires, drafts,
  reverse input drafts, branch/reconnect, network hover and causal playback.
  Module and terminal leads use the same style. Multi-bit pins are hollow squares
  in the original 24px texture canvas; bus routing nodes are square too.
- Added line/pin samples to the existing early width explanation, preserving
  count labels and user-chosen colors. The line explanation is placed first.
- Mixed-width interface tests verify actual input/output widths, square socket
  pixels and footprint. Game replay explicitly starts 1/2/4-bit reverse drafts,
  captures them and cancels without modifying the workbench.
- First run: all 20 suites passed; Chinese replay retained two obsolete presentation
  assertions (English-only "1-bit" and 5.5px buses). Updated these to localized
  width plus direction and the new separated stroke ranges; no gameplay assertion
  removed. Next English replay passed 590 checks with zero failures.
- Native RAM: hand-connected DATA→Register4 data, WRITE→load and Q→OUT. Debug
  output was 3 (0011), with a thin single-bit control cable and ribbon data cables
  in the same player-selected cyan. This partial debug circuit is not an official
  RAM solution. Capture predates the final diagnostic/guide-order follow-up.
- Draft screenshots exposed a pre-existing status bug: drawing compatible-target
  guides repeatedly ran a validator that wrote unrelated errors to the status
  label. Separated read-only compatibility from the actual hovered-port diagnostic.
  Actual invalid connections still use the existing rejection rules.
- Final source passes all 20 suites and 593 ordinary Game checks in each language.
  Native final-source RAM verifies 4→1 rejection, reverse connection, a 4-bit bus
  branch, Command-Z/Command-Shift-Z, decimal text focus, debug output 12/1100,
  91%/150% view framing and fullscreen. Existing player editor/game instances and
  actual player data have not been changed.

## Completion — 2026-09-08

Final source and tests match the isolated and native copies byte for byte.
[Verification and screenshots](../../verification/2026-09-08-scalar-bus/summary.json)
separate viewport replay, native partial-circuit actions and unperformed acceptance.
Final diff reviewed; the verified increment is ready for the user-requested commit.
