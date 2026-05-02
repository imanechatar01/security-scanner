#!/bin/bash


source modules/scan_files.sh 

#!/bin/bash
# ============================================================
# AutoDefender — Intelligent Linux Security Scanner
# Point d'entrée principal
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
# On récupère le dossier où se trouve autodefender.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="$SCRIPT_DIR/modules"

# Source = "importer" le fichier → ses fonctions deviennent disponibles ici
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

    # Créer le dossier de logs s'il n'existe pas
    mkdir -p "$LOG_DIR"

    # -----------------------------------------------
    # getopts = parser les flags passés en ligne de commande
    # ex: ./autodefender.sh -a -l /var/log -t
    #
    # chaque lettre = un flag

    # lettre: (avec :) = attend une valeur après le flag
    # ex: -l /var/log   →  l est suivi d'une valeur
    # -----------------------------------------------

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

    while getopts ":hpcflastrl:" opt; do
        case $opt in
            h) help ; exit 0 ;;
            p) flag_ports=true ;;
            c) flag_processes=true ;;
            f) flag_files=true ;;          # ← appelle scan_files
            l) custom_log_dir="$OPTARG"    # ← reçoit le chemin ex: -l /var/log
               flag_logs=true ;;           # ← appelle scan_logs
            a) flag_all=true ;;            # ← appelle TOUT
            s) flag_subshell=true ;;
            t) flag_parallel=true ;;
            r) flag_reset=true ;;
            --) shift; [ "$1" = "--simulate-attack" ] && flag_simulate=true ;;
            ?) echo "Flag inconnu : -$OPTARG" ; help ; exit 1 ;;
        esac
    done

    # Reset nécessite root
    if $flag_reset; then
        if [ "$EUID" -ne 0 ]; then
            echo "[ERREUR] Le flag -r nécessite les droits root."
            log "ERROR" "Tentative de reset sans droits root."
            exit 1
        fi
    fi

    # Si -a → on active tous les scanners
    if $flag_all; then
        flag_ports=true
        flag_processes=true
        flag_files=true
        flag_logs=true
    fi

    # --simulate-attack (géré séparément car c'est --  pas -)
    for arg in "$@"; do
        if [ "$arg" = "--simulate-attack" ]; then
            flag_simulate=true
        fi
    done

    # -----------------------------------------------
    # EXÉCUTION DES SCANNERS
    # -----------------------------------------------

    # Exécution en parallèle (-t flag)
    if $flag_parallel; then
        echo "[*] Mode parallèle activé..."
        $flag_ports     && scan_ports &
        $flag_processes && scan_processes &
        $flag_files     && scan_files &                                    
        $flag_logs      && scan_logs "${custom_log_dir:-$LOG_SCAN_DIR}" &  
        wait   # attend que tous les processus background finissent
        echo "[*] Tous les scans parallèles terminés."

    # Exécution en subshell (-s flag)
    elif $flag_subshell; then
        echo "[*] Mode subshell activé..."
        $flag_ports     && ( scan_ports )
        $flag_processes && ( scan_processes )
        $flag_files     && ( scan_files )                                    
        $flag_logs      && ( scan_logs "${custom_log_dir:-$LOG_SCAN_DIR}" ) 

    # Exécution normale séquentielle
    else
        $flag_ports     && scan_ports
        $flag_processes && scan_processes
        $flag_files     && scan_files                                    
        $flag_logs      && scan_logs "${custom_log_dir:-$LOG_SCAN_DIR}" 
    fi

    # Simulation d'attaque
    $flag_simulate && simulate_attack

    # Calcul du score final
    scoring_engine

}

# ---------- POINT D'ENTRÉE ----------
main "$@"
