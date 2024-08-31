#!/bin/bash


gh pr list --author "@me"

pr_id=$(gh pr list --author "@me" --json number -q ".[] | .number" | gum choose --height 15)

# Check out the selected PR
if [ -n "$pr_id" ]; then
    gh pr checkout "$pr_id"
else
    echo "No PR selected."
fi
