#!/bin/bash
# ============================================================
# AutoDefender — Intelligent Linux Security Scanner
# Auteur principal : Membre 1 (Bessar)
# ============================================================

# ---------- VARIABLES GLOBALES ----------
THREAT_SCORE=0
LOG_DIR="/var/log/autodefender"
LOG_FILE="$LOG_DIR/autodefender.log"
SUSPICIOUS_PORTS=(4444 6666 1337 31337 9999)
LOG_SCAN_DIR="/var/log"
CPU_THRESHOLD=80
FAILED_LOGIN_THRESHOLD=5

# ---------- CHARGEMENT DES MODULES ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="$SCRIPT_DIR/modules"

source "$MODULES/log.sh"
source "$MODULES/help.sh"
source "$MODULES/scan_ports.sh"
source "$MODULES/scan_processes.sh"
source "$MODULES/scan_files.sh"
source "$MODULES/scan_logs.sh"
source "$MODULES/scoring_engine.sh"
source "$MODULES/response_engine.sh"
source "$MODULES/simulate_attack.sh"

# ---------- FONCTION MAIN ----------
main() {

    mkdir -p "$LOG_DIR"
    init_logger

    if [ $# -eq 0 ]; then
        help
        exit 0
    fi

    local flag_ports=false
    local flag_processes=false
    local flag_files=false
    local flag_logs=false
    local flag_all=false
    local flag_subshell=false
    local flag_parallel=false
    local flag_reset=false
    local flag_simulate=false
    local custom_log_dir=""

    for arg in "$@"; do
        if [ "$arg" = "--simulate-attack" ]; then
            flag_simulate=true
        fi
    done

    while getopts ":hpcfl:astr" opt; do
        case $opt in
            h) help ; exit 0 ;;
            p) flag_ports=true ;;
            c) flag_processes=true ;;
            f) flag_files=true ;;
            l) custom_log_dir="$OPTARG"
               flag_logs=true ;;
            a) flag_all=true ;;
            s) flag_subshell=true ;;
            t) flag_parallel=true ;;
            r) flag_reset=true ;;
            :) echo "Option -$OPTARG necessite un argument." ; exit 1 ;;
            ?) echo "Flag inconnu : -$OPTARG" ; help ; exit 1 ;;
        esac
    done

    if $flag_reset; then
        if [ "$EUID" -ne 0 ]; then
            echo "[ERREUR] Le flag -r necessite les droits root."
            log "ERROR" "Tentative de reset sans droits root."
            exit 1
        fi
        rm -f "$LOG_FILE"
        init_logger
        log "INFO" "Logs reinitialises par root"
        exit 0
    fi

    if $flag_all; then
        flag_ports=true
        flag_processes=true
        flag_files=true
        flag_logs=true
    fi

    if $flag_parallel; then
        log "INFO" "Mode parallele active"
        $flag_ports     && scan_ports &
        $flag_processes && scan_processes &
        $flag_files     && scan_files &
        $flag_logs      && scan_logs "${custom_log_dir:-$LOG_SCAN_DIR}" &
        wait
        log "INFO" "Tous les scans paralleles termines"

    elif $flag_subshell; then
        log "INFO" "Mode subshell active"
        $flag_ports     && ( scan_ports )
        $flag_processes && ( scan_processes )
        $flag_files     && ( scan_files )
        $flag_logs      && ( scan_logs "${custom_log_dir:-$LOG_SCAN_DIR}" )

    else
        $flag_ports     && scan_ports
        $flag_processes && scan_processes
        $flag_files     && scan_files
        $flag_logs      && scan_logs "${custom_log_dir:-$LOG_SCAN_DIR}"
    fi

    $flag_simulate && simulate_attack

    scoring_engine
}

# ---------- POINT D'ENTREE ----------
main "$@"
