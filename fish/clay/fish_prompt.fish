function fish_prompt
    set -l last_status $status

    set_color --bold cyan
    if test "$PWD" = "$HOME"
        echo -n '~'
    else
        echo -n (basename "$PWD")
    end
    set_color normal

    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
    if test -n "$branch"
        set_color --bold magenta
        echo -n " on $branch"
        set_color normal
    else
        set -l sha (command git rev-parse --short HEAD 2>/dev/null)
        if test -n "$sha"
            set_color --bold green
            echo -n " ($sha)"
            set_color normal
        end
    end

    set -l state (__prompt_git_state)
    if test -n "$state"
        set_color --bold yellow
        echo -n " $state"
        set_color normal
    end

    if test "$CMD_DURATION" -gt 2000
        set_color --bold yellow
        echo -n " took "(__prompt_duration $CMD_DURATION)
        set_color normal
    end

    if test $last_status -eq 0
        set_color --bold green
    else
        set_color --bold red
    end
    echo -n ' ❯'
    set_color normal
    echo
end

function __prompt_git_state
    set -l git_dir (command git rev-parse --git-dir 2>/dev/null)
    test -z "$git_dir"; and return

    if test -d "$git_dir/rebase-merge" -o -d "$git_dir/rebase-apply"
        echo REBASING
    else if test -f "$git_dir/MERGE_HEAD"
        echo MERGING
    else if test -f "$git_dir/CHERRY_PICK_HEAD"
        echo CHERRY-PICKING
    else if test -f "$git_dir/REVERT_HEAD"
        echo REVERTING
    else if test -f "$git_dir/BISECT_LOG"
        echo BISECTING
    end
end

function __prompt_duration -a ms
    set -l s (math -s0 "$ms / 1000")
    set -l m (math -s0 "$s / 60")
    set -l rem (math -s0 "$s % 60")
    if test $m -gt 0
        echo -n {$m}m{$rem}s
    else
        echo -n {$s}s
    end
end
