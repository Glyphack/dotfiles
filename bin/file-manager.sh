#!/bin/bash

# $1 is the temporary file where we write the final directory path
# If $1 is empty (script run directly), we default to /dev/stdout
RESULT_FILE="${1:-/dev/stdout}"

# Start in current directory
cd "." || exit 1

while true; do
    FILES=$(ls -p -a | grep -vE '^\./$|^\.\./$')
    OPTIONS=$(echo -e ".\n..\n~\n$FILES")
    SELECTION=$(echo "$OPTIONS" | gum filter --height 20 --placeholder "Navigate ('.' to Select/Exit, '~' for Home)")

    # 4. Handle selection
    case "$SELECTION" in
        ".")
            # Write final path to the result file (or stdout)
            pwd > "$RESULT_FILE"
            break
            ;;
        "..")
            cd ..
            ;;
        "~")
            cd ~
            ;;
        "")
            # Cancelled (Esc/Ctrl+C) - Do nothing/Exit loop
            break
            ;;
        */)
            cd "$SELECTION" || exit
            ;;
        *)
            # File: Open in Vim
            if [ -f "$SELECTION" ]; then
                nvim "$SELECTION"
            fi
            ;;
    esac
done
