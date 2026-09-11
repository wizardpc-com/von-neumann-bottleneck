# Portable receiver operations (examples, not deployed)

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

## Local installation / later host installation

Use Python 3.9+ and `python3 feedback_server.py --database <local-file>` for loopback.
For Docker, create `server/data` writable by UID 65532, then `docker compose up --build`.
Compose publishes only 127.0.0.1. Its image listens on the container interface;
never publish that port on all host interfaces. Docker/Caddy/systemd examples have
not been executed on this Mac; production installation is a later acceptance gate.
The service unit expects a dedicated unprivileged user, protected environment file
and a writable `/var/lib/vnb-feedback`; install these explicitly on the chosen host.

Caddy's example hostname is deliberately invalid. Later configure real DNS, TLS,
firewall and a public privacy page before enabling client upload. Keep administration
loopback-only; Caddy blocks `/admin/*`. The receiver ignores forwarded IP headers.
Behind a proxy its IP limit is an aggregate safety limit, not per-player capacity;
set an appropriate measured global budget and edge rate limits before public traffic.
No raw request access logs. Process/service logs and private counts can reveal
availability without retaining player IP, note, token or query strings.

## Backups and restore

`python3 storage.py backup live.sqlite snapshot-<timestamp>.sqlite` uses SQLite's
online backup API, including WAL data; never copy only the live main file.
`python3 storage.py check snapshot.sqlite` shows schema and row counts.
`python3 storage.py restore snapshot.sqlite fresh.sqlite` refuses an existing target.
Stop the receiver, restore to a new path, check integrity/counts, start against that
path, and exercise synthetic upload/retry/delete before switching traffic.
Protect backups like live data, keep a bounded 30-day rotation, and include deletion
tombstones from the newest database before exposing a restored old backup.

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
