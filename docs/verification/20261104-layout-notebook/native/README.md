# Native input boundary

A fresh `cua.getState()` attempt in this round returned no native apps and:

```text
Native apps: Error: The Mac is locked and automatic unlock could not unlock it.
Ask the user to unlock the Mac manually before continuing.
```

No native click or key was sent and no ordinary GUI play sequence was started.
This round is **NOT_RUN for native input**, independently of the scripted GPU
checks and the actual headless restart/writer-process verification. The fourth
round's historical native observations do not establish notebook acceptance.
The native task was closed after recording this blocker; no lock-screen bypass
or unrelated process termination was attempted.
