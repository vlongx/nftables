# NFTABLES

一个基于 `nftables` 的端口转发管理工具，提供：

- 一键安装
- CLI 菜单管理
- TCP / UDP / BOTH 转发
- nftables 规则生成与应用
- 简单静态面板
- systemd 后台服务管理
---
## 安装方式

### 海外服务器
```bash
wget -qO- https://raw.githubusercontent.com/vlongx/nftables/main/vl.sh | sudo bash -s install
```
### 国内服务器
```bash
wget -qO- https://ghfast.top/https://raw.githubusercontent.com/vlongx/nftables/main/vl.sh | sudo bash -s install
```
---

## 功能特性

- 基于 `nftables` 实现端口转发
- 支持 `TCP`、`UDP`、`BOTH`
- 自动开启 `IPv4 Forward`
- 自动安装基础依赖
- 统一命令入口：`vl`
- 支持规则新增、删除、查看、应用
- 支持面板服务启动与查看状态
- 结构模块化，便于后续扩展

---
## 核心特性

- 🚀 一键安装，开箱即用
- 📦 统一命令入口：`vl`
- 🔁 支持 TCP / UDP / BOTH 转发
- 🧩 模块化脚本结构，便于维护
- 🛠 基于 nftables 实现规则管理
- 🌐 内置简易管理面板
- 🔧 支持 systemd 服务托管
- 📈 便于后续扩展 Web API 与鉴权系统

---
## 📊 nftables / realm / gost 转发对比

| 项目 | nftables | realm | gost |
|------|----------|-------|------|
| 类型定位 | Linux 内核级防火墙 / NAT / 端口转发 | 轻量级四层转发工具 | 通用代理 / 隧道 / 转发工具 |
| 工作层级 | 内核层 | 用户态 | 用户态 |
| 主要用途 | DNAT、SNAT、端口映射、规则控制 | TCP/UDP 端口转发、流量中继 | 端口转发、代理、隧道、链式转发 |
| 性能表现 | **最高**，适合高并发和长期稳定运行 | 较高，适合轻量转发 | 中等到较高，取决于功能链路复杂度 |
| 资源占用 | 最低 | 较低 | 相对更高 |
| 配置复杂度 | 较高 | 简单 | 中等到较高 |
| 上手难度 | 偏高，需要理解 NAT / 路由 / 防火墙规则 | 低，配置直观 | 中等，功能强但参数较多 |
| 支持协议 | 主要是 TCP / UDP / NAT 层规则 | 主要是 TCP / UDP | TCP / UDP / HTTP / HTTPS / SOCKS / WS / TLS 等多种协议 |
| 功能扩展性 | 偏底层，适合做基础转发平台 | 偏单一，适合专注端口转发 | **最强**，适合复杂代理和多级转发 |
| 面板化难度 | 中等，需自己做规则管理 | 较低，逻辑相对简单 | 中等，配置项较多 |
| 稳定性 | **非常高** | 高 | 高 |
| 适合场景 | 服务器端口转发、NAT 网关、长期稳定生产环境 | 简单端口中继、落地转发、轻量替代方案 | 多协议代理、跨网络隧道、复杂中转链路 |
| 是否适合做“转发管理面板” | **非常适合**，但要自己做规则抽象 | 适合，逻辑简单 | 适合，但配置模型会更复杂 |

## 🧭 选择建议

- **只做端口转发 / NAT / 高性能生产环境**：优先选择 `nftables`
- **只想做简单 TCP/UDP 转发**：可以选择 `realm`
- **需要代理、隧道、链式转发、多协议支持**：优先选择 `gost`

## ✅ 简单结论

- `nftables`：最适合做底层、高性能、长期运行的转发系统
- `realm`：最适合做轻量级、简单直接的端口转发
- `gost`：最适合做复杂网络代理和多协议隧道场景

如果你的目标是做一个 **可视化端口转发管理面板**，那么：

- 想追求性能和生产可用性：推荐 `nftables`
- 想追求简单快速实现：推荐 `realm`
- 想做功能很多的综合网关：推荐 `gost`

---

## 目录结构

```text
nftables/
├── lib/
│   ├── core.sh
│   ├── rules.sh
│   ├── server.sh
│   └── ui.sh
├── systemd/
│   └── vl-panel.service
├── web/
│   └── vl-panel.html
├── README.md
└── vl.sh
