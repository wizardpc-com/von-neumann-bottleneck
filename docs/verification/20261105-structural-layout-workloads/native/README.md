# Round7 native observation

A normal playable copy was prepared with the repository launcher and profile
`VonNeumannBottleneckChecks/layout_strategy/codex-round7-preview-20261105`.
The exact invocation and owned PID are in `initial.json`; `initial.log` is the
untouched engine output. It used the experimental main scene, ordinary startup,
windowed1280×720, and no test/capture script or fixture data.

CUA attempted to observe the existing Godot app. The returned result was:
“The Mac is locked and automatic unlock could not unlock it.”
No mouse or keyboard input was sent. `lock-observation.json` records this
NOT_RUN outcome and the exact process command checked before cleanup.
Root stopped only owned PID86113 with SIGTERM; its wrapper observed exit−15.
This is cleanup, not graceful-exit or native interaction acceptance.

The previous round's successful native route is historical. It does not verify
the new structures, contextual starter or copy-forward flow. This round's
scripted GPU checks, process reopens and ordinary headless startup remain
separate evidence. Manual follow-up should play the pair's RAM challenge,
compare phased layouts, explicitly save and reopen, then try a genuine earlier
profile in a backed-up isolated copy.
