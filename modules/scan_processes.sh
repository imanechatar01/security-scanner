#!/bin/bash
# ==============================================
# MODULE : scan_processes.sh
# RÔLE   : Détecter les processus suspects (CPU)
# AUTEUR : Member 2
# ==============================================

scan_processes() {

    log "INFO" "Démarrage du scan des processus..."
    local score=0

    # -----------------------------------------------
    # ÉTAPE 1 : Lister les processus à haute CPU
    # ps aux format :
    #   col 1  = USER
    #   col 2  = PID
    #   col 3  = %CPU
    #   col 4  = %MEM
    #   col 11 = COMMAND
    #
    # CPU_THRESHOLD est défini dans scanner.sh (défaut 80)
    # awk filtre les lignes où %CPU dépasse le seuil
    # -----------------------------------------------
    local threshold="${CPU_THRESHOLD:-80}"

    echo "[*] Recherche des processus dépassant ${threshold}% CPU..."
    echo ""

    local flagged=0

    # ps aux | awk → pour chaque processus au-delà du seuil :
    #   afficher PID, %CPU, et nom de commande
    while IFS= read -r line; do

        local pid cpu cmd
        pid=$(echo "$line"  | awk '{print $2}')
        cpu=$(echo "$line"  | awk '{print $3}')
        cmd=$(echo "$line"  | awk '{print $11}')

        echo "[!!!] ALERTE : Processus suspect"
        echo "      Nom     : $cmd"
        echo "      PID     : $pid"
        echo "      CPU     : ${cpu}%"
        echo ""

        log "ERROR" "Processus CPU élevée — PID=$pid NOM=$cmd CPU=${cpu}%"

        # Ajouter le PID au tableau global pour response_engine()
        DANGEROUS_PIDS+=("$pid")

        score=$((score + 20))
        flagged=$((flagged + 1))

    done < <(ps aux 2>/dev/null | awk -v thr="$threshold" 'NR>1 && $3+0 >= thr {print}')

    # -----------------------------------------------
    # ÉTAPE 2 : Résumé
    # -----------------------------------------------
    if [ "$flagged" -eq 0 ]; then
        echo "[OK] Aucun processus ne dépasse ${threshold}% CPU."
        log "INFO" "scan_processes : aucun processus suspect détecté."
    else
        echo "[*] $flagged processus suspect(s) détecté(s)."
    fi

    # -----------------------------------------------
    # ÉTAPE 3 : Retourner le score
    # -----------------------------------------------
    echo ""
    echo "[SCORE] scan_processes contribution : +$score"
    log "INFO" "scan_processes terminé. Score ajouté : $score"

    THREAT_SCORE=$((THREAT_SCORE + score))
}
