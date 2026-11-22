# v0.6.1-playtest.2 公开试玩版

GitHub 于 2026-11-22T17:12:38Z 发布本轮公开试玩版。GitHub 已将本版本标为 Latest。冻结产品源码为 `38538b66474591d5cae4db4d07ac1dfc452af1c4`。Game 批次为 `Players061-Release2`，Test 批次为 `Players061-Release2-Test`。两版沿用各自存档位置，两版首次启动均可选择「接受服务」或「拒绝服务」，并可通过「查看详情」打开隐私说明。拒绝后仍可离线游玩与单次发送意见。Test 另外保留离线现场和 ZIP 导出。[公开下载](<https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.6.1-playtest.2>)

## 公开资产

| 版本 | 平台 | ZIP | 字节 | SHA-256 |
| --- | --- | --- | ---: | --- |
| Game | Windows x64 | `Von-Neumann-Bottleneck-Windows-vnb-game-release-v0.6.1-playtest.2-Players061-Release2-38538b664745.zip` | 211979505 | `c07a96e0721ce2237a78127a25aa1fc3da0b12285e0f316f1ff4be2ba01b5c1d` |
| Game | macOS Universal | `Von-Neumann-Bottleneck-macOS-vnb-game-release-v0.6.1-playtest.2-Players061-Release2-38538b664745.zip` | 234415268 | `f0430cc140d74f4598bdbe3e4bbb2b8117b20c0e9d57ad4a3e705fe3f645e873` |
| Test | Windows x64 | `Von-Neumann-Bottleneck-Windows-vnb-test-release-v0.6.1-playtest.2-Players061-Release2-Test-38538b664745.zip` | 211979802 | `a060e9b06fb97044ebff5fc446ed7df96d6135f8b4a3fed3aa5f124910532e41` |
| Test | macOS Universal | `Von-Neumann-Bottleneck-macOS-vnb-test-release-v0.6.1-playtest.2-Players061-Release2-Test-38538b664745.zip` | 234415529 | `0a7cd6138b142cfee476dafe419d73539a8a27732cbee4672bc64b1a4e326338` |

`SHA256SUMS.txt` 的 SHA-256 为 `6a0d685770317fec151b25e457bb0c58e76e1f59b5810a963d0a6235a3f6e855`。

以匿名玩家身份完整下载了四个 ZIP 和校验清单，共 892,790,786 字节。逐包重新计算的 SHA-256 与冻结文件、GitHub 资产摘要和随附清单一致。另已验证四包的 HTTP Range 读取与清单字节。GitHub Release ID 为 `454557229`。

## 许可与个人成绩

接受服务后，游戏在服务器确认本次安装首次成功上传前仍禁用「反馈 → 查看我的成绩」，也不提供链接。首次同步后可打开个人只读网页，查看已同步的部分关卡成绩。网页标签可见时每 15 秒刷新一次，原始链接请勿分享。

## 实测与边界

- **冻结 CI** – Godot 7/7 阶段和 Python 22/22 门禁通过。Godot 运行 311 个套件，Python 有 16 个检查程序通过，含 124 个 unittest 用例。[工作流](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45044275601)
- **Windows 实包** – 两版均通过隔离配置中的旧存档、首次同意、回执后的成绩入口和合成回环反馈检查。 Windows 两版 EXE 均未做 Authenticode 签名。两版均在托管 Windows 上通过无界面及窗口启动检查。窗口检查进入实验室并初始化 OpenGL，Game 的片头预设为已看。未验证实体机首次打开下载包。[工作流](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45047365843/attempts/1)
- **macOS 实包** – 隔离配置中的旧存档、首次同意、回执后的成绩入口和回环反馈均通过。 macOS 两版均仅有 ad-hoc 签名，未经 Apple 公证。本机 Gatekeeper 评估拒绝两版。另在本地 Apple Silicon 的隔离环境中，两版均以窗口模式进入游戏。未验证 Intel Mac 或另一台 Mac 首次打开下载包。
- **反馈外网** – 独立托管门禁通过公网 TLS、健康、拒绝路径和两版冻结隐私说明字节校验。公网成绩页及心跳另有运维回执。成绩读密钥隔离验收使用回环合成数据。

尚未验证 Intel Mac、另一台 Mac 或实体 Windows 电脑下载后首次打开，以及玩家在真实网络上的长期使用。

[v0.6.1-playtest.1 历史发布证据](../20261122-public-release/README.md)

[Apple 官方 macOS 首次打开说明](https://support.apple.com/en-us/102445)

[专用接收器、反馈监控与个人成绩运维验收](operations.md)
