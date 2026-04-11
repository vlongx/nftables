#!/bin/bash
set -euo pipefail
install_panel_service(){ require_root; install -Dm644 /opt/vlongx/systemd/vl-panel.service /etc/systemd/system/vl-panel.service; sed -i "s#__VL_HOME__#$VL_HOME#g" /etc/systemd/system/vl-panel.service; sed -i "s#__VL_PANEL_PORT__#$VL_PANEL_PORT#g" /etc/systemd/system/vl-panel.service; systemctl daemon-reload; systemctl enable --now vl-panel.service; success "面板已启动: http://127.0.0.1:${VL_PANEL_PORT}/vl-panel.html"; }
show_panel_status(){ systemctl status vl-panel.service --no-pager || true; }
smart_install(){ ensure_dirs; install_deps; apply_ruleset || true; install_panel_service; success 'vlongx 安装完成'; }
