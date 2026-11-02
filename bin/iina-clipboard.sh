#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Play Clipboard in IINA
# @raycast.mode silent

URL="$(pbpaste | tr -d '[:space:]')"

if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Clipboard does not contain a URL."
  exit 1
fi

iina --no-stdin "$URL"

echo "Playing in IINA"
