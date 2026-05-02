#!/bin/bash
# ============================================================
# log.sh — Systeme de journalisation central
# Auteur  : Membre 1 (Bessar)
# Utilise par : TOUTES les fonctions du projet
# ============================================================

LOG_DIR="/var/log/autodefender"
LOG_FILE="$LOG_DIR/autodefender.log"

log() {
    local level="$1"
    local message="$2"

    local timestamp
    timestamp=$(date +"%Y-%m-%d-%H-%M-%S")

    local user
    user=$(whoami)

    local log_line="$timestamp : $user : $level : $message"

    # Affichage couleur dans le terminal
    case "$level" in
        INFO)    echo -e "\e[32m[INFO]\e[0m    $log_line" ;;
        WARNING) echo -e "\e[33m[WARNING]\e[0m $log_line" ;;
        ERROR)   echo -e "\e[31m[ERROR]\e[0m   $log_line" ;;
        *)       echo "[LOG] $log_line" ;;
    esac

    # Ecriture dans le fichier
    if [ -d "$LOG_DIR" ]; then
        echo "$log_line" >> "$LOG_FILE"
    fi
}

init_logger() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    log "INFO" "AutoDefender demarre - logger initialise"
}
