# Feedback receiver and local report: Windows audit

Baseline: `origin/main` `cfdee8a`, with the pre-release plan at `aede422`. This audit used synthetic records only. Raw test output is ignored under `.godot/pre-release-20261012/feedback-local/`.

## Result

**PASS — local Python behavior.** With `TEMP` and `TMP` pointed at the ignored workspace test directory, these checks passed on Windows Python 3.14:

| Command | Result |
|---|---|
| `python -X utf8 scripts/test-report-playtests.py` | Three report calibration groups passed |
| `python -X utf8 server/test_storage.py` | 3/3 |
| `python -X utf8 server/test_receiver.py` | 4/4 |
| `python -X utf8 server/test_community.py` | 9/9, including inherited receiver checks |
| `python -X utf8 server/test_delivery.py` | 3/3 |
| `python -X utf8 server/test_private_report.py` | 5/5 |

The three HTTP suites needed local loopback permission outside the network sandbox. Their final logs end in `-drain-deadline.txt`. The storage, private report and report calibration logs have `-after-fix` names, with the final private report run in `server-test_private_report.py-after-fix2.txt`.

**Root cause and change.** `sqlite3.Connection` used as a context manager commits or rolls back but does not close. Storage backup/count/merge and private report reads therefore held SQLite files open until garbage collection; Windows rejected `TemporaryDirectory` cleanup with `WinError 32`. These paths now close connections explicitly. Synthetic tests close their own database connections and HTTP error responses. The sidecar alias test still checks a lexical alias when Windows disallows creating a symlink.

A near-limit oversized request intermittently caused `WinError 10053` while the client read its 400 response. The receiver now drains at most twice the configured body limit in fixed-size chunks with a one-second total deadline before rejecting it. The accepted body limit and response code remain unchanged. A slow-trickle regression confirms the bounded 400 response and a subsequent successful health request on the single-threaded receiver.

**PARTIAL — privacy, deletion, and recovery.** The local suites exercise field allowlisting, fixed rejection codes, authenticated counts, ID-scoped deletion, tombstone-safe restore/merge, HTML escaping, private sidecar purge, and score/source separation. This is synthetic receiver evidence; it does not establish the operator's backup deletion policy, off-host restore, Windows ACL privacy of generated files, or a public HTTPS endpoint. Those remain deployment gates. The symlink-specific alias branch was unavailable under this Windows permission profile; the direct-path and lexical-alias checks passed.

**NOT_RUN.** `scripts/verify-feedback-local.py` needs an isolated Godot project and was reserved for the game audit. No Docker/Caddy/VPS operation, real player upload, or production backup restore was performed here.

## Exported package verifier portability

**PASS — static Python gate.** `python -X utf8 scripts/test-package-feedback.py` passed 5/5 on Windows. It checks exclusive `--exe`/`--app` arguments, both embedded and external PCK layouts against the platform and root manifests, tamper rejection, literal UTF-8 Chinese paths in Godot scene/override files, and the actual private report CLI output path. The latter confirms `os.fchmod` works in this Windows Python environment; it does not establish owner-only Windows ACLs. An older local Windows EXE also passed the embedded PCK footer/hash parser. Raw output is `scripts-test-package-feedback.py-unicode.txt` in the ignored local evidence directory.

**PASS — frozen Windows package over local HTTP.** The Windows-only candidate was exported from source `61edc8063078ee26882189efdb8bd56d70b87d8b` using Godot `4.7.1.stable.official.a13da4feb`, the local Windows release template, profile `HTTPLocal`, batch `LocalAcceptance20261012`, and `http://127.0.0.1:28765`. `python -X utf8 scripts/check-candidate-identity.py build/playtest-LocalAcceptance20261012-61edc8063078` passed ZIP/file hashes and build identity. `python -X utf8 scripts/verify-package-feedback.py --exe build/playtest-LocalAcceptance20261012-61edc8063078/Windows/Von-Neumann-Bottleneck.exe` passed `offline`, `online`, and `delete` in fresh actual exported EXE processes. The receipt confirms one committed row after retry, the same feedback ID in the private report and triage, and no revived event after tombstone merge into an old snapshot. The source EXE SHA-256 is `0f65f9808ba6f6e0a21851764c31eadaf843be007ced3035bfaf3665a4ae1831`; its embedded PCK SHA-256 is `347629ac3db7d3da881a63930ea8eb757b16095f0f7a0954aa67a4f2abcbd2ca`.

The build and verifier logs are under `.godot/pre-release-20261012/feedback-local/`; the private receipt and synthetic report are under `.godot/package-feedback/6df5d3f0389b/`. The verifier used literal UTF-8 Chinese paths in its external scene and QA override, isolated `APPDATA`/`LOCALAPPDATA`/`USERPROFILE`, and verified the saved work path stayed inside that runtime. This is headless synthetic local HTTP acceptance; native player input, a public endpoint, and VPS HTTPS behavior belong to separate gates.
