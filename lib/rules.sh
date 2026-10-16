#!/bin/bash
set -euo pipefail

rule_db_new_header='id|listen_port|proto|input_spec|output_spec|target_ip|target_port|remark'

ensure_rule_db_schema() {
    mkdir -p "$(dirname "$VL_RULE_DB")"

    if [ ! -f "$VL_RULE_DB" ] || [ ! -s "$VL_RULE_DB" ]; then
        echo "$rule_db_new_header" > "$VL_RULE_DB"
        return 0
    fi

    local header
    header="$(head -n 1 "$VL_RULE_DB" 2>/dev/null || true)"

    if [ "$header" = "$rule_db_new_header" ]; then
        return 0
    fi

    if [ "$header" = 'id|listen_port|proto|target_ip|target_port|remark' ]; then
        awk -F'|' '
        BEGIN {
            OFS="|";
            print "id|listen_port|proto|input_spec|output_spec|target_ip|target_port|remark"
        }
        NR>1 && $1 != "" {
            print $1,$2,$3,"::","::",$4,$5,$6
        }' "$VL_RULE_DB" > "${VL_RULE_DB}.tmp"
        mv "${VL_RULE_DB}.tmp" "$VL_RULE_DB"
        success "已自动迁移旧规则库到新格式"
        return 0
    fi

    warn "检测到未知 rules.db 格式，已备份为 ${VL_RULE_DB}.bak"
    cp -f "$VL_RULE_DB" "${VL_RULE_DB}.bak"
    echo "$rule_db_new_header" > "$VL_RULE_DB"
}

next_rule_id() {
    ensure_rule_db_schema
    local counter_file="$VL_CONF_DIR/last_rule_id" max_id last_id next_id
    max_id="$(awk -F'|' 'NR>1 && $1 ~ /^[0-9]+$/ {if($1+0>m)m=$1+0} END{print m+0}' "$VL_RULE_DB")"
    last_id=0
    if [ -f "$counter_file" ]; then
        read -r last_id < "$counter_file" || true
        [[ "$last_id" =~ ^[0-9]+$ ]] || last_id=0
    fi
    [ "$max_id" -gt "$last_id" ] && last_id="$max_id"
    next_id=$((last_id + 1))
    printf '%s\n' "$next_id" > "${counter_file}.tmp"
    mv "${counter_file}.tmp" "$counter_file"
    printf '%s\n' "$next_id"
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

is_ipv4() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

    local a b c d
    IFS='.' read -r a b c d <<< "$ip"
    for n in "$a" "$b" "$c" "$d"; do
        [ "$n" -ge 0 ] 2>/dev/null && [ "$n" -le 255 ] 2>/dev/null || return 1
    done
    return 0
}

is_wildcard_spec() {
    case "${1:-}" in
        ""|::|0.0.0.0|any|all|*) [ "$1" = "*" ] && return 0 ;;
    esac
    case "${1:-}" in
        ""|::|0.0.0.0|any|all|'*') return 0 ;;
        *) return 1 ;;
    esac
}

normalize_spec() {
    local s="${1:-}"
    if is_wildcard_spec "$s"; then
        echo "::"
    else
        echo "$s"
    fi
}

build_input_match() {
    local spec
    spec="$(normalize_spec "${1:-}")"

    if is_wildcard_spec "$spec"; then
        echo ""
    elif is_ipv4 "$spec"; then
        echo "ip daddr $spec"
    else
        echo "iifname \"$spec\""
    fi
}

build_output_rule_suffix() {
    local spec target_ip
    spec="$(normalize_spec "${1:-}")"
    target_ip="$2"

    if is_wildcard_spec "$spec"; then
        echo "ip daddr $target_ip masquerade"
    elif is_ipv4 "$spec"; then
        echo "ip daddr $target_ip snat to $spec"
    else
        echo "oifname \"$spec\" ip daddr $target_ip masquerade"
    fi
}

proto_show_text() {
    case "$1" in
        tcp) echo "TCP" ;;
        udp) echo "UDP" ;;
        both) echo "TCP/UDP" ;;
        *) echo "$1" ;;
    esac
}

render_ruleset() {
    require_root
    ensure_dirs
    ensure_rule_db_schema

    local staging_file="${VL_NFT_FILE}.tmp.$"
    cat > "$staging_file" <<'NFT'
#!/usr/sbin/nft -f

flush ruleset

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

    while IFS='|' read -r id listen_port proto input_spec output_spec target_ip target_port remark; do
        [ "$id" = "id" ] && continue
        [ -z "${id:-}" ] && continue

        local input_match postrouting_suffix resolved_target
        resolved_target="$target_ip"
        if ! is_ipv4 "$target_ip"; then
            resolved_target="$(getent ahostsv4 "$target_ip" 2>/dev/null | awk 'NR==1 {print $1}')"
            if [ -z "$resolved_target" ] || ! is_ipv4 "$resolved_target"; then
                err "规则 #$id 目标域名解析失败：$target_ip；保留当前生效规则"
                return 1
            fi
        fi
        input_match="$(build_input_match "$input_spec")"
        postrouting_suffix="$(build_output_rule_suffix "$output_spec" "$resolved_target")"

        if [ "$proto" = "tcp" ] || [ "$proto" = "both" ]; then
            if [ -n "$input_match" ]; then
                echo "add rule ip vlongx prerouting $input_match tcp dport $listen_port dnat to $resolved_target:$target_port" >> "$staging_file"
            else
                echo "add rule ip vlongx prerouting tcp dport $listen_port dnat to $resolved_target:$target_port" >> "$staging_file"
            fi
            echo "add rule inet vlongx_filter forward ip daddr $resolved_target tcp dport $target_port accept" >> "$staging_file"
        fi

        if [ "$proto" = "udp" ] || [ "$proto" = "both" ]; then
            if [ -n "$input_match" ]; then
                echo "add rule ip vlongx prerouting $input_match udp dport $listen_port dnat to $resolved_target:$target_port" >> "$staging_file"
            else
                echo "add rule ip vlongx prerouting udp dport $listen_port dnat to $resolved_target:$target_port" >> "$staging_file"
            fi
            echo "add rule inet vlongx_filter forward ip daddr $resolved_target udp dport $target_port accept" >> "$staging_file"
        fi

        echo "add rule ip vlongx postrouting $postrouting_suffix" >> "$staging_file"
    done < "$VL_RULE_DB"

    mv "$staging_file" "$VL_NFT_FILE"
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
    ensure_rule_db_schema

    local C_RESET='\033[0m'
    local C_TITLE='\033[38;5;136m'
    local C_TEXT='\033[38;5;239m'
    local C_INFO='\033[38;5;25m'
    local C_OK='\033[38;5;34m'
    local C_DIM='\033[38;5;245m'
    local C_HL='\033[38;5;161m'

    local listen_port proto target_ip target_port remark id
    local input_spec output_spec

    echo ""
    echo -e "${C_TITLE}=== 中转服务器配置（不了解入口出口一般回车默认即可） ===${C_RESET}"
    echo ""

    echo -e "${C_INFO}支持单端口使用，回车可自动分配随机端口${C_RESET}"
    read -rp '请输入本地监听端口（客户端连接的端口）: ' listen_port
    if [ -z "${listen_port:-}" ]; then
        listen_port="$(shuf -i 20000-60000 -n 1)"
        echo -e "${C_OK}监听端口设置为：${listen_port}${C_RESET}"
    else
        validate_port "$listen_port" || { err "监听端口无效"; return 1; }
        echo -e "${C_OK}监听端口设置为：${listen_port}${C_RESET}"
    fi

    echo ""
    read -rp '自定义(指定)入口监听 IP/网卡接口（回车默认全部监听 ::）: ' input_spec
    input_spec="$(normalize_spec "${input_spec:-}")"
    if is_wildcard_spec "$input_spec"; then
        echo -e "${C_OK}使用默认监听入口：::（全部监听）${C_RESET}"
    else
        echo -e "${C_OK}入口监听设置为：${input_spec}${C_RESET}"
    fi

    echo ""
    read -rp '自定义(指定)出口 IP/网卡接口（回车默认自动 masquerade）: ' output_spec
    output_spec="$(normalize_spec "${output_spec:-}")"
    if is_wildcard_spec "$output_spec"; then
        echo -e "${C_OK}使用默认出口：自动 masquerade${C_RESET}"
    else
        echo -e "${C_OK}出口设置为：${output_spec}${C_RESET}"
    fi

    echo ""
    read -rp '请输入转发协议 [tcp/udp/both，默认 both]: ' proto
    [ -z "${proto:-}" ] && proto="both"
    validate_proto "$proto" || return 1
    echo -e "${C_OK}协议设置为：$(proto_show_text "$proto")${C_RESET}"

    echo ""
    read -rp '请输入目标 IP: ' target_ip
    [ -n "${target_ip:-}" ] || { err "目标 IP 不能为空"; return 1; }
    is_ipv4 "$target_ip" || warn "目标 IP 看起来不是标准 IPv4，请自行确认是否可路由"

    read -rp '请输入目标端口: ' target_port
    validate_port "$target_port" || { err "目标端口无效"; return 1; }
    echo -e "${C_OK}目标地址：${target_ip}:${target_port}${C_RESET}"

    echo ""
    read -rp '请输入备注信息（可留空）: ' remark
    [ -z "${remark:-}" ] && remark="-"

    echo ""
    echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
    echo -e "${C_TEXT}配置预览：${C_RESET}"
    echo -e "  ${C_TEXT}监听端口：${C_RESET}${C_INFO}${listen_port}${C_RESET}"
    echo -e "  ${C_TEXT}入口监听：${C_RESET}${C_INFO}${input_spec}${C_RESET}"
    echo -e "  ${C_TEXT}出口设置：${C_RESET}${C_INFO}${output_spec}${C_RESET}"
    echo -e "  ${C_TEXT}协议类型：${C_RESET}${C_INFO}$(proto_show_text "$proto")${C_RESET}"
    echo -e "  ${C_TEXT}转发目标：${C_RESET}${C_HL}${target_ip}:${target_port}${C_RESET}"
    echo -e "  ${C_TEXT}备注信息：${C_RESET}${C_DIM}${remark}${C_RESET}"
    echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
    echo ""

    id="$(next_rule_id)"
    echo "$id|$listen_port|$proto|$input_spec|$output_spec|$target_ip|$target_port|$remark" >> "$VL_RULE_DB"

    success "已添加规则 #$id"
    apply_ruleset
}

list_rules() {
    ensure_dirs
    ensure_rule_db_schema

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

    while IFS='|' read -r id listen_port proto input_spec output_spec target_ip target_port remark; do
        [ "$id" = "id" ] && continue
        [ -z "${id:-}" ] && continue

        echo -e "  ${C_TITLE}[ID: ${id}]${C_RESET}"
        echo -e "  ${C_KEY}• 中转：${C_RESET} ${C_VALUE}${input_spec}:${listen_port}${C_RESET} ${C_DIM}→${C_RESET} ${C_HL}${target_ip}:${target_port}${C_RESET}"
        echo -e "    ${C_KEY}协议：${C_RESET}${C_WARN}$(proto_show_text "$proto")${C_RESET}"
        echo -e "    ${C_KEY}入口：${C_RESET}${C_DIM}${input_spec}${C_RESET}"
        echo -e "    ${C_KEY}出口：${C_RESET}${C_DIM}${output_spec}${C_RESET}"
        if [ -n "${remark:-}" ] && [ "$remark" != "-" ]; then
            echo -e "    ${C_KEY}备注：${C_RESET}${C_DIM}${remark}${C_RESET}"
        fi
    done < "$VL_RULE_DB"

    echo -e "${C_DIM}────────────────────────────────────────────${C_RESET}"
}

delete_rule_cli() {
    require_root
    ensure_dirs
    ensure_rule_db_schema

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

    echo ""
    echo "即将删除以下规则："
    awk -F'|' -v id="$id" 'NR>1 && $1==id {printf "  ID: %s | 端口: %s | 目标: %s:%s | 备注: %s\\n",$1,$2,$6,$7,$8}' "$VL_RULE_DB"
    local confirm
    read -rp '确认删除？[y/N]: ' confirm
    case "${confirm,,}" in
        y|yes) ;;
        *) warn "已取消删除"; return 0 ;;
    esac
    awk -F'|' -v id="$id" 'NR==1 || $1!=id' "$VL_RULE_DB" > "$VL_RULE_DB.tmp"
    mv "$VL_RULE_DB.tmp" "$VL_RULE_DB"

    echo ""
    success "已删除规则 #$id"
    apply_ruleset
}
