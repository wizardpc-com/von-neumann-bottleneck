# Windows verification at Mac handoff

Godot `4.7.1.stable.official.a13da4feb`; Windows; current original Game build `polish-20260907T010358-76ef116`. No macOS or native desktop acceptance is implied.

- `fresh-check-results.json` and its 23 `.txt` logs: fresh resource import, actual isolated-user-directory probe, all 20 conventional suites and the short ordinary Game GUI replay (127 checks). Every process exited 0 and passed its checks.
- `ordinary-game-zh.txt`, `ordinary-game-en.txt` and the observation JSON files: prior final candidate's complete ordinary Game GUI routes, 461 checks per language. Tutorial, both construction branches, CPU and LOAD/STORE are earned through viewport GUI input, then Chapter 1 opens from the hub. These runs predate migration-only documentation/test-harness changes; game runtime sources are unchanged.
- `windows-package.json` and `windows-startup.json`: unchanged candidate EXE/ZIP hashes and awaited Game/Test startup results. The build manifest in the ZIP identifies its original source baseline.
- `evidence-manifest.json`: original and published file hashes. Absolute workstation repository paths are replaced with `<repo>`; line endings are normalized. No player files, telemetry, credentials or workstation backups are included.
- `publication.json`: verified GitHub source-tree identity and prerelease asset digests; Mac/native acceptance remains pending.

The fresh-copy run uses `scripts/verify-project.py`. Its initial diagnostic runs exposed a font bootstrap order issue and two tests that assumed an existing output directory. Those failed logs remain in the local `.godot/verification/` history. Final bootstrap imports the font before enabling the real global font, and the two tests create/check their own output directories without dropping behavioral assertions. The final run identifier is `20260907T015542Z-967a21a5`.

The certificate-store warning in Windows logs is nonfatal; other script/resource/test errors cause the runner to fail. Ordinary GUI replay is internal Godot mouse/keyboard dispatch. Native OS-level computer-use stopped when Windows was locked. Physical mouse feel, beginner comprehension, Retina/High DPI and Mac shortcuts still require direct observation.
