# Portable receiver operations

The shipped client endpoint remains empty. Configure one stable HTTPS API root
ending in `/v1` only after the owner's deployment decision. The legacy origin-root
form remains supported. A changed configured string revokes consent; a DNS IP
change behind the same hostname does not. Never ship the administration token.

Start with one process and SQLite on persistent local disk. A small 1–2 CPU / 1–2 GB
machine is an initial sizing assumption, not a capacity guarantee. Measure batch
latency, rejected requests, disk growth and backup duration before increasing load.
No Godot engine is required on the server. Keep at least twice the database size
free for backups. Defaults: 30-day event retention, 128 KiB bodies, 32 records/batch,
120 requests/minute/IP, 100,000 event safety cap. Stop intake with 503 at capacity;
do not delete fresh data silently. Health is `/v1/health` (legacy `/health` retained).

## Selected shared VPS

The [Ray VPS deployment plan](../../docs/distribution/ray-vps.md) records the earlier
Compose staging/prod paths and ports; its 2026-10-04 `NOT_RUN` result describes that
historical check, not the current host state. The separate localhost deployment
templates use `vnb-feedback` on loopback port 18081, an independent Caddy instance
at `https://localhost:28443`, the `/srv/ray/apps/vnb/current-local` source symlink,
and a daily maintenance timer. They do not change the older staging instance or other Caddy
sites. Treat the templates as prepared until host installation, isolation and
end-to-end results are recorded separately. No public feedback domain is configured.

## Local installation / later host installation

Use Python 3.9+ and `python3 feedback_server.py --database <local-file>` for loopback.
For Docker, create `server/data` writable by UID 65532, then `docker compose up --build`.
Compose publishes only 127.0.0.1. Its image listens on the container interface;
never publish that port on all host interfaces. The current localhost systemd
templates are separate from this Docker example; check their actual installed
paths, users, mounts, listeners and restart behavior before claiming host acceptance.

Caddy's `Caddyfile.example` hostname is deliberately invalid. Later configure real DNS, TLS,
firewall and a public privacy page before enabling client upload. Keep administration
loopback-only; Caddy blocks `/admin/*`. The receiver ignores forwarded IP headers.
Behind a proxy its IP limit is an aggregate safety limit, not per-player capacity;
set an appropriate measured global budget and edge rate limits before public traffic.
No raw request access logs. Process/service logs and private counts can reveal
availability without retaining player IP, note, token or query strings.

## Backups and restore

The local daily timer calls the standard-library maintenance CLI from the complete
`current-local` source. Run it manually after a deletion and before viewing the
current private report:

```sh
python3 server/deploy/maintain.py daily \
  --database /srv/ray/data/vnb/local/feedback.sqlite \
  --backup-dir /srv/ray/backups/vnb-local \
  --report-dir /srv/ray/data/vnb/reports/current \
  --triage /srv/ray/data/vnb/reports/triage.sqlite \
  --source-commit FULL_40_HEX_SOURCE_COMMIT
```

`daily` uses SQLite's online backup API, including WAL data; never copy only the
live main file. It records the source commit, schema/counts and SHA-256 beside a
private snapshot, purges stale triage annotations and regenerates `current` report
JSON/HTML, then removes only its own backup pairs with matching managed metadata
older than 30 days.
Directories are mode 0700 and output files mode 0600. Managed-prefix orphan, partial, invalid or hash-mismatched backups fail maintenance visibly and remain private for operator review and removal under the 30-day policy. Check `systemctl --failed` and the maintenance journal; no external failure notification is configured. A confirmed live deletion
does not immediately erase earlier backups: they remain until their 30-day age
limit and the next successful daily cycle. Necessary deletion tombstones do not
expire with event or backup rotation. Off-host backup is not configured.

Before recovery, stop the maintenance timer, wait for any running maintenance to finish, then stop intake and the receiver so the timer cannot restart it. Preserve the latest **full** live
database (including tombstones) with `storage.py backup`, and freeze that snapshot.
Restore only into a new private directory distinct from live and backup directories:

```sh
install -d -m 0700 /srv/ray/data/vnb/recovery-input-NEW
python3 server/storage.py backup /srv/ray/data/vnb/local/feedback.sqlite \
  /srv/ray/data/vnb/recovery-input-NEW/latest-full.sqlite
python3 server/deploy/maintain.py restore \
  --backup /srv/ray/backups/vnb-local/vnb-feedback-UTC-ID.sqlite \
  --latest /srv/ray/data/vnb/recovery-input-NEW/latest-full.sqlite \
  --destination /srv/ray/data/vnb/recovery-NEW/feedback.sqlite
```

`restore` verifies the managed backup metadata/hash/counts, merges the frozen
latest full database so deletion tombstones defeat older events, checks the final
SQLite backup, and refuses to overwrite an existing path. Verify integrity,
counts, deletion behavior and synthetic upload/retry before switching the receiver
to the recovered database. If the latest full deletion state is missing or
untrustworthy, do not put an old backup online; these steps cannot eliminate data
loss when the latest state itself has been lost. Before starting a receiver after offline root-owned SQLite maintenance, verify ownership of its database and any WAL/SHM files. The selected writable directory and those files must belong to the receiver account; update the unit write-path allowlist if switching to a recovery directory. Protect and remove the temporary
latest-full snapshot under the same private retention rules after the recovery
decision.

## Migration / DNS cutover

1. Back up the full database (clients and deletion hashes, events, tombstones).
2. Lower DNS TTL in advance, e.g. 300 seconds. Start compatible code on the new host,
   restore the snapshot and verify synthetic operations with the same API version.
3. Prefer one writer: point both old and new reverse proxies at the new receiver
   during DNS propagation. Alternatively accept on both and keep immutable backups.
4. Stop intake briefly on both before final merge. `storage.py merge old-snapshot.sqlite
   new-offline.sqlite` is idempotent and transactional; conflicting identity/event
   content aborts instead of choosing a winner. Run again with the final old snapshot.
   **Deletion tombstones win over old events in either direction.**
5. Verify counts, hashes and deletion behavior, switch DNS, retain old proxy 48–72 h
   according to observed traffic, then retire it. Do not claim TTL alone prevents loss.
6. Roll back by switching proxies to a compatible full database, not a stale copy.

Tombstones retain only random installation ID, deletion-token hash and deletion time.
They prevent old snapshots or delayed retries recreating erased records. They have no
automatic expiry: prune only when every backup/old receiver capable of reintroducing
that identity has expired, under a documented operator retention decision.
A deleted installation must obtain a new random identity after explicit re-consent.

References: [Docker loopback publishing](https://docs.docker.com/engine/network/port-publishing/),
[Caddy request limits](https://caddyserver.com/docs/caddyfile/directives/request_body),
[Caddy proxy routing](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy).

The tombstone table also has a 100,000-row intake cap. At the cap, unknown-identity
deletion requests receive 503 and remain pending on the client; existing identities
can still be deleted. Review capacity rather than pruning still-needed tombstones.

## Private feedback review and deletion-safe sidecar

Run the report from the frozen complete repository (it reuses
`scripts/report-playtests.py`), on a private filesystem. The receiver container
needs only its existing receiver files. Do not add report downloads or triage
routes to Caddy. `private_report.py --database DB --output PRIVATE_DIR --triage
PRIVATE_SIDECAR` lists committed opinions by their receipt IDs; `--set-status ID
needs_review` creates an ID-linked review note and `--fix-build`, `--fix-commit`,
`--review-note` record later reproduction/fix work. See the [server guide](../README.md)
for valid states and full commands.

The sidecar is an optional separate private SQLite file, not a migration of the
receiving schema2. It contains review annotations and must be protected/retained
like feedback. After confirmed live deletion or retention, run:

```sh
python3 server/private_report.py --database /private/current/feedback.sqlite \
  --triage /private/current/private-triage.sqlite --purge-triage
```

Before bringing an old receiving backup online or reporting it, use the frozen
latest full database and `maintain.py restore` above, then purge the sidecar and
regenerate reports with `maintain.py daily --database` pointed at the selected
recovered database before viewing them. An old
sidecar never makes a missing feedback ID visible; an old receiving database
without newest tombstones can, so it must not be exposed. Delete superseded report
outputs and apply the approved backup retention/deletion policy to receiving and
sidecar snapshots. These commands alone do not prove off-host backups or an
external player endpoint.

Receiver `/admin/report` contains fixed-code rejection counts only since process
start, explicitly reset after restart. The local SQLite report marks persistent
rejection totals unknown. Neither captures rejected player text.
