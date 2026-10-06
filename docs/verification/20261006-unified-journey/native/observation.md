# Actual native candidate observations — 2026-10-06

Exact app: free-alpha-d26ff8d62cfd, source d26ff8d62cfd, profile Journey-d26ff8d.
Observed by root through CUA native macOS input/screenshots on Apple M2. Three
agents did not run GUI. This profile began empty; no QA solution imports or injected
completion. Native captures remain in the conversation; rendered PNGs elsewhere
are explicitly automated viewport evidence and are not relabeled native captures.

1. Normal launch displayed the new composed home with title/theme/art, two game
   actions and visible build identity. Tab+Return entered Journey map.
2. Four Tabs focused search; typed representation/cross_assets and pressed Return.
   Map selected actual Representation task5, with Service and optional Prediction
   visibly in the same map. First pointer attempt used the wrong coordinate scale
   and hit empty canvas; corrected observed pixel coordinates opened the task.
3. Actual task5 workspace showed AssetA/AssetB, unchanged RAW64 initial plan and no
   records. Scrolled its left workbench to Run; clicked Run current plan.
   Observed record1, task5, **136/438cycles,68B**, failed public constraints.
4. Task map raised Save/Keep editing/Discard. Escape canceled, keeping the exact
   record and draft. Reopened the dialog, Return on Save and leave returned to
   selected task5 in the map; it remained Available, not Completed.
5. Selected Service contract1 on the map and entered. Changed only A RAW64→RLE64
   with24 interleaved one-request groups and one state slot. Ran: **2072cycles,
   2532B state traffic,266B peak,first responses78/158/249/340**, zero numeric error
   but contract failed. Saved using visible Save, returned to map; contracts2/3
   remained locked, no fabricated success.
6. Selected Prediction regular stream, entered, revealed one demand: history[0],
   next address unknown, total not yet revealed. Task map raised explicit temporary
   discard dialog. Confirmed, then Escape to home. Homepage visibly said
   “重新探索预测” and “临时探索，离开后不保留”. Prediction Cancel is covered by
   automated checks; this native increment observed confirm/discard, not Cancel.
7. CmdQ normal exit; ps showed no candidate/engine process. Relaunched exact app,
   Tab+Return map retained last Prediction location. Selected Representation task5
   and entered; record1 restored unchanged **136/438cycles,68B**. Returned map→home
   and activated the primary action; same task5/record remained visible.
8. CmdQ normal exit; process absence confirmed. Saved candidate recipe files show
   Representation task4(zero-based),1run,0supports; Service task0,1run,0supports.
   Navigation preference ends representation/cross_assets. Own two candidate QA
   profile directories were moved into the ignored archive with exact hashes;
   delivered profile paths are absent/fresh. See profile-archive.json.

CUA AX is sparse; screenshots and visible button/keyboard effects provided evidence.
One getAX call reported cgWindowNotFound; re-observation found the live Save dialog.
Some native captures had a macOS overlay strip. These tool limitations are recorded,
not treated as game state changes. Saved data here belongs only to this session's
QA profile. No real save, network upload, main merge or security bypass occurred.

NOT_RUN: fresh full40 or5+3 completion, latest-package endings after full earning,
Service native independent-restart reload, all task-region dropdown mouse flows,
listening, user comprehension, other hardware/OS and final art acceptance.
