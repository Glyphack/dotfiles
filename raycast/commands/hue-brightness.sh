#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Hue Brightness
# @raycast.mode silent
# @raycast.icon 🔆

# Optional parameters:
# @raycast.argument1 { "type": "text", "title": "Brightness", "placeholder": "0-254", "default": "150" }

BRIGHTNESS="$1"

/Users/shayeganhooshyari/.local/bin/huec brightness set "$BRIGHTNESS"
