function ,pf --description "Paste file or clipboard content"
    if test (count $argv) -gt 0
        # Paste clipboard content to the specified file
        set -l output_file "$argv[1]"

        # Try to paste as text first (handles text, code, etc.)
        if pbpaste > "$output_file" 2>/dev/null
            return 0
        end

        # If text paste failed, try image data
        osascript -e "set png_data to the clipboard as «class PNGf»" \
                  -e "set the_file to open for access POSIX file \"$PWD/$output_file\" with write permission" \
                  -e "try" \
                  -e "  set eof the_file to 0" \
                  -e "  write png_data to the_file" \
                  -e "  close access the_file" \
                  -e "on error" \
                  -e "  try" \
                  -e "    close access the_file" \
                  -e "  end try" \
                  -e "end try"
    else
        # Check for Finder file first (files also have PNGf as their icon thumbnail)
        if osascript -e 'the clipboard as «class furl»' &>/dev/null
            osascript -e 'on run args' \
                      -e 'tell application "Finder"' \
                      -e 'set clipboardItems to (the clipboard as «class furl»)' \
                      -e 'set destinationFolder to POSIX file (item 1 of args) as alias' \
                      -e 'duplicate clipboardItems to destinationFolder' \
                      -e 'end tell' \
                      -e 'end run' \
                      "$PWD"
        else if osascript -e 'the clipboard as «class PNGf»' &>/dev/null
            set -l random_name (LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)
            set -l output_file "$random_name.png"
            osascript -e "set png_data to the clipboard as «class PNGf»" \
                      -e "set the_file to open for access POSIX file \"$PWD/$output_file\" with write permission" \
                      -e "try" \
                      -e "  set eof the_file to 0" \
                      -e "  write png_data to the_file" \
                      -e "  close access the_file" \
                      -e "on error" \
                      -e "  try" \
                      -e "    close access the_file" \
                      -e "  end try" \
                      -e "end try"
            and echo "Pasted image as $output_file"
        else
            echo ",pf: nothing useful on clipboard (no file or image found)" >&2
            return 1
        end
    end
end
