# Owner's later deployment checklist

This checkout is offline by default. Server code, portable configuration, synthetic
integration and client UI are prepared; no production endpoint, domain, account or
key is filled in. No purchase, DNS change, public hosting or release occurred.

Before enabling public sharing:

1. Select host/region and budget; measure loopback load and test actual player regions.
   A 1–2 CPU / 1–2 GB single process with SQLite is a starting assumption, not a promise.
2. Obtain a stable domain; decide the actual privacy notice, retention including
   backups/tombstones, and applicable hosting/filing requirements with the provider.
   These jurisdiction-dependent decisions have not been made by this implementation.
3. Configure DNS, TLS, firewall, reverse proxy/body and rate limits. Test from intended
   regions; do not ship an IP or temporary vendor hostname. Keep admin private.
4. Install Docker/Compose or the systemd service on the chosen host. Test restart,
   read-only container, writable volume ownership, health, logs, disk-full behavior,
   backup recovery and the deletion-tombstone cutover procedure.
5. Publish a human-readable privacy page naming the actual destination/operator.
   Configure the single API root and release batch in the build. Review the notice
   version; leave upload off until the player chooses. Do not turn on public designs.
6. Seed only clearly separated synthetic test rows, confirm deletion and clean those
   rows before public use. Check source separation and small-sample suppression.
7. Configure Steam/Playtest separately, distribute a frozen source commit, and verify
   the actual Windows EXE and another Mac. Sign/notarize where applicable. No storefront
   promises about verified rankings, rewards or server-side anticheat.
8. Observe request rejection/disk/latency and private counts; record changes and roll
   back using compatible data, never a stale database missing deletion tombstones.

Use [the operator runbook](../../server/deploy/RUNBOOK.md) for exact local maintenance
commands. Public launch still requires the owner's explicit decision and host checks;
“prepared” does not assert that an untested production machine is ready for traffic.
