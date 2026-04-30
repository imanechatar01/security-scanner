#!/usr/bin/env bash
# =============================================================================
#  AutoDefender — simulate_attack()
#  Member 4 | Paste this function into autodefender.sh after response_engine()
# =============================================================================

# ── Colour palette (ANSI) — remove if already defined in autodefender.sh ─────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# =============================================================================
#  simulate_attack
#  ─────────────────────────────────────────────────────────────────────────────
#  PURPOSE : Create controlled, harmless fake threats to demonstrate the full
#            detection → scoring → response pipeline live.
#
#  WHAT IT CREATES:
#    • A world-writable file (chmod 777)  → triggers scan_files() detection
#    • Fake failed-login log entries      → triggers scan_logs() detection
#    • A dummy high-CPU background process → triggers scan_processes() detection
#
#  After injecting the fake threats it fires scoring_engine() which will
#  reach CRITICAL and auto-call response_engine() for a full live demo.
#  A trap ensures ALL artefacts are cleaned up on exit, even on Ctrl+C.
# =============================================================================
simulate_attack() {

    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║     AutoDefender — Attack Simulation Mode    ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${YELLOW}⚠  This is a CONTROLLED simulation. No real harm will occur.${RESET}"
    echo ""

    # ── Temp artefact paths ──────────────────────────────────────────────────
    local SIM_FILE="/tmp/autodefender_sim_vuln_file"
    local SIM_LOG="/tmp/autodefender_sim_auth.log"
    local SIM_PID=""

    # ── Cleanup trap — always runs on EXIT, INT, TERM ────────────────────────
    _sim_cleanup() {
        echo ""
        echo -e "  ${CYAN}[Cleanup] Removing simulation artefacts…${RESET}"

        if [[ -n "${SIM_PID}" ]] && kill -0 "${SIM_PID}" 2>/dev/null; then
            kill "${SIM_PID}" 2>/dev/null
            echo -e "  ${CYAN}[Cleanup] Dummy process (PID ${SIM_PID}) stopped.${RESET}"
            log "INFOS" "simulate_attack cleanup — killed dummy PID ${SIM_PID}"
        fi

        rm -f "${SIM_FILE}" "${SIM_LOG}"
        echo -e "  ${CYAN}[Cleanup] Fake file and fake log removed.${RESET}"
        log "INFOS" "simulate_attack cleanup — removed ${SIM_FILE} and ${SIM_LOG}"

        echo -e "  ${GREEN}✔  Simulation environment fully cleaned.${RESET}"
        echo ""
    }
    trap _sim_cleanup EXIT INT TERM

    # ── Step 1: World-writable vulnerable file ───────────────────────────────
    echo -e "  ${BOLD}[Step 1/3]${RESET} Creating world-writable file…"
    touch "${SIM_FILE}"
    chmod 777 "${SIM_FILE}"
    echo "Simulated vulnerable file — AutoDefender test" > "${SIM_FILE}"
    DANGEROUS_FILES+=("${SIM_FILE}")
    SCORE=$(( SCORE + 25 ))
    echo -e "  ${GREEN}  ✔  Created : ${SIM_FILE}  (permissions: 777)${RESET}"
    echo -e "  ${GREEN}     Score   : +25 → total = ${SCORE}${RESET}"
    log "INFOS" "simulate_attack — created fake vulnerable file: ${SIM_FILE}"
    echo ""

    # ── Step 2: Fake failed-login log entries ────────────────────────────────
    echo -e "  ${BOLD}[Step 2/3]${RESET} Injecting fake failed-login entries…"
    local fake_ips=("192.168.100.50" "10.0.0.99" "172.16.5.20")
    for ip in "${fake_ips[@]}"; do
        for i in $(seq 1 5); do
            echo "Apr 29 12:0${i}:00 hostname sshd[1234]: Failed password for root from ${ip} port 2200${i} ssh2" \
                >> "${SIM_LOG}"
        done
        SUSPICIOUS_IPS+=("${ip}")
    done
    local total_fake
    total_fake=$(wc -l < "${SIM_LOG}")
    SCORE=$(( SCORE + 40 ))
    echo -e "  ${GREEN}  ✔  Written : ${total_fake} fake failed-login lines → ${SIM_LOG}${RESET}"
    echo -e "  ${GREEN}     Score   : +40 → total = ${SCORE}${RESET}"
    log "INFOS" "simulate_attack — injected ${total_fake} fake auth failures into ${SIM_LOG}"
    echo ""

    # ── Step 3: Dummy high-CPU background process ────────────────────────────
    echo -e "  ${BOLD}[Step 3/3]${RESET} Launching dummy high-CPU process…"
    yes > /dev/null &
    SIM_PID=$!
    DANGEROUS_PIDS+=("${SIM_PID}")
    SCORE=$(( SCORE + 20 ))
    echo -e "  ${GREEN}  ✔  Started : dummy CPU process (PID ${SIM_PID})${RESET}"
    echo -e "  ${GREEN}     Score   : +20 → total = ${SCORE}${RESET}"
    log "INFOS" "simulate_attack — started dummy CPU process PID ${SIM_PID}"
    echo ""

    # ── Simulate a suspicious open port score bump ───────────────────────────
    SCORE=$(( SCORE + 30 ))
    echo -e "  ${GREEN}  ✔  Simulated suspicious open port — Score: +30 → total = ${SCORE}${RESET}"
    log "INFOS" "simulate_attack — injected fake suspicious port score"
    echo ""

    # ── Pause for demo audience ──────────────────────────────────────────────
    echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${YELLOW}  All fake threats injected. Launching scoring…${RESET}"
    echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    sleep 1

    # ── Fire the full analysis pipeline ─────────────────────────────────────
    log "INFOS" "simulate_attack — triggering scoring_engine (score=${SCORE})"
    scoring_engine   # → reaches CRITICAL → auto-calls response_engine()

    # Trap fires on EXIT → _sim_cleanup() runs automatically
}
