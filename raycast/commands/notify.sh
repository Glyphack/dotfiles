#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Notify me
# @raycast.mode silent
# @raycast.icon 🔔

# Optional parameters:
# @raycast.argument1 { "type": "text", "placeholder": "delay (e.g. 30min, 2h)" }
# @raycast.argument2 { "type": "text", "placeholder": "message" }

DELAY="$1"
MESSAGE="$2"

if [ -z "$DELAY" ] || [ -z "$MESSAGE" ]; then
  echo "Usage: notify <delay> <message>"
  exit 1
fi

"$(dirname "$0")/ntfy.sh" "$DELAY" "$MESSAGE"

echo "Notification scheduled in $DELAY"
