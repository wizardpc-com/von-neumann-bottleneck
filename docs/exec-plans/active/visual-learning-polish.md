# Circuit visual language and learning guide

## Scope and invariants

Improve the original campaign's presentation, signal controls, component catalogue, Mission copy and progressive illustrated Handbook. The existing free construction editor, floating instruments, named workbenches, three separate Hint levels, prerequisites, official tests and simulation remain authoritative. Preserve all existing features, saves and historical comparison content. No engine rewrite, answer insertion, save-format migration, commits or pushes.

## Steps

1. Protect current working tree and actual player data; inspect screenshots and ordinary Game UI.
2. Replace redundant input toggle presentation with compact 0/1 signal symbols; align shared component previews and text. Establish a coherent technical instrument visual style across the original game.
3. Unlock Handbook subjects from actual original progression and current Mission requirements. Add readable behavioural illustrations/examples without revealing level solutions. Refine task and continuation copy.
4. Test original interactions, progress, saves, localization and simulation. Use computer-use to play ordinary Game and fix observed UI failures. Export an identifiable package and inspect that package.

## Affected areas

Hardware Foundations UI and component palette; shared UI styling and floating instruments; Handbook/diagrams; original hub, Chapter 1/2 presentation; bilingual text; focused UI and progression regression tests; status/testing documentation.

## Decisions

- Borrow Turing Complete's consistent schematic symbols, concise controls and construction-to-computer learning approach, using original procedural artwork rather than copying game assets.
- Retain 0/1 and distinct outlined/filled shapes as redundant signal cues. Low is a normal state, not an error; diagnostic errors remain separate.
- Handbook unlocks are derived from existing progress, never a new completion authority. Required current-stage specifications stay readable. Future subjects show an unlock explanation.
- Do not change authored seed coordinates: they participate in existing workbench fingerprints.
- Native UI, injected Godot GUI input, headless tests and novice human evidence are reported separately. Release readiness requires demonstrated acceptance, not a passing checklist alone.

## Baseline and evidence

2026-09-07: HEAD `76ef11610c3faf2b81722877fa91877a4589074d`; existing staged recovery and unstaged experience changes preserved. Hash-verified backup: `.godot/polish/20260907T003207/backup` (339 workspace files, binary staged/unstaged patches; 21 actual Lenovo player files). Prior packages retained.

| Capability / issue | Observed cause | Change | Evidence |
| --- | --- | --- | --- |
| Input high/low choice | Repeats name, word, digit, line glyph and native switch | Compact outlined 0 / filled 1 control and one external label | Hardware UI suite; Chinese/English Game GUI input and Mission screenshots |
| Palette symbol alignment | Full GraphNode preview carries title/row extents into a small thumbnail | Shared schematic renderers fitted inside one column, aligned localized text in the other | Hardware / prologue UI suites; placement and exact ghost geometry checks |
| Progressive explanation | Handbook lists all subjects regardless of progress | 89 topics mapped to first playable original lesson; 29 illustrated entries; current specs remain readable | 558 Handbook checks and GUI search/open/return interaction |
| Original editing and hints | Existing recovered implementation | Preserve selection, branching, precise erase, clipboard, snapshots and separately confirmed Hint levels | Chinese 461 / English 461 ordinary Game GUI checks; native desktop replay pending |

## Progress / open acceptance

- Implementation, localization, regression and candidate export complete. See [status and package](../../status/visual-learning-polish.md).
- All 20 conventional suites pass after updating the two obsolete presentation assertions. Original failed logs and revised passing logs are retained. Chinese and English ordinary Game GUI replays pass 461 checks each.
- Exported build `polish-20260907T010358-76ef116` starts in Game and Test with exit 0; its internally rendered default hub was inspected.
- The native computer-use helper enumerated the game window, but a fresh desktop capture revealed the Windows lock screen. Input stopped immediately and the user was asked to unlock. No full native playtest of this build has occurred.
- This plan stays active for the final native desktop replay and observed-play feedback. Novice understanding, physical mouse comfort and High DPI remain unverified; the candidate is not a production release.
- 2026-09-07: the user moved primary development and native playtesting to Mac, with Windows retained for validation. Continue this acceptance plan through the [Mac handoff](../../development/mac-handoff.md); do not wait for the original Windows desktop to unlock before independent Mac work.

## References

- [Turing Complete developer description and screenshots](https://store.steampowered.com/app/1444480/Turing_Complete/): gradual construction, freedom to solve, readable schematic vocabulary.
- [Developer updates](https://steamcommunity.com/app/1444480): consistent component shapes and clear communication of the intended experience.
