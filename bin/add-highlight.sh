#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Highlight
# @raycast.mode silent
#
#
# @raycast.argument1 { "type": "text", "placeholder": "Text"}
# @raycast.argument2 { "type": "text", "placeholder": "Tag"}

TEXT=$1
TAG=$2
API_KEY=$(security find-generic-password -a "glyphack" -s "readwise_api" -w)

RESPONSE=$(curl --request POST --url https://readwise.io/api/v2/highlights/ \
  -H "Authorization: Token ${API_KEY}" -H 'Content-Type: application/json' \
  --data "{\"highlights\":[{\"title\": \"Words\", \"text\": \"$TEXT\", \"note\": \".${TAG}\"}]}")

echo "$RESPONSE"
