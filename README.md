# Linux 网站部署与运维监控平台

一个在 Ubuntu 虚拟机（VMware）上完成的个人 Linux 运维练习项目。使用 Docker Compose 部署 Nginx 静态网站，并加入指标监控、日志收集、邮件告警和自动备份。

> **说明**：这是本地实验环境下的个人学习项目，不是承载真实业务的生产平台。已验证的功能和尚未实现的内容见下文。

## 功能

- **网站部署**：Nginx 容器提供静态页面，配置健康检查和自动重启策略。
- **指标监控**：Nginx Exporter 和 Node Exporter 采集网站与主机指标，由 Prometheus 存储，Grafana 展示连接数、请求速率、CPU、内存、磁盘等图表。
- **日志收集**：Alloy 收集 Docker 容器日志，发送到 Loki，在 Grafana Explore 中查询。
- **邮件告警**：Prometheus 规则触发告警，Alertmanager 通过 163 邮箱 SMTP 发送邮件。
- **自动备份**：Shell 脚本打包项目并保留最近 7 份备份，由 systemd timer 每周日凌晨 3 点触发。

## 已验证的内容

- Nginx 网站可访问，容器健康检查通过。
- Prometheus 能采集 Nginx 和 Ubuntu 主机指标。
- Grafana 仪表盘能显示监控图表。
- Loki 能查询 Docker 容器日志，例如 `{job="docker"} |= "404"`。
- Nginx 指标采集失败时，告警能触发、恢复，并成功送达邮件。
- 备份脚本能生成压缩包并清理旧备份；备份已解压到临时目录验证可用。
- systemd timer 已启用。

## 架构

```text
浏览器 ──> Nginx 容器 ──> site/index.html
                  │
                  └── /stub_status ──> Nginx Exporter ──┐
Ubuntu 主机 ──> Node Exporter ──────────────────────────┤
                                                        v
                                                   Prometheus
                                                     │     │
                                          指标查询   │     └── 告警 ──> Alertmanager ──> 邮箱
                                                     v
                                                   Grafana

Docker 容器日志 ──> Alloy ──> Loki ──> Grafana

backup.sh ──> 项目压缩包 ──> ~/backups/
systemd timer ──> 定时运行 backup.sh
```

- **指标链路**：Exporter 采集 → Prometheus 存储 → Grafana 展示；触发规则后由 Alertmanager 发邮件。
- **日志链路**：Alloy 收集 → Loki 存储 → Grafana 查询。

## 技术栈

Ubuntu、Docker、Docker Compose、Nginx、Prometheus、Nginx Exporter、Node Exporter、Grafana、Loki、Grafana Alloy、Alertmanager、Bash、systemd

## 目录结构

```text
linux-ops-platform/
├── compose.yaml                     # 服务编排
├── site/
│   └── index.html                   # 网站页面
├── monitoring/
│   ├── nginx/default.conf           # Nginx 配置（含 /stub_status）
│   ├── prometheus/
│   │   ├── prometheus.yml           # 采集目标
│   │   └── alerts.yml               # 告警规则
│   ├── alertmanager/
│   │   └── alertmanager.example.yml # 邮件配置示例（占位值）
│   ├── alloy/config.alloy           # 日志收集配置
│   ├── loki/loki-config.yaml        # 日志存储配置
│   └── grafana/dashboard.json       # 导出的仪表盘
├── systemd/
│   ├── linux-ops-backup.service     # 执行一次备份
│   └── linux-ops-backup.timer       # 每周日 03:00 触发
├── backup.sh                        # 备份脚本
├── deploy.sh                        # 部署脚本：校验配置 → 启动服务 → 显示状态
└── .gitignore
```

## 快速开始

### 1. 准备配置（敏感文件不在仓库中）

仓库不包含真实的邮箱和密码。请自行创建：

```bash
# 复制示例配置，并改成你自己的邮箱信息
cp monitoring/alertmanager/alertmanager.example.yml monitoring/alertmanager/alertmanager.yml

# 创建 SMTP 授权码文件（163 邮箱需使用"授权码"，不是登录密码）
mkdir -p secrets
echo "你的授权码" > secrets/163_smtp_password
chmod 600 secrets/163_smtp_password
```

然后编辑 `alertmanager.yml`，把 `your-address@163.com` 替换为你的邮箱。

### 2. 启动

```bash
docker compose up -d
docker compose ps
```

### 3. 访问

以 `docker compose ps` 中显示的**已发布端口**为准。当前配置下，网站使用 `8080`，Grafana 使用 `3000`；Prometheus 和 Alertmanager 仅在 Compose 内部网络中使用，未发布到宿主机。

## 常用命令

```bash
docker compose ps                              # 查看容器状态和端口
docker compose up -d                           # 后台启动
docker compose stop                            # 停止服务
docker compose restart                         # 重启服务
docker compose logs --tail=50 -f web           # 查看网站容器日志
./backup.sh                                    # 手动备份一次
ls -lt ~/backups/linux-ops-platform-*.tar.gz   # 查看备份列表
```

## 告警规则

| 规则 | 触发条件 | 级别 |
|---|---|---|
| `NginxMetricsUnavailable` | `up{job="nginx"} == 0` 持续 1 分钟 | warning |
| `RootDiskUsageHigh` | 根分区（`/`，排除 tmpfs 和 overlay）使用率超过 80%，持续 5 分钟 | warning |

测试告警：停止 Nginx Exporter 容器，约 1 分钟后触发；重新启动后告警恢复。> 已实际测试 `NginxMetricsUnavailable` 的触发、恢复和邮件送达；`RootDiskUsageHigh` 目前只配置了规则，尚未实际触发测试。

## 备份与恢复

`backup.sh` 的流程：生成带时间戳的文件名 → 用 `tar` 打包项目（排除 `.git`）→ 只保留最新 7 份。

恢复验证请解压到单独目录，**不要直接覆盖运行中的项目**：

```bash
mkdir -p ~/restore-test
tar -xzf ~/backups/<备份文件>.tar.gz -C ~/restore-test
```

启用定时备份：

```bash
sudo cp systemd/linux-ops-backup.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now linux-ops-backup.timer
systemctl list-timers | grep linux-ops
```
timer 设置了 `Persistent=true`：若计划时间虚拟机处于关机状态，开机后会补执行一次错过的备份。

## 截图

<img width="1010" height="656" alt="Grafana 仪表盘" src="https://github.com/user-attachments/assets/6bf17ca9-2d02-486d-b841-19dd66d7d7c7" />
<img width="1280" height="800" alt="Loki 日志查询" src="https://github.com/user-attachments/assets/41e72e26-360a-4594-8ba1-8f731fce9334" />
<img width="1272" height="2800" alt="告警邮件恢复" src="https://github.com/user-attachments/assets/7c4b0697-19d7-4712-866a-e75c8ee5667d" />
<img width="1272" height="2800" alt="告警邮件触发" src="https://github.com/user-attachments/assets/01c61dcb-bf51-4218-afb2-30b6f5e285bd" />


## 局限与改进计划

这是个人实验项目，以下是尚未完成的部分：

- 未启用 UFW 防火墙，也没有做访问控制。
- 部分镜像使用 `latest` 标签，计划固定具体版本。
- 备份保存在同一台虚拟机内，计划同步到宿主机或异地。
- 没有 HTTPS、域名和高可用。
- 没有 CI/CD 自动化部署流水线。

## 安全说明

- `secrets/` 和真实的 `alertmanager.yml` 已在 `.gitignore` 中排除，请勿提交。
- 仓库中仅保留带占位值的 `alertmanager.example.yml`。
