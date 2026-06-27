#!/bin/bash

set -e

sudo softwareupdate --install-rosetta --agree-to-license

echo "Setup fish"
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish


mise i

echo "settings"
sh ./setup/block-sites.sh
sh ./setup/mac-settings.sh

fish
