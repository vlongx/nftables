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
        zh:panel_title) echo "VLONGX 面板" ;;
        en:panel_title) echo "VLONGX PANEL" ;;

        zh:subtitle) echo "增强安装版 v1.0" ;;
        en:subtitle) echo "Enhanced Setup v1.0" ;;

        zh:menu_1) echo "1) 添加转发规则" ;;
        en:menu_1) echo "1) Add forwarding rule" ;;

        zh:menu_2) echo "2) 查看规则列表" ;;
        en:menu_2) echo "2) List rules" ;;

        zh:menu_3) echo "3) 删除转发规则" ;;
        en:menu_3) echo "3) Delete rule" ;;

        zh:menu_4) echo "4) 应用 nftables 规则" ;;
        en:menu_4) echo "4) Apply nftables rules" ;;

        zh:menu_5) echo "5) 安装或重启面板" ;;
        en:menu_5) echo "5) Install or restart panel" ;;

        zh:menu_6) echo "6) 查看面板状态" ;;
        en:menu_6) echo "6) Show panel status" ;;

        zh:menu_7) echo "7) 切换语言 / Switch Language" ;;
        en:menu_7) echo "7) Switch Language / 切换语言" ;;

        zh:menu_0) echo "0) 退出" ;;
        en:menu_0) echo "0) Exit" ;;

        zh:prompt) echo -n "请输入选项 [0-7]: " ;;
        en:prompt) echo -n "Please enter your choice [0-7]: " ;;

        zh:press_enter) echo -n "按回车继续..." ;;
        en:press_enter) echo -n "Press Enter to continue..." ;;

        zh:invalid) echo "无效选项，请重新输入" ;;
        en:invalid) echo "Invalid option, please try again" ;;

        zh:exit) echo "已退出。" ;;
        en:exit) echo "Exited." ;;

        zh:choose_lang) echo -e "1) 中文\n2) English" ;;
        en:choose_lang) echo -e "1) 中文\n2) English" ;;

        zh:choose_lang_prompt) echo -n "请选择语言 [1-2]: " ;;
        en:choose_lang_prompt) echo -n "Choose language [1-2]: " ;;

        zh:lang_saved) echo "语言已切换为中文" ;;
        en:lang_saved) echo "Language switched to English" ;;

        zh:lang_invalid) echo "语言选项无效" ;;
        en:lang_invalid) echo "Invalid language option" ;;

        *) echo "$key" ;;
    esac
}

show_banner() {
    clear
    printf '\033[2J\033[H'

    echo -e "\033[38;5;213m"
    cat <<'TXT'
██    ██ ██       ██████  ███    ██  ██████  ██   ██
██    ██ ██      ██    ██ ████   ██ ██       ██   ██
██    ██ ██      ██    ██ ██ ██  ██ ██   ███ ███████
 ██  ██  ██      ██    ██ ██  ██ ██ ██    ██ ██   ██
  ████   ███████  ██████  ██   ████  ██████  ██   ██
TXT
    echo -e "\033[0m"

    echo -e "\033[38;5;135m$(tr_text panel_title)${_NC}"
    echo -e "\033[38;5;45m$(tr_text subtitle)${_NC}"
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
            success "$(tr_text lang_saved)"
            ;;
        2)
            set_lang en
            success "$(tr_text lang_saved)"
            ;;
        *)
            warn "$(tr_text lang_invalid)"
            ;;
    esac
}

main_menu() {
    while true; do
        show_banner
        echo -e "\033[38;5;46m$(tr_text menu_1)${_NC}"
        echo -e "\033[38;5;82m$(tr_text menu_2)${_NC}"
        echo -e "\033[38;5;118m$(tr_text menu_3)${_NC}"
        echo -e "\033[38;5;45m$(tr_text menu_4)${_NC}"
        echo -e "\033[38;5;213m$(tr_text menu_5)${_NC}"
        echo -e "\033[38;5;51m$(tr_text menu_6)${_NC}"
        echo -e "\033[38;5;220m$(tr_text menu_7)${_NC}"
        echo -e "${_YELLOW}$(tr_text menu_0)${_NC}"
        echo ""
        printf "%s" "$(tr_text prompt)"
        read -r choice

        case "$choice" in
            1)
                add_rule_cli
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            2)
                list_rules
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            3)
                delete_rule_cli
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            4)
                apply_ruleset
                printf "%s" "$(tr_text press_enter)"
                read -r
                ;;
            5)
                install_panel_service
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
                echo -e "${_GREEN}$(tr_text exit)${_NC}"
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
