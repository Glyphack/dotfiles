#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Bookmark
# @raycast.mode silent
#
# @raycast.argument1 { "type": "text", "placeholder": "URL"}
# @raycast.argument2 { "type": "text", "placeholder": "Tag", "optional": true}

URL=$1
TAG=$2
API_KEY=$(security find-generic-password -a "glyphack" -s "readwise_api" -w)


if [ -n "$TAG" ]; then
  TAGS="[\"$TAG\"]"
else
  TAGS="[]"
fi

RESPONSE=$(curl -s --request POST --url https://readwise.io/api/v3/save/ \
  -H "Authorization: Token ${API_KEY}" \
  -H "Content-Type: application/json" \
  --data "{\"url\": \"$URL\", \"tags\": $TAGS}")

echo $RESPONSE

if echo "$RESPONSE" | grep -q '"url"'; then
  echo "Saved to Reader"
else
  echo "Error: $RESPONSE"
fi
