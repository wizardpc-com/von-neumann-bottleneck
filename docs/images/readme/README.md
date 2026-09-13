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
