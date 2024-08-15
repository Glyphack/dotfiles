#!/bin/bash

# Ensure gh CLI is installed
if ! command -v gh &> /dev/null
then
    echo "GitHub CLI (gh) could not be found. Please install it from https://cli.github.com/"
    exit
fi

# Determine the clipboard command based on the operating system
if command -v xclip &> /dev/null
then
    clipboard_cmd="xclip -selection clipboard"
elif command -v pbcopy &> /dev/null
then
    clipboard_cmd="pbcopy"
else
    echo "Neither xclip nor pbcopy could be found. Please install xclip (Linux) or pbcopy (macOS)."
    exit
fi

# Check if a PR link was provided
if [ -z "$1" ]
then
    pr_link=$1
fi

pr_link=$(gh pr view --json url --jq .url)

# Extract the PR number from the provided link using sed
pr_number=$(echo $pr_link | sed -n 's#.*/pull/\([0-9]*\).*#\1#p')

# Validate PR number
if [ -z "$pr_number" ]
then
    echo "Invalid PR link. Please provide a valid GitHub pull request link."
    exit
fi

# Retrieve the PR title using GitHub CLI
pr_title=$(gh pr view $pr_number --json title -q .title)

# Validate PR title retrieval
if [ -z "$pr_title" ]
then
    echo "Could not retrieve PR title. Please ensure the PR link is correct and you have the necessary permissions."
    exit
fi

# Format the text for clipboard
text="please review: $pr_title\n$pr_link"

# Copy the formatted text to clipboard
echo -e $text | $clipboard_cmd

echo "Formatted text has been copied to clipboard:"
echo -e $text

