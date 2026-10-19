# Documentation map

Start with [CURRENT_STATE](CURRENT_STATE.md). It identifies the current source,
frozen candidate and verification boundaries. Old execution instructions have been
removed; recover historical task books from Git when needed.

## Product and contracts

- [Game constitution](briefs/codex-night/GAME_CONSTITUTION.md)
- [Chinese introduction](../README.md) · [English introduction](../README.en.md) · [Changelog](../CHANGELOG.md)
- [Architecture](../ARCHITECTURE.md) · [Simulation](architecture/simulation.md)
- [Content and player save contracts](architecture/content-system.md)
- [Chapter 3 overlap](architecture/overlap-chapter.md) · [Chapter 4 layout](architecture/layout-chapter.md)
- [Second-act framework](design/second-act-framework.md)
- [Creative model and save contract](../experiments/creation/CONTRACT.md) · [Player route](../experiments/creation/README.md)
- [Creative design rationale](briefs/20261008-creation/00_README.md)
- [Feedback, consent and privacy](architecture/community-feedback.md)
- [Offline teammate feedback and import](architecture/offline-playtest.md)
- [Localization](architecture/localization.md)
- [Architectural decisions](decisions/)

## Development and distribution

- **[实验室旅程交接与待办（2026-10-19，当前入口）](development/LAB_JOURNEY_HANDOFF_20261019.md)**
- [创作方向与美术约束（2026-10-19 主创文档）](briefs/20261019-lab/)
- [Claude development handoff: conversation changes and unmet owner requirements](development/CLAUDE_HANDOFF_20261018.md) — 已由上一条接续

- [Shared collaboration](development/collaboration.md) · [Git workflow](development/git-workflow.md)
- [Testing commands](development/testing.md) · [Mac setup](development/mac-handoff.md)
- [Task matrix](development/task-matrix.md) · [Adding tasks](development/adding-tasks.md)
- [Maintenance](development/final-maintenance.md)
- [Current execution queue](exec-plans/active/README.md) · [Planning rules](../PLANS.md)
- [Candidate build procedure](distribution/free-alpha.md)
- [Current acceptance gates](../RELEASE_BLOCKERS.md)
- [VPS staging contract](distribution/ray-vps.md) · [Receiver](../server/README.md) · [Operator runbook](../server/deploy/RUNBOOK.md)
- [September 2026 challenge preparation (historical)](distribution/astra-challenge/README.md)

## Verification

- [Current journey candidate: fixed Windows packages, change images and next-day handoff](verification/20261018-journey-final/README.md)
- [Earlier creative presentation and original-work review](verification/20261018-creative-framework/README.md)
- [Full-journey task context, earned journal and 3D observatory](verification/20261018-full-journey/README.md)

- [Offline teammate Windows tester, screenshots and final-only multi-play import](verification/20261017-offline-teammate/README.md)

- [Windows draft and deletion-safe private VPS operations](verification/20261017-feedback-release/README.md)

- [Latest creative expression candidate and acceptance limits](verification/20261013-creation-expression/README.md)
- [Whole-journey experience, before/after and art/playtest handoff](verification/20261012-experience/README.md)
- [Windows freeze and actual private VPS HTTPS feedback](verification/20261012-pre-release/README.md)
- [Sixty-task package and feedback receipt](verification/20261010-cloud-playtest/README.md)
- [Creative studio and saved performances](verification/20261010-creative-experience/README.md)
- [Main integration](verification/20261010-main-integration/README.md)
- [Native Representation / Service resume](verification/20261009-native-region-resume/README.md)
- [Native original-core continuation](verification/20261009-native-core-tooltip/README.md)
- [README image provenance](images/readme/README.md)

Earlier records remain under `verification/`, completed implementation history under
`exec-plans/completed/`, and subsystem delivery observations under `status/`.
Those dated records do not define a new task queue or certify the current package.
Update the most specific current contract instead of repeating it in a task book.
