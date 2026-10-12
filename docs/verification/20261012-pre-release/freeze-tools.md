# Candidate freeze tooling check — 2026-10-12

Source reviewed: `cfdee8a54f0ca2787f66f91ef4d0c4d4233dbf97` on `codex/pre-release-20261012`. No candidate was frozen from this source. The final source commit and batch are selected after integration.

The existing builder already archives one commit, applies `--second-act-profile` on both platforms, enables `--creation-journey`, uses the stable `VonNeumannBottleneckCandidates/representation/<profile>` directory and validated Service sibling, and leaves the feedback endpoint empty and automatic upload off by default. The authored manifest has 60 keys: core 40, Representation 5, Service 3, optional address Prediction 3, and creation 9. Candidate progress is separate from the production save; no migration is performed.

The Windows-hosted build path now packages the Mac export without calling `/usr/bin/ditto`. Its ZIP preserves symbolic links and marks the Mac app's `Contents/MacOS` executable entries runnable. The identity check covers every declared packaged file, rejects undeclared files under the platform directory, checks archive size/hash, notes, engine/platform identity and bundled project/font/engine licenses. The Mac package QA probe compares the exported journey's exact task keys with the 60-key manifest. A loopback HTTPS endpoint may be explicitly labelled `--local-feedback-test`; that label rejects non-loopback hosts. TLS tunnel and test certificate setup remain QA inputs, outside the distributable build.

Private template cache, without changing the global Godot install:

| File | SHA-256 |
| --- | --- |
| `build/template-cache/Godot_v4.7.1-stable_export_templates.tpz` | `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| `build/template-cache/templates/macos.zip` | `f9de131f5ed0210924b9b156aea43b1e20fd720dd97690e151081a65c0937a3e` |
| `build/template-cache/templates/windows_release_x86_64.exe` | `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07` |

The `macos.zip` file was extracted from `templates/macos.zip` in that cached TPZ. Its bytes match the archive entry; both ZIPs pass integrity checks, and `version.txt` reads `4.7.1.stable`. No independently authenticated upstream checksum was available in this cache.

Verification: `python -X utf8 scripts/test-candidate-packaging.py` PASS, including Mac executable permission and undeclared-file rejection; `python -X utf8 -m py_compile` for four changed Python scripts PASS; `git diff --check` PASS. Exported Windows/Mac binaries, Mac signature, native launch, and feedback receiver acceptance were **NOT_RUN** here. The integrator will run the final build and platform checks from the selected commit.
