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

- **一键安装**  
  提供海外直连与国内加速两种安装方式，部署更方便。

- **统一命令入口**  
  所有操作统一使用 `vl` 命令管理，使用简单直观。

- **基于 nftables 转发**  
  使用 `nftables` 实现端口转发，规则清晰，便于维护和扩展。

- **支持多协议转发**  
  支持 `TCP`、`UDP` 以及 `BOTH` 模式，适配更多使用场景。

- **模块化脚本结构**  
  采用 `vl.sh + lib/*.sh` 结构拆分，便于后续维护、更新和二次开发。

- **规则增删改查**  
  支持新增规则、查看规则、删除规则，并可一键应用到系统。

- **自动生成规则文件**  
  自动生成对应的 `nftables` 配置文件，减少手动配置错误。

- **简单管理面板**  
  内置静态面板页面，方便后续继续扩展为动态 Web 管理面板。

- **systemd 服务管理**  
  面板服务支持 `systemd` 启动、重启和状态查看，便于长期运行。

- **适合继续扩展**  
  后续可以继续接入登录鉴权、API、规则搜索、批量导入导出等功能。

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
