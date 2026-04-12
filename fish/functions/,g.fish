function __g_stash_run_unstash --description "Stash, run command, then pop"
    set needs_stash false
    if not git diff --quiet; or not git diff --cached --quiet
        set needs_stash true
        git stash push -m "auto-stash before switching branches"
    end
    $argv
    if test "$needs_stash" = true
        git stash pop
    end
end

function ,g --description "Git workflow helper commands"
    if test (count $argv) -eq 0
        echo "Usage: ,g <command> [args]"
        echo ""
        echo "Commands:"
        echo "  base        Print the base branch (main or master)"
        echo "  bco         Switch to the base branch"
        echo "  new         Create a new branch (from base, or current branch with 2nd arg)"
        echo "  mybranches  List and checkout branches authored by you (-d to delete)"
        echo "  clean       Delete local branches merged into base"
        echo "  brprune     Delete all local branches except the base branch"
        echo "  sync        Update local base branch (from upstream if available, else origin)"
        echo "  merge       Sync base and merge it into current branch"
        echo "  rebase      Sync base and rebase current branch onto it"
        echo "  squash      Squash all commits ahead of base into one"
        echo "  done        Stash changes, switch to base branch, and sync"
        echo "  prc         Push and create a PR, then copy review link"
        echo "  pro         Open PR in browser"
        echo "  prr         Copy formatted PR review request to clipboard"
        echo "  myprs       List and checkout your open PRs"
        echo "  coauthored  Generate Co-authored-by trailer for a GitHub user"
        echo "  stash       Stash changes with a named message"
        echo "  unstash     Pick a stash to pop via interactive chooser"
        echo "  wk          Switch to a git worktree via interactive chooser"
        echo "  cmp         Show commits ahead of upstream base branch"
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

        case bco
            set base_branch (,g base)
            __g_stash_run_unstash git checkout $base_branch

        case brprune
            set base_branch (,g base)
            set current_branch (git rev-parse --abbrev-ref HEAD)

            if test "$current_branch" != "$base_branch"
                __g_stash_run_unstash git checkout $base_branch
            end

            for branch in (git branch --format="%(refname:short)" | string match -v "$base_branch")
                echo "Deleting branch: $branch"
                git branch -D $branch
            end

        case clean
            ,g sync
            set base_branch (,g base)

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
            ,g sync
            set base_branch (,g base)
            git merge $base_branch

        case mybranches
            set user_email (git config user.email)
            set my_branches
            git branch --format="%(refname:short)" | while read branch
                set author (git log -1 --format="%ae" "$branch" 2>/dev/null)
                if test "$author" = "$user_email"
                    set -a my_branches "$branch"
                end
            end

            printf '%s\n' $my_branches

            if test (count $argv) -ge 1; and test "$argv[1]" = -d
                set branch (printf '%s\n' $my_branches | gum choose --height 15 --header "Select branch to delete:")
                if test -n "$branch"
                    git branch -D "$branch"
                else
                    echo "No branch selected."
                end
            else
                set branch (printf '%s\n' $my_branches | gum choose --height 15)
                if test -n "$branch"
                    set action (printf 'checkout\ndelete' | gum choose --header "Action for '$branch':")
                    if test "$action" = checkout
                        __g_stash_run_unstash git checkout "$branch"
                    else if test "$action" = delete
                        git branch -d "$branch"
                    end
                else
                    echo "No branch selected."
                end
            end

        case myprs
            set pr_data (gh pr list --author "@me" --json number,title -q '.[] | "\(.number)\t\(.title)"')

            printf '%s\n' $pr_data

            set selection (printf '%s\n' $pr_data | gum choose --height 15)

            if test -n "$selection"
                set pr_id (string split \t "$selection")[1]
                __g_stash_run_unstash gh pr checkout "$pr_id"
            else
                echo "No PR selected."
            end

        case new
            if test (count $argv) -eq 0
                echo "Usage: ,g new <branch> [from-current]"
                return 1
            end
            set branch_name "shaygan-$argv[1]"
            if test (count $argv) -ge 2
                git checkout -b $branch_name
            else
                ,g sync
                set base_branch (,g base)
                git checkout -b $branch_name $base_branch
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

        case done
            set current_branch (git rev-parse --abbrev-ref HEAD)
            set base_branch (,g base)

            if test "$current_branch" = "$base_branch"
                echo "Already on $base_branch, nothing to do."
                return 1
            end

            set needs_stash false
            if not git diff --quiet; or not git diff --cached --quiet
                set needs_stash true
                git stash push -m "done: $current_branch"
            end

            ,g sync
            git checkout $base_branch

            if test "$needs_stash" = true
                git stash pop
            end

        case rebase
            ,g sync
            set base_branch (,g base)
            git rebase $base_branch

        case squash
            set base_branch (,g base)
            set commit_count (git rev-list --count $base_branch..HEAD)

            if test "$commit_count" -eq 0
                echo "No commits ahead of $base_branch to squash."
                return 1
            end

            echo "Squashing $commit_count commit(s) ahead of $base_branch..."
            git reset --soft $base_branch
            git commit

        case stash
            if test (count $argv) -eq 0
                echo "Usage: ,g stash <message>"
                return 1
            end
            set stash_msg (string join " " $argv)
            git stash push -m "$stash_msg"
            echo "📦 Stashed as: $stash_msg"

        case sync
            set base_branch (,g base)
            set current_branch (git rev-parse --abbrev-ref HEAD)

            if test "$current_branch" = "$base_branch"
                git pull
            else if git remote get-url upstream >/dev/null 2>&1
                git fetch upstream
                git fetch origin
                git branch -f $base_branch upstream/$base_branch
                git push origin $base_branch --force
            else
                git fetch origin +$base_branch:$base_branch
            end

        case unstash
            set stash_list (git stash list)
            if test -z "$stash_list"
                echo "No stashes found."
                return 1
            end

            set selection (printf '%s\n' $stash_list | gum choose --height 15)

            if test -n "$selection"
                set stash_ref (string split ":" "$selection")[1]
                git stash pop "$stash_ref"
            else
                echo "No stash selected."
            end

        case wk
            set wt_entries
            set wt_paths
            set current_path ""
            set current_branch ""
            git worktree list --porcelain | while read -l line
                if string match -q "worktree *" "$line"
                    set current_path (string replace "worktree " "" "$line")
                else if string match -q "branch *" "$line"
                    set current_branch (string replace "branch refs/heads/" "" "$line")
                else if string match -q "HEAD *" "$line"
                    # detached HEAD, will be overwritten if branch line follows
                else if test -z "$line"; and test -n "$current_path"
                    if test -z "$current_branch"
                        set current_branch "(detached)"
                    end
                    set -a wt_entries "$current_path"\t"[$current_branch]"
                    set -a wt_paths "$current_path"
                    set current_path ""
                    set current_branch ""
                end
            end
            # handle last entry if no trailing blank line
            if test -n "$current_path"
                if test -z "$current_branch"
                    set current_branch "(detached)"
                end
                set -a wt_entries "$current_path"\t"[$current_branch]"
                set -a wt_paths "$current_path"
            end

            if test (count $wt_entries) -eq 0
                echo "No worktrees found."
                return 1
            end

            set selection (printf '%s\n' $wt_entries | gum choose --height 15)

            if test -n "$selection"
                set selected_path (string split \t "$selection")[1]
                cd "$selected_path"
            else
                echo "No worktree selected."
            end

        case '*'
            echo "Unknown command: $subcmd"
            ,g
            return 1
    end
end
