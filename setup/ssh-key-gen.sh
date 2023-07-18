#!/usr/bin/env bash

read email

ssh-keygen -t ed25519 -f ~/.ssh/id_${email}_ed25519
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_${email}_ed25519
pbcopy < ~/.ssh/id_${email}_ed25519.pub


