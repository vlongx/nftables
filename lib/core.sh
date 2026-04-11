
#!/bin/bash
set -euo pipefail
VL_HOME="/opt/vlongx"
VL_CONF_DIR="/etc/vlongx"
VL_RULE_DB="$VL_CONF_DIR/rules.db"
VL_NFT_FILE="$VL_CONF_DIR/vlongx.nft"
VL_PANEL_PORT="${VL_PANEL_PORT:-18080}"
_RED='\033[0;31m'; _GREEN='\033[0;32m'; _YELLOW='\033[1;33m'; _BLUE='\033[0;34m'; _MAGENTA='\033[0;35m'; _CYAN='\033[0;36m'; _NC='\033[0m'
msg(){ echo -e "$*"; }
info(){ msg "${_CYAN}[*]${_NC} $*"; }
success(){ msg "${_GREEN}[✓]${_NC} $*"; }
warn(){ msg "${_YELLOW}[!]${_NC} $*"; }
err(){ msg "${_RED}[x]${_NC} $*"; }
require_root(){ [ "$(id -u)" -eq 0 ] || { err '需要 root 权限'; exit 1; }; }
ensure_dirs(){ mkdir -p "$VL_HOME/web" "$VL_HOME/systemd" "$VL_CONF_DIR"; [ -f "$VL_RULE_DB" ] || echo 'id|listen_port|proto|target_ip|target_port|remark' > "$VL_RULE_DB"; }
install_deps(){ require_root; export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install -y nftables curl wget python3 ca-certificates util-linux >/dev/null 2>&1 || apt-get install -y nftables curl wget python3 ca-certificates util-linux; echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-vlongx.conf; sysctl --system >/dev/null 2>&1 || true; systemctl enable nftables >/dev/null 2>&1 || true; systemctl start nftables >/dev/null 2>&1 || true; ensure_dirs; success '基础环境安装完成'; }
