# v0.6.0 · Final Game / Test delivery · 2026-11-16

Four offline archives were built and verified from the **same frozen product commit**
`63584487c1af190a05d294bb758b7ab3fc610063`, using Godot
`4.7.1.stable.official.a13da4feb` and its matching export templates.
The subsequent closeout commit changes verification tools and documentation only;
it is not a different game build. This delivery does not create a GitHub Release.

## Packages and identity

| Edition | Batch | Profile | Platforms |
| --- | --- | --- | --- |
| Game | Final20261116Game | EditionGame | Windows x86_64; macOS arm64 + x86_64 |
| Test | Final20261116Test | EditionTest | Windows x86_64; macOS arm64 + x86_64 |

Each archive includes the executable, bilingual running instructions, known issues,
licenses and a per-file build manifest. The build roots also contain SHA256SUMS.
Exact filenames, byte sizes and hashes: [delivery.json](delivery.json) and
[combined SHA256SUMS](SHA256SUMS). Local archives are under
`build/vnb-{game,test}-v0.6.0-Final20261116{Game,Test}-63584487c1af/`.
Release version is v0.6.0; content configuration is
`tasks-20261013-journey-v1`, creation scope, all **60 task entrances**.
The ordinary durable journey counter is 57 because three prediction investigations
are intentionally temporary; no task was removed. Native Windows version is
0.6.0.429; macOS short version is 0.6.0 and bundle build version is 1.4.29.

## Final product

One bright ceramic-white laboratory and restrained dark terminal, with original
replaceable VNB symbol, bilingual wordmarks and native app icons. Historical
October19/23 light-room concepts govern the choice; later Claude panel, focus and
chapter colors were selected individually. No wholesale visual-branch or scale
merge, bit-signal redesign or blanket font-size floor.
[Visual decision](../../development/FINAL_VISUAL_20261116.md) ·
[Brand and replacement](../../development/BRAND_20261116.md) ·
[Raw source presentation](screenshots/README.md).

Game follows earned prerequisites. Test opens entrances using the same real models
and official conditions without awarding Game progress, components or rankings.
Separate stable profiles isolate saves, works, feedback and scheduling experiments.
Temporary core Test progress remains session-only; explicitly saved works/service
plans remain in the Test edition's own profile. Existing player data is not migrated,
overwritten or deleted; no persistent schema or simulation rule changed.

The optional scheduling lab uses its existing model, real measured results, strict
edition profile binding, pending-input/save/discard protection and Laboratory return.
Product builds disable developer capture and arbitrary creative-profile overrides.
Edition/version appears in the terminal/settings, with full SHA, batch, content and
profile in identity details and diagnostic exports. No account or network is required.

## Verification performed

- Clean local/remote main baseline: `8105b928319c28d75a485371f32ca332dcde1793`.
  Read-only Claude refs: visual `e53b94682cbd26ddc26f57c86dd489071d5d777f`,
  scale `0f00fe057699d8b37c88901337b3656941b1a37d`.
- Full isolated source sweep: **310 suites**, initially 302 passes / 8 failures.
  Original results and failures are preserved in `logs/full-sweep`. Corrected title
  fixtures (2), missing public palette alias (3), baseline unadded-example guard
  fixtures (2), and the actual new settings identity overflow (1).
- Fresh final snapshot `.godot/verification/20261116T093554Z-c091f96c`:
  import/isolation and **30 affected suites pass** (`logs/final-affected`).
  Runtime/resource files matched this imported QA copy before freezing.
- **Eight GPU operation/presentation suites pass** (`logs/gpu`). Corrected the
  room-capture driver, then separately passed 84 checks with six actual visible-room
  captures (`logs/gpu-room-corrected`). Reviewed Chinese/English at 1280×720,
  1280×800 and 1600×900 plus archive, works and settings raw pixels.
- Creation write→fork→read across three fresh processes and chapter workspace
  writer→two fresh readers pass. No synthetic awards entered real player data.
- Both actual exported Mac binaries pass isolated probes: identity, locked edition,
  all content, Game gates/Test entrances, no precompletion, disabled developer
  overrides, profile binding, repeated workspace save and server/test exclusion.
  Exact binary/PCK hashes and checks: `logs/exported-probe-{game,test}.json`.
- All four native package checks pass: Windows PE x86_64, native version and exact
  authored icon PNGs; Mac Universal slices, exact ICNS and strict deep ad-hoc signature.
  See `logs/native-*-final.json`. These structural checks do not establish Windows
  or Intel Mac native gameplay.
- All four actual ZIPs pass strict inventory, CRC, per-file SHA, instructions,
  source/content/version identity and Game/Test profile separation:
  `logs/zip-verifier-edition-delivery.txt`. New negative packaging controls pass.
- Native Apple M2 Game Edition pointer/keyboard route passed: open terminal,
  Chinese→English, gated journey map, wire A→NOT→lamp, run both inputs, disconnect,
  observe authoritative result invalidation, reconnect, actual tutorial completion,
  return to the bright laboratory showing earned 1/57 and illuminated globe, quit.
  See [native scope and exit diagnostics](native-mac.md).

## Verification corrections and remaining limits

Initial restricted QA import was denied editor-settings writes; scoped permitted
isolated reruns passed. Initial native-icon verifier wrongly required optional24px
in the PE; the exporter retains six standard sizes and every retained PNG matches
exactly. Initial ZIP verifier did not handle ditto's unflagged UTF-8 names and
AppleDouble. Followup verifier changes retain strict inventories, hashes, bounds
and collision rejection; [icon note](logs/native-icon-verifier-note.md) and
[ZIP note](logs/zip-verifier-note.md) preserve the failures and corrections.
**No product binary, asset, PCK or ZIP was changed after freeze.**

Supported-Python3.9 timeout handling was corrected with passing Receiver7 and
Community16 checks ([diagnosis](server-python39-boundary.md)). One existing server
maintenance test still fails on host SQLite3.51.0 due to an orphan SHM sidecar;
[reproduction](server-sqlite-maintenance.md). The backup audit was not weakened,
server/storage behavior was not modified and servers are excluded from the packages.
Do not report all Python checks as passing.

Windows native input, Intel Mac execution, another machine's downloaded first launch,
full sixty-task human completion, newcomer comprehension, long sessions and subjective
audio acceptance remain unverified this round. Mac is ad-hoc signed/unnotarized;
Windows is unsigned, so OS first-launch trust warnings remain possible. One GLES3
shader allocation was reported on Mac shutdown; process exit was0, without an
observed play/save failure. This is retained as a diagnostic, not declared fixed.
Existing identical-parent/recipe Fork ambiguity is unchanged; explicit Fork remains
the recovery route and saved works are protected. No online service was deployed.
