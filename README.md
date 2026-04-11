# NFTABLES

一个基于 `nftables` 的端口转发管理工具，提供：

- 一键安装
- CLI 菜单管理
- TCP / UDP / BOTH 转发
- nftables 规则生成与应用
- 简单静态面板
- systemd 后台服务管理
---
### 安装方式

#### 海外服务器
```bash
wget -qO- https://raw.githubusercontent.com/vlongx/nftables/main/vl.sh | sudo bash -s install
```
#### 国内服务器
```bash
wget -qO- https://ghfast.top/https://raw.githubusercontent.com/vlongx/nftables/main/vl.sh | sudo bash -s install
```
---
### 核心特性

- 🚀 一键安装，开箱即用
- 📦 统一命令入口：`vl`
- 🔁 支持 TCP / UDP / BOTH 转发
- 🧩 模块化脚本结构，便于维护
- 🛠 基于 nftables 实现规则管理
- 🌐 内置简易管理面板
- 🔧 支持 systemd 服务托管
- 📈 便于后续扩展 Web API 与鉴权系统

---
### 📊 nftables / realm / gost 转发对比

| 项目 | nftables | realm | gost |
|------|----------|-------|------|
| 类型 | 系统级转发 | 中继转发工具 | 代理/转发工具 |
| 性能 | 高 | 高 | 中 |
| 配置难度 | 中 | 简单 | 中 |
| 支持协议 | TCP / UDP | TCP / UDP | TCP / UDP / 更多代理协议 |
| 适合场景 | 长期稳定转发 | 轻量转发 | 复杂代理与转发 |
| 推荐程度 | ✅ 生产转发 | ✅ 简单中转 | ✅ 功能扩展 |

> 选择建议
> - 只做端口转发 / NAT / 高性能生产环境：优先选择 `nftables`
> - 只想做简单 TCP/UDP 转发：可以选择 `realm`
> - 需要代理、隧道、链式转发、多协议支持：优先选择 `gost`

> 简单结论
> - `nftables`：最适合做底层、高性能、长期运行的转发系统
> - `realm`：最适合做轻量级、简单直接的端口转发
> - `gost`：最适合做复杂网络代理和多协议隧道场景

如果你的目标是做一个 **可视化端口转发管理面板**，那么：

- 想追求性能和生产可用性：推荐 `nftables`
- 想追求简单快速实现：推荐 `realm`
- 想做功能很多的综合网关：推荐 `gost`

---

### 目录结构

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
