#!/usr/bin/env python3
"""Install a validated certificate pair and restart only the VNB 8443 edge."""
import argparse
import fcntl
import http.client
from importlib.util import module_from_spec, spec_from_file_location
import ipaddress
import os
from pathlib import Path
import shutil
import ssl
import subprocess
import tempfile
import time

monitor_spec = spec_from_file_location("release_monitor", Path(__file__).with_name("monitor-release.py"))
monitor = module_from_spec(monitor_spec)
monitor_spec.loader.exec_module(monitor)

TLS = Path("/etc/vnb-feedback-public/tls")
HOST = "feedback.yanruiqing.com"
NAMES = ("fullchain.pem", "key.pem")
OPENSSL = "/usr/bin/openssl"


def openssl(*args):
    return subprocess.check_output([OPENSSL, *map(str, args)], stdin=subprocess.DEVNULL,
                                   stderr=subprocess.DEVNULL, timeout=10)


def leaf(certificate):
    return openssl("x509", "-in", certificate, "-outform", "DER")


def expiry(certificate):
    value = openssl("x509", "-in", certificate, "-noout", "-enddate").decode("ascii")
    return ssl.cert_time_to_seconds(value.strip().split("=", 1)[1])


def validate(chain, key):
    openssl("verify", "-purpose", "sslserver", "-verify_hostname", HOST, "-untrusted", chain, chain)
    openssl("x509", "-in", chain, "-noout", "-checkend", str(30 * 86400))
    if openssl("x509", "-in", chain, "-pubkey", "-noout") != openssl("pkey", "-in", key, "-pubout", "-passin", "pass:"):
        raise ValueError("certificate and key do not match")


def restart_edge():
    subprocess.run(["/usr/bin/systemctl", "restart", "vnb-feedback-public.service"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)


def require_served(bind, expected):
    deadline = time.monotonic() + 25
    while True:
        try:
            _, served = monitor.probe_edge(bind)
            if served == expected:
                return
        except (OSError, ValueError, http.client.HTTPException):
            pass
        if time.monotonic() >= deadline:
            raise ValueError("served certificate or release health did not match")
        time.sleep(0.5)


def copy_private(source, target):
    with os.fdopen(os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as output, source.open("rb") as content:
        shutil.copyfileobj(content, output)
        output.flush()
        os.fsync(output.fileno())


def rotate(directory, chain, key, bind):
    with tempfile.TemporaryDirectory(prefix=".vnb-cert-", dir=directory) as temporary:
        staged = Path(temporary)
        current = [directory / name for name in NAMES]
        candidate = [staged / name for name in NAMES]
        previous = [staged / (name + ".previous") for name in NAMES]
        for source, target in zip((chain, key), candidate):
            copy_private(source, target)
        validate(*candidate)
        old_leaf, new_leaf = leaf(current[0]), leaf(candidate[0])
        if old_leaf == new_leaf:
            require_served(bind, old_leaf)
            return False
        if expiry(candidate[0]) <= expiry(current[0]):
            raise ValueError("candidate certificate does not extend expiry")
        for source, target in zip(current, previous):
            copy_private(source, target)
        try:
            for source, target in zip(candidate, current):
                source.replace(target)
            restart_edge()
            require_served(bind, new_leaf)
        except (Exception, KeyboardInterrupt):
            try:
                # Copy so the known-good pair remains together if recovery fails.
                for i, target in enumerate(current):
                    restore = staged / (NAMES[i] + ".restore")
                    copy_private(previous[i], restore)
                    restore.replace(target)
                restart_edge()
                require_served(bind, old_leaf)
            except (Exception, KeyboardInterrupt):
                recovery = directory / (".recovery-" + staged.name.removeprefix(".vnb-cert-"))
                recovery.mkdir(mode=0o700)
                for source, name in zip(previous, NAMES):
                    source.replace(recovery / name)
                raise RuntimeError("rollback unverified; inspect the private .recovery-* pair") from None
            raise RuntimeError("activation failed and prior certificate restored") from None
        return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("chain", type=Path)
    parser.add_argument("key", type=Path)
    parser.add_argument("--bind", required=True)
    parser.add_argument("--install", action="store_true", help="activate after operator approval")
    args = parser.parse_args()
    os.umask(0o077)
    try:
        ipaddress.IPv4Address(args.bind)
        validate(args.chain, args.key)
        if not args.install:
            print("VNB certificate candidate validated")
            return 0
        if os.geteuid() != 0 or TLS.is_symlink() or TLS.stat().st_uid != 0 or TLS.stat().st_mode & 0o077:
            raise ValueError("VNB TLS directory must be private and root-owned")
        for name in NAMES:
            path = TLS / name
            if path.is_symlink() or not path.is_file() or path.stat().st_uid != 0 or path.stat().st_mode & 0o077:
                raise ValueError("invalid installed pair ownership or mode")
        with Path("/run/vnb-feedback-certificate.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            changed = rotate(TLS, args.chain, args.key, args.bind)
    except RuntimeError as error:
        parser.exit(1, str(error) + "\n")
    except (OSError, ValueError, IndexError, subprocess.SubprocessError, http.client.HTTPException):
        parser.exit(1, "VNB certificate validation or installation failed\n")
    print("VNB 8443 certificate activated" if changed else "VNB 8443 already serves the validated certificate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
