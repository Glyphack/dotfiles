function wo --description "WezTerm workspace manager"
    argparse 'l/list' 'n/new' 'c/clean' -- $argv

    if set -q _flag_list
        __w_list
    else if set -q _flag_clean
        __w_clean
    else
        __w_new
    end
end

function __w_new --description "Fuzzy find a project and open it in a new WezTerm workspace"
    set -l project (fd -t d . $PROGRAMMING_DIR -d 3 | fzf)
    if test -z "$project"
        return 1
    end
    set -l workspace_name (basename $project)
    set -l existing (wezterm cli list --format json | python3 -c "
import sys, json
seen = set()
for p in json.load(sys.stdin):
    seen.add(p['workspace'])
for w in sorted(seen):
    print(w)
")
    if contains -- $workspace_name $existing
        set -l i 1
        while contains -- "$workspace_name$i" $existing
            set i (math $i + 1)
        end
        set workspace_name "$workspace_name$i"
    end
    set -l pane_id (wezterm cli spawn --new-window --workspace $workspace_name --cwd $project)
    __w_switch $workspace_name
end

function __w_clean --description "Remove all WezTerm workspaces except the current one"
    set -l current_pane $WEZTERM_PANE
    set -l pane_ids (wezterm cli list --format json | python3 -c "
import sys, json
panes = json.load(sys.stdin)
current_pane = int('$current_pane' or '0')
current_ws = ''
for p in panes:
    if p['pane_id'] == current_pane:
        current_ws = p['workspace']
        break
for p in panes:
    if p['workspace'] != current_ws:
        print(p['pane_id'])
")
    for pid in $pane_ids
        wezterm cli kill-pane --pane-id $pid
    end
end

function __w_list --description "List and manage WezTerm workspaces"
    while true
        set -l current_pane $WEZTERM_PANE
        set -l workspaces (wezterm cli list --format json | python3 -c "
import sys, json
panes = json.load(sys.stdin)
current_pane = int('$current_pane' or '0')
current_ws = ''
for p in panes:
    if p['pane_id'] == current_pane:
        current_ws = p['workspace']
        break
seen = set()
for p in panes:
    w = p['workspace']
    if w not in seen:
        seen.add(w)
        print(('* ' if w == current_ws else '  ') + w)
")

        if test -z "$workspaces"
            echo "No workspaces found."
            return 1
        end

        set -l choice (printf "%s\n" $workspaces | gum choose --header "Workspaces (g: goto  d: delete  r: rename)")

        if test -z "$choice"
            return 0
        end

        set -l choice (string replace -r '^\*?\s+' '' $choice)
        set -l action (printf "goto\ndelete\nrename" | gum choose --header "Action for '$choice'")

        switch $action
            case goto
                __w_switch $choice

            case delete
                set -l pane_ids (wezterm cli list --format json | python3 -c "
import sys, json
for p in json.load(sys.stdin):
    if p['workspace'] == '$choice':
        print(p['pane_id'])
")
                for pid in $pane_ids
                    wezterm cli kill-pane --pane-id $pid
                end

            case rename
                set -l new_name (gum input --header "Rename '$choice' to:" --placeholder "new name")
                if test -n "$new_name"
                    wezterm cli rename-workspace --workspace $choice $new_name
                end

            case ''
                continue
        end

        return 0
    end
end

function __w_switch --description "Switch to a WezTerm workspace by name"
    set -l workspace $argv[1]
    if test -z "$workspace"
        echo "Usage: wo switch <workspace_name>"
        return 1
    end
    printf "\033]1337;SetUserVar=%s=%s\007" switch_workspace (echo -n $workspace | base64)
end
