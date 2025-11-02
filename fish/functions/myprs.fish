function myprs
    gh pr list --author "@me"

    set pr_id (gh pr list --author "@me" --json number -q ".[] | .number" | gum choose --height 15)

    # Check out the selected PR
    if test -n "$pr_id"
        gh pr checkout "$pr_id"
    else
        echo "No PR selected."
    end
end