#!/bin/bash
# ============================================================
# help.sh — Affichage de l'aide
# Auteur : Membre 1 (Bessar)
# ============================================================

help() {
    echo ""
    echo "================================================"
    echo "   AutoDefender — Linux Security Scanner"
    echo "================================================"
    echo ""
    echo "Usage : bash scanner.sh [OPTIONS]"
    echo ""
    echo "  -h               Afficher cette aide"
    echo "  -p               Scanner les ports reseau"
    echo "  -c               Scanner les processus suspects"
    echo "  -f               Scanner les fichiers dangereux"
    echo "  -l [dossier]     Analyser les logs systeme"
    echo "  -a               Lancer TOUS les scans"
    echo "  -s               Mode subshell"
    echo "  -t               Mode parallele (plus rapide)"
    echo "  -r               Reinitialiser les logs (root)"
    echo "  --simulate-attack  Simuler une attaque (demo)"
    echo ""
    echo "Exemples :"
    echo "  bash scanner.sh -h"
    echo "  bash scanner.sh -a"
    echo "  bash scanner.sh -p -c"
    echo "  bash scanner.sh -l /var/log"
    echo "  bash scanner.sh -a -t"
    echo "  bash scanner.sh --simulate-attack"
    echo "================================================"
    echo ""
}