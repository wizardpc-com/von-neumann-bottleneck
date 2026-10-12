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

**PASS — static Python gate.** `python -X utf8 scripts/test-package-feedback.py` passed 4/4 on Windows. It checks exclusive `--exe`/`--app` arguments, both embedded and external PCK layouts against the platform and root manifests, tamper rejection, and the actual private report CLI output path. The latter confirms `os.fchmod` works in this Windows Python environment; it does not establish owner-only Windows ACLs. An older local Windows EXE also passed the embedded PCK footer/hash parser. Raw output is `scripts-test-package-feedback.py.txt` in the ignored local evidence directory.

**NOT_RUN — current exported package.** The frozen local-acceptance EXE and its matching manifest had not yet been produced for this gate. The full `offline → online → private report → delete/restore` run using `--exe` remains required. The Windows verifier copies the package before writing `override.cfg`, isolates `APPDATA`/`LOCALAPPDATA`/`USERPROFILE`, and checks the probe's work path stays under that isolated runtime.
