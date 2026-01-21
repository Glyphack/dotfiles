function gcmp --description "Show commits in current branch compared to upstream/main"
    if git remote get-url upstream >/dev/null 2>&1
	git fetch upstream
	set current_branch (git rev-parse --abbrev-ref HEAD)
	git log upstream/main.."$current_branch"
    else
        echo "No upstream remote configured"
    end
end
