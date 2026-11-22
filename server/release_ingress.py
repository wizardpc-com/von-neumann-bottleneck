"""Opt-in admission and bounded, in-memory budgets for the public release lane."""
import hmac
import ipaddress
import json
import os
import re
import sqlite3
from pathlib import Path
import time


TOKEN = re.compile(r"[0-9a-f]{64}")
BATCH = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,63}")
COMMIT = re.compile(r"[0-9a-f]{40}")
# Requests per minute: (per address, total). Keep deletion budgets independent
# of uploads, and known installations independent of unclaimed identities.
LIMITS = {"upload": (30, 120), "known_delete": (30, 120), "unknown_delete": (4, 12)}
MAX_PEERS_PER_LANE = 1024
UNKNOWN_DELETE_CEILING = 10000
REHEARSAL_PREFIX = "vnb-rehearsal-"
LIVE_USED_LIMIT = 48 * 1024**2
LIVE_FILE_LIMIT = 56 * 1024**2
LIVE_FREE_RESERVE = 256 * 1024**2
HOST_FREE_RESERVE = 4 * 1024**3
HEARTBEAT = Path("/run/vnb-release-status/heartbeat.json")
HEARTBEAT_MAX_AGE = 11 * 60


def heartbeat(now):
    stamp = None
    healthy = False
    try:
        with HEARTBEAT.open("rb") as source:
            raw = source.read(129)
        value = json.loads(raw)
        if (len(raw) <= 128 and isinstance(value, dict) and set(value) == {"checked_utc", "ok"}
                and type(value["checked_utc"]) is int and value["checked_utc"] >= 0
                and type(value["ok"]) is bool):
            stamp = value["checked_utc"]
            healthy = value["ok"] and 0 <= now - stamp <= HEARTBEAT_MAX_AGE
    except (OSError, ValueError, RecursionError):
        pass
    return {"checked_utc": stamp, "ok": healthy}


def available_bytes(directory):
    space = os.statvfs(directory)
    return space.f_bavail * space.f_frsize


def host_has_reserve(directory):
    return available_bytes(os.environ.get("VNB_RELEASE_HOST_FILESYSTEM", directory)) >= HOST_FREE_RESERVE


def live_can_grow(db, directory, incoming):
    try:
        room = host_has_reserve(directory) and available_bytes(directory) >= LIVE_FREE_RESERVE
    except OSError as error:
        raise sqlite3.OperationalError("release volume unavailable") from error
    if not room:
        return False
    page_size = db.execute("PRAGMA page_size").fetchone()[0]
    file_bytes = db.execute("PRAGMA page_count").fetchone()[0] * page_size
    reusable_bytes = db.execute("PRAGMA freelist_count").fetchone()[0] * page_size
    projected_used = file_bytes - reusable_bytes + incoming
    projected_file = file_bytes + max(0, incoming - reusable_bytes)
    return projected_used <= LIVE_USED_LIMIT and projected_file <= LIVE_FILE_LIMIT


class ReleaseIngress:
    def __init__(self, entries, token, *, rehearsal=False):
        if not isinstance(token, str) or not TOKEN.fullmatch(token):
            raise ValueError("release edge credential must be 64 lowercase hex characters")
        if not isinstance(entries, list) or not 1 <= len(entries) <= 128:
            raise ValueError("release admission requires 1–128 build entries")
        self.builds = set()
        self.rehearsal = rehearsal
        self.label = "release-rehearsal" if rehearsal else "release"
        for entry in entries:
            if not isinstance(entry, dict) or set(entry) != {"build_version", "source_commit", "test_batch", "mode"}:
                raise ValueError("invalid release admission entry")
            version, commit, batch, mode = (entry[key] for key in ("build_version", "source_commit", "test_batch", "mode"))
            if (not all(isinstance(value, str) for value in (version, commit, batch, mode))
                    or not 1 <= len(version) <= 80 or any(ord(ch) < 32 for ch in version)
                    or not COMMIT.fullmatch(commit) or not BATCH.fullmatch(batch)
                    or batch.startswith(REHEARSAL_PREFIX) != rehearsal
                    or mode not in ("game", "test")):
                raise ValueError("invalid release build identity")
            identity = (version, commit, batch, mode)
            if identity in self.builds:
                raise ValueError("duplicate release build identity")
            self.builds.add(identity)
        self.batches = {mode: {batch for _, _, batch, edition in self.builds if edition == mode}
                        for mode in ("game", "test")}
        if self.batches["game"] & self.batches["test"]:
            raise ValueError("release Game and Test batches must be distinct")
        self.token = token
        self.window = -1
        self.rates = {}
        self.totals = {}

    @classmethod
    def load(cls, admissions, credential, *, rehearsal=False):
        return cls(json.loads(admissions.read_text(encoding="utf-8")),
                   credential.read_text(encoding="ascii").strip(), rehearsal=rehearsal)

    def admits_installation(self, client):
        return client.startswith(REHEARSAL_PREFIX) == self.rehearsal

    def admits(self, records):
        for record in records:
            payload = record["payload"]
            identity = tuple(payload.get(key) for key in ("build_version", "source_commit", "test_batch", "mode"))
            if (payload.get("source") != "external_player" or identity not in self.builds
                    or payload.get("source_batch") not in self.batches[identity[3]]):
                return False
        return True

    def peer(self, socket_peer, headers):
        # A loopback peer alone is insufficient on a shared host. Caddy
        # overwrites both headers and supplies the private edge credential.
        tokens = headers.get_all("X-VNB-Edge-Token", [])
        addresses = headers.get_all("X-VNB-Client-IP", [])
        if (socket_peer != "127.0.0.1" or len(tokens) != 1 or len(addresses) != 1
                or not TOKEN.fullmatch(tokens[0]) or not hmac.compare_digest(tokens[0], self.token)
                or "%" in addresses[0]):
            return None
        try:
            address = ipaddress.ip_address(addresses[0])
        except ValueError:
            return None
        if isinstance(address, ipaddress.IPv6Address) and address.ipv4_mapped:
            address = address.ipv4_mapped
        return str(address)

    def take(self, lane, peer):
        window = int(time.monotonic() // 60)
        if window != self.window:
            self.window = window
            self.rates.clear()
            self.totals.clear()
        per_peer, total = LIMITS[lane]
        peers = self.rates.setdefault(lane, {})
        count = peers.get(peer, 0)
        used = self.totals.get(lane, 0)
        if count >= per_peer or used >= total or (peer not in peers and len(peers) >= MAX_PEERS_PER_LANE):
            return False
        peers[peer] = count + 1
        self.totals[lane] = used + 1
        return True
