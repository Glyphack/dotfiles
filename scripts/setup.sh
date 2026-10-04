#!/usr/bin/env bash
#
# Sets up this Mac from the dotfiles.
#
# Linking first runs setup.local.sh in the dotfiles folder when it exists.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

install_packages() {
    brew bundle install --file=Brewfile
}

apply_settings() {
    bash bin/block-sites.sh block
    bash scripts/mac-settings.sh
}

run_local_setup() {
    if [[ ! -x setup.local.sh ]]; then
        return
    fi
    ./setup.local.sh
}

# Links a package into a target folder, creating the folder first and
# moving any existing files in the target into the package.
stow_into() {
    local target="$1"
    local package="$2"
    mkdir -p "$target"
    stow --adopt --target="$target" "$package"
}

link() {
    run_local_setup

    mkdir -p "$HOME/.config"
    ln -sfn "$DOTFILES/fish" "$HOME/.config/fish"
    ln -sfn "$DOTFILES/wezterm" "$HOME/.config/wezterm"
    stow_into "$HOME" gitconf
    stow_into "$HOME" ripgrep
    stow_into "$HOME" zsh
    stow_into "$HOME/.config/nvim" nvim
    stow_into "$HOME/.config/mise" mise
    stow_into "$HOME/.config/fd" fd
    stow_into "$HOME/.hammerspoon" hammerspoon
    stow_into "$HOME/.qutebrowser" qutebrowser
    stow_into "$HOME/Library/Application Support/harper-ls" harper-ls
}

# Installs the tools listed in the mise config and puts them on PATH.
install_tools() {
    mise install
    eval "$(mise activate bash --shims)"
}

build_karabiner() {
    uv run karabiner/build.py
    ln -sfn "$DOTFILES/karabiner/config" "$HOME/.config/karabiner"
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
    (cd obsidian && vault="$vault" npm run install-vault)
}

cd "$DOTFILES"
install_packages
apply_settings
link
install_tools
build_karabiner
install_vault_plugin
