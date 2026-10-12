#!/usr/bin/env bash

HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --cleanup --file=~/Programming/dotfiles/Brewfile
(cd "$DOTFILES_DIR/obsidian" && npm audit fix --force)
