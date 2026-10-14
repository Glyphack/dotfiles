#!/usr/bin/env bash

set -euo pipefail

REPO="Glyphack/dotfiles"
DOTFILES="${DOTFILES:-$HOME/Programming/dotfiles}"
CLAY_REPO="Glyphack/clay"
CLAY_BIN="$HOME/.local/bin/clay"

install_clay() {
    local asset="clay-darwin-arm64"
    local url="https://github.com/$CLAY_REPO/releases/download/dev/$asset"
    local tmp
    tmp="$(mktemp -d)"
    curl -fL --progress-bar -o "$tmp/$asset" "$url"
    curl -fsSL -o "$tmp/$asset.sha256" "$url.sha256"
    (cd "$tmp" && shasum -a 256 -c "$asset.sha256")
    mkdir -p "$(dirname "$CLAY_BIN")"
    install -m 755 "$tmp/$asset" "$CLAY_BIN"
    rm -rf "$tmp"
    "$CLAY_BIN" --no-interactive --profile install-apps
}

clone_dotfiles() {
    if [[ -d "$DOTFILES" ]]; then
        return
    fi
    mkdir -p "$(dirname "$DOTFILES")"
    git clone "https://github.com/$REPO.git" "$DOTFILES"
}

connect_github() {
    eval "$(mise activate bash --shims)"
    if ! gh auth status >/dev/null 2>&1; then
        gh auth login --git-protocol ssh
    fi
    git -C "$DOTFILES" remote set-url origin "git@github.com:$REPO.git"
}

install_clay
eval "$(/opt/homebrew/bin/brew shellenv)"
clone_dotfiles
"$DOTFILES/scripts/setup.sh"
"$CLAY_BIN" --no-interactive --profile current-mac
connect_github
exec fish
