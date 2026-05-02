#!/bin/bash
# ==============================================
# MODULE : scan_logs.sh
# RÔLE   : Détecter les tentatives de connexion
# AUTEUR : Member 3
# ==============================================

scan_logs() {

    log "INFO" "Démarrage du scan des logs..."
    local score=0

    # -----------------------------------------------
    # Le répertoire de logs vient du flag -l de main()
    # Si non fourni, on utilise /var/log/ par défaut
    # -----------------------------------------------
    local log_dir="${1:-/var/log}"
    echo "[*] Analyse des logs dans : $log_dir"

    # -----------------------------------------------
    # ÉTAPE 1 : Trouver le bon fichier auth log
    # Selon la distro Linux :
    #   Debian/Ubuntu → /var/log/auth.log
    #   CentOS/RHEL   → /var/log/secure
    # -----------------------------------------------
    local auth_log=""

    if [ -f "$log_dir/auth.log" ]; then
        auth_log="$log_dir/auth.log"
    elif [ -f "$log_dir/secure" ]; then
        auth_log="$log_dir/secure"
    else
        echo "[!] Aucun fichier auth log trouvé dans $log_dir"
        log "WARNING" "Fichier auth log introuvable dans $log_dir"
        return
    fi

    echo "[*] Fichier analysé : $auth_log"

    # -----------------------------------------------
    # ÉTAPE 2 : Compter les échecs de connexion
    # grep cherche les lignes contenant ces patterns
    # wc -l compte le nombre de lignes trouvées
    # -----------------------------------------------
    local failed_count
    failed_count=$(grep -iE "Failed password|authentication failure" "$auth_log" 2>/dev/null | wc -l)

    echo ""
    echo "[*] Nombre total d'échecs de connexion : $failed_count"
    log "INFO" "Échecs de connexion détectés : $failed_count"

    # -----------------------------------------------
    # ÉTAPE 3 : Seuil d'alerte
    # Si trop d'échecs → probable attaque brute-force
    # FAILED_LOGIN_THRESHOLD est défini dans autodefender.sh
    # -----------------------------------------------
    local threshold="${FAILED_LOGIN_THRESHOLD:-5}"

    if [ "$failed_count" -gt "$threshold" ]; then
        echo "[!!!] ALERTE : Nombre d'échecs dépasse le seuil ($threshold) !"
        log "ERROR" "Tentatives de brute-force détectées : $failed_count échecs"
        score=$((score + 40))
    else
        echo "[OK] Nombre d'échecs dans la normale."
        log "INFO" "Pas d'anomalie dans les connexions."
    fi

    # -----------------------------------------------
    # ÉTAPE 4 : Afficher les IPs suspectes
    # grep      → filtre les lignes "Failed password"
    # grep -oP  → extrait uniquement l'IP avec regex
    # sort      → trie les IPs
    # uniq -c   → compte les doublons
    # sort -rn  → trie du plus grand au plus petit
    # head -10  → affiche les 10 pires
    # -----------------------------------------------
    echo ""
    echo "[*] Top 10 des IPs suspectes :"

    grep "Failed password" "$auth_log" 2>/dev/null \
        | grep -oP '(\d{1,3}\.){3}\d{1,3}' \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -10 \
        | while read -r count ip; do
            echo "    $count tentatives  ←  IP : $ip"
            log "WARNING" "IP suspecte : $ip ($count tentatives)"
        done

    # -----------------------------------------------
    # ÉTAPE 5 : Retourner le score
    # -----------------------------------------------
    echo ""
    echo "[SCORE] scan_logs contribution : +$score"
    log "INFO" "scan_logs terminé. Score ajouté : $score"

    THREAT_SCORE=$((THREAT_SCORE + score))
}
