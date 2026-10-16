# Feedback receiver operations — localhost phase

Operator: yanruiqing · contact: yanruiqing@agent.qq.com. This page describes the
separate localhost-only VPS receiver installed from
`97874c133069b4de4e964a86410048ea789acfd4`. It is not a public player endpoint.
Connect using the private SSH inventory; do not put the host address, credentials,
database, backups or reports in this repository or a public download. The earlier
[Ray VPS plan](ray-vps.md) and [general runbook](../../server/deploy/RUNBOOK.md)
retain their own dated scope.

## Running service and private checks

`vnb-local-receiver.service` runs as `vnb-feedback` on localhost port 18081.
`vnb-local-proxy.service` is an independent HTTPS proxy on localhost port 28443;
only exact health, upload, delete and static privacy-page routes are exposed there.
`vnb-maintenance.timer` schedules `vnb-maintenance.service` daily. The maintenance
unit requires the receiver and checks its health before backing up, so an idle or
stopped receiver is not treated as a successful maintenance run. The services and
timer are enabled; the first actual maintenance run completed with schema 2 and
zero events. Five backend suites and private SSH HTTPS route checks passed. The
final other-process PID/hash isolation audit remains open.

On the VPS, inspect state and the private journal before acting:

```sh
sudo systemctl status vnb-local-receiver.service vnb-local-proxy.service vnb-maintenance.timer --no-pager
sudo systemctl status vnb-maintenance.service --no-pager
sudo systemctl list-timers vnb-maintenance.timer --all
sudo journalctl -u vnb-maintenance.service -n 100 --no-pager
```

The receiver has no public report route. The current report files and triage data
are private under `/srv/ray/data/vnb/reports/`; view them only through the private
SSH session. After confirmed live deletion, refresh the private report and purge
stale triage entries by starting the installed maintenance unit, then check its
result before viewing the report:

```sh
sudo systemctl start vnb-maintenance.service
sudo systemctl status vnb-maintenance.service --no-pager
sudo journalctl -u vnb-maintenance.service -n 100 --no-pager
```

The daily command makes a consistent SQLite backup, writes managed hash/schema/
count metadata, refreshes the private report and triage, then removes only verified
managed backup pairs older than 30 days. The VPS-local backup policy is 30 days;
expired backup cleanup may wait until the next successful daily cycle. Off-host
backup is not configured. A failed or incomplete backup, missing metadata, hash
mismatch or unexpected managed-prefix file requires private human review. Inspect
the unit failure and journal; preserve the files rather than guessing what to
delete. There is no automatic external failure alert configured.

## Restore without reviving deleted feedback

A confirmed online deletion removes live records, not earlier backup bytes.
Necessary deletion tombstones remain until every backup or old receiver capable of
reintroducing the identity has expired. Before using an old backup, stop new intake,
stop the timer, **wait for any already-running maintenance service to finish**, then
stop the proxy and receiver. Do not interrupt an active backup or let the timer
restart the receiver during the recovery decision:

```sh
sudo systemctl stop vnb-maintenance.timer
sudo systemctl status vnb-maintenance.service --no-pager
# Wait until vnb-maintenance.service is no longer active.
sudo systemctl stop vnb-local-proxy.service
sudo systemctl stop vnb-local-receiver.service
```

Freeze the newest complete database, including deletion tombstones, with SQLite's
backup API. Use a new private directory and a separately verified managed backup:

```sh
sudo install -d -m 0700 /srv/ray/data/vnb/recovery-input-NEW
sudo python3 /srv/ray/apps/vnb/current-local/server/storage.py backup \
  /srv/ray/data/vnb/local/feedback.sqlite \
  /srv/ray/data/vnb/recovery-input-NEW/latest-full.sqlite
sudo python3 /srv/ray/apps/vnb/current-local/server/deploy/maintain.py restore \
  --backup /srv/ray/backups/vnb-local/vnb-feedback-UTC-ID.sqlite \
  --latest /srv/ray/data/vnb/recovery-input-NEW/latest-full.sqlite \
  --destination /srv/ray/data/vnb/recovery-NEW/feedback.sqlite
sudo python3 /srv/ray/apps/vnb/current-local/server/storage.py check \
  /srv/ray/data/vnb/recovery-NEW/feedback.sqlite
```

The restore command verifies backup identity and counts, merges the latest full
deletion state, and refuses to overwrite an existing target. Verify integrity,
counts, deleted-identity rejection and synthetic retry before switching any
receiver to the recovered database; then purge/regenerate private reports before
viewing them. If the newest full deletion state is missing or cannot be trusted,
**do not put an old backup online**. Keep the current database and all recovery
inputs private while the operator audits the loss. The [runbook](../../server/deploy/RUNBOOK.md#backups-and-restore)
has the full recovery boundary. Before restarting, check database/WAL/SHM ownership for `vnb-feedback` and the selected unit write-path allowlist; offline root maintenance can create root-owned SQLite sidecars.

## Future public entry — not active

The planned `feedback.yanruiqing.com` domain has not been purchased or resolved;
hosting/filing requirements have not been checked. The owner is keeping the
service on localhost. If public access is later prepared, the DNS worksheet is:

| Type | Host | TTL | Value |
| --- | --- | --- | --- |
| A | `feedback` | 300 seconds | `<VPS_PUBLIC_IPV4 from private inventory>` |

Do not add an AAAA record without verified IPv6 service. Public ports 80/443,
external TLS, exact routes, privacy page, DNS and an external-machine upload/
delete test require separate acceptance before a client uses that name. The
current Windows public online package has not passed those checks.
