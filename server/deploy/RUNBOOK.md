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
and a daily maintenance timer. The independent `8443` ingress has a recorded
limited-source synthetic acceptance. See the [connectivity runbook](../../docs/distribution/feedback-connectivity.md#独立公网入口)
for the dedicated proxy and its rollback. General player access needs separate acceptance.

## Local installation / later host installation

Use Python 3.9+ and `python3 feedback_server.py --database <local-file>` for loopback.
For Docker, create `server/data` writable by UID 65532, then `docker compose up --build`.
Compose publishes only 127.0.0.1. Its image listens on the container interface;
never publish that port on all host interfaces. The current localhost systemd
templates are separate from this Docker example; check their actual installed
paths, users, mounts, listeners and restart behavior before claiming host acceptance.

Caddy's `Caddyfile.example` hostname is deliberately invalid. Later configure real DNS, TLS,
firewall and a public privacy page before enabling client upload. Keep administration
loopback-only; Caddy blocks `/admin/*`. The historical receiver ignores forwarded IP
headers, so its per-address limit is shared behind a proxy. The opt-in release
receiver uses a separate authenticated edge and independent budgets below.
No raw request access logs. Process/service logs and private counts can reveal
availability without retaining player IP, note, token or query strings.

## Install the player privacy page

The candidate [player notice](privacy-player.html) is staged in source. The
operator must review both languages against the intended build and the actual
service before publishing it. Confirm the contact mailbox, explicit opinion
send behavior, optional statistics and scores, consent version, retention,
private report and annotation handling, and deletion. The QA page at
`/privacy.html` continues to describe the synthetic QA lane.

1. Save a copy of the active dedicated Caddyfile outside the web root. Install
   `privacy-player.html` as `/etc/vnb-feedback-public/www/privacy-player.html`,
   root-owned and readable by the dedicated service. Keep the existing
   `www/privacy.html` in place.
2. Validate the repository's `vnb-feedback-public.caddy` with the production
   `VNB_PUBLIC_BIND` and a protected `CREDENTIALS_DIRECTORY` that has the matching
   `fullchain.pem` and `key.pem`. Use `caddy adapt --validate --adapter caddyfile`
   with the candidate file while logged in as the operator. Install the validated
   file at `/etc/vnb-feedback-public/Caddyfile` and restart only
   `vnb-feedback-public.service`. The dedicated instance has its admin API off.
3. From an approved external test network, using normal TLS validation, check
   `GET /privacy-player.html` returns 200 and the approved player text, and that
   `GET /privacy.html` returns 200 with the QA text. Check `GET /v1/health` still
   returns 200 with the expected VNB environment. Verify 404 for `HEAD` and
   `POST /privacy-player.html`, `GET /privacy-player.html/`, and `GET /admin/report`.
   Check the notice link in the exact Windows and macOS builds intended for
   distribution. Real-player distribution also requires approval of target
   ingress sources. From the supported platforms and representative authorized
   networks, use a synthetic opinion to verify the matching client receipt,
   one row in the private report, and removal after confirmed deletion and
   report refresh. A working static notice leaves the firewall, ingestion
   policy and database unchanged.

If validation or smoke checks fail, restore the saved dedicated Caddyfile and
restart only the dedicated unit. Verify the previous QA page and health route,
then remove the staged player file if rolling back installation. If a player
build already links to this URL, pause distribution and preserve or restore the
approved notice for those installs as soon as possible. Keep the receiver and
its database, reports, and backups in place during a notice rollback.

## Dedicated TCP 8443 release cutover

Root executes the VPS steps after approval, from a frozen source bundle and
with separate approval and a network operator for firewall changes. The
commands below do not change any firewall rules. Keep the historical
receiver, TLS 28443, QA staging, TCP 80/443, and other applications untouched.
The existing dedicated 8443 service keeps its certificate, bind address and
hostname. Confirm certificate expiry and the existing renewal procedure.
The proxy defaults to loopback 18081. Only the dedicated release drop-in selects
18082. Release packets must arrive directly at the 8443 socket so Caddy can
overwrite the trusted address using the real socket peer. If a CDN or another
proxy is added, revisit this trust boundary before using forwarded addresses.

The release receiver admits `external_player` records only when the build version,
full source commit, build batch and Game/Test mode exactly match the approved
list and the consent batch is approved. Keep still-supported entries across
upgrades because existing consent may retain its original batch. QA tools,
synthetic staging and release rehearsal use separate admissions/storage. These
client-supplied labels classify records and do not authenticate players. The
edge overwrites both private headers and uses a root-managed credential shared
only by the two dedicated processes. Keep Caddy debug and access logging off.
The credential stays out of command arguments, service environment files,
adapted Caddy JSON and its autosave. Keep both units' journals private anyway.

The receiver allows up to 30 requests/minute/address and 120 globally for
uploads, with a separate equal budget for authenticated known-installation
deletes. Unseen or invalid deletion attempts share a smaller budget of 4/12.
Pre-upload deletion tombstones stop late uploads, up to the 10,000-tombstone
threshold for new unknown entries. Existing installations still delete at that
threshold. Both rate and edge concurrency limits can return retryable responses
during bursts. Check latency, 429/5xx, disk/backup growth and deletion with
representative client traffic before distribution. Shared NAT clients share an
address budget. Keep public admin, community reads and backup paths closed.

### 1. Stage privately

Preflight: confirm loopback 18082 is free, the existing VNB units are active
as expected, and the source, report and backup filesystems have space. Use the
existing private `storage.py check` to verify **clients, events and tombstones**
in the legacy SQLite, and confirm with the release owner that no historical
installations are still uploading or awaiting deletion on the public URL.
An empty event count alone cannot establish that. Stop before switching if
the shared public endpoint still has historical users or queued requests.
Retain a record of the original TCP 8443 firewall rule and enablement state.
Have the release owner verify the approved notice and contact against the
exact build.

Stage the frozen source as a complete root-owned tree under
`/srv/ray/apps/vnb/`, and stage the approved admission list as a root-owned
file outside the checkout. Each admission entry uses this shape, with the
actual values taken from the frozen playable build:

```json
[
  {
    "build_version": "EXACT_CLIENT_BUILD_VERSION",
    "source_commit": "FULL_LOWERCASE_40_HEX_CLIENT_SOURCE_COMMIT",
    "test_batch": "EXACT_CLIENT_BUILD_BATCH",
    "mode": "game"
  }
]
```

In one root shell, substitute the three operator inputs below. Use a new
private checkpoint directory per attempt. Stop if `current-release`, the
configuration or production DB already exists and this is meant to be a
first deployment. Establish ownership from the existing VNB layout before
changing it. The data, backup and apps parent directories must allow the
service accounts to traverse their own paths. Do not change historical
directories' permissions.

```sh
set -eu
set +x
umask 077
frozen=/srv/ray/apps/vnb/REPLACE_WITH_FROZEN_DIRECTORY
backend_commit=REPLACE_WITH_FULL_40_HEX_BACKEND_COMMIT
approved=/root/REPLACE_WITH_APPROVED_ADMISSION_JSON
work=$(mktemp -d /var/tmp/vnb-release-cutover.XXXXXX)
cfg=/etc/vnb-feedback-release
edge=/etc/vnb-feedback-public
edge_override=/etc/systemd/system/vnb-feedback-public.service.d/50-release.conf
rehearsal_override=/run/systemd/system/vnb-release-receiver.service.d/60-rehearsal.conf
live=/srv/ray/data/vnb/release/feedback.sqlite
rehearsal=/srv/ray/data/vnb/release-rehearsal-$(basename "$work")

test -r "$approved"
test -f "$frozen/server/deploy/check-release-feedback.py"
test ! -e "$live"
test ! -e "$cfg"
test ! -e /srv/ray/apps/vnb/current-release
test ! -L /srv/ray/apps/vnb/current-release
test ! -e "$edge_override"
test ! -e "$rehearsal_override"
getent group vnb-feedback-release >/dev/null || groupadd --system vnb-feedback-release
id vnb-feedback-release >/dev/null 2>&1 ||
  useradd --system --gid vnb-feedback-release --no-create-home --shell /usr/sbin/nologin vnb-feedback-release
install -d -m 0750 -g vnb-feedback-release "$cfg" "$cfg/rehearsal"
install -d -m 0700 -o vnb-feedback-release -g vnb-feedback-release "$(dirname "$live")" "$rehearsal"
install -d -m 0700 /srv/ray/data/vnb/release-reports /srv/ray/backups/vnb-release
ln -s "$frozen" /srv/ray/apps/vnb/current-release
code=/srv/ray/apps/vnb/current-release/server
install -m 0640 -g vnb-feedback-release "$approved" "$cfg/admissions.json"
printf 'VNB_SOURCE_COMMIT=%s\n' "$backend_commit" > "$cfg/maintenance.env"
python3 -B "$code/deploy/prepare-release-edge.py" "$cfg/edge.token"
python3 -B "$code/deploy/prepare-release-edge.py" "$cfg/rehearsal/edge.token"
printf '%s\n' '[{"build_version":"vnb-rehearsal","source_commit":"0000000000000000000000000000000000000000","test_batch":"vnb-rehearsal-smoke","mode":"test"}]' > "$work/rehearsal-admissions.json"
install -m 0640 -g vnb-feedback-release "$work/rehearsal-admissions.json" "$cfg/rehearsal/admissions.json"
for unit in vnb-release-receiver.service vnb-release-maintenance.service vnb-release-maintenance.timer; do
  install -m 0644 "$code/deploy/$unit" "/etc/systemd/system/$unit"
done
install -m 0600 "$edge/Caddyfile" "$work/Caddyfile.before"
if test -e "$edge/www/privacy-player.html"; then
  install -m 0600 "$edge/www/privacy-player.html" "$work/privacy-player.before"
fi
install -d -m 0700 "$work/caddy-credentials"
install -m 0600 "$edge/tls/fullchain.pem" "$edge/tls/key.pem" "$work/caddy-credentials/"
install -m 0600 "$code/deploy/vnb-release-upstream-auth.caddy" "$work/caddy-credentials/"
bind=$(sed -n 's/^VNB_PUBLIC_BIND=//p' "$edge/listener.env")
test -n "$bind"
VNB_PUBLIC_BIND="$bind" VNB_FEEDBACK_UPSTREAM_PORT=18082 CREDENTIALS_DIRECTORY="$work/caddy-credentials" \
  /usr/bin/caddy validate --config "$code/deploy/vnb-feedback-public.caddy" --adapter caddyfile
rm -- "$work/caddy-credentials/fullchain.pem" "$work/caddy-credentials/key.pem" \
  "$work/caddy-credentials/vnb-release-upstream-auth.caddy"
rmdir "$work/caddy-credentials"
systemd-analyze verify /etc/systemd/system/vnb-release-{receiver,maintenance}.service \
  /etc/systemd/system/vnb-release-maintenance.timer
```

The example expects a bare, unquoted `VNB_PUBLIC_BIND=<address>` in the
existing listener file and uses Bash for the commands. If the installed file
uses different quoting, supply the verified address to validation directly.
Keep the checkpoint private until rollback is closed. Check that the existing
`listener.env` has no `VNB_FEEDBACK_UPSTREAM_PORT` assignment.

### 2. Rehearse the public path on a disposable DB

Keep distribution paused. The network operator initially keeps the existing
8443 restriction or temporarily allows only nominated test networks.
Install a runtime receiver override and a rehearsal-only copy of the edge
drop-in. Keep all source/credentials and the production DB path separate.

```sh
install -d -m 0755 "$(dirname "$rehearsal_override")" "$(dirname "$edge_override")"
cat > "$work/receiver-rehearsal.conf" <<EOF
[Service]
LoadCredential=
LoadCredential=edge.token:$cfg/rehearsal/edge.token
ReadWritePaths=
ReadWritePaths=$rehearsal
ExecStart=
ExecStart=/usr/bin/python3 -B $code/feedback_server.py --host 127.0.0.1 --port 18082 --database $rehearsal/feedback.sqlite --release-admissions $cfg/rehearsal/admissions.json --release-edge-token-file \${CREDENTIALS_DIRECTORY}/edge.token --release-rehearsal
EOF
install -m 0644 "$work/receiver-rehearsal.conf" "$rehearsal_override"
sed 's@/etc/vnb-feedback-release/edge.token@/etc/vnb-feedback-release/rehearsal/edge.token@' \
  "$code/deploy/vnb-feedback-public-release.conf" > "$work/edge-rehearsal.conf"
systemctl daemon-reload
systemctl start vnb-release-receiver.service
python3 -B "$code/deploy/check-release-feedback.py" --local --rehearsal
install -m 0644 "$code/deploy/privacy-player.html" "$edge/www/privacy-player.html"
install -m 0644 "$code/deploy/vnb-feedback-public.caddy" "$edge/Caddyfile"
install -m 0644 "$work/edge-rehearsal.conf" "$edge_override"
systemctl daemon-reload
systemctl restart vnb-feedback-public.service
```

From a reachable external network with normal certificate trust and a local
copy of the frozen script, run:

```sh
python3 -B server/deploy/check-release-feedback.py --public --rehearsal --synthetic-write
```

Expect a mixed QA/player rejection, an exact retry receipt, confirmed deletion
twice, and rejection of the late upload. The tool sends deliberately false
forwarding headers while Caddy provides the authoritative ones. On the VPS,
verify the rehearsal DB has zero clients/events and at least one tombstone,
and the production DB does not exist. The dedicated maintenance timer must
remain off during rehearsal. Unit status and Caddy validation should be
checked without dumping credential files or live request headers.

```sh
python3 -B "$code/storage.py" check "$rehearsal/feedback.sqlite"
test ! -e "$live"
```

### 3. Switch the edge to clean production

Stop the edge first, then stop the rehearsal receiver. Remove only the two
specific rehearsal overrides you installed. Install the production drop-in,
which uses the same fresh production edge credential as the real receiver.
Never copy, merge or restore the rehearsal DB into production. Retain it
privately while reviewing evidence, then remove the disposable directory
under the operator's cleanup policy.

```sh
systemctl stop vnb-feedback-public.service vnb-release-receiver.service
rm -- "$rehearsal_override"
test ! -e "$live"
install -m 0644 "$code/deploy/vnb-feedback-public-release.conf" "$edge_override"
systemctl daemon-reload
systemctl start vnb-release-receiver.service
python3 -B "$code/deploy/check-release-feedback.py" --local
python3 -B "$code/storage.py" check "$live"
systemctl start vnb-release-maintenance.service
systemctl start vnb-feedback-public.service
systemctl is-active vnb-release-receiver.service
systemctl is-active vnb-feedback-public.service
ss -ltn '( sport = :8443 or sport = :18081 or sport = :18082 )'
```

Expected fresh counts are zero clients/events/tombstones. Expect 18082 on
IPv4 loopback and only the existing dedicated bind on 8443. Verify the first
backup and metadata and the current report under their separate private roots.
From a reachable external network run `python3 -B server/deploy/check-release-feedback.py --public`.
It uses normal certificate validation, only GET/HEAD, checks release health
through the authenticated edge, verifies the notices, and expects the gated
routes to return 404. Have the network operator then open only TCP 8443 for
the intended public networks. Repeat the same read-only check from an
ordinary network outside the original allowlist. Persist only the dedicated
units after that:

```sh
systemctl enable vnb-release-receiver.service vnb-feedback-public.service
systemctl enable --now vnb-release-maintenance.timer
systemctl list-timers vnb-release-maintenance.timer
systemctl show -p Result vnb-release-maintenance.service
```

No synthetic writes against production. Keep monitoring the three dedicated
units and their effect on the historical listeners. Configure an operator
alert for maintenance failure and check available disk. Privacy requests
require regenerating the current report and retaining the deletion tombstones
in every recovery. Use the backup/restore procedure below with the release
paths.

### 4. Rotate or roll back

For rotation, prepare a new root-only credential before planned downtime.
Use a unique new checkpoint and keep the previous credential private until
the switch is verified. Replace the one shared source file only while the
two consumers are stopped, so both systemd credential snapshots are reloaded.

```sh
rotation=$(mktemp -d /var/tmp/vnb-release-rotation.XXXXXX)
python3 -B "$code/deploy/prepare-release-edge.py" "$rotation/new"
install -m 0600 "$cfg/edge.token" "$rotation/previous"
systemctl stop vnb-release-maintenance.timer
# Wait for any active oneshot to finish, then stop the two consumers.
systemctl stop vnb-feedback-public.service vnb-release-receiver.service
install -m 0600 "$rotation/new" "$cfg/edge.token.next"
mv -Tf "$cfg/edge.token.next" "$cfg/edge.token"
systemctl start vnb-release-receiver.service
python3 -B "$code/deploy/check-release-feedback.py" --local
systemctl start vnb-feedback-public.service
# From an external network run the --public check before resuming the timer.
systemctl start vnb-release-maintenance.timer
```

If validation fails, repeat the rotation steps with `"$rotation/previous"`
as the input and use a fresh temporary destination. Keep credentials out of
terminal output, shell tracing, package artifacts and logs. Use only the
scoped systemd journal.

**Before distributing any release builds**, rollback can return the edge to
18081. First have the network operator restore the previous 8443 rule and
confirm the release DB is absent or still has zero clients, events and tombstones. Stop
the dedicated edge and release timer and wait for any maintenance oneshot.
Set `restore_absent_notice=yes` only after the release owner confirms no
distributed build links to the player notice. Then run:

```sh
systemctl disable --now vnb-release-maintenance.timer
systemctl stop vnb-feedback-public.service
systemctl disable --now vnb-release-receiver.service
if test -e "$rehearsal_override"; then rm -- "$rehearsal_override"; fi
if test -e "$edge_override"; then rm -- "$edge_override"; fi
install -m 0644 "$work/Caddyfile.before" "$edge/Caddyfile"
if test -e "$work/privacy-player.before"; then
  install -m 0644 "$work/privacy-player.before" "$edge/www/privacy-player.html"
elif test "${restore_absent_notice:-no}" = yes && test -e "$edge/www/privacy-player.html"; then
  rm -- "$edge/www/privacy-player.html"
fi
systemctl daemon-reload
systemctl start vnb-feedback-public.service
# Restore the recorded preflight enablement state of this one unit.
```

Run `--public-historical` from the historical test network. If the player
notice was absent at preflight and its absence was restored, verify
`GET /privacy-player.html` returns 404. Keep the approved notice if any
distributed build links to it. Once the release endpoint has
served real installations, keep release storage and its deletion tombstones
authoritative on 18082 when rolling back software. Repointing or silently
returning deletion success from an empty/historical DB would strand release
data. If a compatible release service cannot be restored immediately, pause
intake and distribution and keep the deletion contact available in the
approved notice. Never replace the live release DB with the rehearsal,
historical, or an older deletion state.

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
