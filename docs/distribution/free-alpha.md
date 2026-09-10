# Five-region free development candidate

This is a local candidate, not a public release or paid Early Access. The build contains 40 tasks in the original prologue and four chapters. Public service deployment, payments, identity submission and release remain separate user decisions.

## Build from one frozen commit

Install official Godot 4.7.1 stable and matching macOS / Windows x86_64 export templates. Run:

```sh
python3 scripts/build-free-candidate.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --commit HEAD
```

The helper archives the specified commit to an ignored staging directory, imports with separate build userdata, exports both platforms from the same source, adds instructions/known issues/change log/project/font/engine licenses, checks ZIP integrity and writes per-file and archive SHA-256 manifests. It never copies player saves, test scripts, local logs, credentials or the feedback database. Candidate builds force ordinary Game and disable switching into Test mode. The first-use normal game is offline; feedback endpoint is empty and automatic upload is disabled.

Mac is universal and ad-hoc signed, not notarized. Windows x86_64 is a validation candidate until tested on Windows. Export success does not establish installation or native play. Current evidence and exact source/hash are recorded in [verification](../verification/20260910-five-chapter/README.md).

## Save and feedback boundaries

Use the existing player save directory and backup mechanism. New layout state is additive and its completions are replay-validated. Back up the whole user data directory before updating or reverting; an older game can discard an unknown new chapter on subsequent saves. QA must use a separate user directory and verify it before starting ordinary Game. Do not distribute an isolation override with the public package.

Ratings are optional, unanswered values remain absent, opinions may be saved on incomplete tasks. Agent and automated sources remain distinct from external players. [Local receiver setup](../../server/README.md) covers synthetic integration, consent, queue limits, receipts, deletion, private reports and retention. No service is deployed publicly in this scope.

## Steam preparation — approval pending

Suggested title: 冯诺伊曼瓶颈 / Von Neumann Bottleneck. Short description: 从逻辑门搭起机器，再探索等待、缓存、协作与数据布局。自由设计、观察真实运行、寻找自己的优化方案。Free public development candidate; no paid access, in-app purchases or custom account requirement.

Use the same frozen content for direct download and a future Steam Playtest depot. A Playtest has its own AppID linked to a main store page; access is free ([Steamworks](https://partner.steamgames.com/doc/features/playtest)). Do not add Steam IDs or credentials until the owner provides them. Prepare the main page, Playtest relationship, OS-specific depot launch executables, language metadata, actual current screenshots, privacy/data description, support link and known issues. Check clean installation, offline boot, save/update/restart, uninstallation retaining saves, and Steam launch/overlay on each supported OS before submitting. No Steam onboarding, payment, identity entry, store upload or release has been performed.

All artwork is original procedural/vector work with bundled Noto Sans SC. Avoid invented playtime claims, mock-up screenshots represented as gameplay, or promises about future workshop/leaderboard support. After this candidate, prioritize external observations and convergence fixes rather than another chapter.
