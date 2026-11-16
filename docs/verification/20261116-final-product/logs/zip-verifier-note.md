# ZIP identity verifier correction

Product source remains `63584487c1af190a05d294bb758b7ab3fc610063`.
This change only repairs verification tooling; no exported archive, embedded
manifest, outer manifest, or SHA256SUMS file was rewritten.

Both Windows inventories matched exactly (10 files). Both macOS inventories
contained the expected 18 product files, but `ditto` encoded the internal
executable/PCK em dash as UTF-8 without ZIP flag 0x800 (observed flags: 0x8).
Python's default CP437 decoding therefore displayed `ΓÇö` instead of `—`.
The original failed receipt remains in `edition-delivery.txt`.

The verifier now strictly decodes unflagged macOS name bytes as UTF-8 and keeps
the original ZipInfo for reads. It rejects illegal paths, invalid UTF-8,
duplicate canonical paths, unlisted product files and unknown directories.
The exact product inventory and SHA-256 checks remain mandatory.

Each real macOS archive also contains 26 AppleDouble files. Their paths must
point to an expected product file or allowed directory. Header magic/version,
unique entry IDs (2/9), descriptor bounds and nonoverlapping data ranges are
checked. Metadata directories must be ancestors of accepted AppleDouble files.
Godot's empty `Contents/Frameworks` is allowed only for a listed app Info.plist
and an actual ZIP directory entry. This does not allow additional product files.

Fresh validation:

- `PYTHONPYCACHEPREFIX=/private/tmp/vnb-edition-pycache python3 scripts/test-candidate-packaging.py`
  passed; see `zip-verifier-packaging.txt`. Covers the existing dual-edition,
  legacy/offline/public packaging checks plus valid unflagged UTF-8/AppleDouble,
  malformed paths/encoding, normalized collisions, unknown files/directories,
  orphan/truncated/invalid/out-of-bounds/overlapping AppleDouble, absent
  Frameworks metadata target and changed product hash rejection.
- `python3 scripts/check-edition-delivery.py build/vnb-game-v0.6.0-Final20261116Game-63584487c1af build/vnb-test-v0.6.0-Final20261116Test-63584487c1af`
  passed for all four existing archives; see `zip-verifier-edition-delivery.txt`.
- `git diff --check -- scripts/check-candidate-identity.py scripts/test-candidate-packaging.py`
  passed. No Godot run or Git mutation was performed by this verification task.

These checks establish package/source/content/profile identity and archive
integrity; native interaction acceptance is recorded separately.
