#!/bin/bash

set -e

sudo softwareupdate --install-rosetta --agree-to-license

echo "Setup fish"
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish


echo "Languages setup"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
mkdir -p ~/.virtualenvs/

mise i

echo "settings"
sh ./setup/block-sites.sh
sh ./setup/mac-settings.sh

echo "tools"

playwright install --with-deps chromium

fish
