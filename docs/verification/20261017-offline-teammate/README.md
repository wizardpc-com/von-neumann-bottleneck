# Offline teammate Windows pre-version — 2026-10-17

The candidate freezes `4df5bad46751cbd0a4eb884c87a9be9a169bcd57` as
`playtest-OfflineTeammate20261017-4df5bad46751`. It is an offline Windows tester
build with all sixty task entrances, separate `OfflineTeammate` saves, no receiver
URL and no automatic upload. The published forty-task Alpha is unchanged.

## Observable changes

| Before | Tester candidate |
| --- | --- |
| Short task opinions lacked screenshots and unsaved game context. | F8 or the persistent feedback button pauses the game and saves the preceding game viewport, live design/program/parameters, run data and context. Notes autosave with an append-only journal. |
| Later export was not a complete multi-play diagnostic package. | One verified ZIP retains earlier and current incidents, screenshots, context, sessions, allowlisted saves and logs. Export leaves local originals intact. |
| A fresh player could not directly inspect every task. | All sixty entrances open. Missing hardware prerequisites have marked temporary reference components; these cannot grant earned completion or sealed works. Existing player components retain precedence. |
| Feedback required separate manual collection and analysis. | Standard-library Python imports multiple ZIPs, checks hashes/paths, deduplicates, retains originals and generates searchable screenshot/context reports plus session analysis. |

[Tester guide](../../../distribution/OFFLINE-PLAYTEST-README.txt) ·
[Maintainer commands](../../../distribution/OFFLINE-MAINTAINER.txt) ·
[Evidence and persistence contract](../../architecture/offline-playtest.md).

## Frozen identity

Windows ZIP: `Von-Neumann-Bottleneck-Windows-playtest-OfflineTeammate20261017-4df5bad46751.zip`

- ZIP size: 57,451,365 bytes.
- ZIP SHA-256: `37137e45a82d5036c9e8ca831089a0621ab846b0c3d8baa2e89230faeb43c8c1`.
- EXE SHA-256: `1da1b0403bd36f1c048372c5286b75e92412bb6dc92e528af8d462109370683f`.
- Embedded PCK SHA-256: `5784ba623bfb021a386496af60698ba4a1467965a41c64f10082c5fb8f595b47`.

The matching Godot 4.7.1 Windows release template, archive inventory, packaged
tools/notes and build/source identity passed `check-candidate-identity.py`.
[Package manifest](candidate-manifest.json) · [Runtime receipt](runtime-receipt.json).

GitHub [Pre-release v0.5.0-alpha.3-offline.1](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.5.0-alpha.3-offline.1)
was **published with explicit owner authorization** at2026-10-17T12:19:19Z,
release ID415782806. Its source and all three uploaded asset sizes/digests match
the tested files. [Published receipt](release-receipt.json).
An ordinary HTTPS download with no GitHub credentials returned200 and matched
all57,451,365 bytes and the frozen ZIP SHA-256. [Download receipt](download-receipt.json).
The [earlier draft receipt](draft-receipt.json) records the pre-publication state.
The separate online Alpha2 draft remains unpublished. This offline package's
`public_release=false` keeps the builder's network-public-playtest profile
disabled; GitHub publication does not enable a receiver or alter the tested ZIP.

## Verification and limits

- The unchanged exported EXE, controlled by an external synthetic QA script,
  actually entered all sixty foreground tasks. It captured three distinct
  workbenches, quit normally and restarted in an independent process. The second
  play entered Service and recorded a fourth incident. **The final ZIP alone**
  imported into a new library with four complete incidents, four screenshots and
  two sessions, without capture errors or ignored session lines. The original
  and repeated imports also passed preservation/deduplication checks.
- Windows full isolated regression initially passed159/160; the sole failure was
  a new test fixture's inferred type, subsequently corrected. The affected
  rerun passed8/8, including66 hardware tester-navigation checks. The final empty
  evidence/logical-key correction passed4/4 import/isolation/store/UI checks.
  The raw earlier run is not reported as160/160.
  [Regression receipts](regression-receipt.json).
- Offline importer/report tests passed10/10. Existing report reducer and candidate
  packaging contracts passed. Corruption, traversal, manifest coverage, batch
  atomicity, duplicate identity, HTML escaping, large notes, original build
  attribution and incomplete sessions are covered.
- Windows OS input confirmed F8 capture and autosaved text in the final EXE.
  At final4df, the first process was normally closed and confirmed gone before
  the second launch. F8 also opened feedback over the tutorial's task explanation.
  The one final ZIP imported into an empty library with both original notes,
  two1280×720 screenshots, both contexts and two sessions. The first normal
  session end is present in that ZIP. Both notes remained drafts, demonstrating
  that submission is not required for persistence. The second game window was
  left under user control when Computer Use stopped; its final close is not an
  acceptance claim. [Native receipt](native-receipt.json). None of these checks
  claims that a human completed all sixty tasks.
- Fixed-source GitHub CI run39031009610 passed all160 Godot import/isolation/suite
  checks and its Python job. This Linux CI is separate from the Windows receipts.
  [Exact CI scope](ci-receipt.json).
- The in-app browser's local-file policy prevented browser visual acceptance of
  the generated report. HTML generation, escaping and link structure passed;
  browser visual acceptance remains NOT_RUN. No alternate browser route was used.
- Current Mac native, unfamiliar-player comprehension and artistic acceptance
  remain separate. Snapshots aid diagnosis; they are not universal UI replay.
  Explicit size/coverage limits and missing fields remain visible. No application
  can prevent physical disk loss; keep local originals and a separate exported copy.

No VPS, DNS, public endpoint, production saves or historical feedback were changed.
