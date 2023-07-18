#!/usr/bin/env bash

ssh-keygen -t ed25519 -C "sh.hooshyari@gmail.com"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub