# VNB 反馈连接与交接

## 环境边界

| 环境 | 客户端和入口 | 数据与操作者 |
| --- | --- | --- |
| 开发 / CI | Mac Apple Silicon、Godot 4.7.1、GitHub Actions Ubuntu 24.04；默认离线，测试可起临时接收器 | QA 使用唯一用户目录及临时 SQLite；GitHub Actions 只读仓库，无 VPS 权限 |
| VPS staging | 独立 Caddy `127.0.0.1:28444` → Python `127.0.0.1:28081`；走 SSH 转发；只收合成数据 | `/var/lib/vnb-feedback-staging/feedback.sqlite`；systemd 动态用户，TLS 与接收器各有私有状态目录；只读核验由批准的 SSH 操作员执行 |
| VPS 现有私有接收器 | 独立 Caddy `127.0.0.1:28443` → Python `127.0.0.1:18081` | 原库、私有报告、备份及每日维护保持原有边界。参见[私有运维](feedback-operations.md) |
| 限定公网验收 | `https://feedback.yanruiqing.com:8443/v1` → 现有 `127.0.0.1:18081`。测试包采用独立 `EditionTestFeedback` 存档 | TCP 8443 仅允许已授权测试出口。只提交合成反馈，普通 Game/Test 交付包继续离线。实际开通证据另见本轮验收记录 |

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
并核验该行消失。限定公网入口使用下文单独的构建与验收命令。
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

## 独立公网入口

域名由所有者在 DNSPod 配置，Lighthouse 防火墙只允许指定测试源的 TCP
8443。独立 `vnb-feedback-public.service` 使用该主机实际公网接口的 IPv4
绑定地址。Caddy 显式加载独立证书，关闭自动 HTTPS 和 Admin API，
仅在 8443 提供四条精确的方法／路径。该单元通过 systemd 凭证读取私钥；
无需读取 MyAgent 证书、改防火墙、重启原接收器或接触原数据库目录。

- 配置采用仓库 `server/deploy/vnb-feedback-public.caddy`，安装为
  `/etc/vnb-feedback-public/Caddyfile`。在该目录的 `www/privacy.html`
  安装 `privacy-public.html`。在 `listener.env` 写入实际
  `VNB_PUBLIC_BIND` IPv4（腾讯云使用实例私网接口做公网映射）。
- 将公开受信的完整链与匹配私钥放入同目录下 `tls/fullchain.pem` 和
  `tls/key.pem`。目录为 root 0700、文件为 root 0600。使用
  `openssl verify -verify_hostname feedback.yanruiqing.com -untrusted fullchain.pem fullchain.pem`
  及证书／私钥公钥摘要比对预检。不要回显私钥或把其写入 Git。
- 以 `VNB_PUBLIC_BIND` 和 `CREDENTIALS_DIRECTORY=/etc/vnb-feedback-public/tls`
  两个环境变量执行 `caddy adapt --validate --adapter caddyfile --config /etc/vnb-feedback-public/Caddyfile`。
  `systemd-analyze verify` 成功后安装独立单元到 `/etc/systemd/system/`，
  运行 `systemctl daemon-reload`，只启动 `vnb-feedback-public.service`。
  监听和路由验收后才设开机启动。
- 紧急回退用 `sudo systemctl disable --now vnb-feedback-public.service` 并验证
  8443 已释放。保留证书与配置用于复盘，原接收器、TLS 及维护照常。由云
  防火墙所有者撤回专属 8443 入站规则。

本次证书使用 Let's Encrypt、Ubuntu 包索引校验的独立 lego 二进制及手动
DNS-01。VNB 私有路径为 `/srv/ray/apps/vnb/acme-public`，证书账户材料
和私钥均在 VPS。手动 TXT 需要人参与，每次续期创建新的 TXT 验证值。
在到期前 30 天由运营者检查 `openssl x509 -in /etc/vnb-feedback-public/tls/fullchain.pem -noout -dates`。
使用同一 lego 路径、现有 ACME 账户邮箱、`--dns manual` 及现有
`--path .../state` 执行 `renew --days 30`，等待权威 DNS 验证。
使用经过核验的证书／私钥对替换路径，并仅重启 VNB 公网代理；复测公网 TLS
和拒绝路由。证书验证失败应恢复旧证书对或停用新入口。
[lego 人工 DNS-01](https://go-acme.github.io/lego/dns/manual/) ·
[腾讯云备案规则](https://cloud.tencent.com/document/product/243/19630)。

公网试验使用单独的真实导出包。以下命令以完整源码 SHA 和新批次生成包，
现有包和存档保持各自渠道。

```sh
python3 scripts/build-free-candidate.py --godot "$HOME/Applications/Godot-4.7.1.app/Contents/MacOS/Godot" \
  --commit FULL_SHA --platform macOS --edition test --release-version v0.6.0 \
  --test-batch FeedbackQA20261122 --network-feedback-test
python3 scripts/verify-feedback-stage.py --public-receiver \
  --app 'build/BUILD_ID/macOS/Von-Neumann-Bottleneck-Test.app' \
  --endpoint https://feedback.yanruiqing.com:8443/v1
```

公网模式用系统默认 TLS 验证。游戏包内置端点及隐私页，探针只覆写 QA
场景和隔离目录。通过正常意见表单发送合成记录，再按原 ID 和内容重发，
用 SSH 对现有库只读核验恰好一行。最后用游戏自身删除操作清理合成数据。
试验包不属于 GitHub Release。请从授权出口测试，并保留同 ID 回执、
SQLite 读回和服务隔离记录。

## 现有服务保护

独立 8443 方案只读对比 MyAgent 代理、Gateway、WSS 服务，以及天机和
VNB 私有服务的进程、运行状态、配置文件摘要与相关监听。验收前后校验原有
MyAgent HTTPS 基础健康。HTTPS 健康不覆盖 Windows WSS 重连或任务状态。
本次不访问 Windows 所有者会话，也不重启、重载或升级共享代理。
如未来确实需要变更共享代理，应另经用户批准并确认 Windows 工作者空闲，
保存配置和任务基线，在维护窗口实测 WSS 重连、工作者恢复、任务一致性及
重复执行保护。失败须立即回滚并核实原服务。Caddy
`stream_close_delay` 只延迟配置卸载时关闭流，不能保护进程重启。
[MyAgent 腾讯云操作说明](https://github.com/wizardpc-com/my-agent/blob/main/deploy/tencent/README.md) ·
[Caddy Streaming](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#streaming)。
