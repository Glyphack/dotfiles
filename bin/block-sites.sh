#!/bin/bash
#
# Toggles blocking the sites below in /etc/hosts. Pass "block" to always block
# them instead of toggling.

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Block Sites
# @raycast.mode silent
# @raycast.icon 🚫

# Documentation:
# @raycast.author glyphack
# @raycast.description Toggle blocking the default list of sites in /etc/hosts

# Changing /etc/hosts needs admin rights. When not running as root, the script
# asks for them with the macOS password dialog and runs itself again as root.
if [[ $EUID -ne 0 ]]; then
    exec osascript - "$(realpath "$0")" "$@" <<'EOF'
on run argv
    set command to ""
    repeat with arg in argv
        set command to command & quoted form of (arg as text) & " "
    end repeat
    set output to do shell script command with administrator privileges without altering line endings
    return text 1 thru -2 of output
end run
EOF
fi

HOSTS_FILE="/etc/hosts"
SITES=("x.com" "instagram.com")

# Prints the hosts file lines that block each site and its www variant.
block_lines() {
    for site in "${SITES[@]}"; do
        echo "127.0.0.1 $site"
        echo "127.0.0.1 www.$site"
    done
}

is_blocked() {
    grep -qxFf <(block_lines) "$HOSTS_FILE"
}

remove_block_lines() {
    local kept
    kept="$(mktemp)"
    grep -vxFf <(block_lines) "$HOSTS_FILE" > "$kept"
    cat "$kept" > "$HOSTS_FILE"
    rm "$kept"
}

flush_dns() {
    dscacheutil -flushcache
    killall -HUP mDNSResponder
}

block() {
    remove_block_lines
    block_lines >> "$HOSTS_FILE"
    flush_dns
    echo "Blocked ${SITES[*]}"
}

unblock() {
    remove_block_lines
    flush_dns
    echo "Unblocked ${SITES[*]}"
}

case "$1" in
    "")
        if is_blocked; then
            unblock
        else
            block
        fi
        ;;
    block)
        block
        ;;
    *)
        echo "Usage: block-sites [block]"
        exit 1
        ;;
esac
