# Mac、GitHub 与 VPS 反馈链路

目标是用实际 macOS Test Edition 客户端验证 HTTPS、接收器、SQLite 和可见回执，再核对 MyAgent Windows WSS 工作者与任务安全。现有离线队列、API v1、SQLite schema 2、删除协议、Game/Test 构建和私有维护继续复用。工作范围限于反馈验收、VPS staging 部署与操作文档。

- 审计注册工作树、远端 main 和 Actions，核对 SSH、监听端口、主机资源及现存 VNB 与 MyAgent 运行实例。
- staging 使用独立接收器、数据库、TLS 进程及端口。先验证私有 HTTPS，再根据真实域名、证书、备案及网络权限决定公网入口。线上端口优先评估 TCP 8443。共享代理的配置与进程无需参与这条路径。
- 在隔离的 Test Edition 副本中向 staging 显式发送一条合成反馈。以同一 ID 对照可见回执及只读 SQLite 行，清理该身份并核验删除。
- 外部验收同时保留代理/传输进程和监听证据，并通过 Windows 所有者验证真实 WSS 与无副作用任务。共享代理方案需要单独人工批准的空闲窗口，且必须演练重连、任务状态与重复执行保护。
- 暂停 ingress 或代码回退仅作用于 VNB staging 单元。回退沿用当前 SQLite 数据，改数据库格式须另行验证。

2026-11-22 起始审计：本地仅主检出，GitHub main 与本地同为 `352b093`，该提交 Actions 成功。VPS 接受现有公钥，当前 Mac 会话的 SSH agent 没有可签名身份。依赖主机或 Windows 的验收仍待执行。

2026-11-22 已恢复 SSH。真实本机 Test Edition 经 VPS staging 私有 HTTPS 完成
两轮同 ID 回执、SQLite 核对和删除；默认 TLS 信任拒绝私有 CA。真实 staging
代码切换并回退通过。MyAgent 配置、进程、监听和转发就绪未变化，最终探针前后
观察到相同的三条 wstunnel 套接字。私有 staging 刻意保留按需启动。完整记录见
[验收证据](../../verification/20261122-feedback-connectivity/README.md)。

公网与 Windows 工作流仍开放。独立入口等待可用于本 VPS 的专用域名、受信
TLS 证书及云网络规则；Windows 工作者的账户认证、指定任务状态和去重仍需
所有者验收。共享代理没有变更，也没有安排其维护窗口。
