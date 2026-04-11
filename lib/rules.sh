#!/bin/bash
set -euo pipefail

next_rule_id() {
    awk -F'|' 'NR>1{if($1>m)m=$1}END{print m+1}' "$VL_RULE_DB"
}

validate_proto() {
    case "$1" in
        tcp|udp|both) ;;
        *)
            err "协议必须是 tcp、udp 或 both"
            return 1
            ;;
    esac
}

validate_port() {
    local p="$1"
    [[ "$p" =~ ^[0-9]+$ ]] || return 1
    [ "$p" -ge 1 ] && [ "$p" -le 65535 ]
}

render_ruleset() {
    require_root
    ensure_dirs

    cat > "$VL_NFT_FILE" <<'NFT'
#!/usr/sbin/nft -f

table ip vlongx {
    chain prerouting {
        type nat hook prerouting priority -100;
        policy accept;
    }

    chain postrouting {
        type nat hook postrouting priority 100;
        policy accept;
    }
}

table inet vlongx_filter {
    chain forward {
        type filter hook forward priority filter;
        policy accept;
    }
}
NFT

    awk -F'|' '
    NR>1 && $1 != "" {
        if ($3=="tcp" || $3=="both") {
            print "add rule ip vlongx prerouting tcp dport " $2 " dnat to " $4 ":" $5
            print "add rule inet vlongx_filter forward ip daddr " $4 " tcp dport " $5 " accept"
        }
        if ($3=="udp" || $3=="both") {
            print "add rule ip vlongx prerouting udp dport " $2 " dnat to " $4 ":" $5
            print "add rule inet vlongx_filter forward ip daddr " $4 " udp dport " $5 " accept"
        }
        print "add rule ip vlongx postrouting ip daddr " $4 " masquerade"
    }' "$VL_RULE_DB" >> "$VL_NFT_FILE"

    success "已生成规则文件: $VL_NFT_FILE"
}

apply_ruleset() {
    require_root
    render_ruleset
    install_nft_main_conf
    nft -c -f /etc/nftables.conf
    systemctl restart nftables
    success "规则已应用"
}

add_rule_cli() {
    require_root
    ensure_dirs

    local listen_port proto target_ip target_port remark id

    echo ""
    read -rp '监听端口: ' listen_port
    validate_port "$listen_port" || { err "监听端口无效"; return 1; }

    read -rp '协议 [tcp/udp/both]: ' proto
    validate_proto "$proto" || return 1

    read -rp '目标 IP: ' target_ip
    [ -n "$target_ip" ] || { err "目标 IP 不能为空"; return 1; }

    read -rp '目标端口: ' target_port
    validate_port "$target_port" || { err "目标端口无效"; return 1; }

    read -rp '备注: ' remark

    id="$(next_rule_id)"
    echo "$id|$listen_port|$proto|$target_ip|$target_port|$remark" >> "$VL_RULE_DB"

    echo ""
    success "已添加规则 #$id"
    apply_ruleset
}

list_rules() {
    ensure_dirs

    local C_RESET='\033[0m'
    local C_TITLE='\033[38;5;34m'
    local C_KEY='\033[38;5;239m'
    local C_VALUE='\033[38;5;27m'
    local C_HL='\033[38;5;161m'
    local C_WARN='\033[38;5;136m'
    local C_DIM='\033[38;5;245m'

    local total enabled disabled
    total=$(( $(awk 'END{print NR}' "$VL_RULE_DB") - 1 ))
    [ "$total" -lt 0 ] && total=0
    enabled="$total"
    disabled=0

    echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
    echo -e "${C_KEY}服务状态：${C_RESET} ${C_TITLE}● 运行中${C_RESET}"
    echo -e "${C_KEY}配置模式：${C_RESET} ${C_TITLE}多规则模式${C_RESET} (${C_TITLE}${enabled}${C_RESET} 启用 / ${C_WARN}${disabled}${C_RESET} 禁用 / 共 ${total} 个)"
    echo -e "${C_TITLE}中转服务器：${C_RESET}"

    if [ "$total" -eq 0 ]; then
        echo -e "  ${C_DIM}暂无规则${C_RESET}"
        echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
        return 0
    fi

    while IFS='|' read -r id listen_port proto target_ip target_port remark; do
        [ "$id" = "id" ] && continue
        [ -z "${id:-}" ] && continue

        local proto_show
        case "$proto" in
            tcp) proto_show="TCP" ;;
            udp) proto_show="UDP" ;;
            both) proto_show="TCP/UDP" ;;
            *) proto_show="$proto" ;;
        esac

        echo -e "  ${C_KEY}• 中转：${C_RESET} ${C_VALUE}0.0.0.0:${listen_port}${C_RESET} ${C_DIM}→${C_RESET} ${C_HL}${target_ip}:${target_port}${C_RESET}"
        echo -e "    ${C_KEY}协议：${C_RESET}${C_WARN}${proto_show}${C_RESET}"
        if [ -n "${remark:-}" ]; then
            echo -e "    ${C_KEY}备注：${C_RESET}${C_DIM}${remark}${C_RESET}"
        fi
    done < "$VL_RULE_DB"

    echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
}

delete_rule_cli() {
    require_root
    ensure_dirs

    local id
    echo ""
    list_rules
    echo ""
    read -rp '输入要删除的规则 ID: ' id

    [[ "$id" =~ ^[0-9]+$ ]] || { err "规则 ID 无效"; return 1; }

    if ! awk -F'|' -v id="$id" 'NR>1 && $1==id{found=1} END{exit !found}' "$VL_RULE_DB"; then
        err "规则 #$id 不存在"
        return 1
    fi

    awk -F'|' -v id="$id" 'NR==1 || $1!=id' "$VL_RULE_DB" > "$VL_RULE_DB.tmp"
    mv "$VL_RULE_DB.tmp" "$VL_RULE_DB"

    echo ""
    success "已删除规则 #$id"
    apply_ruleset
}
