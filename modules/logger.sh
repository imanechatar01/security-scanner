#!/bin/bash
# ============================================================
# logger.sh - Systeme de journalisation
# Auteur  : Bessar
# Role    : Fonction log() utilisee par tout le projet
# ============================================================

# Fichier ou les logs seront sauvegardes
LOG_DIR="/var/log/scanner"
LOG_FILE="$LOG_DIR/history.log"

# ── Fonction principale de logging ──────────────────────────
log() {
    # Parametres : log "NIVEAU" "message"
    # Exemple    : log "INFO"  "Scan des ports termine"
    # Exemple    : log "ERROR" "Fichier suspect detecte"

    local LEVEL="$1"    # INFO / WARNING / ERROR
    local MESSAGE="$2"  # Le texte du message

    # Date et heure au format demande par le prof
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

    # Nom de l utilisateur actuel
    local USER_NAME
    USER_NAME=$(whoami)

    # Ligne complete au format : date : user : NIVEAU : message
    local LOG_LINE="$TIMESTAMP : $USER_NAME : $LEVEL : $MESSAGE"

    # 1) Afficher dans le terminal avec couleur
    case "$LEVEL" in
        INFO)
            echo -e "\e[32m[INFO]\e[0m    $LOG_LINE"
            ;;
        WARNING)
            echo -e "\e[33m[WARNING]\e[0m $LOG_LINE"
            ;;
        ERROR)
            echo -e "\e[31m[ERROR]\e[0m   $LOG_LINE"
            ;;
        *)
            echo "[LOG] $LOG_LINE"
            ;;
    esac

    # 2) Ecrire dans le fichier history.log
    echo "$LOG_LINE" >> "$LOG_FILE"
}

# ── Fonction pour creer le dossier de log au demarrage ──────
init_logger() {
    # Creer le dossier /var/log/scanner s il n existe pas
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi

    # Creer le fichier s il n existe pas
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi

    log "INFO" "Logger initialise - session demarree"
}
