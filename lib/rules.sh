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

    nft delete table ip vlongx >/dev/null 2>&1 || true

    cat > "$VL_NFT_FILE" <<'NFT'
#!/usr/sbin/nft -f

table ip vlongx {
    chain prerouting {
        type nat hook prerouting priority -100;
    }

    chain postrouting {
        type nat hook postrouting priority 100;
    }
}
NFT

    awk -F'|' '
    NR>1 && $1 != "" {
        if ($3=="tcp" || $3=="both")
            print "add rule ip vlongx prerouting tcp dport "$2" dnat to "$4":"$5;
        if ($3=="udp" || $3=="both")
            print "add rule ip vlongx prerouting udp dport "$2" dnat to "$4":"$5;
        print "add rule ip vlongx postrouting ip daddr "$4" masquerade";
    }' "$VL_RULE_DB" >> "$VL_NFT_FILE"

    success "已生成规则文件: $VL_NFT_FILE"
}

apply_ruleset() {
    require_root
    render_ruleset
    nft -c -f "$VL_NFT_FILE"
    nft -f "$VL_NFT_FILE"
    systemctl restart nftables >/dev/null 2>&1 || true
    success "规则已应用"
}

add_rule_cli() {
    require_root
    ensure_dirs

    local listen_port proto target_ip target_port remark id

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

    success "已添加规则 #$id"
    apply_ruleset
}

list_rules() {
    ensure_dirs
    if command -v column >/dev/null 2>&1; then
        column -t -s '|' "$VL_RULE_DB"
    else
        cat "$VL_RULE_DB"
    fi
}

delete_rule_cli() {
    require_root
    ensure_dirs

    local id
    list_rules
    read -rp '输入要删除的规则 ID: ' id

    awk -F'|' -v id="$id" 'NR==1 || $1!=id' "$VL_RULE_DB" > "$VL_RULE_DB.tmp"
    mv "$VL_RULE_DB.tmp" "$VL_RULE_DB"

    success "已删除规则 #$id"
    apply_ruleset
}
