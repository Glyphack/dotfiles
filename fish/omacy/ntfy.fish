function ntfy
    if test (count $argv) -lt 2
        echo "Usage: ntfy <delay> <message>"
        return 1
    end

    if not set -q ntfy
        echo "ntfy: set your topic first with: set -U ntfy <topic>"
        return 1
    end

    set delay $argv[1]
    set message "$argv[2..-1]"

    curl -s -H "In: $delay" -d "$message" ntfy.sh/"$ntfy" > /dev/null
end
