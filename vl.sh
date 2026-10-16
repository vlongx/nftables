#!/bin/bash
set -e

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
    curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$target" 2>/dev/null || \
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
            chmod +x "$LIB_DIR/$f"
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

update_cli() {
    [ "$(id -u)" -eq 0 ] || { echo "需要 root 权限"; return 1; }
    local stage backup f answer failed=0 same=1
    stage="$(mktemp -d)" || return 1
    backup="$(mktemp -d)" || { rm -rf "$stage"; return 1; }
    echo "正在检查 GitHub 最新版本..."
    for f in vl.sh lib/core.sh lib/rules.sh lib/server.sh lib/ui.sh; do
        mkdir -p "$stage/$(dirname "$f")"
        if ! _download "$REPO_RAW_URL/$f" "$stage/$f" || [ ! -s "$stage/$f" ] || ! bash -n "$stage/$f"; then
            echo "下载或校验失败：$f；未修改当前安装"
            rm -rf "$stage" "$backup"
            return 1
        fi
        cmp -s "$stage/$f" "$INSTALL_DIR/$f" || same=0
    done
    if [ "$same" -eq 1 ]; then
        echo "当前已是最新版本"
        rm -rf "$stage" "$backup"
        return 0
    fi
    read -rp "发现更新，输入 YES 确认安装: " answer
    if [ "$answer" != "YES" ]; then
        echo "已取消"
        rm -rf "$stage" "$backup"
        return 0
    fi
    for f in vl.sh lib/core.sh lib/rules.sh lib/server.sh lib/ui.sh; do
        mkdir -p "$backup/$(dirname "$f")"
        cp -p "$INSTALL_DIR/$f" "$backup/$f" || { rm -rf "$stage" "$backup"; return 1; }
    done
    for f in vl.sh lib/core.sh lib/rules.sh lib/server.sh lib/ui.sh; do
        cp "$stage/$f" "$INSTALL_DIR/$f" && chmod 755 "$INSTALL_DIR/$f" || { failed=1; break; }
    done
    if [ "$failed" -ne 0 ]; then
        echo "更新失败，恢复旧文件..."
        for f in vl.sh lib/core.sh lib/rules.sh lib/server.sh lib/ui.sh; do
            cp -p "$backup/$f" "$INSTALL_DIR/$f" || true
        done
        rm -rf "$stage" "$backup"
        return 1
    fi
    rm -rf "$stage" "$backup"
    echo "更新完成。已保留规则数据库和系统配置；重新执行 vl menu 即可。"
}

_load_libs() {
    if [ ! -d "$LIB_DIR" ] || [ ! -f "$LIB_DIR/core.sh" ]; then
        echo -e "${_RED}错误: 未找到模块目录，请先安装${_NC}"
        echo -e "${_BLUE}wget -qO- ${REPO_RAW_URL}/vl.sh | sudo bash -s install${_NC}"
        return 1
    fi

    for f in "${LIB_FILES[@]}"; do
        if [ -f "$LIB_DIR/$f" ]; then
            . "$LIB_DIR/$f"
        else
            echo -e "${_RED}错误: 缺少模块 $f${_NC}"
            return 1
        fi
    done
}

case "${1:-}" in
    install)
        [ "$(id -u)" -ne 0 ] && {
            echo -e "${_RED}错误: 需要 root 权限${_NC}"
            exit 1
        }
        _bootstrap || exit 1
        _load_libs || exit 1
        _SKIP_SCRIPT_UPDATE=1 smart_install
        ;;
    *)
        _load_libs || exit 1
        main "$@"
        ;;
esac
