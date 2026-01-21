function prr --description "Copy formatted pull request title and link to clipboard"
    # Ensure gh CLI is installed
    if not command -v gh >/dev/null
        echo "GitHub CLI (gh) could not be found. Please install it from https://cli.github.com/"
        return 1
    end

    # Determine the clipboard command based on the operating system
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

    # Extract the PR number from the provided link using sed
    set pr_number (echo $pr_link | sed -n 's#.*/pull/\([0-9]*\).*#\1#p')

    # Validate PR number
    if test -z "$pr_number"
        echo "Invalid PR link: $pr_link"
        echo "Please provide a valid GitHub pull request link."
        return 1
    end

    # Retrieve the PR title using GitHub CLI
    set pr_title (gh pr view $pr_number --json title -q .title)

    # Validate PR title retrieval
    if test -z "$pr_title"
        echo "Could not retrieve PR title. Please ensure the PR link is correct and you have the necessary permissions."
        return 1
    end

    set text "✨ Please review: $pr_title 
$pr_link"

    # Copy the formatted text to clipboard
    echo -e $text | $clipboard_cmd

    echo "Formatted text has been copied to clipboard:"
    echo -e $text
end