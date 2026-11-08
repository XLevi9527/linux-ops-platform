# Linux 企业级网站部署与运维平台

这是我的第一个 Linux 网站部署项目，运行在 Ubuntu 虚拟机中，使用 Docker Compose 管理 Nginx 容器。

## 启动网站

```bash
docker compose up -d
## 监控与邮件告警

本项目使用 Prometheus 采集 Nginx 和 Ubuntu 主机指标，Grafana 展示监控面板，Alertmanager 通过 163 邮箱发送告警。Loki 和 Alloy 用于收集 Docker 容器日志。

### 访问地址

- 网站：`http://虚拟机IP:8080`
- Prometheus：`http://虚拟机IP:9090`
- Grafana：`http://虚拟机IP:3000`
- Alertmanager：`http://虚拟机IP:9093`

将“虚拟机IP”替换为 Ubuntu 的实际 IP 地址。

### 启动和检查

在项目目录执行：

```bash
docker compose up -d
docker compose ps
