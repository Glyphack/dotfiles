function g --description "Git workflow helper commands"
    if test (count $argv) -eq 0
        echo "Usage: g <command> [args]"
        echo "Commands: base, clean, cmp, new, sync"
        return 1
    end

    set subcmd $argv[1]
    set -e argv[1]

    switch $subcmd
        case base
            if git branch -r | grep -q "origin/main"
                echo main
            else
                echo master
            end

        case clean
            set base_branch (g base)
            git fetch origin
            git checkout $base_branch

            for branch in (git branch --merged $base_branch | string trim | string replace -r '^\* ' '' | string match -v "$base_branch")
                echo "Deleting merged branch: $branch"
                git branch -d $branch
            end

        case cmp
            if git remote get-url upstream >/dev/null 2>&1
                set base_branch (g base)
                git fetch upstream
                set current_branch (git rev-parse --abbrev-ref HEAD)
                git log upstream/$base_branch.."$current_branch"
            else
                echo "No upstream remote configured"
            end

        case new
            git fetch origin
            set base_branch (g base)
            git fetch origin $base_branch:$base_branch

            if test (count $argv) -gt 0
                git checkout $base_branch
                and git checkout -b $argv[1]
            end

        case sync
            if git remote get-url upstream >/dev/null 2>&1
                set base_branch (g base)
                git fetch origin
                git fetch upstream
                git pull upstream $base_branch
                git push origin $base_branch --force
            else
                echo "No upstream remote configured"
            end

        case '*'
            echo "Unknown command: $subcmd"
            echo "Commands: base, clean, cmp, new, sync"
            return 1
    end
end
