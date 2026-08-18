# ADR 0005: semantic-key localization boundary

## Status

Accepted for the current playable prototypes.

## Context

The game should default to Simplified Chinese and later support additional languages. Directly replacing English literals with Chinese would make every future translation a code change and could accidentally make deterministic trace or circuit signatures depend on the selected language.

The current UI is assembled procedurally across the hub, Hardware Foundations, Cache Locality Lab, and shared floating windows. Player-facing parser and circuit errors also originate near domain logic, so only translating static button labels would leave an incomplete and misleading boundary.

## Decision

- Use Godot `TranslationServer` with independent gettext catalogs and stable semantic keys.
- Select `zh_CN` as the project default and retain `en` as the first alternate and fallback catalog.
- Keep all localized wording in presentation resources; UI code supplies only keys and language-neutral formatting arguments.
- Represent DSL and circuit diagnostics as semantic keys plus arguments while retaining deterministic developer fallback text where existing APIs require it.
- Derive localized trace captions from authoritative event kinds and structured fields rather than changing stored simulation messages.
- Keep DSL tokens, source code, IDs, addresses, ports, signal names, metrics, topology, and canonical signatures language-neutral.

## Consequences

- Adding or revising copy no longer requires changes to simulation, gameplay, layout, or animation logic.
- Locale switching cannot change the authoritative locality or circuit trace; automated tests compare both signatures across Chinese and English.
- The initial Chinese interface and English alternate can be reviewed independently in version control.
- A future settings window still needs an explicit refresh/rebuild policy for already-created procedural controls and persistence for player preference.
- Translation completeness is now a tested contract: every semantic key referenced by the current playable source must resolve in every registered catalog.
