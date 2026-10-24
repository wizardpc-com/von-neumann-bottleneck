# Candidate builds and Windows team handoff

## Windows mode debugging package — 2026-10-23

Normal builds start in Game and expose Game/Test selection in laboratory Settings.
Hardware and Chapters 1/2 also retain their supported in-place selectors. Other
workbenches use their existing save/departure flow before returning home to switch;
their generic settings do not change a live draft's namespace. Test components and
completion remain separate from Game. Developer capture commands remain disabled
in exported candidates.

Use the existing builder with a fixed main commit, `--platform Windows`, a matching
`--windows-template`, `--second-act-profile ModeDebug20261023`, `--creation-journey`
and `--test-batch ModeDebug20261023`. Omit `--offline-tester` to retain Game's normal
prerequisites; explicitly selecting Test supplies free testing access. The stable
profile is separate from production data. Share the emitted ZIP and its manifest;
never include QA saves. Packaging and headless binary checks do not establish
native graphical/audio acceptance.

The current Windows team procedure and Chinese player guide are in
[team handoff](../development/team-handoff.md). The offline package includes
four actual screenshots and uses a separate named `OfflineTeammate-<suffix>`
profile. The builder reads and writes source/configuration/notes as UTF-8 on
Windows, independent of the system code page.


## Sixty-task candidate

The ordinary builder default remains the original 40-task candidate. A complete
candidate uses `--second-act-profile CloudPlaytest --creation-journey` with both
platforms and matching private Godot 4.7.1 templates. This enables core40 + Representation5 + Service3 + optional
address Prediction3 + C/P/G9. The emitted manifest is the actual content/build/
source/batch authority, not the historical default paragraph below.

The source/F5 `game/full_journey=true` shortcut is not a partial-package selector.
The builder clears it only in the exported 40/51-task copy; a current complete
60-task candidate retains it, including the earned final cinematic. The source
checkout is unchanged. Configuration/manifest regression checks cover all three
scopes with a mocked exporter; they do not replace exported-binary acceptance.

The profile is stable across builds and isolated from production saves. On Mac:
`~/Library/Application Support/VonNeumannBottleneckCandidates/representation/CloudPlaytest/`
and the `service/CloudPlaytest/` sibling. On Windows use the same suffix below
`%APPDATA%/`. Creation profiles live inside the Representation directory. Back up
both complete directories before an update or rollback; do not ship QA data.
The candidate starts without Godot or launch flags. Home recommends the existing
core ending, Representation/Service and the personal C→P→G work/creative closure;
optional investigations do not become hard prerequisites. Continue, guarded
departure and saved-work review use the existing contracts.

`--feedback-endpoint <approved-HTTPS-base>` only binds a supplied approved target;
it does not deploy or verify it. Without that target, the distributable package
keeps local Save/Export and reports not configured. Automatic statistics are off;
single-opinion Send has independent consent and never uploads works/programs/
examples/intention. Keep a distinct immutable batch for the localhost acceptance
package (`--local-feedback-test`), which must never be passed off as externally
connected. This label accepts only an explicit loopback HTTP or HTTPS endpoint;
private HTTPS tunnel and test CA setup belong to QA, not the distributable build.
Current evidence and exact platform boundaries belong in
[CURRENT_STATE](../CURRENT_STATE.md).

This is a local candidate, not a public release or paid Early Access. Public service deployment, payments, identity submission and release remain separate user decisions.

## Build from one frozen commit

Install Godot 4.7.1 stable and matching macOS / Windows x86_64 export templates. On Windows, pass the private `macos.zip` and Windows release executable directly; no global template change is needed. From the repository root, run with the selected frozen commit and a new immutable batch name:

```powershell
$frozenCommit = 'PASTE_SELECTED_FULL_COMMIT_SHA'
$batch = 'NEW_IMMUTABLE_BATCH'
python scripts/build-free-candidate.py --godot 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --commit $frozenCommit --platform both --mac-template 'build\template-cache\templates\macos.zip' --windows-template 'build\template-cache\templates\windows_release_x86_64.exe' --second-act-profile CloudPlaytest --creation-journey --test-batch $batch
python scripts/check-candidate-identity.py "build/playtest-$batch-$($frozenCommit.Substring(0,12))"
```

The helper archives the specified commit to an ignored staging directory, imports with separate build userdata, exports both platforms from the same source, adds instructions/known issues/change log/project/font/engine licenses, checks ZIP integrity and writes per-file and archive SHA-256 manifests. It never copies player saves, test scripts, local logs, credentials or the feedback database. Candidate builds start in ordinary Game and allow explicit Game/Test selection from the normal UI. The first-use normal game is offline; feedback endpoint is empty and automatic upload is disabled.

The macOS preset requests a universal binary and ad-hoc signing; verify the resulting signature on a Mac. Windows x86_64 is a validation candidate until tested on Windows. Export success does not establish installation or native play. Current evidence and exact source/hash are linked from [CURRENT_STATE](../CURRENT_STATE.md).

The profile is 1–40 letters, digits or hyphens;
it binds the package to `VonNeumannBottleneckCandidates/representation/<profile>`
and its validated Service sibling. The journey setting enables the two candidate
entries and saved review without launch flags only in that bound directory. It
does not migrate production progress. Build/import and release-binary QA still use
separate `VonNeumannBottleneckChecks` directories. Default builder behavior remains
the ordinary two-platform candidate above; do not reuse an existing frozen build ID.

Add `--creation-journey` to that isolated command to include the nine
compression/content-prediction/creation units in the same journey. This opt-in
requires `--second-act-profile`; the default forty-task build stays unchanged.
The original address-prediction investigations remain optional separate tasks.
Creation saves use `creation-candidate/session.json` inside the bound candidate
profile, with explicit writer retry, stopped-owner recovery and validated-copy
selection. Normal retry preserves the current exploration; adopting changed
saved contents requires confirmed reload. The manifest records this feature and
`verify-mac-candidate.py` checks the actual exported configuration/resources and
task count on macOS. Windows native play and Mac first launch require separate
platform acceptance; an export and ZIP hash check do not establish either.

## Save and feedback boundaries

Offline Windows tester builds accept `--second-act-profile OfflineTeammate` or a
separate named profile such as `OfflineTeammate-Night20261018`, together with
`--offline-tester --creation-journey`. The complete profile must remain within
40 letters, digits or hyphens; a suffixed name requires a nonempty suffix.
Use the suffixed profile for a separate nightly playtest so opening it leaves
the October17 `OfflineTeammate` saves and feedback untouched. Its Representation,
Service and Creation data all follow that selected profile, and the packaged
README lists its actual directories. No saves are copied or migrated. Reusing
the exact default profile intentionally resumes that channel; back it up first.

Use the existing player save directory and backup mechanism. New layout state is additive and its completions are replay-validated. Back up the whole user data directory before updating or reverting. Current schema-2 saves carry a minimum writer version; unsupported future fields or writer versions block replacement, and previously issued schema-1 games reject schema 2. Do not replace a protected current save with an older backup to bypass that guard. QA must use a separate user directory and verify it before starting ordinary Game. Do not distribute an isolation override with the public package.

Ratings are optional, unanswered values remain absent, opinions may be saved on incomplete tasks. Agent and automated sources remain distinct from external players. [Local receiver setup](../../server/README.md) covers synthetic integration, consent, queue limits, receipts, deletion, private reports and retention. No service is deployed publicly in this scope.

## Steam preparation — approval pending

Suggested title: 冯诺伊曼瓶颈 / Von Neumann Bottleneck. Short description: 从逻辑门搭起机器，再探索等待、缓存、协作与数据布局。自由设计、观察真实运行、寻找自己的优化方案。Free public development candidate; no paid access, in-app purchases or custom account requirement.

Use the same frozen content for direct download and a future Steam Playtest depot. A Playtest has its own AppID linked to a main store page; access is free ([Steamworks](https://partner.steamgames.com/doc/features/playtest)). Do not add Steam IDs or credentials until the owner provides them. Prepare the main page, Playtest relationship, OS-specific depot launch executables, language metadata, actual current screenshots, privacy/data description, support link and known issues. Check clean installation, offline boot, save/update/restart, uninstallation retaining saves, and Steam launch/overlay on each supported OS before submitting. No Steam onboarding, payment, identity entry, store upload or release has been performed.

All artwork is original procedural/vector work with bundled Noto Sans SC. Avoid invented playtime claims, mock-up screenshots represented as gameplay, or promises about future workshop/leaderboard support. After this candidate, prioritize external observations and convergence fixes rather than another chapter.

## Current local artifacts

See [CURRENT_STATE](../CURRENT_STATE.md) and its convergence evidence for the exact
current source/build/archive mapping. The builder stamps the exported project and
all package notes using its archived commit; checkout development versions are not
candidate identities. Earlier reports and archives remain historical only.
