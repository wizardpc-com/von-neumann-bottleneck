# 游戏远程部署：接入现有 Ray VPS

更新：2026-10-04（北京时间）。状态：**仓库部署适配已准备，VPS 实际部署未执行。**

依据用户《评析云服务器方案》及《Ray_VPS_部署与运维规划_2026-10-04.md》v1.0（2026-10-03 16:32 UTC 生成）。该规划是分阶段配置合同，不是部署验收回执；其中服务器地址、SSH 配置与其它业务的私有信息不复制到本公开仓库。

## 1. 已知条件与分工

- 目标为已购腾讯云上海轻量服务器：2 vCPU / 4 GB / 60 GB / 5 Mbps / 500 GB 月流量。
- 用户已验收 Ubuntu 24.04、Docker 29.6.1、Compose 5.3.1、Asia/Shanghai 时区和 SSH 公钥登录；既有安装保留，操作前复核。此文作者没有登录 VPS 再验收。
- VPS 只运行现有 Python/SQLite 反馈接收器，按批准情况提供介绍/隐私页和冻结包下载。游戏仿真仍在玩家本机，离线功能不依赖服务器。
- 不安装 Godot 编辑器、模型服务、通用数据库集群，不新增云存档/账号/多人服务。
- 既有 Hub 仍在 Cloudflare Workers + D1。购买 VPS 不代表迁移完成；游戏部署不改它的路由、OAuth 或数据。天机与游戏使用各自数据与权限。
- 主机底座、账户、防火墙、备份调度归用户的独立私有 ray-infra；本仓库只维护游戏接口、可复用模板和验收要求。

## 2. 路径和端口合同

| 用途 | 约定 |
|---|---|
| 冻结源码 | `/srv/ray/apps/vnb/releases/<commit>/`，保留 server/ |
| 当前版本 | `/srv/ray/apps/vnb/current`，切换前核验数据库兼容 |
| 测试数据 | `/srv/ray/data/vnb/staging/feedback.sqlite` |
| 正式数据 | `/srv/ray/data/vnb/prod/feedback.sqlite` |
| 私有实例配置 | `/etc/ray/vnb/{staging,prod}.env` |
| 已安装 Compose | `/srv/ray/infra/compose/` 下独立项目 |
| 公开安装包 | `/srv/ray/public/game/releases/<version>/`，仅经批准产物 |
| 备份 | `/srv/ray/backups/`，不得作为静态站点根目录 |
| 游戏 staging | `127.0.0.1:28081 → 容器8765` |
| 游戏 production | `127.0.0.1:18081 → 容器8765` |
| Caddy 内部验收入口 | `127.0.0.1:18000 → 游戏staging` |

原 `server/compose.yaml` 的宿主机8765与天机原生HTTP冲突。它仍是独立本地演示模板；**共享 VPS 使用新的独立 compose.vps.yaml，不能叠加旧文件**。天机保留宿主机8765；游戏容器内部8765不改。实际冲突先停下修正私有服务清单，不抢占端口。

## 3. 准备与隔离测试

以下供已获授权的服务器执行者使用，本次未执行其中安装/启动动作。

1. 核对目标源码commit和工作区；部署完整冻结server目录，不能自动git pull追分支。先核验主机端口、磁盘、已有数据与UID65532用途。
2. 沿用原Dockerfile，从冻结源码构建 `ray-vnb:<完整commit>`，记录基础镜像实际digest与产物image ID。构建可在受控机器完成后传输镜像；镜像架构须匹配VPS。不要使用浮动latest自动更新。
3. 按现有权限体系创建独立staging数据目录，使UID/GID65532可写，代码只读。prod/staging分别挂载、分别Compose项目；共享UID并不构成宿主机用户级强隔离。禁止递归放宽整个/srv权限。
4. 从env示例生成私有实例配置，替换image占位值。不要把真实管理token放入示例、游戏客户端、构建参数或仓库。模板不启用admin token；若以后需要，另走凭证配置流程。
5. **只传一个Compose文件**，先render，逐项检查实际image、唯一loopback端口、数据路径、资源和日志限制：

```sh
# 路径须替换为已经审核安装的文件；此命令不启动服务。
docker compose --env-file /etc/ray/vnb/staging.env \
  -p ray-vnb-staging -f /srv/ray/infra/compose/compose.vps.yaml config
```

模板要求全部变量显式提供，拒绝自动创建缺失挂载目录，并禁止隐式拉取镜像。staging固定28081/prod固定18081；若偏离此合同，先更新登记和代理，不直接启动。

6. 获准后启动staging，检查容器health、退出/重启、实际监听、非root和只读根文件系统；使用现有Python合成测试核验业务。512MiB/0.75CPU/128PID是初始上限，不是并发能力承诺。staging按需运行，避免和其它服务争抢4GB内存。
7. 宿主机Caddy导入 `Caddyfile.staging.example` 的站点片段，先 `caddy validate`。不替换整份已有Caddyfile，不创建公网欢迎页，不尝试假域名证书。
8. 开发者可用自己已有SSH配置建立本地18000到VPS loopback18000的隧道，验收health、上传、删除；这不证明ChatGPT云端可达，也不是公众服务。

## 4. 路由与隐私

Caddy模板只允许 GET `/v1/health`、POST `/v1/events`、DELETE `/v1/data`；其他方法/路径默认404。管理报表、社区汇总、榜单默认不代理。未来需要社区功能时单独明确产品开放范围。

保持128KiB请求体/32条批次；接收器120请求/分钟/IP在代理后可能成为所有用户的总保护限制，不能当每位玩家限额。现有服务不信任转发IP，不加伪造的Caddy限流指令。需要更大容量时先测量，再审查边缘限流和可信代理方案。

客户端endpoint仍留空，上传仍默认关闭。域名、告知文本/版本、服务端允许版本及删除流程一致后，才制作单独获准的发布包。自动统计、单次意见发送、实验成绩同意保持原有边界；服务器配置不能替玩家同意。

公开前核对真实域名、DNS/TLS、提供方适用接入/备案要求、隐私页和用户发布许可。`Caddyfile.example` 是未来模板，不能以裸IP或临时入口绕过这些验收门槛。不要把私有配置、数据库、备份或整份源码目录作为静态下载根。

## 5. 备份、恢复与发布

复用 [RUNBOOK](../../server/deploy/RUNBOOK.md) 和 `server/storage.py`，保持单个receiver写独立SQLite。活库使用SQLite备份API，不能仅复制主文件遗漏WAL。备份集记录源码commit、schema、时间和校验值。

游戏沿用30天事件保留；备份保留/删除策略须与隐私承诺一致。删除tombstone不能随普通日志清理；恢复旧备份前必须合入最新删除记录，验证已删数据不会复活。恢复到新路径，先保留安全副本，不能覆盖唯一生产库。

同盘备份不是异机备份。离机加密副本、密钥保管和恢复演练由ray-infra实现并提供证据；未配置就明确未完成。代码回退也不能简单用旧数据库覆盖新数据。

5Mbps约0.625MB/s标称总吞吐，多个下载共享；不要让安装包耗尽反馈入口带宽。先少量分发，未来国内对象存储需要独立批准，不自动开新账单。

## 6. 验收清单与本次结果

| 层级 | 必须核对 | 本次状态 |
|---|---|---|
| 仓库合同 | 新旧端口分离、路径/资源/日志、方法白名单、默认不上传 | 模板与文档已更新 |
| 本地业务 | receiver/storage/community合成回归 | PASS：2 + 3 + 5项，共10项 |
| Docker解析与运行 | 实际Compose config、构建、health、重启/挂载/限额 | NOT_RUN：当前开发环境无Docker |
| Caddy | validate、三条允许路由及管理/社区拒绝测试 | NOT_RUN：当前开发环境无Caddy |
| VPS | SSH有效配置、真实目录权限/资源/端口、故障/恢复 | NOT_RUN：本次未连接 |
| 真实发布 | 域名/TLS/接入要求、隐私、玩家同意、外部可达 | 尚未启动 |

后续服务器Codex应先读此文、RUNBOOK和用户私有ray-infra总规划，按固定commit准备staging。配置与真实数据迁入、公开上线分别报告；不要把本地测试绿灯写成远程部署完成。

官方核对（2026-10-04）：[Docker端口发布](https://docs.docker.com/engine/network/port-publishing/)、[Compose服务配置](https://docs.docker.com/reference/compose-file/services/)、[Caddy路由匹配](https://caddyserver.com/docs/caddyfile/matchers)。

本次还通过了YAML结构、单loopback映射、缺目录拒绝、资源/日志字段、Caddy方法路径白名单、相对文档链接和客户端未配置endpoint静态检查。静态检查不等同Compose变量展开、Caddy解析或网络隔离实测。
