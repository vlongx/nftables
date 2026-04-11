#!/bin/bash
set -euo pipefail

VL_LANG_FILE="/etc/vlongx/lang"

get_lang() {
    if [ -f "$VL_LANG_FILE" ]; then
        cat "$VL_LANG_FILE"
    else
        echo "zh"
    fi
}

set_lang() {
    require_root
    mkdir -p /etc/vlongx
    echo "$1" > "$VL_LANG_FILE"
}

tr_text() {
    local key="$1"
    local lang
    lang="$(get_lang)"

    case "$lang:$key" in
        zh:title) echo "VLONGX 面板" ;;
        en:title) echo "VLONGX Panel" ;;

        zh:subtitle) echo "增强安装版 v1.0" ;;
        en:subtitle) echo "Enhanced Setup v1.0" ;;

        zh:info_title) echo "服务器信息" ;;
        en:info_title) echo "Server Information" ;;

        zh:server_ip) echo "服务器 IP" ;;
        en:server_ip) echo "Server IP" ;;

        zh:rule_store) echo "规则存储" ;;
        en:rule_store) echo "Rule Store" ;;

        zh:version) echo "版本" ;;
        en:version) echo "Version" ;;

        zh:m1) echo "1) 安装并初始化 VLONGX 面板" ;;
        en:m1) echo "1) Install & Set Up VLONGX Panel" ;;

        zh:m2) echo "2) 添加转发规则" ;;
        en:m2) echo "2) Add forwarding rule" ;;

        zh:m3) echo "3) 查看规则列表" ;;
        en:m3) echo "3) List rules" ;;

        zh:m4) echo "4) 删除转发规则" ;;
        en:m4) echo "4) Delete rule" ;;

        zh:m5) echo "5) 应用 nftables 规则" ;;
        en:m5) echo "5) Apply nftables rules" ;;

        zh:m6) echo "6) 查看面板状态" ;;
        en:m6) echo "6) Show panel status" ;;

        zh:m7) echo "7) 切换语言 / Switch Language" ;;
        en:m7) echo "7) Switch Language / 切换语言" ;;

        zh:m0) echo "0) 退出" ;;
        en:m0) echo "0) Exit" ;;

        zh:prompt) echo -n "请输入选项 [0-7]: " ;;
        en:prompt) echo -n "Please enter your choice [0-7]: " ;;

        zh:press_enter) echo -n "按回车继续..." ;;
        en:press_enter) echo -n "Press Enter to continue..." ;;

        zh:invalid) echo "无效选项，请重新输入" ;;
        en:invalid) echo "Invalid option, please try again" ;;

        zh:exit_msg) echo "已退出。" ;;
        en:exit_msg) echo "Exited." ;;

        zh:choose_lang) echo -e "1) 中文\n2) English" ;;
        en:choose_lang) echo -e "1) 中文\n2) English" ;;

        zh:choose_lang_prompt) echo -n "请选择语言 [1-2]: " ;;
        en:choose_lang_prompt) echo -n "Choose language [1-2]: " ;;

        zh:lang_zh_saved) echo "语言已切换为中文" ;;
        en:lang_zh_saved) echo "Language switched to Chinese" ;;

        zh:lang_en_saved) echo "语言已切换为 English" ;;
        en:lang_en_saved) echo "Language switched to English" ;;

        zh:lang_invalid) echo "语言选项无效" ;;
        en:lang_invalid) echo "Invalid language option" ;;

        *) echo "$key" ;;
    esac
}

apply_terminal_theme() {
    local term="${TERM:-}"
    case "$term" in
        xterm*|screen*|tmux*|rxvt*|alacritty*|foot*|wezterm*|kitty*)
            printf '\033]10;#7DFF80\007' 2>/dev/null || true
            printf '\033]11;#05070B\007' 2>/dev/null || true
            printf '\033]12;#F7F7F7\007' 2>/dev/null || true
            ;;
    esac
    printf '\033[0m\033[40m\033[2J\033[H'
}

get_server_ip() {
    local ip
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [ -z "${ip:-}" ]; then
        ip="127.0.0.1"
    fi
    echo "$ip"
}

repeat_char() {
    local char="$1" count="$2"
    printf '%*s' "$count" '' | tr ' ' "$char"
}

print_box_line() {
    local left="$1" fill="$2" right="$3" width="$4"
    printf "%b%s%b%s%b%s%b\n" "$C_BORDER" "$left" "$C_RESET" "$(repeat_char "$fill" "$width")" "$C_BORDER" "$right" "$C_RESET"
}

print_box_text() {
    local text="$1" width="$2"
    local plain_len padding
    plain_len=$(printf "%s" "$text" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print length}')
    padding=$(( width - plain_len ))
    [ "$padding" -lt 0 ] && padding=0
    printf "%b│%b %s%*s %b│%b\n" "$C_BORDER" "$C_RESET" "$text" "$padding" "" "$C_BORDER" "$C_RESET"
}

init_colors() {
    C_RESET='\033[0m'
    C_BG='\033[40m'
    C_TITLE='\033[38;5;212m'
    C_TITLE_SHADOW='\033[38;5;168m'
    C_GREEN='\033[38;5;82m'
    C_GREEN2='\033[38;5;77m'
    C_BLUE='\033[38;5;39m'
    C_ORANGE='\033[38;5;215m'
    C_RED='\033[38;5;203m'
    C_WHITE='\033[38;5;252m'
    C_DIM='\033[38;5;240m'
    C_BORDER='\033[38;5;77m'
}

show_logo() {
    echo -e "${C_TITLE}"
    cat <<'TXT'
██    ██ ██       ██████  ███    ██  ██████  ██   ██
██    ██ ██      ██    ██ ████   ██ ██       ██   ██
██    ██ ██      ██    ██ ██ ██  ██ ██   ███ ███████
 ██  ██  ██      ██    ██ ██  ██ ██ ██    ██ ██   ██
  ████   ███████  ██████  ██   ████  ██████  ██   ██
TXT
    echo -e "${C_RESET}"
}

show_info_box() {
    local width=62
    print_box_line "┌" "─" "┐" "$width"
    print_box_text "${C_GREEN}$(tr_text info_title)${C_RESET}" "$width"
    print_box_text "${C_WHITE}• $(tr_text server_ip): ${C_ORANGE}$(get_server_ip)${C_RESET}" "$width"
    print_box_text "${C_WHITE}• $(tr_text rule_store): ${C_DIM}/etc/vlongx/rules.db${C_RESET}" "$width"
    print_box_text "${C_WHITE}• $(tr_text version): ${C_DIM}v1.0${C_RESET}" "$width"
    print_box_line "└" "─" "┘" "$width"
}

show_banner() {
    init_colors
    apply_terminal_theme

    show_logo
    echo -e "${C_TITLE}$(tr_text title)${C_RESET}"
    echo -e "${C_BLUE}$(tr_text subtitle)${C_RESET}"
    echo ""
    show_info_box
    echo ""
}

switch_language() {
    echo ""
    echo -e "${C_BLUE}$(tr_text choose_lang)${C_RESET}"
    echo ""
    printf "%s" "$(tr_text choose_lang_prompt)"
    read -r lang_choice

    case "$lang_choice" in
        1)
            set_lang zh
            success "$(tr_text lang_zh_saved)"
            ;;
        2)
            set_lang en
            success "$(tr_text lang_en_saved)"
            ;;
        *)
            warn "$(tr_text lang_invalid)"
            ;;
    esac
}

main_menu() {
    init_colors

    while true; do
        show_banner

        echo -e "${C_GREEN}$(tr_text m1)${C_RESET}"
        echo -e "${C_GREEN2}$(tr_text m2)${C_RESET}"
        echo -e "${C_BLUE}$(tr_text m3)${C_RESET}"
        echo -e "${C_GREEN2}$(tr_text m4)${C_RESET}"
        echo -e "${C_BLUE}$(tr_text m5)${C_RESET}"
        echo -e "${C_TITLE}$(tr_text m6)${C_RESET}"
        echo -e "${C_ORANGE}$(tr_text m7)${C_RESET}"
        echo -e "${C_RED}$(tr_text m0)${C_RESET}"
        echo ""
        echo -e "${C_DIM}$(repeat_char '─' 44)${C_RESET}"
        printf "%s" "$(tr_text prompt)"
        read -r choice

        case "$choice" in
            1)
                install_panel_service
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            2)
                add_rule_cli
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            3)
                list_rules
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            4)
                delete_rule_cli
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            5)
                apply_ruleset
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            6)
                show_panel_status
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            7)
                switch_language
                sleep 1
                ;;
            0)
                echo -e "${C_GREEN}$(tr_text exit_msg)${C_RESET}"
                printf '\033[0m'
                exit 0
                ;;
            *)
                warn "$(tr_text invalid)"
                sleep 1
                ;;
        esac
    done
}

main() {
    case "${1:-menu}" in
        menu)
            main_menu
            ;;
        add)
            add_rule_cli
            ;;
        list)
            list_rules
            ;;
        delete|del)
            delete_rule_cli
            ;;
        apply)
            apply_ruleset
            ;;
        panel-install)
            install_panel_service
            ;;
        panel-status)
            show_panel_status
            ;;
        lang-zh)
            set_lang zh
            ;;
        lang-en)
            set_lang en
            ;;
        *)
            main_menu
            ;;
    esac
}
