# Mac Test Edition 与 VPS 私有 HTTPS 验收

2026-11-22，Mac Apple Silicon 经 `ray-vps` 将本机回环 28444
转发到 VPS 回环 28444。Test Edition 原始二进制和 PCK 通过交付清单哈希
验证。QA 启动隔离副本，用实际意见表单提交一条合成反馈，未开启统计或成绩
分享。游戏收到并显示回执后，在 VPS 以只读 SQLite 连接校验对应行的模式、
来源、任务、版本、完整源码 SHA、批次及合成内容。随后在同一客户端删除，
回执确认后 SQLite 已查不到该行。两次独立实测通过。最后一次回执和二进制
身份见 [private-https-receipt.json](private-https-receipt.json)。
默认 TLS 信任拒绝私有证书。加入仅本次 QA 使用的私有 CA 后，健康和隐私页
返回 200，六个拒绝用例返回 404。

| 核查 | 结果 |
| --- | --- |
| Mac 与 CI 基线 | arm64；Godot `4.7.1.stable.official.a13da4feb`。开始时本地和 GitHub main 为 `352b093776c5ff02e054ea09695ed4a196adc8d6`；其 Actions 成功。 |
| Git 工作树 | `git worktree list --porcelain` 只列主检出，无附加工作树需要合并或删除。历史分支继续保留。 |
| VPS | Ubuntu 24.04.5 LTS，2 vCPU，约 1.5 GiB 可用内存及 35 GiB 可用磁盘（审计时）。Caddy 2.6.2。staging 两单元合计约 22 MiB 当前内存；接收器 28081 和 TLS 28444 均仅监听回环。 |
| staging 检查及回退 | 单元和配置解析通过。从 `352b093` 真实切换到 `6358448` 后恢复 `352b093`，两次健康均为 API v1 / schema 2。当前 staging SQLite 完整性检查通过，0 客户端、0 事件、2 条合成删除墓碑。 |
| 现有 VNB | 私有接收器及代理的进程和调用 ID 保持一致。私有健康返回 schema 2；维护计时器 active，最近运行 Result=success。未打开生产库进行写入验证。 |
| MyAgent | 共享配置哈希、代理/工作者传输/Gateway 的进程和调用 ID、监听快照前后一致。Windows 反向映射 `/readyz` 200。最终真实 VNB 验收前后均观察到 3 条相同既有 wstunnel 套接字。回退演练用于探测的转发请求会建立子连接，套接字总表发生变化。没有执行 Windows 工作者重连、原生账号认证或任务去重验收。 |
| 公网 | 两个候选 VNB 域名从 VPS 解析均为 NXDOMAIN，8443 未监听；缺已核准域名、受信证书及云入站证据。没有启用公网或更改 MyAgent。 |

Mac 新隔离导入和用户目录探针通过。Godot `test_offline_feedback`、
`test_playtest_feedback_ui`、`test_remote_feedback` 通过。Python 品牌检查、
打包反馈（5）、存储（3）、接收器（7）、交付（3）、私有报告（5）通过。
接收器慢请求用例首次遇到 Mac TCP reset，原样复跑通过。仓库原有维护套件
在 Mac 通过 3/4 项，备份用例仍遇到 SQLite 的额外 `.sqlite-shm` 文件，
与此前交付的已知现象一致；本轮未修改维护实现。首次 staging TLS 配置在
Caddy 2.6.2 上关闭了内部证书自动加载，改为禁用自动重定向后重验通过。
首次无头包探针也因本地问卷默认关闭失败，启用探针的本地问卷后通过。

部署、复测和公网放行边界见[运维交接](../../distribution/feedback-connectivity.md)。

## 独立 8443 公网准备记录

后续指令将公网验收收敛到 `feedback.yanruiqing.com:8443`，通过独立
Caddy 转发既有回环 18081。配置、隐私页和 systemd 单元已安装，Caddy
实际解析只声明指定 IPv4 的 8443、关闭自动 HTTPS 与 Admin API。
配置预置前后 MyAgent 三单元、天机三单元、原 Caddy 和 VNB 私有服务
的状态、PID、调用 ID、单元文件摘要及相关监听摘要逐字节一致，MyAgent
现有外部 HTTPS 两次均为 200、TLS 校验正常。Windows 工作流由用户明确排除。

Ubuntu 发布包索引的 SHA-256 校验通过，从包中解出 lego 单二进制到 VNB
专用目录；未通过包管理器安装系统服务。Let's Encrypt 生产 DNS-01 已
生成 TXT 挑战。先后直查两台 DNSPod 权威服务器，A 和 TXT 尚未生效。
等待所有者完成 A、TXT 和仅测试源 TCP 8443 云规则。证书尚未签发，8443
没有监听，公网 TLS、上传、重复投递及路由拒绝尚未验收。

macOS 联网 Test 包以 `dd22cd0eb71cb73dd48255c6764778e2e7456606`
为冻结源码，build ID 为 `vnb-test-feedback-v0.6.0-FeedbackQA20261122-dd22cd0eb71c`，
ZIP SHA-256 为 `a8d521e258245c60019cc11901d2551a7cc9a41bc54f9b314e44275a2d73ac65`。
通过构建、ZIP 逐文件哈希、Godot 实包运行、60 任务和默认关闭统计检查，
本机 ad-hoc 签名结构验证通过。此前导出因调度实验室未识别网络 Test 档
被实包门禁拦截，修复后新冻包通过。精确重发和数据库单行检查已在原离线
Test 包的隔离 staging 预演通过。实际公网包未用测试覆写改变服务器端点或
证书信任。本地原交付包保持各自版本与隔离存档。
