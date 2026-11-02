function ,c --description "Open a new Claude desktop Code session in a folder"
    set -l folder $PWD
    if test (count $argv) -gt 0
        set folder $argv[1]
    end

    if not test -d "$folder"
        echo "Not a directory: $folder" >&2
        return 1
    end

    set -l encoded (string escape --style=url (realpath $folder))
    open "claude://code/new?folder=$encoded"
end
