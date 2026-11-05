# Limited native challenge loop — 2026-11-04 local

Earlier Round6 CUA attempts were blocked by the locked Mac. A fresh attempt at
`20261105T043946Z` succeeded after the ordinary QA lab launched. Root used only
the CUA native-app interface for mouse and keyboard; no scripted test driver or
simulation helper operated this scene. The [invocation](20261105T043946Z/invocation.json)
records the exact isolated profile and engine command.

Observed directly in the returned native screenshots:

1. Mouse **Run plan** creates run1 with Q1/total/RAM/copy307/2456/2176/0.
2. Mouse **Challenges**, then **Try: all requests ready**, opens the actual
   preview with Q1≤350/copy≤0 and remeasured direct-source target.
3. Mouse **Accept target** returns to a saved, tied target. The original
   group1/tile17 draft remains visible behind the popup.
4. Escape returns to that draft. Clicking the query-group editor, selecting its
   text, typing2 and pressing Command+Enter creates only run2, measured as
   group2/tile17. It ties307/2456/2176/0.
5. Clicking the record-tile editor, typing1 and Command+Enter creates only run3:
   **339/1368/1088/0**, visibly **improved by1088 cycles** under the saved350/0 rule.
6. Mouse Challenges → **Share attempt with target goal** opens readable selected
   `VNBSC1` text containing goal350/0 and plan group2/tile1, with matching metrics.
   No third-party message or upload was sent.
7. Escape twice, mouse Exit, then **Save and exit** closes the gameplay process
   normally with exit0. QA project settings were restored byte-for-byte.

The first starter click's combined observation timed out and reset the CUA kernel.
After rebinding the app, a screenshot showed the completed preview, so the click
was not repeated. This is a tool observation timeout, not an engine crash.
Full native screenshots remain in the task's CUA tool history; they are not
the separately archived scripted GPU PNGs. Native screenshots were2940×1846,
rescaled by the chat viewer, despite the command's1280×720 request. This receipt
does not use native screenshots as a minimum-size layout assertion.

After exit, root read the two real isolated saved files and archived exact copies:

- [Target inputs](20261105T043946Z/layout_strategy_challenges_v1.json) contain the
  original accepted direct-source goal350/0, not the later improved reply.
- [Notebook inputs](20261105T043946Z/layout_strategy_notebook_v1.json) contain the
  group2/tile1 draft and unchanged unlimited personal goal.
- [Hashes](20261105T043946Z/saved-file-sha256.json) bind both archived copies to
  the actual profile files. [Engine log](20261105T043946Z/session.log) has no
  Godot errors; it includes a macOS keyboard CapsLock-LED informational line.

This limited Chinese path establishes native popup mouse activation, numeric
Command+Enter, real improvement, immutable-goal reply generation and ordinary
save/exit. Native clipboard paste/copy, keypad input, language/settings/feedback
routes, drag/resize, same-profile native reopen and the full English path were
not exercised here. Their scripted checks or separate process evidence should
not be relabeled as native acceptance. Exports, other platforms, newcomer
understanding, long sessions and audio remain outside this receipt.
