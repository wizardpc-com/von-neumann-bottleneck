# 参赛准备 · GPT-6 Astra Challenge

这是可审查的本地准备材料。没有代替你提交作品、预约发布或部署网站。

## 本轮取舍

保留五区域、40 任务。近期不加章节、不把深层关卡提前解锁、不放置自动解题按钮。
参赛需要补的内容是：可辨认的双语入口、首次试玩指引、真实展示画面、开发过程证据和可下载的稳定包。
新增谜题留到外部反馈能说明哪段路线缺少用途以后；当前没有证据支持为了比赛再加一种机制。

## 已核对的规则（2026-09-14）

- [OpenAI 公告](https://community.openai.com/t/gpt-6-astra-challenge-on-product-hunt/1396727)写明使用 Astra 构建，并在 9 月 18 日前于 Product Hunt 发布。
- [挑战赛入口](https://www.producthunt.com/contests/gpt-6-astra-challenge)标注 September 18th；Submit now 带 `contest=gpt-6-astra-challenge`。公开页倒计时显示零，不能据此判断是否截止。
- [Product Hunt 官方指南](https://www.producthunt.com/launch/preparing-for-launch)：名称只用产品名；tagline 最多 60 字符，description 最多 500；至少两张 gallery，推荐 1270×760；方形 thumbnail 推荐 240×240，低于 3MB；视频可选。
- **待你在登录后核对**：现有项目是否符合本届资格、实际截止时区、是否必须选 18 日以及模型使用证明要求。公开页没有完整细则；社区普通用户的推测不是比赛规则。

## 可直接使用的材料

- [填写字段](submission.json)：英文介绍、tagline、首条评论草稿。下载 URL 为空，防止误指向旧八关/旧试玩包。
- [首次试玩（中文）](quickstart.zh-CN.md) / [First session (English)](quickstart.en.md)。不剧透解法，不绕过进度。
- [开发过程与声明边界](development-evidence.md)：提交只能证明代码变化，不能单独证明当时使用的模型。
- [展示顺序](showcase.md)：从构建到数据移动，避免 gallery 全是菜单。
- [代表关卡画面](../../images/readme/layout-en.png)：第四章综合关的实际运行。[来源与哈希](../../images/readme/layout-manifest.json)。它不是导出包验收证明。

## 提交前顺序

1. 本机复查最新构建：语言 → 任务树 → 教程 → 保存 → 正常退出 → Continue。
2. 你完成 Windows 实机与 Mac 导出包鼠标检查，按 [RELEASE_BLOCKERS](../../../RELEASE_BLOCKERS.md)记录失败和支持范围。
3. 冻结同一提交的候选包，核对 manifest、ZIP 哈希和随包说明；不覆盖旧 candidate。
4. 你确认实际分发渠道后发布包，填入 `public_download_url`。从未登录的浏览器验证可下载，不能只链接源码给普通玩家。
5. 选择至少两张实际游戏画面和现有临时图标（正式 Logo 仍可后补）；核对 gallery 对应的源码与候选差异。
6. 按你的实际模型记录补齐 Astra 说明，检查 Challenge 关联与日期，最后由你确认提交。

服务器不是进入游戏的前提。可先保留游戏内离线反馈和 GitHub 问题入口；若启用服务器，单独完成既有部署清单与授权检查。本轮不购买、不部署、不填写凭据。

## 已备妥的图库与本地打包

[图库来源与哈希](gallery/manifest.json)：中英文任务树、普通教程工作台、第四章综合关各一张，共六张。所有画面直接来自 Godot；综合关使用已获得的合成 QA 方案重新运行，未伪造进度或结果。图片保留原始清晰度，可在提交页面预览裁切，避免截掉任务或指标。

从仓库根目录运行以下命令生成仅含说明、字段和 PNG 的本地素材包；不会发布或上传：

```sh
python3 scripts/prepare-launch-kit.py --output build/VNB-Astra-launch-kit-60de5e54c95d.zip
```

已有同名包会被拒绝覆盖。公开下载地址仍待选择；截图不能代替最终安装包验收。
