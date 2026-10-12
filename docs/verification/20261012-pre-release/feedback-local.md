# Feedback receiver and local report: Windows audit

Baseline: `origin/main` `cfdee8a`, with the pre-release plan at `aede422`. This audit used synthetic records only. Raw test output is ignored under `.godot/pre-release-20261012/feedback-local/`.

## Result

**PASS — local Python behavior.** With `TEMP` and `TMP` pointed at the ignored workspace test directory, these checks passed on Windows Python 3.14:

| Command | Result |
|---|---|
| `python -X utf8 scripts/test-report-playtests.py` | Three report calibration groups passed |
| `python -X utf8 server/test_storage.py` | 3/3 |
| `python -X utf8 server/test_receiver.py` | 3/3 |
| `python -X utf8 server/test_community.py` | 7/7, including inherited receiver checks; repeated twice after the HTTP fix |
| `python -X utf8 server/test_delivery.py` | 3/3 |
| `python -X utf8 server/test_private_report.py` | 5/5 |

The three HTTP suites needed local loopback permission outside the network sandbox. Their final logs are in `server-test_receiver.py-final.txt`, `server-test_community.py-drain-1.txt`, `server-test_community.py-drain-2.txt`, and `server-test_delivery.py-final.txt`. The storage, private report and report calibration logs have `-after-fix` names, with the final private report run in `server-test_private_report.py-after-fix2.txt`.

**Root cause and change.** `sqlite3.Connection` used as a context manager commits or rolls back but does not close. Storage backup/count/merge and private report reads therefore held SQLite files open until garbage collection; Windows rejected `TemporaryDirectory` cleanup with `WinError 32`. These paths now close connections explicitly. Synthetic tests close their own database connections and HTTP error responses. The sidecar alias test still checks a lexical alias when Windows disallows creating a symlink.

A near-limit oversized request intermittently caused `WinError 10053` while the client read its 400 response. The receiver now drains at most twice the configured body limit in fixed-size chunks before rejecting it. The accepted body limit and response code remain unchanged. Two consecutive community runs then passed.

**PARTIAL — privacy, deletion, and recovery.** The local suites exercise field allowlisting, fixed rejection codes, authenticated counts, ID-scoped deletion, tombstone-safe restore/merge, HTML escaping, private sidecar purge, and score/source separation. This is synthetic receiver evidence; it does not establish the operator's backup deletion policy, off-host restore, Windows ACL privacy of generated files, or a public HTTPS endpoint. Those remain deployment gates. The symlink-specific alias branch was unavailable under this Windows permission profile; the direct-path and lexical-alias checks passed.

**NOT_RUN.** `scripts/verify-feedback-local.py` needs an isolated Godot project and was reserved for the game audit. No Docker/Caddy/VPS operation, real player upload, or production backup restore was performed here.
