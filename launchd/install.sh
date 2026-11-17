#!/usr/bin/env bash
#

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS="$HOME/Library/LaunchAgents"
DOMAIN="gui/$(id -u)"

mkdir -p "$AGENTS"
for source in "$DOTFILES"/launchd/*.plist; do
    target="$AGENTS/$(basename "$source")"
    launchctl bootout "$DOMAIN" "$target" 2>/dev/null || true
    sed -e "s|\$DOTFILES|$DOTFILES|g" -e "s|\$HOME|$HOME|g" "$source" >"$target"
    launchctl bootstrap "$DOMAIN" "$target"
    echo "Started $(basename "$source" .plist)"
done
