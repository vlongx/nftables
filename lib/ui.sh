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

        zh:server_info) echo "服务器信息" ;;
        en:server_info) echo "Server Information" ;;

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

get_server_ip() {
    local ip
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [ -z "${ip:-}" ]; then
        ip="127.0.0.1"
    fi
    echo "$ip"
}

draw_line() {
    printf '%*s\n' "$1" '' | tr ' ' '─'
}

show_banner() {
    clear
    printf '\033[2J\033[H'

    local pink='\033[38;5;212m'
    local green='\033[38;5;82m'
    local blue='\033[38;5;45m'
    local orange='\033[38;5;216m'
    local white='\033[38;5;252m'
    local reset='\033[0m'

    echo -e "${pink}"
    cat <<'TXT'
██    ██ ██       ██████  ███    ██  ██████  ██   ██
██    ██ ██      ██    ██ ████   ██ ██       ██   ██
██    ██ ██      ██    ██ ██ ██  ██ ██   ███ ███████
 ██  ██  ██      ██    ██ ██  ██ ██ ██    ██ ██   ██
  ████   ███████  ██████  ██   ████  ██████  ██   ██
TXT
    echo -e "${reset}"

    echo -e "${pink}$(tr_text title)${reset}"
    echo -e "${blue}$(tr_text subtitle)${reset}"
    echo ""

    echo -e "${green}┌──────────────────────────────────────────────────────────────┐${reset}"
    printf "${green}│${reset} %-60s ${green}│${reset}\n" "$(tr_text server_info)"
    printf "${green}│${reset} • %s: ${orange}%-47s${reset} ${green}│${reset}\n" "$(tr_text server_ip)" "$(get_server_ip)"
    printf "${green}│${reset} • %s: ${white}%-45s${reset} ${green}│${reset}\n" "$(tr_text rule_store)" "/etc/vlongx/rules.db"
    printf "${green}│${reset} • %s: ${white}%-52s${reset} ${green}│${reset}\n" "$(tr_text version)" "v1.0"
    echo -e "${green}└──────────────────────────────────────────────────────────────┘${reset}"
    echo ""
}

switch_language() {
    echo ""
    echo -e "${_CYAN}$(tr_text choose_lang)${_NC}"
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
    local green='\033[38;5;82m'
    local blue='\033[38;5;45m'
    local pink='\033[38;5;212m'
    local orange='\033[38;5;216m'
    local reset='\033[0m'

    while true; do
        show_banner

        echo -e "${green}$(tr_text m1)${reset}"
        echo -e "${green}$(tr_text m2)${reset}"
        echo -e "${blue}$(tr_text m3)${reset}"
        echo -e "${green}$(tr_text m4)${reset}"
        echo -e "${blue}$(tr_text m5)${reset}"
        echo -e "${pink}$(tr_text m6)${reset}"
        echo -e "${orange}$(tr_text m7)${reset}"
        echo -e "${orange}$(tr_text m0)${reset}"
        echo ""
        echo -e "\033[38;5;240m────────────────────────────────────────────\033[0m"
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
                echo -e "${_GREEN}$(tr_text exit_msg)${_NC}"
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
