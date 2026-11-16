# Existing maintenance check: macOS SQLite sidecar boundary

The final sweep's [maintenance log](logs/test_maintenance.txt) contains one failure
out of four tests: the second daily backup sees its newly generated `.sqlite-shm`
file and fails the existing strict managed-file audit. This is not a passing gate.
No maintenance behavior or audit rule was changed for the offline product release.

On the observed host, `/usr/bin/python3` is Python 3.9.6 linked to SQLite 3.51.0.
The following files remain byte-identical to HEAD (`git diff --exit-code HEAD --`
these three paths returned 0):

| File | SHA-256 |
| --- | --- |
| `server/deploy/maintain.py` | `a6d550008af056b2ea391bbfd8d56efc897cf5b894d8a303e98efd47e8c98829` |
| `server/test_maintenance.py` | `43d92f137808dcda091777dd0b00cceb7f2f7ff4cd8c859a9f66181ec02db821` |
| `server/storage.py` | `04438e2a5f92889766a1c86dd71d8e97839cd84a571062c0b6c52c346ad0e72a` |

This bounded synthetic reproduction uses a temporary directory, no listener and
no player/server data. It keeps the source WAL writer open as a real receiver may,
while every destination connection is explicitly closed by the existing helpers:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
import sys, sqlite3, tempfile
from pathlib import Path
from contextlib import closing
sys.path.insert(0, 'server')
from storage import migrate
from deploy import maintain
print('Python', sys.version.split()[0], 'SQLite', sqlite3.sqlite_version)
with tempfile.TemporaryDirectory(prefix='vnb-shm-diagnostic-', dir='/private/tmp') as folder:
    root = Path(folder)
    live = root / 'live.sqlite'
    with closing(sqlite3.connect(live)) as writer:
        migrate(writer)
        writer.execute('PRAGMA journal_mode=WAL').fetchone()
        writer.execute('SELECT * FROM clients').fetchall()
        snapshot, _ = maintain.make_backup(live, root / 'backups', 'a' * 40)
        print('snapshot:', snapshot.name)
        print('files:', sorted(p.name for p in snapshot.parent.iterdir()))
        print('audit:', maintain.audit_backups(snapshot.parent))
PY
```

Observed result with generated basename
`vnb-feedback-20261116T092425Z-2d16a0e2`:

```text
Python 3.9.6 SQLite 3.51.0
managed files: ['vnb-feedback-20261116T092425Z-2d16a0e2.json',
 'vnb-feedback-20261116T092425Z-2d16a0e2.sqlite',
 'vnb-feedback-20261116T092425Z-2d16a0e2.sqlite-shm']
audit: ['vnb-feedback-20261116T092425Z-2d16a0e2.sqlite-shm: unexpected managed-prefix file']
```

A second bounded probe inspected the intermediate copy: backup created both WAL
sidecars; `PRAGMA journal_mode=DELETE` returned `delete`, removed `-wal`, but left
`-shm` even after destination close. Moving DELETE before the count or integrity
query did not remove the sidecar. This disproves the proposed test-connection-leak
explanation for this reproduction. It establishes behavior of this SQLite build,
not a universal Python 3.9 or macOS failure. An initial empty, already-closed WAL
source probe stopped earlier with `unable to open database file`; it was not used
as the matching reproduction.

Do not weaken the audit, blindly delete sidecars or claim that maintenance passed.
A privately staged, finalized snapshot followed by exclusive publication of its
main file avoided final sidecars in a separate synthetic experiment, but changes
to backup publication/crash/collision semantics require their own review and tests;
that approach was not implemented here.

The offline Game/Test packages exclude the server and have no feedback receiver.
This maintenance boundary does not affect their local saves or feedback exports.
No service was deployed, no production backup was touched, and no maintenance or
storage source was edited. The separate HTTP timeout compatibility fix is covered
by the passing `python39-fixed-receiver.txt` and `python39-fixed-community.txt`
logs and does not resolve or mask this SQLite failure.
