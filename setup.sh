#!/bin/bash

set -e

sudo softwareupdate --install-rosetta --agree-to-license

echo "settings"
sh ./bin/block-sites.sh
sh ./setup/mac-settings.sh

fish
