#!/usr/bin/env bash

set -euo pipefail

REPO="Glyphack/dotfiles"
DOTFILES="${DOTFILES:-$HOME/Programming/dotfiles}"

install_homebrew() {
    if command -v brew >/dev/null; then
        return
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

clone_dotfiles() {
    if [[ -d "$DOTFILES" ]]; then
        return
    fi
    mkdir -p "$(dirname "$DOTFILES")"
    git clone "https://github.com/$REPO.git" "$DOTFILES"
}

# Logs in to GitHub, adds an SSH key to the account and switches the repo
# remote to SSH.
connect_github() {
    eval "$(mise activate bash --shims)"
    if ! gh auth status >/dev/null 2>&1; then
        gh auth login --scopes admin:public_key
    fi
    bash "$DOTFILES/scripts/ssh-key-gen.sh"
    git -C "$DOTFILES" remote set-url origin "git@github.com:$REPO.git"
}

install_homebrew
clone_dotfiles
"$DOTFILES/scripts/setup.sh"
connect_github
exec fish
