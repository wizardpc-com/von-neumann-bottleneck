# Bounded native playback follow-up

Runtime: `012f261` (the continuity follow-up). This partial native review supplements
the separately recorded actual renderer-clock pause/step/finish check. It does not
replace that check or claim native pause timing.

Exact launch from the repository root:

```sh
.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --path .godot/verification/20261009T190717Z-97aaa282/project res://experiments/creation/workbench.tscn --windowed -- --locale=en
```

Godot reported `4.7.1.stable.official.a13da4feb`, Compatibility / Apple M2. The
project uses only QA custom user directory
`VonNeumannBottleneckChecks/personal-works-continuity-final`. Terminal session was
`9480`; no fixture script or capture flags were passed.

Imported source hashes:

| File | SHA-256 |
| --- | --- |
| `work_focus.gd` | `1b34010eefd2121bc4192c1d9a6b9965ad0eebe651bda5f0642530c5cd17eb25` |
| `work_canvas.gd` | `d2cfda70483023eebf18ac672bf41adb3678a9f6f60caaa9fdf8853aa10b356a` |
| `workbench.gd` | `54c5d295e4663ad2b7708c1f05aeb244a7525537f2e00429c6fbdf7f2536ff4a` |

## Observed native input

1. CUA selected Godot and returned the real reopened workbench screenshot. It
   showed A, B, and the previously saved independent-process child.
2. Native mouse selected B, then clicked `Focus on work`. The modal showed saved
   B (`另一条路 · B`), all 64 symbols, static overview on, and the corrected visible
   restrained glows/trails. The native observation call took about 167 seconds,
   exceeding its requested 60-second timeout.
3. A separate native mouse click activated Play. Its subsequent observation took
   about 200 seconds; the screenshot therefore showed the finished `Cell 64 / 64`
   state, static overview off, Play button restored, and the full illuminated
   saved work. This is an observed native end state, **not** an intermediate
   progression or precise pause measurement.
4. After the second slow call, the bounded review stopped. Native Escape and
   Command-Q cleanly closed the QA app. Terminal session 9480 returned exit **0**;
   fresh `pgrep -fl Godot` returned **1**, with no Godot processes remaining.
   The exclusive engine slot was released before any subsequent local run.

Post-exit read-only inspection found exactly three saved QA works. Original A and
B remained structurally equal to their frozen export JSON; IDs are recorded in
[post-exit-works.json](post-exit-works.json). No work was edited or added during this
native review, and no real player data was accessed.

The screenshots were returned inline by CUA; the tool supplied no filesystem path,
so this directory contains no claimed native PNG. Precise native pause timing,
step timing, and continuous motion footage remain unverified. The actual renderer
frame-clock check provides its own explicit evidence for pause/step/completion.
