# VNB 反馈连接与交接

## 环境边界

| 环境 | 客户端和入口 | 数据与操作者 |
| --- | --- | --- |
| 开发 / CI | Mac Apple Silicon、Godot 4.7.1、GitHub Actions Ubuntu 24.04；默认离线，测试可起临时接收器 | QA 使用唯一用户目录及临时 SQLite；GitHub Actions 只读仓库，无 VPS 权限 |
| VPS staging | 独立 Caddy `127.0.0.1:28444` → Python `127.0.0.1:28081`；走 SSH 转发；只收合成数据 | `/var/lib/vnb-feedback-staging/feedback.sqlite`；systemd 动态用户，TLS 与接收器各有私有状态目录；只读核验由批准的 SSH 操作员执行 |
| VPS 现有私有接收器 | 独立 Caddy `127.0.0.1:28443` → Python `127.0.0.1:18081` | 原库、私有报告、备份及每日维护保持原有边界。参见[私有运维](feedback-operations.md) |
| 公网测试 / 生产 | 独立 TCP 8443 为候选。公开 Game/Test 均沿用离线构建 | staging 公网尚未启用，生产域名、入站与对玩家发布均未启用 |

客户端使用现有 `/v1` API。接收端 `GET /v1/health` 返回
`ok=true`、`api_version=1`、`schema_version=2` 和保留天数，staging
代理另返回 `X-VNB-Environment: staging`。检查读取 SQLite 元数据。
`POST /v1/events` 提交 `client_id`、`deletion_token` 和
`records`。SQLite 提交后才返回包含对应 `event_id` 的 `ack`。
完全相同的重试去重，冲突 ID 返回 409。客户端以匹配回执显示已收到，
保留未确认的队列。 `DELETE /v1/data` 确认后该身份的活库数据被删除并保留
删除墓碑。数据目录、备份、令牌和报告通过私有运维通道处理。

记录携带 `build_version`（Test Edition 为显示版本）、完整
`source_commit`、`test_batch`、任务版本及运行模式。构建清单以独立
`build_id` 标识交付件。服务器部署以完整 Git SHA 指定不可变的接收器源码，
SQLite API 版本、存储 schema 和游戏构建号各自独立。边缘白名单为精确的
健康、提交、删除和静态隐私页，管理、社区及排行接口不设入口。
请求体以 128 KiB、每批 32 条为限。接收器在反代后按代理来源计限，因此当前
限额是共享保护上限。staging 只有合成数据，现有生产候选库的私有备份及维护见
[接收器运维手册](../../server/deploy/RUNBOOK.md)。

## 重跑真实私有验收

Mac 上启动隧道，私有 CA 文件来自现有 SSH 信任。它只用于这个 QA 进程。

```sh
qa=$(mktemp -d /tmp/vnb-stage.XXXXXX)
ssh -o BatchMode=yes ray-vps \
  'sudo -n cat /var/lib/private/vnb-feedback-staging-proxy/data/caddy/pki/authorities/local/root.crt' > "$qa/ca.pem"
ssh -fNM -S "$qa/ssh" -o ExitOnForwardFailure=yes -o BatchMode=yes \
  -L 127.0.0.1:28444:127.0.0.1:28444 ray-vps
python3 -B scripts/verify-feedback-stage.py \
  --app build/vnb-test*/macOS/Von-Neumann-Bottleneck-Test.app \
  --endpoint https://localhost:28444/v1 --ca-file "$qa/ca.pem"
ssh -S "$qa/ssh" -O exit ray-vps
rm -f "$qa/ca.pem"
rmdir "$qa"
```

命令先校验 TLS、健康与入口限制，再用原始 Test Edition 的哈希校验副本、
唯一用户目录和外部 QA 控制器触发真实意见表单。设置覆盖只作用于副本，
打开意见发送界面并绑定 staging；自动统计与分数分享保持关闭。客户端显示
回执后，SSH 用只读连接按同一 ID 查 staging SQLite，再由客户端发出删除请求
并核验该行消失。受信证书的公网 staging 使用同一命令并省略 `--ca-file`。
原始安装包维持分发时的离线行为。控制器验证程序交互与回执，不提供原生鼠标输入
或公网发布证据。私有证据和 QA 用户目录含客户端删除能力，应留在本机；可公开
转交的内容只取汇总和合成回执 ID。失败时保留 QA 用户目录供同一身份重试删除，
避免重跑后遗失其身份。现有 Actions 运行独立 Godot 测试和 Python 接收器、
去重、备份与打包回归。VPS 验收由操作员在部署后触发。

## 只部署和回退 VNB staging

首装使用仓库 `server/deploy/vnb-feedback-staging*.service` 与
`vnb-feedback-staging.caddy`。先确认目标服务、配置路径和 28081/28444
尚未占用。把固定 SHA 的 `git archive FULL_SHA server` 解到
`/srv/ray/apps/vnb/staging-releases/` 下同一文件系统的新临时目录。检查
`server/feedback_server.py` 后，以 root 所有、只读部署目录权限 0755
原子移动到 `staging-releases/FULL_SHA`，再建 `current-staging` 指向该
目录。将仓库 Caddy 模板验证后安装为 `/etc/vnb-feedback-staging/Caddyfile`
（0644，模板无密钥）。验过单元后安装为 `/etc/systemd/system/` 中相应
两个新文件，重读单元定义并启动 staging 代理。

```sh
sudo caddy adapt --validate --adapter caddyfile --config /etc/vnb-feedback-staging/Caddyfile >/dev/null
sudo systemd-analyze verify /etc/systemd/system/vnb-feedback-staging{,-proxy}.service
sudo systemctl daemon-reload
sudo systemctl start vnb-feedback-staging-proxy.service
systemctl is-active vnb-feedback-staging.service
systemctl is-active vnb-feedback-staging-proxy.service
curl -fsS http://127.0.0.1:28081/v1/health
```

升级时先记录 `readlink /srv/ray/apps/vnb/current-staging`。保留前一冻结目录，
按相同步骤只准备新版本目录，然后从 Mac 推送受控激活脚本。

```sh
ssh -o BatchMode=yes ray-vps 'sudo -n bash -s -- FULL_SHA' \
  < server/deploy/activate-feedback-staging.sh
```

脚本串行地原子切换路径，重启 staging 接收器并检查 API/数据库版本。失败会
尝试恢复旧链接和健康；回退健康仍失败时停止 staging 入口。回退也可显式传入原
SHA。两者都保留同一库，禁止用旧 DB 覆盖现状。改 schema 前须验证兼容及删除
安全恢复；生产数据恢复遵循现有运维手册。更改代理配置时在候选文件执行
`caddy adapt --validate`，保存原件后只切换该 staging 配置并重启该单元，
然后重跑 HTTPS 验收。停入口用
`sudo systemctl stop vnb-feedback-staging-proxy.service`，按需再停 staging 接收器。
两单元目前按需启动。故障从 `systemctl status` 和该单元的私有 journal 检查。

## 独立公网入口与 MyAgent P0

优先在 staging 的独立 Caddy 上用 TCP 8443 和专用域名，保留 `admin off`
和独立账号。需要确认域名适用于腾讯云当前接入，在受控位置提供独立、完整受信的
证书链和私钥，配置自动续期并实测；可以评估由有权限的 DNS 运维者签发 DNS-01
证书。在 Caddy 候选文件把 site 改为 `https://专用域名:8443`，使用已经审核
且主机拥有的 bind 地址，使用显式 TLS 证书文件，将 `auto_https` 改为
`off`，停用对 80/443 的隐式重定向或 ACME 绑定。TLS 私钥由私有路径交付给
staging 专用服务身份，以最小读权限挂载或使用 systemd 凭证，避免共享 MyAgent
证书目录。公网测试采用云规则限定测试来源，仅 staging 合成数据。域名、证书、
网络规则、适用备案和隐私页须验明后再开放。8443 还需从实际测试网络确认可达。
若将来需要普通玩家运行的网络构建，另做发行入口和隐私链接验收。
[腾讯云备案规则](https://cloud.tencent.com/document/product/243/19630)。

MyAgent 的 80/443、Caddyfile 和运行进程无需参与独立方案。其 Windows 工作者
经现有 WSS 使用反向映射。独立方案在上线前后用现有所有者的
`node scripts/windows-worker.mjs verify` 获取认证就绪证据，并观察同一个
无外部副作用任务的进度、终态和执行次数，保留相同任务 ID 的对照记录。VPS
端的进程/调用 ID、配置哈希、监听、持续 WSS 套接字及现有转发的
`/readyz` 证明主机隔离与可达性，Windows 任务验收仍需所有者证据。
[MyAgent 腾讯云操作说明](https://github.com/wizardpc-com/my-agent/blob/main/deploy/tencent/README.md)。

共享代理仅在用户确认必须采用且人工批准的维护窗口内实施。由 Windows 所有者
先确认空闲和任务状态，私下完整备份共享配置，保留权限、哈希、进程及状态基线。
校验候选后才操作。主动验证真实 WSS 重连、同一工作者恢复、任务状态一致及无
重复执行。任何验收失败立即恢复备份并重新验证原连接和任务。
`stream_close_delay` 适用于配置卸载时延迟关闭流，进程重启依然必须按可能断线处理。
[Caddy Streaming](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#streaming)。
