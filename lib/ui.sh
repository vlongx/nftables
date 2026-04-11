#!/bin/bash
set -euo pipefail
show_banner(){ cat <<'TXT'
██    ██ ██       ██████  ███    ██  ██████  ██   ██
██    ██ ██      ██    ██ ████   ██ ██       ██   ██
██    ██ ██      ██    ██ ██ ██  ██ ██   ███ ███████
 ██  ██  ██      ██    ██ ██  ██ ██ ██    ██ ██   ██
  ████   ███████  ██████  ██   ████  ██████  ██   ██
TXT
msg "${_MAGENTA}VLONGX PANEL${_NC}"; msg "${_CYAN}Enhanced Setup v1.0${_NC}"; msg ""; }
main_menu(){ while true; do clear; show_banner; echo '1) Add forwarding rule'; echo '2) List rules'; echo '3) Delete rule'; echo '4) Apply nftables rules'; echo '5) Install or restart panel'; echo '6) Show panel status'; echo '0) Exit'; echo ''; read -rp 'Please enter your choice [0-6]: ' choice; case "$choice" in 1) add_rule_cli ;; 2) list_rules; read -rp 'Press Enter to continue' ;; 3) delete_rule_cli ;; 4) apply_ruleset; read -rp 'Press Enter to continue' ;; 5) install_panel_service; read -rp 'Press Enter to continue' ;; 6) show_panel_status; read -rp 'Press Enter to continue' ;; 0) exit 0 ;; *) warn '无效选项'; sleep 1 ;; esac; done; }
main(){ case "${1:-menu}" in menu) main_menu ;; add) add_rule_cli ;; list) list_rules ;; delete|del) delete_rule_cli ;; apply) apply_ruleset ;; panel-install) install_panel_service ;; panel-status) show_panel_status ;; *) main_menu ;; esac; }
