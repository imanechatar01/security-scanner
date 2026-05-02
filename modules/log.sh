#!/bin/bash
# ==============================================
# MODULE : log.sh  (version temporaire pour tests)
# Le vrai sera fait par Member 1
# ==============================================

log() {
    local level="$1"    # INFO ou ERROR ou WARNING
    local message="$2"  # Le message

    # Format : yyyy-mm-dd-hh-mm-ss : user : LEVEL : message
    local timestamp
    timestamp=$(date +"%Y-%m-%d-%H-%M-%S")

    local user
    user=$(whoami)

    # Affiche dans le terminal
    echo "$timestamp : $user : $level : $message"

    # Écrit dans le fichier log si le dossier existe
    if [ -d "$LOG_DIR" ]; then
        echo "$timestamp : $user : $level : $message" >> "$LOG_FILE"
    fi
}
