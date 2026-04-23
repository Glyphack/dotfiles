function ntfy
    if test (count $argv) -lt 2
        echo "Usage: ntfy <delay> <message>"
        return 1
    end

    set delay $argv[1]
    set message $argv[2]

    curl -s -H "In: $delay" -d "$message" ntfy.sh/"$ntfy" > /dev/null
end
