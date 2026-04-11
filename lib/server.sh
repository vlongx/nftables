#!/bin/bash
set -euo pipefail

show_runtime_status() {
    echo "========== VLONGX 状态 =========="
    echo "规则文件: $VL_RULE_DB"
    echo "nft 配置: $VL_NFT_FILE"
    echo "nftables 服务:"
    systemctl is-active nftables 2>/dev/null || true
    echo ""
    echo "当前规则:"
    list_rules
}

smart_install() {
    ensure_dirs
    install_deps
    apply_ruleset || true
    success "VLONGX CLI 安装完成"
}
