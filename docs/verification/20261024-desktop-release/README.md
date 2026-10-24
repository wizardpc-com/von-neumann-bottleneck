# Desktop offline release — 2026-10-24

[v0.5.0-alpha.4](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.5.0-alpha.4) is a public Alpha prerelease with Windows x86_64 and universal macOS downloads. Both packages were built from `2c4a9d8bdf132bd20491f4ef2a2ba2f25d770e51` with Godot4.7.1. Later main changes update documentation/download links only; the release tag identifies the packaged source.

Both include all60 tasks, normal Game rules, explicit isolated Test selection, stable CloudPlaytest save channels and no feedback receiver. No QA save/profile or override is distributed. Project/engine/font/asset notices accompany both. The submitted competition ZIP remains unchanged.

## Verification

- `python scripts/test-candidate-packaging.py`: PASS, including40/51/60 content scopes.
- `python scripts/check-candidate-identity.py build/playtest-Release20261024-2c4a9d8bdf13`: PASS for exact ZIP inventory, CRC, per-file/archive SHA256 and Mac executable permissions.
- Actual unchanged Windows EXE:17 package checks,14 Game/Test checks,39 navigation checks,97 bilingual terminal geometry/mode checks and50 cinematic checks PASS, including all4 natural decoder ends. See [results](results.json).
- Ordinary GPU launch with only QA-user-directory isolation: laboratory → Enter terminal → Enter tutorial → AltF4 normal exit0 observed through Windows Computer Use. No scene override, developer route or fabricated earned progress in that run. Audio used Dummy; audible behavior is not claimed.
- Mac [static structure](platform-structure.json): x86_64 + arm64 Mach-O slices, executable entry, PCK, version and ad-hoc signature flags. Windows cannot validate Gatekeeper, signature validity, first launch, saves or audiovisual behavior on Mac. No Mac native PASS is claimed.
- Uploaded server-side SHA256 values match all4 local assets. Source tag and public release are checked separately from main.

## Retained harness diagnostics

Initial probe inherited an obsolete assumption that full-journey startup refuses every QA directory; the corrected QA adapter checks the profile-binding function directly while preserving the source full-journey rule. A first GPU capture attempt targeted read-only `res://` paths; only the QA capture destination changed. A cinematic adapter restarted its own override main scene; it now explicitly targets actual startup. The next attempt reused the consumed viewing-history fixture; final verification uses a fresh isolated profile. Initial failure logs remain here, with final successes beside them. No production runtime or exported binary was changed to pass these checks.

Mac native validation, another machine's first launch, human newcomer/full-game experience and audible sync remain open. Download/package checks do not establish those results.

Local upload-ready copies and SHA256SUMS are in `E:/VNB/deliveries/Release-v0.5.0-alpha.4-20261024`.
