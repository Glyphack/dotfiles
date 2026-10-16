#!/usr/bin/env bash
#
# Sets up this Mac from the dotfiles.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
LOCAL_SETUP="${LOCAL_SETUP:-$DOTFILES/setup.local.sh}"

install_packages() {
    local output
    if ! output="$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --quiet --file=Brewfile 2>&1)"; then
        echo "$output"
        echo "Some Brewfile packages failed to install, continuing the setup."
    fi
}

run_local_setup() {
    if [[ ! -x "$LOCAL_SETUP" ]]; then
        return
    fi
    "$LOCAL_SETUP"
}

stow_into() {
    local target="$1" package="$2" file
    mkdir -p "$target"
    for file in $(stow -n --target="$target" "$package" 2>&1 | sed -n 's/.*existing target \(.*\) since.*/\1/p'); do
        mv "$target/$file" "$target/$file.bak"
        echo "Backed up $target/$file to $target/$file.bak"
    done
    stow --ignore='\.DS_Store' --target="$target" "$package"
}

link_dir() {
    local source="$1"
    local target="$2"
    if [[ -d "$target" && ! -L "$target" ]]; then
        mv "$target" "$target.bak"
        echo "Backed up $target to $target.bak"
    fi
    ln -sfn "$source" "$target"
}

link() {
    run_local_setup

    mkdir -p "$HOME/.config"
    link_dir "$DOTFILES/fish" "$HOME/.config/fish"
    link_dir "$DOTFILES/wezterm" "$HOME/.config/wezterm"
    link_dir "$DOTFILES/mise" "$HOME/.config/mise"
    link_dir  "$DOTFILES/hammerspoon" "$HOME/.hammerspoon"
    # These use stow cause the whole folder is not supposed to be synced
    stow_into "$HOME" gitconf
    stow_into "$HOME" ripgrep
    stow_into "$HOME" zsh
    stow_into "$HOME/.config/nvim" nvim
    stow_into "$HOME/.config/fd" fd
    stow_into "$HOME/.qutebrowser" qutebrowser
    stow_into "$HOME/Library/Application Support/harper-ls" harper-ls
}

# Installs the tools listed in the mise config and puts them on PATH.
install_tools() {
    mise install
    eval "$(mise activate bash --shims)"
}

build_karabiner() {
    link_dir "$DOTFILES/karabiner/config" "$HOME/.config/karabiner"
    uv run karabiner/build.py
    launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server" || true
}

# Installs the Obsidian plugin into the vault set by the fish config.
install_vault_plugin() {
    local vault
    vault="$(fish -lc 'echo $vault')"
    if [[ -z "$vault" ]]; then
        echo "Skipping the Obsidian plugin because vault is not set."
        return
    fi
    local output
    if ! output="$(cd obsidian && vault="$vault" npm run install-vault 2>&1)"; then
        echo "$output"
        return 1
    fi
    echo "Installed the Obsidian plugin into $vault."
}

cd "$DOTFILES"
install_packages
bash scripts/mac-settings.sh
link
install_tools
build_karabiner
install_vault_plugin
