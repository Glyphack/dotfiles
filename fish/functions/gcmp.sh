#!/bin/bash

# Fetch latest changes from upstream
git fetch upstream

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Show commits in current branch not in upstream/main
git log upstream/main.."$current_branch"
