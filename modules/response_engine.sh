#!/usr/bin/env bash
# =============================================================================
#  AutoDefender — response_engine()
#  Member 4 | Paste this function into autodefender.sh after scoring_engine()
# =============================================================================

# ── Colour palette (ANSI) — remove if already defined in autodefender.sh ─────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# =============================================================================
#  response_engine
#  ─────────────────────────────────────────────────────────────────────────────
#  PURPOSE : Automated defense actions triggered when scoring_engine() reaches
#            CRITICAL. Blocks IPs, kills processes, fixes file permissions.
#
#  INPUTS  : Global arrays:
#              $SUSPICIOUS_IPS[]   → populated by Member 2's scan_ports()
#              $DANGEROUS_PIDS[]   → populated by Member 2's scan_processes()
#              $DANGEROUS_FILES[]  → populated by Member 3's scan_files()
#  OUTPUTS : Prints action report to stdout; every action written via log()
#  NOTE    : iptables and kill -9 require root privileges
# =============================================================================
response_engine() {

    echo ""
    echo -e "${BOLD}${RED}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║       AutoDefender — Active Response         ║${RESET}"
    echo -e "${BOLD}${RED}╚══════════════════════════════════════════════╝${RESET}"
    echo ""

    local actions_taken=0

    # ── Guard: warn if not root ──────────────────────────────────────────────
    if [[ "${EUID}" -ne 0 ]]; then
        echo -e "  ${YELLOW}⚠  Warning: not running as root.${RESET}"
        echo -e "  ${YELLOW}   iptables and kill commands may fail.${RESET}"
        log "ERROR" "response_engine called without root — some actions may fail"
        echo ""
    fi

    # ── 1. Block suspicious IPs ──────────────────────────────────────────────
    if (( ${#SUSPICIOUS_IPS[@]} > 0 )); then
        echo -e "  ${BOLD}[1/3] Blocking suspicious IP addresses…${RESET}"
        for ip in "${SUSPICIOUS_IPS[@]}"; do
            echo -ne "       Blocking ${ip} … "
            if iptables -A INPUT  -s "${ip}" -j DROP 2>/dev/null && \
               iptables -A OUTPUT -d "${ip}" -j DROP 2>/dev/null; then
                echo -e "${RED}BLOCKED${RESET}"
                log "INFOS" "response_engine — blocked IP: ${ip}"
                (( actions_taken++ ))
            else
                echo -e "${YELLOW}FAILED (check permissions)${RESET}"
                log "ERROR" "response_engine — failed to block IP: ${ip}"
            fi
        done
    else
        echo -e "  ${BOLD}[1/3]${RESET} No suspicious IPs to block."
        log "INFOS" "response_engine — no IPs to block"
    fi
    echo ""

    # ── 2. Kill dangerous processes ──────────────────────────────────────────
    if (( ${#DANGEROUS_PIDS[@]} > 0 )); then
        echo -e "  ${BOLD}[2/3] Terminating dangerous processes…${RESET}"
        for pid in "${DANGEROUS_PIDS[@]}"; do
            if ! kill -0 "${pid}" 2>/dev/null; then
                echo -e "       PID ${pid} — already gone, skipping."
                continue
            fi
            local pname
            pname=$(ps -p "${pid}" -o comm= 2>/dev/null || echo "unknown")
            echo -ne "       Killing PID ${pid} (${pname}) … "
            if kill -9 "${pid}" 2>/dev/null; then
                echo -e "${RED}KILLED${RESET}"
                log "INFOS" "response_engine — killed PID ${pid} (${pname})"
                (( actions_taken++ ))
            else
                echo -e "${YELLOW}FAILED (check permissions)${RESET}"
                log "ERROR" "response_engine — failed to kill PID ${pid} (${pname})"
            fi
        done
    else
        echo -e "  ${BOLD}[2/3]${RESET} No dangerous processes to terminate."
        log "INFOS" "response_engine — no processes to kill"
    fi
    echo ""

    # ── 3. Fix insecure file permissions ─────────────────────────────────────
    if (( ${#DANGEROUS_FILES[@]} > 0 )); then
        echo -e "  ${BOLD}[3/3] Fixing insecure file permissions…${RESET}"
        for fpath in "${DANGEROUS_FILES[@]}"; do
            echo -ne "       Fixing ${fpath} … "
            if [[ -e "${fpath}" ]]; then
                chmod o-w "${fpath}" 2>/dev/null
                chmod o-x "${fpath}" 2>/dev/null
                echo -e "${GREEN}FIXED  (removed world write/execute)${RESET}"
                log "INFOS" "response_engine — fixed permissions on: ${fpath}"
                (( actions_taken++ ))
            else
                echo -e "${YELLOW}NOT FOUND (may have been removed)${RESET}"
                log "ERROR" "response_engine — file not found: ${fpath}"
            fi
        done
    else
        echo -e "  ${BOLD}[3/3]${RESET} No dangerous files to fix."
        log "INFOS" "response_engine — no files to fix"
    fi
    echo ""

    # ── Summary ──────────────────────────────────────────────────────────────
    echo -e "  ${BOLD}Response complete.${RESET} ${actions_taken} action(s) taken."
    log "INFOS" "response_engine — finished. Total actions: ${actions_taken}"
    echo ""
    echo -e "${BOLD}${RED}══════════════════════════════════════════════${RESET}"
    echo ""
}
