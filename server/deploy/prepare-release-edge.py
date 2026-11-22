#!/usr/bin/env python3
"""Create a new private edge credential without printing it."""
import argparse
import os
from pathlib import Path
import secrets


def prepare(path):
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w", encoding="ascii") as output:
        output.write(secrets.token_hex(32) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("new_credential", type=Path)
    args = parser.parse_args()
    try:
        prepare(args.new_credential)
    except OSError:
        parser.exit(1, "Could not create a new edge credential at the supplied path.\n")
