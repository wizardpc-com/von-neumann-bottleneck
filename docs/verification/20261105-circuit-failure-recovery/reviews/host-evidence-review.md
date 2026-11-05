# Round10 host recovery evidence review

Independent read-only review by `audit_polish`, 2026-11-05. Root executed all
Godot invocations. No source edits, engine/native execution or Git mutation
were performed during this review.

## Observed model-recovery acceptance

The complete logs and result metadata for these invocations were inspected:

| Run under `.godot/circuit-recovery-checks/` | Runtime | Input path | Result |
| --- | --- | --- | --- |
| `20261105T112522Z` | frozen old runtime | Chinese headless callbacks | 124 checks, 7 failures, exit1 |
| `20261105T112836Z` | repaired candidate | Chinese viewport input | 144 checks, 0 failures, exit0 |
| `20261105T112914Z` | repaired candidate | English viewport input | 144 checks, 0 failures, exit0 |

All three recorded the same host fixture SHA256:
`e0913fe9a1768d905b81c4134cc0b3cef19cf1eb8862022524188afe7199558e`.
Their log hashes were independently recomputed and match their result metadata.

Old simulator:
`ea22934e27dc08fcc1cc64c7158f5f028bf6a5a7150eee02b56c834bf502b371`.
Repaired simulator, still matching the current checkout during review:
`3ed8eb32b91b9b7b00fcd9a5b8fa7c25f0095e9c561389632b448e2b51723462`.

The old runtime's seven failures directly concern last-valid carry, corrected
preview/Debug recovery, error clearance and the missing recovered HOLD boundary.
It reaches the fixture's FAIL marker without a parse or script crash. This is a
valid negative regression control.

The earlier `20261105T112423Z` attempt instead failed script compilation because
the fixture annotated the host as `HardwareFoundations` before autoloads entered
the tree. Root corrected the annotation to `Control` with deferred scene loading.
That initial attempt is fixture-failure evidence, not proof of the runtime bug.

The passing GPU routes check actual visible inputs and real Debug/Pause/Step
controls. Their ordinary pressed observer remains attached through down/up and
six settling frames and requires exactly one activation. This closes the
one-shot-observer evidence gap encountered in Round9. GPU execution remains
scripted viewport input; it does not establish native OS or exported acceptance.

## Six inspected raw frames and their limits

All six files were actually viewed under:

`.godot/verification/20261105T112607Z-5880555a/project/.godot/hardware-recovery-captures/`

The PNG headers independently report 1280 by720 for each file.

| Relative frame | SHA256 |
| --- | --- |
| `en/corrected-live-hold.png` | `aebcc6d862e4c97d80494c15f8108e4593502f8bd527393adc0a2f222eb246c2` |
| `en/failed-conflicting-drivers.png` | `bd1fe047c9abf2ee9c23fba745b417ffcc289ab904cc35dd219d054a15d97a6e` |
| `en/recovered-debug-hold.png` | `b72f9f7dac36759b5fa775a9d5708b1c7a8290843dbd80ab6d209cc84486be25` |
| `zh_CN/corrected-live-hold.png` | `9f32e39a01a72ef98e8e9afb84511cd283312b3e4432d41671d3c1d9177ad20d` |
| `zh_CN/failed-conflicting-drivers.png` | `a9aa35cd06a975093f68caaef4da2f077406d983241385314478f057d1950ddd` |
| `zh_CN/recovered-debug-hold.png` | `1d00a4f0a195fbf78eccc87bd81f9c183d607688989c483d82857b97d6e2b21b` |

The failed frames show the red failed/blocked status and conflicting driver
evidence. The corrected-preview frames show changed inputs and Q3 without
completion. The recovered Debug frames show successful Debug, Q3 and the
register component caption `Stored0=0x3`.

The first two frame types still show the register component caption as0,
despite authoritative runtime and Q already being3. They are partial-playback
observations after the fixture interrupts the initial write before reaching
its storage-boundary animation. The corrected preview is also captured at
the first source wave, so the B node still shows the preceding6. These frames
must not be used alone as settled visual proof of retained storage or fully
settled source values.

The compact test bench is scrolled. Some input controls and lower result text
are outside the instantaneous screenshot viewport, although the action helpers
check their visibility when operating them. English header/footer truncation
is visible. This review does not claim that every input or complete error text
is simultaneously readable.

## Newly strengthened presentation regression is still pending

During this review root changed the host fixture to SHA256:
`88170ef898b86d36d012996463782c381a3610c0f99dadeb0ece5e28bbf46b4c`.
This adds a real interrupted-playback caption assertion and steps the corrected
preview's first source wave before asserting its visible state.

The complete newer headless result
`.godot/circuit-recovery-checks/20261105T113442Z/`
is **142 checks, 2 failures, exit1**. It records the new fixture hash and the
same repaired simulator. The two failures are:

1. Failed Debug does not replace the interrupted previous playback's register
   caption with its real incoming storage.
2. The corrected preview's completed first source wave does not show its
   corrected inputs together with the retained-storage caption.

Static inspection supports the caption cause:
`_play_prologue_events()` clears the initial component-state snapshot but only
calls `_prepare_component_playback_state()` when the new event stream has a
`state_transition`. Failed pre-commit observations and live previews have no
such event, so an interrupted prior stream's caption can survive. The second
assertion combines input and storage-caption checks; the log alone does not
establish an independent source-wave defect.

The original144/0 GPU passes remain valid evidence for the earlier fixture and
runtime-recovery contract. They do not verify this newer presentation regression
or any subsequent production host edit. Root is integrating the bounded
presentation repair and owns fresh candidate checks. Earlier frames should be
preserved as diagnostic evidence.

No remaining defect is asserted in the simulator's last-valid carry patch from
these host observations. Current final acceptance is pending the strengthened
fixture and any host presentation repair, with fresh logs/source bindings and
updated raw frames.
