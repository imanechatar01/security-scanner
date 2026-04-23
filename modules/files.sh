#/bin/bash
scan_files() {
    echo " Scanning system files..."

    danger_count=0
    unknown_count=0

    # 🔴 fichiers avec permission 777
    find /home -type f -perm 777 2>/dev/null | while read file
    do
        echo "🔴 $file : WORLD WRITABLE (777) → DANGEROUS"
        ((danger_count++))
    done

    # 🔴 fichiers exécutables dans /tmp
    find /tmp -type f -executable 2>/dev/null | while read file
    do
        echo "🔴 $file : EXECUTABLE IN /tmp → SUSPICIOUS"
        ((danger_count++))
    done

    # 🟡 fichiers récents
    find /home -type f -mtime -1 2>/dev/null | head -n 5 | while read file
    do
        echo "🟡 $file : RECENT FILE → CHECK"
        ((unknown_count++))
    done

    echo ""
    echo " ===== Résumé ====="
    echo "🔴 Dangerous : $danger_count"
    echo "🟡 Suspicious: $unknown_count"
}
