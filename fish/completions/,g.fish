set -l subcmds base bco co clean cmp coauthored done merge new pr rebase squash status stash sync unstash
set -l pr_subs create open review list

complete -c ,g -f

# Top-level subcommands
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a base       -d "Print detected base branch"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a bco        -d "Switch to base branch"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a new        -d "New branch from base (-w for linked worktree)"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a co         -d "Pick & switch branch (-a all, -d delete, -w worktree)"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a done       -d "Finish branch and clean up (-d for unmerged)"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a sync       -d "Update local base from source-of-truth remote"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a merge      -d "Merge base into current branch"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a rebase     -d "Rebase current onto base"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a squash     -d "Squash commits ahead of base"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a cmp        -d "Commits ahead of source-of-truth base"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a pr         -d "PR: create / open / review / list"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a status     -d "One-screen branch + worktree + base status"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a stash      -d "Manual stash with ,g name"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a unstash    -d "Pop a ,g stash (falls back to any)"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a clean      -d "Delete merged shaygan- branches (--all to prune all)"
complete -c ,g -n "not __fish_seen_subcommand_from $subcmds" -a coauthored -d "Co-authored-by trailer for a GitHub user"

# Flags
complete -c ,g -n "__fish_seen_subcommand_from new"   -s w -d "Create linked worktree and cd into it"
complete -c ,g -n "__fish_seen_subcommand_from co"    -s a -d "Show all local branches"
complete -c ,g -n "__fish_seen_subcommand_from co"    -s d -d "Delete the selected branch"
complete -c ,g -n "__fish_seen_subcommand_from co"    -s w -d "Worktree mode (promote / cd / create)"
complete -c ,g -n "__fish_seen_subcommand_from done"  -s d -d "Allow deleting an unmerged branch"
complete -c ,g -n "__fish_seen_subcommand_from clean" -l all   -d "Delete every branch except base"
complete -c ,g -n "__fish_seen_subcommand_from clean" -l prune -d "Alias for --all"

# pr subcommands
complete -c ,g -n "__fish_seen_subcommand_from pr; and not __fish_seen_subcommand_from $pr_subs" -a create -d "Push & create PR via gh"
complete -c ,g -n "__fish_seen_subcommand_from pr; and not __fish_seen_subcommand_from $pr_subs" -a open   -d "Open current PR in browser"
complete -c ,g -n "__fish_seen_subcommand_from pr; and not __fish_seen_subcommand_from $pr_subs" -a review -d "Copy 'please review' message to clipboard"
complete -c ,g -n "__fish_seen_subcommand_from pr; and not __fish_seen_subcommand_from $pr_subs" -a list   -d "Pick from your open PRs and check out"
