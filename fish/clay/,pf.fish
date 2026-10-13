function ,pf --description "Paste the clipboard into a file: a Finder file, an image, or text"
    set -l target $argv[1]
    set -l kinds (osascript -e 'clipboard info' 2>/dev/null | string join ' ')

    if string match -q '*«class furl»*' -- $kinds
        set -l source (osascript -e 'POSIX path of (the clipboard as «class furl»)')
        test -n "$target"; or set target (path basename $source)
        cp -R "$source" "$target"
        and echo "Pasted file as $target"
        return
    end

    if string match -q '*«class PNGf»*' -- $kinds
        test -n "$target"; or set target (LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 8).png
        osascript -e 'set png_data to the clipboard as «class PNGf»' \
            -e "set f to open for access POSIX file \"$(path resolve $target)\" with write permission" \
            -e 'set eof f to 0' \
            -e 'write png_data to f' \
            -e 'close access f'
        and echo "Pasted image as $target"
        return
    end

    if test -z "$target"
        echo ",pf: clipboard holds only text, give a file name to paste it into" >&2
        return 1
    end
    pbpaste >"$target"
end
