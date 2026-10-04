# Alarm and order result feedback

Presentation-only iteration from `2185f1caaf74d0ded6f21cf96086f404f8a936bf`, branch `ray/representation-playloop-20261003`.

## Scope

- Alarm actions use CLEAR priority, then FAULT, then HOLD. Official rows chain actual observed ALARM values; missing initial/observed data remains unavailable.
- During alarm playback the monitor identifies the previous observation, obtained from the actual incoming source port, including routed and renamed sources. Completion, stop and replay use actual observations without inventing a reset value. Blocked traces say observed, not committed.
- Two-orders Parts shows the real per-order budget. Each case keeps a separate cost/cycle verdict visible even when output bytes are compacted. Correct-output rows retain their independent pass/fail color.
- Current-order feedback uses only the latest catalog-qualified receipt. Earlier accepted orders and earned completion remain historical evidence, never current-run success.
- No simulator, thresholds, catalog gates, receipt formats, save formats or completion authority changes. Existing read-once and core comparison feedback remain unchanged.

## Regression evidence

Regression-first isolated run `20261004T163116Z-be76c459` reproduced alarm SET/CLEAR/state and order budget/current-result defects in English and Chinese. The preceding command rejected system Godot 4.6.3 before import/tests; all actual test runs used the official 4.7.1 engine.

Focused runs `20261004T163335Z-80424a62`, `20261004T163656Z-6647626a` and `20261004T164013Z-abdc1cb8` passed the evolving new regression, existing optional-result feedback and localization checks where selected. Final affected/adjacent run `20261004T164125Z-35c521b9` passed nine suites: alarm/order feedback, circuit simulation, exploration, hardware foundations UI, hardware prologue UI, localization, optional-result feedback, system applications and system lab UI.

Synthetic unit fixtures are explicitly separate from native campaign evidence. New coverage includes all 64 alarm official cases, CLEAR+FAULT priority, prior/current chaining, missing values, high impedance, blocked known/missing observations, replay/step restart, renamed source and nonzero output port, routing, cost boundary 24, cost39 failure, cycles86>66 failure, compact 16-output results, independent orders, historical completion followed by a failed rerun, receipt non-mutation and wrong-output custom-program feedback. English and Chinese action/result branches are covered.

## Native before-fix reproduction and initial blocker

An isolated copy of the saved `remaining-optionals-20261005` profile was made without editing completion data. Runtime started from exact parent tracked files plus two documented save-isolation project settings. Linux cloud desktop, Chinese, 1364×1024. Only the newly launched window60817411 was operated; five older game windows were untouched.

- Two-orders copied accepted compute setup cost24 still said cost was only recorded/no hard gate. Native switch to BalancedCPU/SlowRAM/Bus4 produced correct2/2 at94cycles and cost18, yet every result and header stayed green despite limit66. Historical completion remained visible.
- Alarm native official rerun passed64/64. Rows58/62/63 with CLEAR=FAULT=1 correctly output ALARM=0 but mislabeled action HOLD and state unknown→unknown.
- Native evidence was inspected in computer-use screenshot history, not saved screenshot artifacts.

Normal closing of only this QA window was rejected by the action reviewer. Saved JSON/workbench files were checked as readable/valid, and one exact retry following supplied authority was rejected again. No alternate close, kill, replacement native window, or workaround was attempted. The before-fix QA window remains open and preserved. Parent owns the pending user confirmation and has held remote publication.

At this initial handoff, post-fix native acceptance was **NOT RUN**, blocked by normal-close/relaunch lifecycle approval. The authorized resumption below supersedes that blocker. Automated source checks remain separate from native acceptance.

## Final automated verification

Frozen final source run `20261004T164306Z-674be529`: import, user-directory isolation and **63 conventional suites passed** (65 stages, exit0). The new suite is included. The actual imported production/test files matched the SHA-256 snapshot in `source-hashes.json`; source stayed unchanged throughout execution. The final header text is compact current-order status; concrete limits remain in Parts and each case label.

All five Python CI commands passed: branding, report-playtests, server storage, receiver and community contracts. Separate normal-game headless startup smokes on that imported source passed in Chinese and English (exit0, no error lines), using fresh isolated smoke profiles. These are startup checks, not rendered or native UI acceptance. `git diff --check` passed. Independent final source review found no blocker. Missing order metric handling was source-reviewed; no new synthetic missing-metric trace test is claimed.

The original source profile save retained SHA-256 `125a565a676f4bae16cdd1b17bc8b8a5d84fda7673a443e9d4645b7c15568c61`. At the initial handoff, remote CI was **NOT RUN** because publication was held pending post-fix native approval. No release or merge is authorized or claimed.


## Authorized native follow-up, 18:28–18:40 UTC

The user approved normal closing and restarting the isolated QA window after explicit temporary-state disclosure. Its saved state was retained across that restart. Only window60817411 was closed; five pre-existing game windows were untouched. The fixed runtime used exact `15bcac93e2d8fcf0d54e8057efce857fe78d24de` tracked files, with only the two documented isolation settings changed. Import passed. Startup fullscreen initially rendered at an offset smaller size; native F11 windowed→fullscreen restored1364×1024 without a source edit.

- Alarm: Chinese and English native official reruns each passed64/64. SET0→1, HOLD1→1, RESET1→0 and CLEAR+FAULT priority rows displayed actual state values. English debug playback showed Previous observation ALARM0, then Observed ALARM1 at completion. Amended text fit the tested view.
- Orders in English: restored BalancedCPU/SlowRAM/Bus4 correctly produced2/2 outputs,94cycles and cost18. Current-order header and cycle94/66 verdict warned while output rows stayed green and earned historical completion remained available. FastCPU/SlowRAM/Bus4 produced62cycles,cost24 and the current-order verdict became Met.
- English move order: saved EcoCPU/FastRAM/Bus4 restored independently, produced224cycles on16 outputs,cost24. The compact result showed both cost24/24 and cycles224/320 above the output-details button, without expanding it.
- Chinese Parts showed total cost24/per-order budget24. A deliberate FastCPU/FastRAM/Bus4 rerun produced correct2/2 move outputs at224cycles but cost33. The budget33/24 and current-order verdict warned; cycle224/320 was explicitly marked met. The historical task remained completed when returning to its tree node.

All actions were native input using the preexisting copied fixture; no reference helper or completion-file edit supplied this follow-up. Screenshots were visually inspected in tool history, not persisted screenshot artifacts. The session returned to the task map and a normal close was issued. An environment replacement immediately afterward prevents claiming an independently verified normal-close outcome for that final window; see recovery below.

Known environment limitations remain unsupported V-Sync and ALSA→Dummy audio fallback; the inspected runtime log had no script errors. No Windows/macOS export, minimum-window acceptance, novice learning, audio acceptance, release or merge claim.

## Exact recovery after cloud environment replacement

At18:40UTC, shell access stopped finding the repository and QA files. The replacement host was `e08036ca9624`; the prior native desktop terminal identified `a35a7af8b5fa`. Computer-use reinitialized and no old game windows remained. This was not treated as proof of normal application shutdown or save recovery. Local test logs and QA profiles were no longer available on the replacement filesystem; the earlier observed tool results remain the evidence for their completed runs.

Recovery fetched the existing authorized branch at `2185f1caaf74d0ded6f21cf96086f404f8a936bf` and replayed the exact retained file-edit commands. Recovered tree **7a553f92a11750f7180260ed7e212426e46d198b** matched the previously verified tree. The complete staged patch SHA-256 also matched **ef248cccbec08d5e78148b58dfc7ddeadcfdc66ed9fe59da58e43c25a125a1a9**. Reconstructing the original commit metadata and checking the Git object hash recovered the original commit **15bcac93e2d8fcf0d54e8057efce857fe78d24de** exactly. No different implementation was substituted.

The production code and tests are therefore byte-identical to the already verified source. Only this follow-up evidence document changes after recovery; `git diff --check` and source-hash verification cover that documentation-only follow-up. No repeated full regression or native reconstruction is claimed. Remote publication/CI status must be checked against the final pushed SHA separately.
