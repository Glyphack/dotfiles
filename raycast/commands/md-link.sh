#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Paste markdown link
# @raycast.mode silent
# @raycast.icon 🔗
# @raycast.packageName Markdown Tools

# Documentation:
# @raycast.author your_name
# @raycast.authorURL https://raycast.com/your_name

# Get content from clipboard
CONTENT="$(pbpaste)"

if [ -z "$CONTENT" ]; then
  echo "No content found in clipboard."
  exit 1
fi

# Check if already a markdown link using grep (fixes regex syntax error)
if echo "$CONTENT" | grep -qE '^\[[^]]+\]\([^)]+\)$'; then
  # Already a link, wrap in new outer link
  echo "Already a markdown link. Wrapping in new one."
  
  # Extract URL from inner link using sed
  URL=$(echo "$CONTENT" | sed -E 's/.*\(([^)]+)\)$/\1/')
  
  # Get page title
  TITLE="$(
    curl -L -s -A 'Mozilla/5.0' --max-time 2 "$URL" \
      | tr -d '\n' \
      | grep -ioE '<title[^>]*>[^<]+</title>' \
      | head -1 \
      | sed -E 's/<title[^>]*>//I;s/<\/title>//I' \
      | sed -E 's/ ·.*$//' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  )"

  # Fallback if no title
  if [ -z "$TITLE" ]; then
    TITLE="$URL"
  fi

  NEW_LINK="[$TITLE]($URL)"
else
  # Treat as plain URL
  URL="$CONTENT"
  
  # Get title
  TITLE="$(
    curl -L -s -A 'Mozilla/5.0' --max-time 2 "$URL" \
      | tr -d '\n' \
      | grep -ioE '<title[^>]*>[^<]+</title>' \
      | head -1 \
      | sed -E 's/<title[^>]*>//I;s/<\/title>//I' \
      | sed -E 's/ ·.*$//' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  )"

  if [ -z "$TITLE" ]; then
    TITLE="$URL"
  fi

  NEW_LINK="[$TITLE]($URL)"
fi

# Copy to clipboard
echo "$NEW_LINK" | pbcopy

# Paste at cursor
osascript <<EOF
tell application "System Events"
    keystroke "v" using command down
end tell
EOF
