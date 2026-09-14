# README images · 配图来源

Captured on 2026-09-13 from source `9454ffb`, using Godot 4.7.1 stable on Mac.
Tracked runtime and localization files were byte-compared with the imported QA
project before capture; they match. The README documentation change does not
change the runtime or the frozen `free-alpha-47a59d385103` candidate.

- `hub-zh.png` / `hub-en.png`: current chapter hub, Chinese / English.
- `tree-zh.png` / `tree-en.png`: the same fresh-profile prerequisite tree, framed to
  show the construction region. Compact labels are the actual game's zoom behavior.
- `manifest.json`: source identity, output dimensions and SHA-256 values.

These are direct viewport captures of real project scenes, not painted mock-ups,
retouched screenshots, or proof of a native playthrough. No solution or completed
progress was inserted. The capture helper changes only language, window/view size
and the tree's camera framing. It uses a dedicated QA user directory, never player
saves. Outputs retain their original pixels; Retina/window sizing can change the
physical image dimensions. Native candidate evidence is recorded separately in
[the verification record](../../verification/20260913-spatial-candidate/README.md).

To reproduce, first create/import an isolated project as documented in
[testing](../../development/testing.md). Verify its custom userdata directory, copy
`capture.gd` into that isolated project's root and run:

```sh
godot --path <isolated-project> --script res://capture.gd -- --capture-size=1600x1000
```

The helper writes four PNGs under that copy's `.godot/` and exits. Review the images
before copying them here. Do not run the capture against a player's live profile.

中文：配图由当前实际场景直接渲染，采用隔离新档，没有拼接界面、添加解法或伪造进度。
旧配图保留在历史记录中，当前 README 不再引用它们。今后更新图片时，请同步更新来源与哈希。

## 2026-09-14 representative level

`layout-zh.png` / `layout-en.png` lead both READMEs. These directly render Chapter 4
Common Ground from a copied, earned synthetic QA profile restored through GlobalSave
revalidation in Game mode. The existing run action reevaluates the saved batch-4
design: A 1364 cycles, B 1131 cycles, 32 B peak scratch. Panels were moved/resized
for legibility; source data, design and metrics were not fabricated or retouched.
This is a real scene render, not proof of native mouse acceptance. `capture-layout.gd`
requires an isolated imported project with a copied completed QA profile; never run
it on player saves. `layout-manifest.json` stores dimensions, hashes and source identities.

## 2026-09-14 CPU and double-buffer highlights

`cpu-zh/en.png` and `buffers-zh/en.png` were directly rendered from runtime commit
`4450c78`, using a copy of the previously earned synthetic QA save. No player save
is distributed. CPU uses the normal workbench loader; the screenshot shows the
saved wiring before a new formal run. Taking Turns reevaluates the saved board and
program: 28 total cycles, 12 overlap cycles, output 46/46. Windows were arranged
for legibility; no score, source data, topology or UI was retouched.

[Capture helper](capture-highlights.gd) · [Source identity, metrics and image hashes](highlights-manifest.json)
· [UI checks and native limitations](../../verification/20260914-compact-desktop/README.md).
These images are source renders, not proof of new exported-package acceptance.
