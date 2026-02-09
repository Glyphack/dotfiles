#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Clipboard URL -> Markdown
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🔗
# @raycast.packageName Markdown Tools

# Documentation:
# @raycast.author your_name
# @raycast.authorURL https://raycast.com/your_name

# Get URL from clipboard
URL="$(pbpaste)"

if [ -z "$URL" ]; then
  echo "No URL found in clipboard."
  exit 1
fi

# Get the page title (improved: remove GitHub issue/repo suffix and trim)
TITLE="$(
  curl -L -s "$URL" \
    | grep -i -m 1 "<title" \
    | sed -E 's/.*<title[^>]*>//I;s/<\/title>.*//I' \
    | sed -E 's/ ·.*$//' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)"

# Fallback if no title found
if [ -z "$TITLE" ]; then
  TITLE="$URL"
fi

MARKDOWN_LINK="[$TITLE]($URL)"

# Print for Raycast output
echo "$MARKDOWN_LINK"

# Copy markdown link to clipboard
echo "$MARKDOWN_LINK" | pbcopy
