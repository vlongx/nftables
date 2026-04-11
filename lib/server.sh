#!/bin/bash
set -euo pipefail

install_nft_main_conf() {
    require_root
    cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset
include "$VL_NFT_FILE"
EOF
    success "已写入 /etc/nftables.conf"
}

show_runtime_status() {
    echo "========== VLONGX 状态 =========="
    echo "规则数据库: $VL_RULE_DB"
    echo "nft 规则文件: $VL_NFT_FILE"
    echo ""
    echo "IP 转发:"
    sysctl net.ipv4.ip_forward 2>/dev/null || true
    echo ""
    echo "nftables 服务状态:"
    systemctl is-active nftables 2>/dev/null || true
    echo ""
    echo "当前规则:"
    list_rules
    echo ""
    echo "当前 nftables 规则集:"
    nft list ruleset 2>/dev/null || true
}

smart_install() {
    ensure_dirs
    install_deps
    render_ruleset
    install_nft_main_conf
    nft -c -f /etc/nftables.conf
    systemctl restart nftables
    success "VLONGX CLI 安装完成"
}
