#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Game Mode
# @raycast.mode silent
# @raycast.packageName System

# Documentation:
# @raycast.author glyphack
# @raycast.description Turn off Karabiner key remaps, quit Hammerspoon, and make the pointer small

set -euo pipefail

KARABINER_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
BIN_DIR="$(cd "$(dirname "$0")" && pwd)"

"$KARABINER_CLI" --select-profile "Empty Profile"
if pgrep -xq Hammerspoon; then
  osascript -e 'quit app "Hammerspoon"'
fi
"$BIN_DIR/pointer-size.swift" small
echo "Game mode on"
