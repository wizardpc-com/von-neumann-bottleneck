# Player release packages

Build all four archives from the same full frozen commit SHA. Release2 uses a
separate admission batch for each edition and the same batch on both platforms
within an edition. Use Godot 4.7.1 and its matching Windows x64 and macOS
Universal templates.

`v0.6.1-playtest.2` is the unpublished Release2 draft identity.

```bash
version=v0.6.1-playtest.2
game_batch=Players061-Release2
test_batch=Players061-Release2-Test
common=(--godot "$GODOT_BIN" --commit "$FROZEN_SHA" --platform both
        --mac-template "$MAC_TEMPLATE" --windows-template "$WINDOWS_TEMPLATE"
        --release-version "$version" --player-release)
online=(--feedback-endpoint 'https://feedback.yanruiqing.com:8443/v1'
        --privacy-url 'https://feedback.yanruiqing.com:8443/privacy-player.html')

python3 scripts/build-free-candidate.py "${common[@]}" --edition game --test-batch "$game_batch" "${online[@]}"
python3 scripts/build-free-candidate.py "${common[@]}" --edition test --test-batch "$test_batch" "${online[@]}"

short=${FROZEN_SHA:0:12}
game_dir="build/vnb-game-release-$version-$game_batch-$short"
test_dir="build/vnb-test-release-$version-$test_batch-$short"
python3 scripts/check-edition-delivery.py --player-release "$game_dir" "$test_dir"
```

Game is the player download for ordinary progress. It retains the existing
`EditionGame` save directories. It supports offline play and optional online
opinions. F8 or the in-task feedback button opens the form. The player chooses
Send for an opinion. The build sets `external_player` as the default source and
leaves consent state to the existing runtime.

Both Release2 editions ask players to **Decline service** or **Accept service**
on first launch. Accept enables Basic play statistics to support game
improvements and a private read-only website for synced results on supported
tasks. The in-game personal results control waits for the first acknowledged
upload, then opens the player's results.
Declining keeps offline play available. Explicit opinion Send remains a
separate action, and players can revisit their choice in Feedback Settings.

Release2 Test retains the independent `EditionTest` save directories and opens
all task entrances. F8 opens the opinion form. Send shares the opinion alone
unless the player separately opts in to automatic statistics. The form also
opens local incident capture and ZIP export. The ZIP stays local until the player
chooses to share it. Game and Test keep their existing save identities.

The published `v0.6.1-playtest.1` package contract remains online Game and
offline capture Test with the shared `Players061-Release1` batch. Reproducing
that release uses its original frozen SHA and passes the two online flags to
Game only.

For the GitHub Release, attach these four ZIPs and their SHA-256 list. Label
each by OS and edition and list Game first. Include the frozen commit, exact
platform acceptance and signing status in the release notes. Test Pilot is a
separate invited-player lane and stays out of the public asset list. Package
identity checks establish the frozen inputs and archive contents. Native startup,
the published player privacy notice and feedback reachability need their own
acceptance before publication.

## Verification from a fresh checkout

The tracked mocked exporter exercises the package lanes. For real build output,
check the ZIP hashes and native structure from the directories above. Run the
native checks on macOS.

```bash
python3 scripts/test-candidate-packaging.py
(cd "$game_dir" && shasum -a 256 -c SHA256SUMS.txt)
(cd "$test_dir" && shasum -a 256 -c SHA256SUMS.txt)

game_app="$game_dir/macOS/Von-Neumann-Bottleneck-Game.app"
test_app="$test_dir/macOS/Von-Neumann-Bottleneck-Test.app"
python3 scripts/check-native-package.py --mac-app "$game_app" \
  --windows "$game_dir/Windows/Von-Neumann-Bottleneck-Game.exe"
python3 scripts/check-native-package.py --mac-app "$test_app" \
  --windows "$test_dir/Windows/Von-Neumann-Bottleneck-Test.exe"

python3 scripts/verify-mac-candidate.py --app "$game_app"
python3 scripts/verify-mac-candidate.py --app "$test_app"
```

The tracked Mac smoke uses a disposable app copy and a headless probe. It checks
the baked identity, locked edition and task access, repeated workbench saves,
and default-disabled sharing. It covers a different path from the rendered
first-launch and feedback acceptance below. For hosted native Windows checks,
use the [Windows release verification workflow](../.github/workflows/verify-release-windows.yml)
with the exact asset names, frozen commit, and ZIP digests.

## Native acceptance and operator evidence

On macOS, launch each verified app through its bundled entry in a fresh,
disposable macOS account or VM with networking denied. Observe the initial
window and two equally sized service choices, choose Decline service, and quit normally. In Test,
also open the in-task opinion form with F8 and use local capture and ZIP export.
Record strict signature verification, local Apple execution and distribution
assessments, and the existing quarantine attributes. These results apply to the
OS and the copy being tested. A download-first-launch check needs a copy
downloaded through the intended distribution path.

For each verified app, use `codesign --display --verbose=4` for signer
details, `spctl --assess --type execute --verbose=4 --ignore-cache --no-cache`
for local Gatekeeper assessment, and `syspolicy_check distribution` where
available. Read quarantine with `xattr -p com.apple.quarantine` on the ZIP and
app. Preserve command output and exit status, including an absent attribute
or rejected assessment.

The Release2 rendered and localhost harness under `.godot/release2-qa/` is
operator-local, alongside the Release1 harness under `.godot/mac-release-qa/`.
In a separate profile restricted to localhost, verify Accept service shows
the disabled waiting control with no results URL. Keep the baked logical
receiver and direct its HTTP transport to the fixture. A mismatched
acknowledgement must leave the control disabled and the record pending. A
matching response from the fixture enables the control. The destination uses
`https://feedback.yanruiqing.com:8443/my-results.html` with an installation
credential in the fragment. Verify the destination shape without opening a
browser or retaining the generated link. Decline and loopback profiles must
hide the personal-results control. The notice link continues to point to
`/privacy-player.html` on the approved 8443 origin.

For the website itself, use an isolated receiver and two synthetic
installations. Verify empty results, synced results, separation between the
two installations, and cleared results after deletion through the same-origin
`POST /v1/my-results` read API. Record those separately from the Mac destination
check. An external smoke may check the public landing page and privacy notice
as static reads. Keep credentialed reads and all test writes on the isolated
receiver.

For Release2, retain evidence of Basic structured delivery without Send,
explicit opinion receipt after restart, one SQLite row per record on exact
retry, and confirmed deletion with local work preserved. Use synthetic
profiles and a loopback-only receiver. For published Release1 evidence, see
the [frozen release receipt](../docs/verification/20261122-public-release/README.md).
