#!/bin/bash
set -euo pipefail

VL_CONF_DIR="/etc/vlongx"
VL_RULE_DB="$VL_CONF_DIR/rules.db"
VL_NFT_FILE="$VL_CONF_DIR/vlongx.nft"
VL_LANG_FILE="$VL_CONF_DIR/lang"

_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_BLUE='\033[0;34m'
_MAGENTA='\033[0;35m'
_CYAN='\033[0;36m'
_NC='\033[0m'

msg() { echo -e "$*"; }
info() { msg "${_CYAN}[*]${_NC} $*"; }
success() { msg "${_GREEN}[✓]${_NC} $*"; }
warn() { msg "${_YELLOW}[!]${_NC} $*"; }
err() { msg "${_RED}[x]${_NC} $*"; }

require_root() {
    [ "$(id -u)" -eq 0 ] || {
        err "需要 root 权限"
        exit 1
    }
}

ensure_dirs() {
    mkdir -p "$VL_CONF_DIR"
    [ -f "$VL_RULE_DB" ] || echo 'id|listen_port|proto|target_ip|target_port|remark' > "$VL_RULE_DB"
    [ -f "$VL_LANG_FILE" ] || echo 'zh' > "$VL_LANG_FILE"
}

install_deps() {
    require_root
    export DEBIAN_FRONTEND=noninteractive

    if ! apt-get update; then
        err "apt-get update 失败，请检查第三方软件源或 GPG 签名"
        return 1
    fi

    apt-get install -y nftables curl wget ca-certificates util-linux >/dev/null 2>&1 || \
    apt-get install -y nftables curl wget ca-certificates util-linux

    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-vlongx.conf
    sysctl --system >/dev/null 2>&1 || true

    systemctl enable nftables >/dev/null 2>&1 || true
    systemctl start nftables >/dev/null 2>&1 || true

    ensure_dirs
    success "基础环境安装完成"
}
