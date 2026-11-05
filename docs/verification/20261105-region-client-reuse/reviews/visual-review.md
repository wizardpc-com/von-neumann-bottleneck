# Round 12 final visual review

Date: 2026-11-05. Reviewer: audit_polish. Assignment: read-only final visual check from `.godot/collaboration/round12-clients.md`.

**Outcome: no concrete blocking visual issue observed in the 20 inspected final-candidate frames.** No source, test, harness, project settings, image or Git changes were made; no engine process or native input was run by this reviewer. This review does not establish zero visual regressions outside the captured states.

## Evidence and observation scope

All 20 untouched PNGs were opened and visually inspected at their original 1280 × 720 size, covering both English and Simplified Chinese initial, source-assets, measured, earned and closure states. The first 16 were inspected before context continuation; the remaining four closure frames were inspected after continuation. PNG headers and SHA256 were independently read again when producing this report.

Capture directory:
`/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/verification/20261105T142756Z-4bd0e0fc/project/.godot/workbench-captures`

The full GPU log and results JSON were independently read:
- `.godot/region-client-checks/20261105T143611Z/test_representation_workbench_presentation.log`
- `.godot/region-client-checks/20261105T143611Z/results.json`

The log is five lines and reports Godot 4.7.1 stable, OpenGL Compatibility on Apple M2, and `PASS: test_representation_workbench_presentation 2115 checks, 0 failures`. Metadata records return code 0, no stop reason, no diagnostics and 32.997670833 seconds. The command uses the isolated QA project with `--workbench-capture` and `--capture-size=1280x720`; it starts in `zh_CN`, and both locale frame sets are present. These are scripted GPU captures, not native OS interaction acceptance.

Log SHA256: `651953467ac63cec94285c08786e3b7c1afbcd40239d1049dbe6bf53db91f0f4` (matches metadata).

Metadata-bound test SHA256: `b367d691d006b38e3292bf256575a7c326c060ee22a029dea84cd596ddb82d4a`.
Metadata-bound Region model SHA256: `71c5a91016a00163b9a3be2f64ca90030f8992469866977521ed5858814ae6d3`.
Metadata-bound Base model SHA256: `698029a07aa2b26097307b40fffbee99c87bcebaacc257d939d1ea942927d136`.
These three hashes are read from run metadata, not a claim that every current working-tree file matches the capture project.

## Visible findings

- All five task-navigation buttons and primary Run, Save and Quit actions remain visible in both locales. Initial states clearly present no measured costs; playback controls are disabled before results exist. Source-assets scrolling leaves the editing and execution controls available.
- Cross-asset measured failure distinguishes asset A and B: A shows preparation 0 + service 133 = total 133 cycles, stored 58 B and service traffic 58 B; B shows 0 + 183 = 183 cycles, stored 58 B and service traffic 158 B.
- Prepare measured failure visibly distinguishes 1 client and 8 clients. The one-client row shows 45 + 16 = 61 cycles, stored 76 B, service traffic 8 B and met; the eight-client row shows 45 + 1064 = 1109 cycles, stored 76 B, service traffic 464 B and unmet.
- Prepare earned states show 88 + 17 = 105 cycles, 76 B stored and 12 B traffic for one client, versus 88 + 800 = 888 cycles, 76 B stored and 160 B traffic for eight clients. Both are marked met, and the next unfinished task action is visible.
- Cross-asset earned states show A at 0 + 130 = 130 cycles, 48 B stored and 48 B traffic; B at 0 + 36 = 36 cycles, 48 B stored and 16 B traffic. All task ticks and the review action are visible.
- The closure results window is bounded by the viewport in both locales. The title, close control, scroll area and fixed bottom Continue / Back actions are visible. Readable result cards retain explicit preparation + service = total equations. The prepare-task explanation states that each order prepares once, eight-client service is aggregated and stored space includes the retained 64 B source.
- The closure-next scroll state exposes the fifth task with both assets' costs and their order mapping. Its conclusion, unsaved-change reminder, next-step explanation and both bottom actions are readable. English text wraps within the modal; the Chinese text remains within the same bounds. The next-step text explicitly says representation plans do not automatically transfer to the separate service machine.

## Nonblocking observations and limitations

- Several Chinese workbench snapshots include a transient task/achievement cue around x372–909, y124–166. It overlaps upper source cells and part of their heading; earned states also overlap the left part of the continuation/review action. Its label remains readable in the inspected earned frames. These static shots do not establish dismissal duration, native hit-testing or whether it intercepts clicks; no new blocking defect is established from this evidence.
- Some lower status/details/restore controls extend below their scroll viewport or are partially visible at its bottom. Primary execution controls and measured equations remain visible. English secondary restore controls wrap farther downward than Chinese. This is not evidence that all scrollable controls fit simultaneously.
- Earned screenshots show a selected preparation or transfer event, not every client's entire event timeline. Typed/model tests, not these frames, establish complete per-client event/access equivalence.
- No before/after pixel baseline was inspected. No native mouse/keyboard acceptance, export validation, Windows run, UI-latency measurement, player-profile check or full-repository regression is claimed by this visual review.
- Review is confined to planned Round 12 closeout. No new content, follow-up optimization round or native pilot is proposed.

## Original PNG inventory

All files below are 1280 × 720 and were not edited.

| Filename | SHA256 |
|---|---|
| `representation-en-assets.png` | `545830f15f6f97e64042f90d51ac6cdd0af3e65658329e81f2e60cff632a1e7b` |
| `representation-en-closure-next.png` | `f23fc51e45d7f8674aff341e834913c691244625facf9bb522cede87b1335a0f` |
| `representation-en-closure-results.png` | `63c511854e948a12625df672dfa6408529c09d57645f4e2959bb6b697e379763` |
| `representation-en-cross-asset-earned.png` | `0b2ff724876cc790e6f6925a835453655253b389293431896349384b21e10a82` |
| `representation-en-initial.png` | `eb4fd9ce447b404c93a0022905faa28dbf8bfa0385eb7216917bd63c8e5d61df` |
| `representation-en-measured.png` | `ac7823a8659c8b28d2b64914e80ce5299a6b84e12e25006d01b04258863d33b7` |
| `representation-en-prepare-assets.png` | `65c3a502e820e5bff16049d86453f99657c028cda764b7dbd02665e7cfd37664` |
| `representation-en-prepare-earned.png` | `97e71931edeb89bf10f53d9f0307cbd07222a3de63524fd516be5b859f45c7f4` |
| `representation-en-prepare-initial.png` | `35df89de8dd937ad5989bff2a677d36891e389ce94befee90cccda4f7f1aef46` |
| `representation-en-prepare-measured.png` | `c9b9c66ad724de03c8f17361dffcfdbb5ad2c5bafe29f85e527054191d68cd1f` |
| `representation-zh_CN-assets.png` | `4d3a6305588a4e2c70051df50b1b8d72343de9e6d1f47a6cd76e468f98104dc4` |
| `representation-zh_CN-closure-next.png` | `4fad4418a287dfce527fa55c1d6fafc98a0bc0e5bb18f98f2f7348bebf1493a1` |
| `representation-zh_CN-closure-results.png` | `240b9b7af002fc482d7f9ae19abc77aee3e83fd5f89b75b4026c5b8ee4fe59a4` |
| `representation-zh_CN-cross-asset-earned.png` | `992461701567fb24e5f1bde96b786f775cade4fd54a046884e778d035b370441` |
| `representation-zh_CN-initial.png` | `f81103d7072d1440e2f2ade0c353cc953b01823d76aeb8cdd0c8ebe263bf3ec2` |
| `representation-zh_CN-measured.png` | `f4b32df48bf1b754e8c31bee610290152dce30ebfd7133cb7ad9be1531216f6a` |
| `representation-zh_CN-prepare-assets.png` | `940e0c364444c52ad72c5be3f0d87c9be518e29dcab2bdd6c40ecf68505ef122` |
| `representation-zh_CN-prepare-earned.png` | `9615b14e43ae8bf89a6e662c040e591364874d210b7e5fc7a3271947d9650bbb` |
| `representation-zh_CN-prepare-initial.png` | `19448dd989e60ec196bcaa50e44345289d3e39ea6b95e8ff36a9dc08ddadfbb8` |
| `representation-zh_CN-prepare-measured.png` | `caee2c9f317778d66ca7b7fb63f9d63c273d60954cd00a82f27994d8c4ff1816` |
