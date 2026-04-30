#!/usr/bin/env bash
# =============================================================================
#  AutoDefender — scoring_engine()
#  Member 4 | Paste this function into autodefender.sh after scan_logs()
# =============================================================================

# ── Colour palette (ANSI) ─────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# =============================================================================
#  scoring_engine
#  ─────────────────────────────────────────────────────────────────────────────
#  PURPOSE : Evaluate the total threat score accumulated by all scanners and
#            classify the system as SAFE / WARNING / CRITICAL.
#
#  INPUTS  : Global $SCORE (integer, built up by Members 2 & 3 scanners)
#  OUTPUTS : Coloured summary banner printed to stdout
#             Sets global $THREAT_LEVEL ("SAFE" | "WARNING" | "CRITICAL")
#             Auto-calls response_engine() when CRITICAL
# =============================================================================
scoring_engine() {

    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║        AutoDefender — Threat Analysis        ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Total Threat Score :${RESET} ${SCORE}"
    echo ""

    # ── Classification ──────────────────────────────────────────────────────
    if   (( SCORE >= 70 )); then
        THREAT_LEVEL="CRITICAL"
        LEVEL_COLOR="${RED}"
        LEVEL_ICON="✖"
    elif (( SCORE >= 30 )); then
        THREAT_LEVEL="WARNING"
        LEVEL_COLOR="${YELLOW}"
        LEVEL_ICON="⚠"
    else
        THREAT_LEVEL="SAFE"
        LEVEL_COLOR="${GREEN}"
        LEVEL_ICON="✔"
    fi

    # ── Visual threat bar (1 block per 5 pts, max 20 blocks) ────────────────
    local bar_fill=$(( SCORE / 5 ))
    (( bar_fill > 20 )) && bar_fill=20
    local bar_empty=$(( 20 - bar_fill ))

    printf "  Threat Bar : ${LEVEL_COLOR}["
    printf '█%.0s' $(seq 1 "${bar_fill}")
    printf '░%.0s' $(seq 1 "${bar_empty}")
    printf "]${RESET}  %d / 100+\n\n" "${SCORE}"

    # ── Status banner ────────────────────────────────────────────────────────
    echo -e "  ${BOLD}${LEVEL_COLOR}${LEVEL_ICON}  System Status : ${THREAT_LEVEL}${RESET}"
    echo ""

    case "${THREAT_LEVEL}" in
        SAFE)
            echo -e "  ${GREEN}No significant threats detected.${RESET}"
            echo -e "  ${GREEN}System appears to be operating normally.${RESET}"
            log "INFOS" "Scoring complete — status: SAFE (score=${SCORE})"
            ;;
        WARNING)
            echo -e "  ${YELLOW}Suspicious activity detected.${RESET}"
            echo -e "  ${YELLOW}Manual review is recommended.${RESET}"
            log "INFOS" "Scoring complete — status: WARNING (score=${SCORE})"
            ;;
        CRITICAL)
            echo -e "  ${RED}Critical threats detected!${RESET}"
            echo -e "  ${RED}Automated response will be triggered immediately.${RESET}"
            log "ERROR" "Scoring complete — status: CRITICAL (score=${SCORE})"
            echo ""
            response_engine   # ← Auto-trigger when CRITICAL
            ;;
    esac

    echo ""
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${RESET}"
    echo ""
}
