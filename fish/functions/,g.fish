function ,g --description "Git workflow helper commands"
    if test (count $argv) -eq 0
        echo "Usage: ,g <command> [args]"
        echo ""
        echo "Commands:"
        echo "  base        Print the base branch (main or master)"
        echo "  clean       Delete local branches merged into base"
        echo "  cmp         Show commits ahead of upstream base branch"
        echo "  coauthored  Generate Co-authored-by trailer for a GitHub user"
        echo "  merge       Fetch and merge origin base branch into current branch"
        echo "  mybranches  List and checkout branches authored by you"
        echo "  myprs       List and checkout your open PRs"
        echo "  new         Create a new branch from the latest base branch"
        echo "  prc         Push and create a PR, then copy review link"
        echo "  pro         Open PR in browser"
        echo "  prr         Copy formatted PR review request to clipboard"
        echo "  sync        Sync local base branch from upstream and push to origin"
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
            set base_branch (,g base)
            git fetch origin
            git checkout $base_branch

            for branch in (git branch --merged $base_branch | string trim | string replace -r '^\* ' '' | string match -v "$base_branch")
                echo "Deleting merged branch: $branch"
                git branch -d $branch
            end

        case cmp
            if git remote get-url upstream >/dev/null 2>&1
                set base_branch (,g base)
                git fetch upstream
                set current_branch (git rev-parse --abbrev-ref HEAD)
                git log upstream/$base_branch.."$current_branch"
            else
                echo "No upstream remote configured"
            end

        case coauthored
            set account $argv[1]
            set data (curl -s https://api.github.com/users/$account)
            set id (echo $data | jq .id)
            set name (echo $data | jq --raw-output '.name // .login')
            printf "Co-authored-by: %s %d+%s@users.noreply.github.com\n" $name $id $account

        case merge
            set base_branch (,g base)
            git fetch origin $base_branch
            and git merge origin/$base_branch

        case mybranches
            set user_email (git config user.email)

            git branch --format="%(refname:short)" | while read branch
                set author (git log -1 --format="%ae" "$branch" 2>/dev/null)
                if test "$author" = "$user_email"
                    echo "$branch"
                end
            end

            set branch (git branch --format="%(refname:short)" | while read branch
                set author (git log -1 --format="%ae" "$branch" 2>/dev/null)
                if test "$author" = "$user_email"
                    echo "$branch"
                end
            end | gum choose --height 15)

            if test -n "$branch"
                git checkout "$branch"
            else
                echo "No branch selected."
            end

        case myprs
            gh pr list --author "@me"

            set pr_id (gh pr list --author "@me" --json number -q ".[] | .number" | gum choose --height 15)

            if test -n "$pr_id"
                gh pr checkout "$pr_id"
            else
                echo "No PR selected."
            end

        case new
            git fetch origin
            set base_branch (,g base)
            git fetch origin $base_branch:$base_branch

            if test (count $argv) -gt 0
                git checkout $base_branch
                and git checkout -b $argv[1]
            end

        case prc
            git push
            gh pr create --fill-first && ,g prr $argv

        case pro
            gh pr view --web $argv

        case prr
            if not command -v gh >/dev/null
                echo "GitHub CLI (gh) could not be found. Please install it from https://cli.github.com/"
                return 1
            end

            set clipboard_cmd ""
            if command -v pbcopy >/dev/null
                set clipboard_cmd "pbcopy"
            else if command -v xclip >/dev/null
                set clipboard_cmd "xclip -selection clipboard"
            else
                echo "Neither xclip nor pbcopy could be found. Please install xclip (Linux) or pbcopy (macOS)."
                return 1
            end

            set pr_link ""
            if set -q argv[1]
                set pr_link $argv[1]
            else
                set pr_link (gh pr view --json url --jq .url)
            end

            set pr_number (echo $pr_link | sed -n 's#.*/pull/\([0-9]*\).*#\1#p')

            if test -z "$pr_number"
                echo "Invalid PR link: $pr_link"
                echo "Please provide a valid GitHub pull request link."
                return 1
            end

            set pr_title (gh pr view $pr_number --json title -q .title)

            if test -z "$pr_title"
                echo "Could not retrieve PR title. Please ensure the PR link is correct and you have the necessary permissions."
                return 1
            end

            set text "✨ Please review: $pr_title 
$pr_link"

            echo -e $text | $clipboard_cmd

            echo "Formatted text has been copied to clipboard:"
            echo -e $text

        case sync
            if git remote get-url upstream >/dev/null 2>&1
                set base_branch (,g base)
                git fetch origin
                git fetch upstream
                git pull upstream $base_branch
                git push origin $base_branch --force
            else
                echo "No upstream remote configured"
            end

        case '*'
            echo "Unknown command: $subcmd"
            ,g
            return 1
    end
end
