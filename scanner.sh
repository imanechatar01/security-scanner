#!/bin/bash


source modules/files.sh


case "$1" in
    -f)
        scan_files
        ;;
    *)
        echo "Usage: $0 -f"
        ;;
esac 
