#!/bin/bash

# Usage: macos-notify.sh <title> <message> [sound]
# Shows a macOS notification. The optional sound is a name from
# /System/Library/Sounds such as Glass or Basso. Without it the
# notification is silent.

if [ $# -lt 2 ]; then
  echo "Usage: macos-notify.sh <title> <message> [sound]" >&2
  exit 1
fi

osascript - "$@" <<'APPLESCRIPT'
on run argv
  set theTitle to item 1 of argv
  set theMessage to item 2 of argv
  if (count of argv) > 2 then
    display notification theMessage with title theTitle sound name (item 3 of argv)
  else
    display notification theMessage with title theTitle
  end if
end run
APPLESCRIPT
