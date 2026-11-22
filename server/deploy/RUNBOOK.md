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
list and the consent batch is approved for that same mode. Game and Test must
use disjoint batch names. Keep still-supported entries across upgrades because
existing consent may retain its original batch. The shipped offline Test ZIP
has no receiver and needs no entry. Add Test only for an independently
approved network-enabled public Test build. QA tools,
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

### Resource envelope on the shared VPS

The read-only audit found 34.05 GiB available on the 58.95 GiB ext4 root
filesystem (`/dev/vda2`), no project quotas, and VNB I/O charged to
`253:0` (`/dev/vda`). The prior 128 KiB request cap and 120 requests/minute
global upload budget allow 21.09 GiB/day of request bodies and up to 5.53
million records/day before other limits. The former 100,000 live-event
ceiling still allowed roughly 1.30 GiB of canonical payload alone
(100,000 × 13,922 bytes, a conservative bound from the whitelist). SQLite
adds rows, indexes, page slack and WAL. At a daily cadence, 30–31 full
high-water snapshots are roughly 39–40 GiB of payload-sized copies even
before SQLite overhead. Age-based cleanup reuses pages and does not shrink
the database file, and known-delete tombstones have no time or row-count
expiry. Restarts reset request counters. In the old maintenance order a
failed report or anomalous backup could prevent expiry rotation while new
snapshots accumulated. Separate directories on the same mount did not
provide a filesystem limit.

The initial playtest allocates **1 GiB live + 3 GiB operations** up front
from root and limits the physical capacity independently of traffic.
Reserve at least **4 GiB available on the backing root** using
`VNB_RELEASE_HOST_FILESYSTEM=/srv/ray/vnb_release`, the unmounted parent.
Require at least 9 GiB free before allocating the two images. Allocation
at the audited free-space sample leaves about 30 GiB, before any old files
are archived. Exclude both fixed-size images from generic full-file
backup jobs. Keep the image files root-only and never put them in Caddy's
state or document root.

| Budget | Behavior |
| --- | --- |
| Live SQLite | New records stop before a projected 48 MiB of occupied pages or 56 MiB of total pages, including incoming row/index allowance. Intake also stops below 256 MiB free on the separate 1 GiB live mount or below 4 GiB on root. The estimates leave room below the 64 MiB backup-file limit. The mount is the hard bound. |
| WAL and deletion | The 1 GiB mount includes the main file, WAL, SHM, freelist and tombstones. The 16 MiB journal-size target applies when SQLite resets the WAL. Long readers and large transactions can temporarily exceed it. Release backup copies 128 pages per step. The live floor leaves room for cleanup, WAL and known-installation deletion. A truly full live volume can still return 503 on deletion. |
| Backups | At most one full snapshot per UTC day, capped at 64 MiB. Check the main file's actual byte length and the logical page count including committed WAL before copying, then check the finalized staged file's actual length before publishing. The 30-day rotation can retain up to 31 UTC dates (1,984 MiB). Age-expired valid pairs rotate before creation, even with low space or an unrelated anomaly. Anomalous pairs stay private for review. Recent hashes are checked on restore, expired hashes before rotation. |
| Report and temporary output | Both current files are staged on the 3 GiB operations mount, with no prior current copies held during the build. Each maintenance file is capped at 128 MiB. The two staged reports together can use at most 256 MiB. Allowing 31 full snapshots, one additional 64 MiB staged snapshot and the two reports leaves 768 MiB nominal for ext4, triage, its journals and SQLite temp. New backups and report builds each require 512 MiB free on operations and the 4 GiB host floor. Failed builds leave the former report invalidated. |

At the storage gate, new uploads and unknown-installation deletes return
`503 storage_limit` without a receipt, row or tombstone. They consume the
normal request-budget attempt and the client keeps the operation pending.
Previously committed identical uploads still return their exact receipt;
known installations can delete, with a successful receipt only after SQLite
commits the tombstone and removal. Deleted installations continue to receive
410 on replay. SQLite I/O/full errors return retryable `503 storage_unavailable`
without claiming success. Separate limiters still return 429 when exhausted.
To recover, free legitimate capacity on the affected filesystem or provision
a larger dedicated volume with verified host headroom. Keep the latest
complete SQLite and all tombstones. If the main file exceeds the backup size
limit through historical free pages, pause intake and compact a verified
offline copy on separate bounded scratch storage before switching. Reports
can hit the service's memory or time limit at high data volumes. Keep the
maintenance alert active and check the first successful report at real load.

### Monitoring and alerting

The dedicated five-minute timer runs as the VNB maintenance UID with read-only
access to the release data and operations volumes. It checks receiver health and
intake, verifies the certificate and exact routes on the local 8443 binding
using the production hostname as TLS SNI, and checks the maintenance timer and
last job result, backup metadata and report freshness (36 hours), and disk
reserves. Backup freshness checks the newest managed pair and its size.
Maintenance verifies new checksums and verifies expired pairs before rotation.
Restore verifies hashes and replays tombstones. The monitoring job does not
rehash large snapshots every five minutes.
The monitor adds a separate ceiling of 10% of one CPU and 64 MiB of RAM.

The release receiver exposes process-lifetime aggregate refusal counters only
on IPv4 loopback at `/internal/release-health`. Caddy blocks this route. The
monitor alerts on 30 or more new rate refusals between samples, any new
storage/refusal/cleanup error, closed intake, or failures of the checks above.
The journal records fixed incident codes, recovery, and reminders every
24 hours while an issue persists. The private status file is
`/var/lib/vnb-release-monitor/status.json`. Both exclude player content, IP
addresses, request headers, receipt IDs and credentials.

The separate hosted probe should check exact `GET /v1/status` on the VNB
hostname and port 8443. Run
`python3 -B server/deploy/check-release-feedback.py --public --heartbeat`
to check this and the existing TLS routes in one invocation. Its JSON consists of only `checked_utc` (Unix UTC
seconds or null) and `ok` (boolean). Healthy samples return 200. Missing,
invalid, failed, future-dated or older-than-660-second samples return 503
with `ok:false`. Treat missing routes, TLS errors, any non-200, invalid
schema, stale timestamps or false status as failure after feature rollout.
The local TLS probe does not query `/v1/status`. Historical and disposable
rehearsal routes retain 404 for this path. HEAD and query variants are
outside the contract. Keep reasons, counters and details private.

The operator's hosted GitHub Actions notification subscription is the
unattended alert path. The VPS sends no mail or third-party webhook.
Configure and verify the subscription separately, and keep the hosted
check disabled for this route until the new deployment returns a healthy
sample. The expected notification delay is the next hosted run, plus the
local sample interval. Independent hosted TLS/health probes remain useful
if the VPS and heartbeat are unreachable.

### Update a deployed release to monitoring

After the frozen SHA and GO, stage the complete root-owned tree as in the
release cutover. Preserve the prior receiver unit, Caddyfile, monitoring
unit state, source symlink target and admission file with mode 0600 in a
root-only checkpoint. Keep both existing release volumes and database.
Pause the release timer and wait for the current maintenance run, then
stop the dedicated edge and receiver. Use the currently
active production bind and do not change DNS, firewall or any shared unit.

```sh
# Run after the checkpoint is saved and before changing current-release.
systemctl stop vnb-release-maintenance.timer
while systemctl show --value -p ActiveState vnb-release-maintenance.service | grep -Eq '^(activating|active|deactivating)$'; do
  sleep 1
done
systemctl stop vnb-feedback-public.service vnb-release-receiver.service
# Point current-release to the approved frozen tree and set maintenance.env.
code=/srv/ray/apps/vnb/current-release/server
for unit in vnb-release-receiver.service vnb-release-monitor.service vnb-release-monitor.timer; do
  install -m 0644 "$code/deploy/$unit" "/etc/systemd/system/$unit"
done
install -m 0644 "$code/deploy/vnb-feedback-public.caddy" /etc/vnb-feedback-public/Caddyfile
systemd-analyze verify /etc/systemd/system/vnb-release-{receiver,monitor}.service \
  /etc/systemd/system/vnb-release-monitor.timer
systemctl daemon-reload
systemctl start vnb-release-receiver.service
python3 -B "$code/deploy/check-release-feedback.py" --local
systemctl start vnb-release-maintenance.service
systemctl start vnb-feedback-public.service
systemctl start vnb-release-maintenance.timer
systemctl start vnb-release-monitor.service
systemctl enable --now vnb-release-monitor.timer
journalctl -u vnb-release-monitor.service -n 20 --no-pager
```

Set the approved frozen backend source commit in the existing
`maintenance.env` before the first maintenance run. Verify the deployed
receiver's I/O limits, heartbeat from an independent network (200, two
fields and fresh timestamp), private-path denial, and monitor timer's next
execution. Rehearse stale/failed heartbeat and recovery only with synthetic
fixtures or an isolated staging copy. If rollout fails, disable the monitor
timer, disarm its hosted route check, and restore the checkpointed dedicated
units, Caddyfile, and source target. Restart the dedicated receiver and
edge using the same live volume and latest tombstones, then re-enable the
original release maintenance timer.

### Renew the dedicated 8443 certificate

Read-only host inventory found the existing Let's Encrypt certificate
expires at 2027-02-20 09:03:06 UTC. The local and hosted checks start
alerting at 30 days. The verified renewal mechanism is the existing
VNB-only lego account and DNSPod manual DNS-01. The DNS owner creates and
removes only the issuance's TXT value at
`_acme-challenge.feedback.yanruiqing.com`. No scoped unattended DNS
credential has been approved. Keep the manual challenge and existing
account state on the VPS. Do not paste the prompt or values into logs,
chat, Git, or shell recordings.

On the authorized root terminal, once renewal is approved:

```sh
set +x
umask 077
vnb_acme=/srv/ray/apps/vnb/acme-public
read -rs -p 'Existing ACME account contact: ' vnb_acme_contact
printf '\n'
"$vnb_acme/lego" --path "$vnb_acme/state" --email "$vnb_acme_contact" \
  --dns manual --domains feedback.yanruiqing.com renew --days 30
unset vnb_acme_contact
# Wait for DNS owner confirmation and successful issuance before proceeding.
code=/srv/ray/apps/vnb/current-release/server
bind=$(sed -n 's/^VNB_PUBLIC_BIND=//p' /etc/vnb-feedback-public/listener.env)
issued="$vnb_acme/state/certificates/feedback.yanruiqing.com"
python3 -B "$code/deploy/install-release-certificate.py" "$issued.crt" "$issued.key" --bind "$bind"
python3 -B "$code/deploy/install-release-certificate.py" "$issued.crt" "$issued.key" --bind "$bind" --install
```

The first command verifies system trust, hostname, at least 30 days of
validity and key pairing. The installer also requires the new leaf to
extend expiry. It stages the pair privately, restarts only the dedicated
8443 edge and checks the actual served leaf, TLS and release routes. It
restores and verifies the prior pair on activation failure. A failed
rollback preserves a private `.recovery-*` pair under the dedicated TLS
directory. If interrupted mid-rotation, stop the dedicated edge, inspect
the private staging directory for the prior pair, validate the pair, and
restore both files before starting only that edge. Then verify hosted
health and expiry. This procedure leaves shared TLS, listeners and
firewall rules untouched.

### Deployed release private triage

Fetch a copy from an authorized operator machine into a private local
directory. Keep the HTML out of web roots, hosted artifacts, and chat.

```sh
umask 077
vnb_review=$(mktemp -d "${TMPDIR:-/tmp}/vnb-private-review.XXXXXX")
ssh -o BatchMode=yes ray-vps 'sudo -n -u vnb-feedback-maint -- /bin/cat /srv/ray/vnb_release/ops/reports/current/report.html' \
  > "$vnb_review/report.html" && open "$vnb_review/report.html"
```

Filter by edition mode, build batch, source and triage status. The receipt
ID identifies the exact accepted opinion. Use Test results as Test evidence
and classify QA or unsupported task versions separately. To set a status,
replace only the placeholder receipt and choose an allowed status
(`needs_review`, `reproduced`, `needs_information`, `fixed`,
`needs_retest` or `deferred`). The command runs under the release
maintenance UID with the dedicated read group and acquires the same
lock as daily maintenance. It writes only the private release triage
sidecar. Refresh under the normal maintenance unit after the edit:

```sh
ssh -o BatchMode=yes ray-vps 'sudo -n -u vnb-feedback-maint -g vnb-feedback-read -- /usr/bin/flock -w 15 /srv/ray/vnb_release/ops/backups/.maintenance.lock /usr/bin/python3 -B /srv/ray/apps/vnb/current-release/server/private_report.py --database /srv/ray/vnb_release/live/data/feedback.sqlite --triage /srv/ray/vnb_release/ops/reports/triage.sqlite --set-status REPLACE_WITH_RECEIPT_ID needs_retest'
ssh -o BatchMode=yes ray-vps 'sudo -n systemctl start vnb-release-maintenance.service'
ssh -o BatchMode=yes ray-vps 'sudo -n -u vnb-feedback-maint -- /bin/cat /srv/ray/vnb_release/ops/reports/current/report.html' \
  > "$vnb_review/report.html" && open "$vnb_review/report.html"
```

Only real review work uses production receipt IDs. Use a temporary SQLite
fixture to verify triage, refresh and deletion behavior. Refresh invalidates
the previous report before rebuilding and purges triage when its receipt
is removed. A fetch failure means the local copy may be incomplete.

Before approving a larger playtest, scale the two mounts and the matching
watermarks together. Budget operations for **31 × snapshot cap + one staged
snapshot + two staged report files + filesystem, triage and temp margin**.
Keep the operations free-space gate above the largest expected staging
write and preserve the 4 GiB backing-root floor. For example, a separately
approved 2 GiB live / 6 GiB operations profile could use 96 MiB occupied,
112 MiB projected file and 128 MiB actual snapshot caps, 512 MiB live free,
768 MiB operations free, and 256 MiB/file for maintenance. That profile
leaves 1,536 MiB nominal after 31 full snapshots, one staged snapshot and
the two reports. Update the seal's exact expected image sizes and the
source/unit limits as part of that change. Stop the three VNB release units
and unmount before resizing images, then verify allocation, filesystem
size, restore/deletion and effective limits before reopening. No root
remount, shared quota change or host-wide trim change is required.

Release CPU ceilings are edge 25%, receiver 50% and maintenance 25% of
one CPU, totaling one of two vCPUs while maintenance runs. Memory maxima are
128 + 384 + 384 = **896 MiB**, with no cgroup swap. The live audit sampled
roughly 1.36 GiB available on a 3.64 GiB host. Limits are ceilings, so that
single sample does not establish headroom for the other workloads. The
configured historical localhost receiver, proxy and maintenance ceilings
add 1.75 CPU and 1,408 MiB if they all run. Leave their settings alone
and check actual concurrent use.

The staging receipt measured a 64 KiB write on each release volume. The
live unit's `io.stat` charged `7:0` and the operations unit's charged
`7:1`, while both reported zero delta on the backing device `253:0`.
Those loop numbers are specific to that mount lifecycle.

| Unit | Live loop read/write | Ops loop read/write | Backing `/dev/vda` read/write |
| --- | --- | --- | --- |
| Receiver | 8/4 MB/s | — | 8/4 MB/s |
| Maintenance | 4/1 MB/s | 4/3 MB/s | 8/4 MB/s |
| Public edge | — | — | 1/1 MB/s |

Before the receiver binds or maintenance opens SQLite, a short privileged
startup command obtains each mounted filesystem's actual major/minor,
confirms the matching VNB backing image through sysfs, and writes the loop
limits directly to that process's own cgroup v2 `io.max`. It first checks
the existing systemd backing cap, then reads back every required row from
the kernel. A missing mount, wrong image, missing I/O controller or failed
read-back fails the unit's startup. The receiver and maintenance workloads
retain their unprivileged IDs and have read-only access to cgroup controls.
The units follow the mounts they use, and each new start resolves the loop
numbers again. No persistent rule relies on `7:0` or `7:1`.

Count limits on the layer where the kernel attributes the workload. The
combined loop limits are **16 MB/s read and 8 MB/s write** across the two
workers, with the edge's separate 1/1 backing cap. The worker backing caps
also cover traffic that the kernel attributes directly to `/dev/vda`.
The filesystems still share the host device and queue. The loop caps do
not establish physical-device isolation or a cap for I/O outside these
cgroups. The existing system journal and TLS edge state remain on root,
with bounded unit logging and no access log.

Release maintenance has a separate unprivileged UID and an empty
capability set. The receiver owns live SQLite; a dedicated read group
receives read access only to the live DB/WAL/SHM. The receiver cannot
traverse the private operations mount or overwrite backups. Read-only WAL
requires both sidecars to be present with group-readable ownership; verify
the maintenance job with the real running receiver on Linux.

### Prepare the two bounded volumes

Run only after approval, on this host with `/dev/vda` as the measured
backing device and the cgroup v2 I/O controller enabled. This allocates exactly 4,294,967,296 bytes of image
capacity and must be scheduled as separate
maintenance work. Do not remount root or change quotas for other users.
For a first deployment, create `vnb-feedback-release` as below before this
step. If migrating, keep the existing account and add only the two
dedicated groups and the new maintenance account.

```sh
vol=/srv/ray/vnb_release
test -b /dev/vda
test ! -e "$vol/images/live.img" && test ! -e "$vol/images/ops.img"
test "$(df -B1 --output=avail /srv/ray | tail -1)" -ge "$((9 * 1024 * 1024 * 1024))"
getent group vnb-feedback-read >/dev/null || groupadd --system vnb-feedback-read
getent group vnb-feedback-maint >/dev/null || groupadd --system vnb-feedback-maint
id vnb-feedback-maint >/dev/null 2>&1 ||
  useradd --system --gid vnb-feedback-maint --no-create-home --shell /usr/sbin/nologin vnb-feedback-maint
install -d -m 0755 "$vol"
install -d -m 0700 "$vol/images" "$vol/live" "$vol/ops"
(umask 077; fallocate -l 1G "$vol/images/live.img"; fallocate -l 3G "$vol/images/ops.img")
for img in "$vol/images/live.img" "$vol/images/ops.img"; do
  mkfs.ext4 -q -F -m 0 -E nodiscard,lazy_itable_init=0,lazy_journal_init=0 "$img"
done
# Confirm the complete backing extents without changing the formatted filesystem.
fallocate -l 1G "$vol/images/live.img"
fallocate -l 3G "$vol/images/ops.img"
for img in "$vol/images/live.img" "$vol/images/ops.img"; do
  read -r blocks length < <(stat -c '%b %s' "$img")
  test "$((blocks * 512))" -ge "$length"
done
for unit in srv-ray-vnb_release-live.mount srv-ray-vnb_release-ops.mount vnb-release-volume@.service; do
  install -m 0644 "$code/deploy/$unit" "/etc/systemd/system/$unit"
done
systemctl daemon-reload
systemctl start srv-ray-vnb_release-live.mount srv-ray-vnb_release-ops.mount
systemctl start vnb-release-volume@live.service vnb-release-volume@ops.service
findmnt -M "$vol/live"
findmnt -M "$vol/ops"
chown root:root "$vol/live"; chmod 0755 "$vol/live"
chown root:vnb-feedback-maint "$vol/ops"; chmod 0750 "$vol/ops"
install -d -m 2750 -o vnb-feedback-release -g vnb-feedback-read "$vol/live/data"
install -d -m 0700 -o vnb-feedback-maint -g vnb-feedback-maint "$vol/ops/backups" "$vol/ops/reports" "$vol/ops/tmp"
```

An active mount is mandatory for each writer. A narrowly scoped root startup
oneshot checks the exact loop backing file, stops discard on that VNB loop
device only and verifies physical image allocation. This prevents periodic
host trim from reopening holes in the reserved images. The checks run on
each mount lifecycle. Do not use the bare mount-point directories if a
mount or its startup check fails. Mounts are pulled in by the release units.

### Migrate an already-active release

Keep the public edge paused during migration, stop the release timer and
wait for any maintenance job, then stop the receiver. Preserve the old
files read-only and take a consistent SQLite backup from
`/srv/ray/data/vnb/release/feedback.sqlite` using `storage.py backup`.
Prefer a staging destination on the new live volume. Compare old and new
counts including tombstones and check SQLite integrity. Record the staged
copy's SHA-256 and verify it after placing the copy at
`$vol/live/data/feedback.sqlite`, owner
`vnb-feedback-release:vnb-feedback-read`, mode 0640. Start the new
receiver without old copied WAL/SHM files. Copy verified existing backup
pairs and the private triage database into the new operations directories,
owned by `vnb-feedback-maint`, files 0600. Preserve the old paths only
for controlled operator rollback and retention. Leave the parent
`/srv/ray/backups` private.

Install only the new release receiver, maintenance and mount units plus
the release edge drop-in, and repoint `current-release` to the verified
source before restarting. Keep the public edge paused until the Linux
I/O gate passes. During a normal local check and the first private
maintenance run, verify while both workers are active:

```sh
stat -c '%U:%G %a %n' "$vol/live/data"/feedback.sqlite*
sudo -u vnb-feedback-maint -g vnb-feedback-read test -r "$vol/live/data/feedback.sqlite-wal"
sudo -u vnb-feedback-maint -g vnb-feedback-read test -r "$vol/live/data/feedback.sqlite-shm"
sudo -u vnb-feedback-maint -g vnb-feedback-read test ! -w "$vol/live/data/feedback.sqlite"
sudo -u vnb-feedback-release test ! -w "$vol/ops/backups"
sudo -u vnb-feedback-release test ! -x "$vol/ops"
live_dev=$(findmnt --noheadings --output MAJ:MIN --mountpoint "$vol/live")
ops_dev=$(findmnt --noheadings --output MAJ:MIN --mountpoint "$vol/ops")
test -n "$live_dev" && test -n "$ops_dev" && test "$live_dev" != "$ops_dev"
printf 'Expected current loop devices: live=%s ops=%s\n' "$live_dev" "$ops_dev"
for unit in vnb-release-receiver.service vnb-release-maintenance.service; do
  cg=$(systemctl show -P ControlGroup "$unit")
  test -n "$cg"
  cat "/sys/fs/cgroup${cg}/io.max" "/sys/fs/cgroup${cg}/io.stat"
done
```

Check the exact live and operations device rows and rates from the table.
Both worker cgroups must also show the backing `253:0` row at
8,000,000/4,000,000 bytes/s. The maintenance cgroup can disappear when its
oneshot ends. Use the operator's bounded pre-exec probe if needed. The
proof must run as each workload UID, in the same mount namespace and
cgroup as the workload, and show a positive `wbytes` delta on the limited
live or ops loop for a small fsynced scratch write. The maintenance UID
writes its scratch file only on ops. Verify that its live loop read cap
is installed even if the read falls in page cache. No shared cache drop
or throughput stress is needed. For a standalone pre-cutover check, the
startup helper also accepts its own exact cgroup under transient
`vnb-release-io-probe-receiver.service` or
`vnb-release-io-probe-maintenance.service`, with the same worker backing
cap configured. Always check again inside the real production units.

Test a restart after a disposable remount that changes loop assignments.
Recheck after production remounts and reboots. Do not promote if a workload
registers I/O on a device without the expected effective cap, even if the
backing row is present. If staging cannot prove the capped path, keep
public intake paused or keep the existing deployment and resolve device
attribution before switching. After the I/O gate passes, check the real
maintenance snapshot digest and mode. After enabling the edge, confirm
its backing row at 1,000,000/1,000,000 bytes/s and verify protected service
state from the existing host receipt. Roll back by pausing release and retaining
the new bounded volumes and newest deletion state while selecting compatible
code. Do not restore unbounded writable paths or start the old SQLite as an
alternative writer. The prior version's root maintenance is not a safe
fallback for the new isolation profile.

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
vol=/srv/ray/vnb_release
live=$vol/live/data/feedback.sqlite
rehearsal=$vol/live/rehearsal-$(basename "$work")

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
ln -s "$frozen" /srv/ray/apps/vnb/current-release
code=/srv/ray/apps/vnb/current-release/server
# Run "Prepare the two bounded volumes" now, then resume this block.
mountpoint -q "$vol/live"
mountpoint -q "$vol/ops"
install -d -m 0700 -o vnb-feedback-release -g vnb-feedback-release "$rehearsal"
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
