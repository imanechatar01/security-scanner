#!/bin/bash
# ==============================================
# MODULE : scan_files.sh
# RÔLE   : Détecter les fichiers dangereux
# AUTEUR : Member 3
# ==============================================

scan_files() {

    log "INFO" "Démarrage du scan des fichiers..."
    local score=0

    # -----------------------------------------------
    # ÉTAPE 1 : Trouver les fichiers "world-writable"
    # "world-writable" = n'importe qui peut modifier ce fichier
    # -perm -o+w = permission "write" activée pour "others"
    # 2>/dev/null = on ignore les erreurs (ex: /proc, /sys)
    # -----------------------------------------------
    echo "[*] Recherche de fichiers world-writable..."

    local ww_files
    ww_files=$(find / -perm -o+w -type f 2>/dev/null)

    if [ -z "$ww_files" ]; then
        echo "[OK] Aucun fichier world-writable trouvé."
        log "INFO" "Aucun fichier world-writable détecté."
    else
        echo "[!] Fichiers world-writable détectés :"
        echo "$ww_files" | while read -r fichier; do
            echo "    -> $fichier"
            log "WARNING" "Fichier world-writable : $fichier"
            score=$((score + 25))
        done
    fi

    # -----------------------------------------------
    # ÉTAPE 2 : Trouver les fichiers SUID
    # SUID = s'exécute avec les droits du propriétaire (souvent root)
    # Dangereux si mal configuré → escalade de privilèges possible
    # -perm -4000 = bit SUID activé
    # -----------------------------------------------
    echo ""
    echo "[*] Recherche de fichiers SUID suspects..."

    local suid_files
    suid_files=$(find / -perm -4000 -type f 2>/dev/null)

    if [ -z "$suid_files" ]; then
        echo "[OK] Aucun fichier SUID suspect trouvé."
        log "INFO" "Aucun fichier SUID détecté."
    else
        echo "[!] Fichiers SUID détectés :"
        echo "$suid_files" | while read -r fichier; do
            echo "    -> $fichier"
            log "WARNING" "Fichier SUID détecté : $fichier"
            score=$((score + 25))
        done
    fi

    # -----------------------------------------------
    # ÉTAPE 3 : Vérifier les fichiers sensibles
    # /etc/passwd et /etc/shadow ne doivent PAS être world-writable
    # ls -l → affiche les permissions
    # -----------------------------------------------
    echo ""
    echo "[*] Vérification des fichiers sensibles..."

    local sensitive_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")

    for fichier in "${sensitive_files[@]}"; do
        if [ -f "$fichier" ]; then
            # On récupère les permissions (ex: -rw-r--r--)
            local perms
            perms=$(ls -l "$fichier" | awk '{print $1}')

            # On vérifie si "others" a le droit d'écriture (position 9)
            local other_write
            other_write=$(echo "$perms" | cut -c9)

            if [ "$other_write" = "w" ]; then
                echo "[!!!] CRITIQUE : $fichier est accessible en écriture par tous !"
                log "ERROR" "Fichier sensible mal configuré : $fichier ($perms)"
                score=$((score + 25))
            else
                echo "[OK] $fichier → permissions correctes ($perms)"
                log "INFO" "Fichier sensible OK : $fichier ($perms)"
            fi
        fi
    done

    # -----------------------------------------------
    # ÉTAPE 4 : Retourner le score à main()
    # On exporte via une variable globale ou echo
    # -----------------------------------------------
    echo ""
    echo "[SCORE] scan_files contribution : +$score"
    log "INFO" "scan_files terminé. Score ajouté : $score"

    # Variable globale partagée avec scoring_engine
    THREAT_SCORE=$((THREAT_SCORE + score))
}
