《冯·诺依曼瓶颈》离线同学试玩说明 / Offline teammate pre-version

一、解压后就能玩

1. 完整解压收到的整个 ZIP；不要在压缩包预览里直接运行。
2. 双击解压目录中的 Windows/Von-Neumann-Bottleneck.exe。
   本说明随包放在 Windows/README.txt；打开游戏不需要执行其他脚本。
   无需安装 Godot 或 Python，无需账号、网络或服务器。
3. 首页可切换中文 / English；F11 切换全屏，F10 打开设置。
   若界面文字被挡，先尝试全屏、移动浮窗或使用窗口内的滚动条。

这是离线测试者包，适合自由查看所有关卡。全部入口开放不等于完成：
不会赠送通关记录、元件封装、训练模型或作品；实际正确性与模型规则仍有效。
硬件关卡提供标注“测试参考”的临时前置组件，方便直接试验；使用它们不能
记录真实通关或封装成果。你已有的自制组件优先使用，不被参考组件覆盖。

二、到哪里找全部 60 项

首页 →「旅程地图」→ 选择区域、查看任务列表 → 选择任务并进入。
若从旧存档继续到了工作台，先用原返回地图 / 首页入口，再打开旅程地图。
不要只在序章列表里找后续内容，也不需要先完成序章才能浏览其他测试入口。

- 原五个区域共 40 项：序章 / 硬件 14、系统 7、局部性 7、时序重叠 6、布局 6。
  地图区域名为「一线成机」「时间的去处」「少走远路」「与等待并行」「各就其位」。
- 表示 5 项、服务 3 项、地址预测 3 项：在地图的相应区域选择。
- 压缩 / 内容预测 / 创造共 9 项：地图内可定位这三个区域，任务编号 C1–C3、
  P1–P3、G1–G3。例如「C1 · 让例外抵达」「P1 · 下一格尚未抵达」
  「G3 · 留下你的下一段」。任务全名与按钮以你当前语言的实际界面为准。

第一次建议：首页「开始旅程」→ 可读 / 可跳过壹的讯息 → 原 NOT 教程。
输入 1 时 NOT 输出 0（灯灭）也正确，是否完成看真实任务要求，不看灯是否一直亮。

三、常用操作：先看目标，再动手，再看证据

- 放元件：从元件台拖到画布，或点击后连续放置；右键 / Esc 取消放置。
- 接线：把输出端口接到兼容输入端口。交叉的线不会自动相连；细线 / 圆端口
  是一位信号，宽线 / 方端口是多位总线。先按教程完成连接、切输入、运行、
  拆线再重连，不必一开始就会搭完整计算机。
- Run / 运行 / 测试：按当前任务按钮检查。调试看一个输入，完整测试检查正式
  用例；一个例子正确不等于全关通过。读结果里的实际值、目标和不满足的条件。
- 播放 / 暂停 / 单步：查看本次轨迹，按需拖动或滚动查看；播放快慢不改变结果。
  Locality 运行后可从结果定位本次取数证据；修改程序后，旧结果入口会失效。
- 不懂规则：先看任务台，再打开「手册」看图示 / 切换示例输入。示例是独立
  演示，不修改你的电路。SRLatch 可按前后例查看同为 00 的不同保持前态。
- 不懂策略：主动逐层打开 Hint；共有三级，后两级会确认。提示画布只读，
  不会把答案接进你的作品，也不要求先失败或看完提示才能通关。
- 改错：Windows Ctrl+Z 撤销，Ctrl+Y 重做；在文本框里时优先撤销文字编辑。
- 离开与继续：按界面保存草稿 / 方案，返回时处理保存提示。正常通过设置退出，
  下次从首页「继续游戏」或旅程地图返回；不要为了换关删除存档。

四、最快亲手走一遍“压缩 → 预测 → 创造”

测试者可以直接进 G1，但没有模型准备时，仍需先完成下面真实步骤。
按工作台的「下一步」引导操作；只打开页面不会建立证据。

1. 地图进入 C1。使用已有样例（若为空，先选一段）→「从当前样例学习」→
   「发送预测包并复原」，确认接收端无损还原。RAW 对照不是预测包复原证据。
2. 进入 P1，或点「接到未见输入」→「练习」。点
   「先提交预测」，再点「再揭晓真值」；首格后可用「执行余段」完成本轮。
   猜错可以追因、继续；要完成整轮，不能只揭晓一格就直接生成。
3. 进入 G1，或按下一步「接上回灌」；若仍未连接，点
   「断开真值 · 接上回灌」，再点「按我的配方生成」。
   此时是用自己的输出接回输入，已没有隐藏原文或正确率评分。
4. 想留下作品时，到 G3 /「作品与配方」按实际引导填写名称，点
   「保存这份作品」或「确认并保存当前作品」。Keep 保存的是这次真实新输出
   及完整配方；查看旧快照不是重新生成，也不会自动成为另一件新作品。

改变样例或记忆长度后，需要主动重新学习；当前模型的复原 / 整轮预测前提
也要重新满足。C2 / C3、P2 / P3、G2 的比较与检查可继续挑战，按各单元目标操作。
这条最短体验路线不等于完成全部九项。

五、档案、图示与 3D 的边界

首页 / 地图「成长档案」可回看真实完成与原保存作品；作品快照是只读查看，
不分叉、不生成，也不补造旧 C/P/G 操作历史。创作仍在原光纹工作台进行。
亲手完成真实 NOT 教程后，可从档案主题回顾播放 / 跳过 / 重播「第一束光」。
固定 NOT 1→0 示意与虚构静态空间图分开，图不是当前电路、电流或节能测量。

「3D成果展示 · 只读原型」只展示成果与任务导航：选任务、近看所选装置、还原
全景或回原工作台。它不是能在 3D 中搭建 / 运行电路的实验室，也不是正式美术。
开放入口不会点亮成果；觉得不好找、看不懂或不符合预期，请直接记录。

六、卡住也能反馈，最后只发一个 ZIP

1. 按 F8，或点工作台已有「反馈」 / 右下角「现场反馈」。有本地入口时，
   重复的全局反馈条可能隐藏，F8 仍可用；未通关也能写。
2. 游戏暂停，自动记录打开面板前的游戏截图、当前方案、编辑文字、参数、
   运行结果 / 轨迹和游戏现场。选择类型，写“在哪一关、点了什么、以为什么、
   实际发生什么”；文字会自动保存在本机。
3. 「记下这条反馈」标为已整理；未标记的草稿也保留并导出。历史下拉框可补充
   旧意见，但原现场不变。Esc / F8 /「返回游戏」继续试玩；Esc 一层一层返回。
4. 试玩结束后点「导出全部反馈」，生成并核验一个 ZIP，并打开所在文件夹。
   最后再导出一次，把最新的这一个 ZIP 发给维护者即可，不用另找多个截图或日志。
   先完成导出，再从设置正常退出。不要强制关进程来代替保存 / 导出。

导出不会删除本机原件。遇到保存或导出失败，会显示原因；请使用“另存到…”
选择可写位置。失败时不要直接关程序，先保留文字并完成导出。
电脑断电/硬盘故障仍可能造成损失；重要反馈建议结束时导出并自行另存一份。

文件仅保存在本机；本版本没有反馈服务器，也不会自动上传。截图只取游戏
窗口，不取桌面、麦克风或摄像头。现场包包含游戏作品、草稿、自由文字、
操作记录、游戏日志及存档副本，请勿写入密码或私人信息，并有意识地分享。
快照用于定位与分析，不能保证每一个 UI 状态都可自动重放。缺失、截断或
无截图会明确记录。单文件 64 MiB、单包展开后 1 GiB；超限不清空原件。

独立存档与反馈目录（Windows）

本包的实际 profile 以随包构建身份为准；以下两个完整目录名由构建时替换。
%APPDATA%/VonNeumannBottleneckCandidates/representation/OfflineTeammate/
%APPDATA%/VonNeumannBottleneckCandidates/service/OfflineTeammate/

反馈在上述 representation 目录的 offline_playtest/；记录跨重启保留。
更新、回退或换版本前，备份这两个完整目录，不要只备份主进度文件。
不要合并普通版与测试者版的 profile，不要导入维护者的 QA 通关档。
不要同时启动多个游戏实例操作同一份存档；换解压目录不等于换存档空间。
新电脑会自动创建本机独立档案。若同电脑以前用过相同 profile 的测试者包，
本次会继续已有档案；更新前先备份，不要重置或删除旧档。
正常退出后再复制备份，不要在游戏写入时搬动档案。遇到较新格式拒绝保存时，
保留旧文件和备份并反馈，不要删除它们强行继续。

维护者：feedback-tools/ 下附 Python 离线导入与分析工具及说明。
同学只需运行游戏和导出 ZIP，不需要执行该工具。

Run the extracted EXE. All sixty task entrances are available without earning
completion. Press F8 anywhere in the game to capture a scene and add an autosaved
note. Export all feedback creates one verified ZIP and retains local originals.
Send that ZIP to the maintainer deliberately. No account or network is used.
Home/Map offer Journey journal and the 3D Observatory. Test access grants no recorded completion or achievement light.
Earn the real NOT tutorial to optionally play/skip/replay First Light, a fixed NOT 1-to-0 retrospective with reduced motion. It grants no new achievement.
The journal opens original saved-work output, recipe and source, labels read-only recovery, and disables forks. It does not generate or reconstruct generation events; create in the original workbench.
F8 keeps feedback in the current window; Escape returns one layer at a time. Preserve a failed-save panel and use Save ZIP as before exiting.
Artwork, character, CG, voice and ending choices remain candidates; newcomer and independent Mac acceptance remain open.
