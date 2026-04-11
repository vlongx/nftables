#!/bin/bash

# vl - VLONGX 端口转发管理工具
# Bootstrap 引导器 + 入口

INSTALL_DIR="/usr/local/bin"
LIB_DIR="$INSTALL_DIR/lib"
SHORTCUT_PATH="/usr/local/bin/vl"
REPO_RAW_URL="https://raw.githubusercontent.com/vlongx/nftables/main"
LIB_FILES=("core.sh" "rules.sh" "server.sh" "ui.sh")
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_BLUE='\033[0;34m'
_NC='\033[0m'
_download() {
    local url="$1" target="$2"
    curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$target" 2>/dev/null ||
    wget -qO "$target" "$url" 2>/dev/null
}
_bootstrap() {
    echo -e "${_YELLOW}正在安装/更新脚本文件...${_NC}"
    mkdir -p "$LIB_DIR"
    if _download "$REPO_RAW_URL/vl.sh" "$INSTALL_DIR/vl.sh"; then
        chmod +x "$INSTALL_DIR/vl.sh"
        echo -e "  ${_GREEN}✓${_NC} vl.sh"
    else
        echo -e "  ${_RED}✗${_NC} vl.sh 下载失败"
        return 1
    fi
    local failed=0
    for f in "${LIB_FILES[@]}"; do
        if _download "$REPO_RAW_URL/lib/$f" "$LIB_DIR/$f"; then
            echo -e "  ${_GREEN}✓${_NC} lib/$f"
        else
            echo -e "  ${_RED}✗${_NC} lib/$f 下载失败"
            failed=1
        fi
    done
    [ "$failed" -eq 1 ] && return 1
    ln -sf "$INSTALL_DIR/vl.sh" "$SHORTCUT_PATH"
    echo -e "${_GREEN}✓ 快捷命令已创建: vl${_NC}"
    echo -e "${_GREEN}=== 脚本安装完成${_NC}"
    echo ""
}
_load_libs() {
    if [ ! -d "$LIB_DIR" ] || [ ! -f "$LIB_DIR/core.sh" ]; then
        echo -e "${_RED}错误: 未找到模块目录，请先安装${_NC}"
        echo -e "${_BLUE}wget -qO- ${REPO_RAW_URL}/vl.sh | sudo bash -s install${_NC}"
        return 1
    fi
    for f in "${LIB_FILES[@]}"; do
        if [ -f "$LIB_DIR/$f" ]; then
            source "$LIB_DIR/$f"
        else
            echo -e "${_RED}错误: 缺少模块 $f${_NC}"
            return 1
        fi
    done
}
case "${1:-}" in
    install)
        [ "$(id -u)" -ne 0 ] && { echo -e "${_RED}错误: 需要 root 权限${_NC}"; exit 1; }
        _bootstrap || exit 1
        _load_libs || exit 1
        _SKIP_SCRIPT_UPDATE=1 smart_install
        ;;
    *)
        _load_libs || exit 1
        main "$@"
        ;;
esac
