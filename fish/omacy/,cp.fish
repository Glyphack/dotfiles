function ,cp --description "Copy files to clipboard"
    if not set -q argv[1]
        echo "usage: ,cp FILE..." >&2
        return 1
    end
    set -l files (path resolve -- $argv)
    for file in $files
        if not test -e $file
            echo ",cp: no such file: $file" >&2
            return 1
        end
    end
    osascript -l JavaScript -e '
        ObjC.import("AppKit")
        function run(paths) {
            const pb = $.NSPasteboard.generalPasteboard
            pb.clearContents
            pb.writeObjects($(paths.map(p => $.NSURL.fileURLWithPath(p))))
        }' $files
end
