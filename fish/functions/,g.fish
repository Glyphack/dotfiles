set -g __g_branch_prefix shaygan-

function __g_ts;     date '+%Y-%m-%d_%H-%M-%S'; end
function __g_base;   git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | cut -d/ -f2-; end
function __g_cur;    git rev-parse --abbrev-ref HEAD 2>/dev/null; end
function __g_top;    git rev-parse --show-toplevel 2>/dev/null; end
function __g_dirty;  not git diff --quiet; or not git diff --cached --quiet; end
function __g_untracked; test -n "$(git ls-files --others --exclude-standard)"; end
function __g_in_main; test (__g_top) = (__g_main_wt) 2>/dev/null; end
function __g_err;     echo $argv >&2; end

function __g_remote --description 'pick the remote to fetch/push from (prefers upstream over origin)'
    set -l upstream_url (git remote get-url upstream 2>/dev/null)
    set -l origin_url (git remote get-url origin 2>/dev/null)
    test -n "$upstream_url"; and test "$upstream_url" != "$origin_url"; and echo upstream; and return
    test -n "$origin_url"; and echo origin
end

function __g_remote_branch --description 'resolve the base as remote or local if remote is not available'
    set -l remote (__g_remote)
    set -l base (__g_base)
    test -n "$remote"; and git show-ref --verify --quiet refs/remotes/$remote/$base
    and echo $remote/$base; or echo $base
end

function __g_fetch_base --description 'fetch the base branch from the chosen remote'
    set -l remote (__g_remote); or return 1
    git fetch $remote (__g_base) 2>/dev/null
    or __g_err "fetch from $remote failed; using local base"
end

function __g_wt_path --description 'build a worktree path'
    test -n "$WORKTREES_DIR"; or begin; __g_err '$WORKTREES_DIR not set'; return 1; end
    echo $WORKTREES_DIR/(basename (__g_top))-$argv[1]
end

function __g_wt_for --description 'find the existing worktree path for a given branch'
    git worktree list --porcelain \
        | awk -v b="branch refs/heads/$argv[1]" '/^worktree /{p=$2} $0==b{print p; exit}'
end

function __g_main_wt --description 'locate the main worktree directory from anywhere in the repo'
    set -l common_dir (git rev-parse --git-common-dir 2>/dev/null); or return 1
    string match -q '/*' "$common_dir"; or set common_dir (realpath $common_dir)
    dirname $common_dir
end

function __g_inprocess_abort --description 'abort if a git op (rebase/merge/cherry-pick/bisect) is in progress'
    set -l git_dir (git rev-parse --git-dir 2>/dev/null)
    for state_file in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD BISECT_LOG
        if test -e "$git_dir/$state_file"
            __g_err "git op in progress ($state_file); resolve first"
            return 1
        end
    end
end

function __g_prefix --description 'ensure a branch name carries the shaygan- prefix'
    string match -q "$__g_branch_prefix*" -- $argv[1]; and echo $argv[1]; or echo "$__g_branch_prefix$argv[1]"
end

function __g_auto_stash --description 'stash dirty and untracked changes'
    __g_dirty; or __g_untracked; or return 0
    set -l flag -u
    if __g_untracked
        echo "Untracked files:"
        git ls-files --others --exclude-standard | sed 's/^/  /'
        gum confirm --default=true "Include untracked in stash?"; or set flag ""
    end
    not __g_dirty; and test -z "$flag"; and return 0
    set -l name ",g/auto/$argv[1]>$argv[2]@"(__g_ts)
    git stash push $flag -m $name; or return 1
    echo "$name (restore: ,g unstash)"
end

function __g_restore_prompt --description 'Prompt to restore stash'
    set -l cur $argv[1]
    set -l matches (git stash list --format='%gd %gs' | string match -e -- ",g/auto/$cur>")
    test (count $matches) -eq 0; and return 0
    set -l sel (printf '%s\n' $matches "(skip)" | gum choose --header "Restore auto-stash for '$cur'?")
    test -z "$sel"; or test "$sel" = "(skip)"; and return 0
    git stash pop (string split ' ' -m 1 -- $sel)[1]
end

function __g_stash_worktree --description 'stash dirty+untracked in another worktree before removal (no prompt)'
    set -l wt_path $argv[1]
    test -d $wt_path; or return 0
    set -l st (git -C $wt_path status --porcelain)
    test (count $st) -eq 0; and return 0
    set -l branch (git -C $wt_path rev-parse --abbrev-ref HEAD 2>/dev/null)
    set -l name ",g/auto/$branch>removed@"(__g_ts)
    git -C $wt_path stash push -u -m $name; or return 1
    echo "$name (restore: ,g unstash)"
end

function __g_is_merged --description 'check if branch is merged into another (handles squash-merge)'
    git merge-base --is-ancestor $argv[1] $argv[2] 2>/dev/null; and return 0
    set -l merge_base (git merge-base $argv[2] $argv[1] 2>/dev/null); or return 1
    set -l branch_tree (git rev-parse "$argv[1]^{tree}")
    for commit in (git rev-list $merge_base..$argv[2])
        test (git rev-parse "$commit^{tree}") = $branch_tree; and return 0
    end
    return 1
end

function __g_clip --description 'pipe stdin into the available clipboard tool'
    if command -v pbcopy >/dev/null; pbcopy
    else if command -v wl-copy >/dev/null; wl-copy
    else if command -v xclip >/dev/null; xclip -selection clipboard
    else; cat >/dev/null; __g_err "no clipboard tool"; return 1; end
end

function __g_need_arg --description 'guard: print usage and fail if first arg is empty'
    test -n "$argv[1]"; and return 0
    __g_err "Usage: $argv[2..]"
    return 1
end

function __g_usage --description 'print the top-level ,g command help'
    echo "Usage: ,g <command> [args]"
    for fn in (functions --all | string match -r '^__g_cmd_.*')
        set -l name (string replace '__g_cmd_' '' $fn)
	set -l desc (functions -D -v $fn)[5]
        printf "  %-10s %s\n" $name $desc
    end
end

function __g_cmd_base --description 'print the detected base branch'
    __g_base
end

function __g_cmd_bco --description 'checkout the base branch'
    __g_inprocess_abort; or return 1
    set -l base (__g_base)
    test (__g_cur) = $base; and echo "Already on $base"; and return
    __g_auto_stash (__g_cur) $base; or return 1
    git checkout $base
end

function __g_cmd_new --description 'create a new branch in a worktree (-b for in-place)'
    __g_inprocess_abort; or return 1
    __g_need_arg "$argv[1]" ',g new <name> [-b]'; or return 1
    set -l branch (__g_prefix $argv[1])
    git show-ref --verify --quiet refs/heads/$branch
    and begin; __g_err "branch '$branch' already exists locally"; return 1; end
    set -l remote (__g_remote)
    test -n "$remote"; and git show-ref --verify --quiet refs/remotes/$remote/$branch
    and begin; __g_err "branch '$branch' already exists on $remote"; return 1; end
    __g_fetch_base
    set -l base_ref (__g_remote_branch)
    if contains -- -b $argv
        __g_auto_stash (__g_cur) $branch; or return 1
        git checkout -b $branch $base_ref
        return
    end
    set -l worktree_path (__g_wt_path $branch); or return 1
    test -e $worktree_path; and begin; __g_err "path exists: $worktree_path"; return 1; end
    mkdir -p (dirname $worktree_path)
    git worktree add -b $branch $worktree_path $base_ref; and cd $worktree_path
end

function __g_convert_to_worktree --description 'move the current branch into a new worktree'
    set -l branch $argv[1]
    set -l worktree_path (__g_wt_path $branch); or return 1
    test -e $worktree_path; and begin; __g_err "path exists: $worktree_path"; return 1; end
    set -l name ",g/auto/$branch>$branch@"(__g_ts)": promote"
    set -l stashed false
    if __g_dirty; or __g_untracked
        git stash push -u -m $name; or return 1
        set stashed true
        echo "$name"
    end
    mkdir -p (dirname $worktree_path)
    if not begin; git checkout (__g_base); and git worktree add $worktree_path $branch; end
        test $stashed = true; and __g_err "stash kept: $name"
        return 1
    end
    cd $worktree_path
    test $stashed = true; and git stash pop
end

function __g_cmd_co --description 'checkout (-a all, -d delete, -w into worktree)'
    __g_inprocess_abort; or return 1
    set -l all false; set -l del false; set -l wt false; set -l query ""
    for arg in $argv
        switch $arg
            case -a; set all true
            case -d; set del true
            case -w; set wt true
            case '*'; set query $arg
        end
    end

    set -l email (git config user.email)
    set -l worktree_branches (git worktree list --porcelain | string match -r '^branch refs/heads/(.*)' --groups-only)
    set -l branches
    for branch in (git branch --format='%(refname:short)')
        test $all = true
        or test (git log -1 --format='%ae' $branch 2>/dev/null) = $email
        or contains $branch $worktree_branches
        and set -a branches $branch
    end
    test -n "$query"; and set branches (string match -- "*$query*" $branches)
    test (count $branches) -gt 0; or begin; __g_err "no matches"; return 1; end

    set -l pr_data
    command -v gh >/dev/null
    and set pr_data (gh pr list --state all --json number,state,headRefName -L 300 -q '.[] | "\(.headRefName)\t#\(.number) \(.state)"' 2>/dev/null)

    set -l wts; set -l prs
    set -l max_branch_w 0; set -l max_wt_w 0
    for branch in $branches
        set -l bw (string length -- $branch)
        test $bw -gt $max_branch_w; and set max_branch_w $bw
        set -l wt ""
        contains $branch $worktree_branches; and set wt (__g_wt_for $branch)
        set -a wts "$wt"
        set -l ww (string length -- "$wt")
        test $ww -gt $max_wt_w; and set max_wt_w $ww
        set -l pr ""
        for p in $pr_data
            set -l prefix $branch\t
            string match -q -- "$prefix*" $p; and set pr (string replace -- $prefix '' $p); and break
        end
        set -a prs "$pr"
    end

    set -l items
    for i in (seq (count $branches))
        set -a items (printf '%-*s  %-*s  %s' $max_branch_w $branches[$i] $max_wt_w "$wts[$i]" "$prs[$i]")
    end
    set -l sel (printf '%s\n' $items | gum choose --height 20 --header "branch:")
    test -z "$sel"; and echo "No selection"; and return 1
    set -l branch (string split -n ' ' -- $sel)[1]

    if test $del = true
        test $branch = (__g_base); and __g_err "refusing to delete base"; and return 1
        set -l existing_path (__g_wt_for $branch)
        set -l msg "Delete '$branch'"; test -n "$existing_path"; and set msg "$msg and worktree '$existing_path'"
        gum confirm --default=false "$msg?"; or begin; echo Cancelled; return 1; end
        if test -n "$existing_path"
            __g_stash_worktree $existing_path; or return 1
            git worktree remove $existing_path --force
        end
        git branch -D $branch
        return
    end

    set -l existing_path (__g_wt_for $branch)
    set -l cur (__g_cur)
    if test $wt = true
        test $branch = $cur; and __g_in_main; and __g_convert_to_worktree $branch; and return
        test -n "$existing_path"; and cd $existing_path; and return
        set -l new_path (__g_wt_path $branch); or return 1
        test -e $new_path; and begin; __g_err "path exists: $new_path"; return 1; end
        mkdir -p (dirname $new_path)
        git worktree add $new_path $branch; and cd $new_path
        return
    end
    test -n "$existing_path"; and cd $existing_path; and return
    __g_auto_stash $cur $branch; or return 1
    git checkout $branch; or return 1
    __g_restore_prompt $branch
end

function __g_cmd_sync --description 'fast-forward the base branch from its remote'
    __g_inprocess_abort; or return 1
    set -l remote (__g_remote); or begin; __g_err "no remote"; return 1; end
    set -l base (__g_base)
    if test (__g_cur) != $base
        git fetch $remote $base
        return
    end
    git fetch $remote $base; and git merge --ff-only $remote/$base
    or begin; __g_err "non-fast-forward on $base"; return 1; end
end

function __g_cmd_merge --description 'merge the base branch into the current branch'
    __g_inprocess_abort; or return 1
    __g_fetch_base
    git merge (__g_remote_branch)
    or begin; __g_err "conflict: git merge --continue | --abort"; return 1; end
end

function __g_cmd_rebase --description 'rebase the current branch onto the base branch'
    __g_inprocess_abort; or return 1
    __g_fetch_base
    git rebase (__g_remote_branch)
    or begin; __g_err "conflict: git rebase --continue | --abort"; return 1; end
end

function __g_cmd_squash --description 'soft-reset to base and re-commit, squashing all branch commits'
    __g_inprocess_abort; or return 1
    set -l base (__g_base)
    set -l commit_count (git rev-list --count $base..HEAD)
    test $commit_count -eq 0; and echo "Nothing to squash"; and return 1
    echo "Squashing $commit_count commit(s) ahead of $base..."
    git reset --soft $base; and git commit
end

function __g_cmd_cmp --description 'show commits on the current branch that are not on the base'
    __g_fetch_base
    git log (__g_remote_branch)..(__g_cur)
end

function __g_cmd_done --description 'delete a finished branch and its worktree (-d forces unmerged)'
    __g_inprocess_abort; or return 1
    set -l force false; contains -- -d $argv; and set force true
    set -l cur (__g_cur)
    set -l base (__g_base)
    test $cur = $base; and __g_err "on base; nothing to do"; and return 1

    __g_fetch_base
    set -l ref (__g_remote_branch)
    set -l merged false; __g_is_merged $cur $ref; and set merged true
    set -l pr_state ""; set -l pr_num ""
    if test $merged = false
        set -l prs (command -v gh >/dev/null; and gh pr view $cur --json state,number -q '.state + " " + (.number|tostring)' 2>/dev/null)
        set pr_state (string split ' ' -- $prs)[1]
        set pr_num (string split ' ' -- $prs)[2]
        test "$pr_state" = MERGED; and set merged true
    end

    if test $merged = false
        test $force = false
        and begin; __g_err "'$cur' not merged; use -d to force"; return 1; end
        test "$pr_state" = OPEN; and __g_err "PR #$pr_num still open"
        gum confirm --default=false "Delete unmerged '$cur'?"
        or begin; echo Cancelled; return 1; end
    end

    set -l here (__g_top)
    if not __g_in_main
        set -l main_worktree (__g_main_wt)
        test -d $main_worktree; or begin; __g_err "main worktree missing: $main_worktree"; return 1; end
        __g_stash_worktree $here; or return 1
        cd $main_worktree
        git worktree remove $here --force; and git branch -D $cur; or return 1
    else
        __g_auto_stash $cur $base; or return 1
        git checkout $base; or return 1
        set -l other (__g_wt_for $cur)
        if test -n "$other"; and test "$other" != "$here"
            __g_stash_worktree $other; or return 1
            git worktree remove $other --force
        end
        git branch -D $cur; or return 1
    end
    echo "removed '$cur'"

    set -l remote (__g_remote)
    if test -n "$remote"
        echo ""
        echo "To clean remote:"
        echo "  git push $remote --delete $cur"
        test -n "$pr_num"; and test "$pr_state" != MERGED; and test "$pr_state" != CLOSED
        and echo "  gh pr close $pr_num"
    end

    __g_cmd_sync
end

function __g_pr_create --description 'push branch, open a PR via gh, and copy a review message'
    command -v gh >/dev/null; or begin; __g_err "gh required"; return 1; end
    set -l remote (__g_remote); or begin; __g_err "no remote"; return 1; end
    git push -u $remote (__g_cur); and gh pr create --fill-first; and __g_pr_share
end

function __g_pr_open --description 'open the PR for the current branch in the browser'
    gh pr view --web $argv
end

function __g_pr_share --description 'copy PR link and title to clipboard to share'
    command -v gh >/dev/null; or begin; __g_err "gh required"; return 1; end
    set -l link $argv[1]
    test -n "$link"; or set link (gh pr view --json url --jq .url 2>/dev/null)
    set -l pr_number (echo $link | sed -n 's#.*/pull/\([0-9]*\).*#\1#p')
    test -n "$pr_number"; or begin; __g_err "bad PR link: $link"; return 1; end
    set -l title (gh pr view $pr_number --json title -q .title 2>/dev/null)
    set -l text "Please review: $title
$link"
    echo $text | __g_clip
    echo "Copied:"; echo $text
end

function __g_pr_list --description 'pick one of your open PRs and check it out locally'
    set -l data (gh pr list --author '@me' --json number,title -q '.[] | "\(.number)\t\(.title)"')
    test -z "$data"; and echo "No open PRs"; and return 0
    set -l sel (printf '%s\n' $data | gum choose --height 15 --header "PR:")
    test -z "$sel"; and echo "No selection"; and return 1
    set -l pr_number (string split \t -- $sel)[1]
    __g_auto_stash (__g_cur) "pr-$pr_number"; or return 1
    gh pr checkout $pr_number
end

function __g_cmd_pr --description 'PR commands'
    set -l sub $argv[1]
    __g_need_arg "$sub" ',g pr <create|open|share [link]|list>'; or return 1
    set -e argv[1]
    set -l fn __g_pr_$sub
    functions -q $fn; or begin; __g_err "unknown pr: $sub"; return 1; end
    $fn $argv
end

function __g_cmd_stash --description 'save a labelled manual stash (under ,g/manual/...)'
    __g_need_arg "$argv[1]" ',g stash <msg>'; or return 1
    set -l name ",g/manual/"(__g_cur)"@"(__g_ts)": "(string join ' ' $argv)
    git stash push -u -m $name; and echo "$name"
end

function __g_cmd_unstash --description 'pick and pop a stash (prefers ,g/-prefixed ones)'
    set -l all (git stash list)
    test (count $all) -eq 0; and echo "No stashes"; and return 1
    set -l mine (string match -- '*,g/*' $all)
    set -l list $mine; test (count $mine) -eq 0; and set list $all
    set -l sel (printf '%s\n' $list | gum choose --height 15 --header "stash:")
    test -z "$sel"; and echo "No selection"; and return 1
    git stash pop (string split ':' -m 1 -- $sel)[1]
end

function __g_cmd_status --description 'show worktree kind, ahead/behind base, and PR state'
    set -l cur (__g_cur); set -l base (__g_base); set -l ref (__g_remote_branch)
    set -l kind main; __g_in_main; or set kind linked
    echo "worktree:  "(__g_top)"  ($kind)"
    if git rev-parse --verify $ref >/dev/null 2>&1
        echo "vs base:   "(git rev-list --count $ref..HEAD)" ahead, "(git rev-list --count HEAD..$ref)" behind ($ref)"
    end
    set -l pr_state unknown
    set -l timeout_cmd ""
    command -v gh >/dev/null; and set timeout_cmd (command -v timeout; or command -v gtimeout)
    if test -n "$timeout_cmd"
        set -l output (eval $timeout_cmd 2 gh pr view $cur --json state -q .state 2>&1)
        if string match -q '*no pull requests*' -- $output
            set pr_state 0
        else if test -n "$output"; and not string match -q '* *' -- $output
            set pr_state $output
        end
    end
    echo "pr state:  $pr_state"
    if test $cur != $base; and git rev-parse --verify $ref >/dev/null 2>&1
        set -l ahead_count (git rev-list --count $ref..HEAD)
        test $ahead_count -gt 0; and echo ""; and echo "Commits ahead of $ref:"; and git log --oneline $ref..HEAD
    end
    return 0
end

function __g_cmd_clean --description 'delete merged shaygan- branches (--all/--prune wipes every non-base branch)'
    __g_inprocess_abort; or return 1
    set -l base (__g_base); set -l cur (__g_cur)
    if contains -- --all $argv; or contains -- --prune $argv
        gum confirm --default=false "Delete every branch except '$base'?"
        or begin; echo Cancelled; return 1; end
        test $cur != $base; and begin; __g_auto_stash $cur $base; and git checkout $base; or return 1; end
        for branch in (git branch --format='%(refname:short)' | string match -v $base)
            set -l worktree_path (__g_wt_for $branch)
            if test -n "$worktree_path"
                __g_stash_worktree $worktree_path; or return 1
                git worktree remove $worktree_path --force 2>/dev/null
            end
            git branch -D $branch
        end
        return
    end
    __g_fetch_base
    set -l ref (__g_remote_branch)
    set -l pr_merged
    command -v gh >/dev/null
    and set pr_merged (gh pr list --state merged --json headRefName -L 300 -q '.[].headRefName' 2>/dev/null)
    set -l deleted 0
    for branch in (git branch --format='%(refname:short)')
        string match -q "$__g_branch_prefix*" $branch; or continue
        test $branch = $cur; and continue
        __g_is_merged $branch $ref; or contains -- $branch $pr_merged; or continue
        set -l worktree_path (__g_wt_for $branch)
        if test -n "$worktree_path"
            __g_stash_worktree $worktree_path; or return 1
            git worktree remove $worktree_path --force 2>/dev/null
        end
        echo "Deleting: $branch"
        git branch -D $branch
        set deleted (math $deleted + 1)
    end
    test $deleted -eq 0; and echo "Nothing to clean"
end

function __g_cmd_coauthored --description 'print a Co-authored-by line for a GitHub username'
    set -l user $argv[1]
    __g_need_arg "$user" ',g coauthored <user>'; or return 1
    set -l data (curl -s https://api.github.com/users/$user)
    printf "Co-authored-by: %s <%d+%s@users.noreply.github.com>\n" \
        (echo $data | jq -r '.name // .login') (echo $data | jq .id) $user
end

function ,g --description 'dispatcher: route ,g <sub> to __g_cmd_<sub>'
    set -l sub $argv[1]
    test -z "$sub"; and __g_usage; and return 1
    set -e argv[1]
    set -l fn __g_cmd_$sub
    functions -q $fn; or begin; __g_err "unknown: $sub"; __g_usage; return 1; end
    $fn $argv
end
