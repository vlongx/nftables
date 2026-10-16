#!/bin/bash
set -euo pipefail

get_lang() {
    [ -f "$VL_LANG_FILE" ] && cat "$VL_LANG_FILE" || echo "zh"
}

set_lang() {
    require_root
    mkdir -p "$VL_CONF_DIR"
    echo "$1" > "$VL_LANG_FILE"
}

tr_text() {
    local key="$1"
    local lang
    lang="$(get_lang)"

    case "$lang:$key" in
        zh:title) echo "VLONGX" ;;
        en:title) echo "VLONGX" ;;

        zh:subtitle) echo "基于 nftables 转发服务" ;;
        en:subtitle) echo "Forwarding Service Based on nftables" ;;

        zh:m1) echo "1) 添加转发规则" ;;
        en:m1) echo "1) Add forwarding rule" ;;

        zh:m2) echo "2) 查看规则列表" ;;
        en:m2) echo "2) List rules" ;;

        zh:m3) echo "3) 删除转发规则" ;;
        en:m3) echo "3) Delete rule" ;;

        zh:m4) echo "4) 应用 nftables 规则" ;;
        en:m4) echo "4) Apply nftables rules" ;;

        zh:m5) echo "5) 查看运行状态" ;;
        en:m5) echo "5) Show runtime status" ;;

        zh:m6) echo "6) 切换语言 / Switch Language" ;;
        en:m6) echo "6) Switch Language / 切换语言" ;;

        zh:m7) echo "7) 检查更新 / 更新脚本" ;;
        en:m7) echo "7) Check updates / Update script" ;;

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

init_colors() {
    C_RESET='\033[0m'
    C_TITLE='\033[38;5;169m'
    C_SUB='\033[38;5;32m'
    C_MENU1='\033[38;5;28m'
    C_MENU2='\033[38;5;24m'
    C_MENU3='\033[38;5;130m'
    C_MENU4='\033[38;5;31m'
    C_MENU5='\033[38;5;95m'
    C_MENU7='\033[38;5;136m'
    C_MENU6='\033[38;5;136m'
    C_DIM='\033[38;5;245m'
}

show_logo() {
    echo -e "${C_TITLE}"
    cat <<'TXT'
__     ___      ___  _   _  ____ __  __
\ \   / / |    / _ \| \ | |/ ___|\ \/ /
 \ \ / /| |   | | | |  \| | |  _  \  /
  \ V / | |___| |_| | |\  | |_| | /  \
   \_/  |_____|\___/|_| \_|\____|/_/\_\
TXT
    echo -e "${C_RESET}"
}

show_banner() {
    init_colors
    clear
    show_logo
    echo ""
    echo -e "${C_TITLE}$(tr_text title)${C_RESET}"
    echo -e "${C_SUB}$(tr_text subtitle)${C_RESET}"
    echo ""
    echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
    echo ""
}

switch_language() {
    echo ""
    echo -e "${C_SUB}$(tr_text choose_lang)${C_RESET}"
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
        echo -e "${C_MENU1}$(tr_text m1)${C_RESET}"
        echo -e "${C_MENU2}$(tr_text m2)${C_RESET}"
        echo -e "${C_MENU3}$(tr_text m3)${C_RESET}"
        echo -e "${C_MENU4}$(tr_text m4)${C_RESET}"
        echo -e "${C_MENU5}$(tr_text m5)${C_RESET}"
        echo -e "${C_MENU6}$(tr_text m6)${C_RESET}"
        echo -e "${C_MENU7}$(tr_text m7)${C_RESET}"
        echo -e "${C_DIM}$(tr_text m0)${C_RESET}"
        echo ""
        echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
        printf "%s" "$(tr_text prompt)"
        read -r choice

        case "$choice" in
            1) add_rule_cli; printf "%s" "$(tr_text press_enter)"; read -r ;;
            2) list_rules; printf "%s" "$(tr_text press_enter)"; read -r ;;
            3) delete_rule_cli; printf "%s" "$(tr_text press_enter)"; read -r ;;
            4) apply_ruleset; printf "%s" "$(tr_text press_enter)"; read -r ;;
            5) show_runtime_status; printf "%s" "$(tr_text press_enter)"; read -r ;;
            6) switch_language; sleep 1 ;;
            7) update_cli; printf "%s" "$(tr_text press_enter)"; read -r ;;
            0) echo -e "${C_SUB}$(tr_text exit_msg)${C_RESET}"; exit 0 ;;
            *) warn "$(tr_text invalid)"; sleep 1 ;;
        esac
    done
}

main() {
    case "${1:-menu}" in
        menu) main_menu ;;
        add) add_rule_cli ;;
        list) list_rules ;;
        delete|del) delete_rule_cli ;;
        apply) apply_ruleset ;;
        status) show_runtime_status ;;
        update) update_cli ;;
        lang-zh) set_lang zh ;;
        lang-en) set_lang en ;;
        *) main_menu ;;
    esac
}
