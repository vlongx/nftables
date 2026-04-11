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
