# Player release packages

Build both editions from the same full frozen commit SHA and use the same
explicit batch in all four archives. The commands use the existing Godot 4.7.1
engine and its matching Windows x64 and macOS Universal templates.

```bash
version=v0.6.1-playtest.1
batch=Players061-Release1
common=(--godot "$GODOT_BIN" --commit "$FROZEN_SHA" --platform both
        --mac-template "$MAC_TEMPLATE" --windows-template "$WINDOWS_TEMPLATE"
        --release-version "$version" --test-batch "$batch" --player-release)

python3 scripts/build-free-candidate.py "${common[@]}" --edition game \
  --feedback-endpoint 'https://feedback.yanruiqing.com:8443/v1' \
  --privacy-url 'https://feedback.yanruiqing.com:8443/privacy-player.html'
python3 scripts/build-free-candidate.py "${common[@]}" --edition test

short=${FROZEN_SHA:0:12}
python3 scripts/check-edition-delivery.py --player-release \
  "build/vnb-game-release-$version-$batch-$short" \
  "build/vnb-test-release-$version-$batch-$short"
```

Game is the player download for ordinary progress. It retains the existing
`EditionGame` save directories. It supports offline play and optional online
opinions. F8 or the in-task feedback button opens the form. The player chooses
Send for an opinion. The build sets `external_player` as the default source and
leaves consent state to the existing runtime.

Test retains the independent `EditionTest` save directories and opens all task
entrances. F8 records a local incident. The player can export a ZIP and share it
privately with the maintainer. The build has no online feedback receiver.

For the GitHub Release, attach these four ZIPs and their SHA-256 list. Label
each by OS and edition and list Game first. Include the frozen commit, exact
platform acceptance and signing status in the release notes. Test Pilot is a
separate invited-player lane and stays out of the public asset list. Package
identity checks establish the frozen inputs and archive contents. Native startup,
the published player privacy notice and feedback reachability need their own
acceptance before publication.

## Mac Game prerelease QA

Preflight the Mac Game ZIP using the full approved commit and SHA-256 from the
build receipt.

```bash
python3 .godot/mac-release-qa/verify-mac-player-release.py \
  --release-dir "$GAME_BUILD_DIRECTORY" --commit "$FROZEN_SHA" --sha256 "$MAC_GAME_ZIP_SHA256"
```

The default action only reads the archive. Add `--execute` after GO to run the
local Mac harness if it is present in the working checkout. It keeps the
original ZIP and packaged executable/PCK unchanged across both tracks.

- **Local Only.** Two windowed processes use an isolated `EditionGame` under
  a no-network sandbox. The probe chooses Local Only, earns the tutorial,
  saves a synthetic opinion through Keep Locally, and verifies the decline,
  progress and local opinion after restart.
- **Localhost Send.** A second isolated profile uses the same frozen bytes.
  The real Send control queues a synthetic opinion with networking denied.
  A restart allows only the fixture socket and checks the displayed receipt.
  An exact retry leaves one SQLite row. A third process confirms deletion and
  preserves Game progress and the local opinion. A stale retry is rejected.

Use `--track local-only` or `--track loopback` to rerun one track. Both receipts
cover synthetic QA. Browser download first launch and external delivery have
separate acceptance.
