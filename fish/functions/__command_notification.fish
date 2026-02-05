function __command_notification --on-event fish_postexec
    if not test $CMD_DURATION
      return
    end
    set duration (echo "$CMD_DURATION 1000" | awk '{printf "%.3fs", $1 / $2}')
    set exclude_cmd "bash|less|man|more|ssh|vim|f|amp|claude|opencode"
    if test $CMD_DURATION -lt 10000; or echo $argv[1] | grep -qE "^($exclude_cmd).*"
      return
    end
      set cmd_title (string replace -a '"' '"' -- $argv[1])
      fish -c "osascript -e 'display notification "Finished in $duration" with title "$cmd_title" sound name "Glass"'; sleep 10; osascript -e 'tell application "System Events" to tell process "NotificationCenter" to perform action "AXCancel" of last item of (windows whose subrole is "AXNotificationCenterAlert")' 2>/dev/null" &
end
