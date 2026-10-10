# Bounded native saved-work review

This is a partial native input review, separate from the bilingual renderer and
independent-process persistence fixtures. It is not novice feedback or complete
native acceptance.

## Runtime and isolation

- Frozen runtime: `77c57dc692626e82a1b98ecc851e51d675a61c6e`.
- Engine: Godot `4.7.1.stable.official.a13da4feb`, Compatibility / Apple M2.
- Project: `.godot/verification/20261009T183724Z-80890d99/project`.
- Project custom user directory:
  `VonNeumannBottleneckChecks/personal-works-render-final-en`.
- Actual QA session:
  `/Users/ray/Library/Application Support/VonNeumannBottleneckChecks/personal-works-render-final-en/creation-candidate/session.json`.
- Native process PID: `60685`; terminal session: `65301`.

Exact command, executed from the repository root:

```sh
.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --path .godot/verification/20261009T183724Z-80890d99/project res://experiments/creation/workbench.tscn --windowed -- --locale=en
```

The playtest did not execute a fixture script, invoke model APIs, alter runtime
code, or access a real player profile. Existing A/B were produced by the rendered
fixture before this review.

Imported source SHA-256:

| File | Hash |
| --- | --- |
| `experiments/creation/work_focus.gd` | `1b34010eefd2121bc4192c1d9a6b9965ad0eebe651bda5f0642530c5cd17eb25` |
| `experiments/creation/work_canvas.gd` | `431bd072339cf212e498fffeeaef87bc346f4d4e2c50df25abf4e499532abd3e` |
| `experiments/creation/workbench.gd` | `54c5d295e4663ad2b7708c1f05aeb244a7525537f2e00429c6fbdf7f2536ff4a` |

## Native actions and observed result

CUA selected the actual Godot application. Godot exposed only window/menu
accessibility, so input used the tool's native screenshot coordinate space.
A first click using half-size coordinates did not activate Focus; using the full
screenshot coordinates did. This was corrected before further actions.

1. The reopened workbench visibly listed `Two paths · A` and `Another path · B`,
   with B selected. Native `Focus on work` click opened the modal saved B exhibit.
2. The screenshot showed all 64 B symbols in the versioned 16-column light trace,
   static overview, Play/Step/speed/mapping controls, and the restrained closing
   text below the work.
3. A deterministic native input batch clicked Play, its same-location Pause
   control, Step, the slider near its first sixth, and Explanation.
4. The resulting native screenshot showed static overview off and `Cell 9 / 64 ·
   A · light-trace-v1`. Explanation showed the same protected B work ID:
   `a43d1ccb13671eee86a04be7814e91dbf286213c24d1d66550b4275b4ac50ba4`.
   Its event was `feedback_write`, before context `A C`, A/B/C/D counts
   `[11, 0, 0, 0]`, sampler `weighted`, and feedback context `C A`. Saved mapping
   remained `light-shapes-v1`; viewer mapping remained `light-trace-v1`.
5. Native Escape returned from the modal; native Command-Q quit the QA app.
   Terminal session exited **0**. A fresh `pgrep -fl Godot` returned **1**, proving
   PID 60685 was gone and no Godot process remained before releasing the engine
   slot to the build owner.

After clean exit, read-only JSON inspection found exactly two saved works, both
structurally equal to `.godot/personal-works-final-en/work-A.json` and
`work-B.json`. Their IDs were unchanged:

- A: `d41ba46301b8fd7b09c2b097ef7833434a20e9581937d8ab69c53c432fd7f589`.
- B: `a43d1ccb13671eee86a04be7814e91dbf286213c24d1d66550b4275b4ac50ba4`.

## Evidence limits

The native tool returned screenshots inline in the task transcript; it did not
return a filesystem screenshot path. No local PNG is claimed for this review.
The modal opening observation took approximately 185 seconds, and the combined
control/observation call took approximately 294 seconds despite a requested
60-second tool timeout. The review stopped after the bounded batch and clean
quit so the build could proceed.

Play/Pause/Step inputs were executed natively, but intermediate cursors were not
photographed individually; this review does **not** independently prove each
advance or exact pause timing. Native slider selection and displayed actual
per-cell explanation were observed. The original-mapping dropdown, native fork,
new child naming/save, and a second native restart were not exercised. Automated
exhibition and independent-process tests provide their separately identified
coverage. Native 1280×720 geometry is not inferred from the screenshot; logical
viewport bounds belong to the renderer fixture evidence.
