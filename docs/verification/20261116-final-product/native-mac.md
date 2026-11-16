# Actual macOS Game Edition input · 2026-11-16

Apple M2, Godot4.7.1 Compatibility OpenGL, actual frozen exported Game binary/PCK.
QA app: `.godot/package-qa/7946f5b83bfd/Von-Neumann-Bottleneck-Game.app`.
Only the external QA user-directory override differs; binary/PCK hashes match
`logs/exported-probe-game.json`. The shell launch used the generated sandbox profile
which denies access to ordinary player/candidate save roots. Input was through CUA.

Observed sequence: bright laboratory; Enter terminal; Game Edition v0.6.0 caption;
keyboard Chinese→English; pointer journey map with normal locked gates; enter
Wiring Tutorial; pointer connect A→NOT→lamp; F6 A=0/lamp1; toggle input then F6
A=1/lamp0; right-click first wire to disconnect; authoritative Actual becomes —
and topology-change/run-again message replaces old results; reconnect and finish
all five real tutorial actions; completion card; Back to lab; earned1/57, next
half-adder task and lit globe; Cmd-Q.

The original shell session34876 returned exit0. Its shutdown stderr contained:

```text
ERROR: 1 shaders of type ParticlesShaderGLES3 were never freed
   at: ~ShaderGLES3 (drivers/gles3/shader_gles3.cpp:838)
ERROR: 1 RID allocations of type 'N5GLES36ShaderE' were leaked at exit.
```

A CUA state request following quit reopened the QA app; it displayed the retained
1/57 progress in Chinese. A second Cmd-Q followed by app inventory showed no running
game. Do not call the first post-quit window a failure to exit, or treat the language
reset as an independently verified preference-persistence bug. The QA log file was
reopened by that relaunch; the original exit diagnostics above come from the shell
session result. No claim of a clean diagnostic-free shutdown is made.

This establishes a representative native Game input/return route. Both Game and Test
also pass actual-binary scripted probes; it does not establish native Test keyboard
coverage, all tasks, Windows, Intel Mac, Gatekeeper downloaded first launch or audio
quality. Source GPU/controller checks have their separate scopes in the main receipt.
