#!/bin/bash
# ==============================================
# MODULE : scan_ports.sh
# RÔLE   : Détecter les ports réseau suspects
# AUTEUR : Member 2
# ==============================================

scan_ports() {

    log "INFO" "Démarrage du scan des ports..."
    local score=0

    # -----------------------------------------------
    # Liste des ports considérés comme suspects/dangereux
    # 4444  → Metasploit reverse shell par défaut
    # 6666  → souvent utilisé par des backdoors
    # 1337  → "leet" — port classique de backdoors
    # 31337 → "elite" — backdoor historique (Back Orifice)
    # 9999  → utilisé par divers outils de C2
    # -----------------------------------------------
    local suspicious_ports=(4444 6666 1337 31337 9999)

    # -----------------------------------------------
    # ÉTAPE 1 : Lister les ports ouverts en écoute
    # ss -tuln :
    #   -t = TCP
    #   -u = UDP
    #   -l = listening (en écoute seulement)
    #   -n = numérique (pas de résolution de noms)
    # On extrait le numéro de port depuis la colonne
    # "Local Address:Port" avec grep -oP
    # Fallback sur netstat si ss n'est pas disponible
    # -----------------------------------------------
    echo "[*] Listage des ports ouverts..."

    local open_ports=""

    if command -v ss &>/dev/null; then
        open_ports=$(ss -tuln 2>/dev/null \
            | awk 'NR>1 {print $5}' \
            | grep -oP '(?<=:)\d+$' \
            | sort -un)
    elif command -v netstat &>/dev/null; then
        open_ports=$(netstat -tuln 2>/dev/null \
            | awk 'NR>2 {print $4}' \
            | grep -oP '(?<=:)\d+$' \
            | sort -un)
    else
        echo "[!] Ni ss ni netstat disponibles — scan des ports impossible."
        log "ERROR" "scan_ports : aucun outil réseau disponible (ss / netstat)."
        THREAT_SCORE=$((THREAT_SCORE + score))
        return
    fi

    if [ -z "$open_ports" ]; then
        echo "[!] Aucun port ouvert détecté (droits insuffisants ?)."
        log "WARNING" "scan_ports : liste de ports vide."
        THREAT_SCORE=$((THREAT_SCORE + score))
        return
    fi

    echo "[*] Ports en écoute détectés :"
    echo "$open_ports" | while read -r p; do
        echo "    → $p"
    done

    # -----------------------------------------------
    # ÉTAPE 2 : Comparer avec la liste des ports suspects
    # Pour chaque port suspect trouvé → log + +30 au score
    # -----------------------------------------------
    echo ""
    echo "[*] Vérification des ports suspects..."

    local found=0

    for suspect in "${suspicious_ports[@]}"; do
        if echo "$open_ports" | grep -qx "$suspect"; then
            echo "[!!!] ALERTE : Port suspect ouvert → $suspect"
            log "ERROR" "Port suspect détecté : $suspect"
            score=$((score + 30))
            found=$((found + 1))
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "[OK] Aucun port suspect détecté."
        log "INFO" "scan_ports : aucun port suspect parmi ${suspicious_ports[*]}"
    fi

    # -----------------------------------------------
    # ÉTAPE 3 : Retourner le score
    # -----------------------------------------------
    echo ""
    echo "[SCORE] scan_ports contribution : +$score"
    log "INFO" "scan_ports terminé. Score ajouté : $score"

    THREAT_SCORE=$((THREAT_SCORE + score))
}
