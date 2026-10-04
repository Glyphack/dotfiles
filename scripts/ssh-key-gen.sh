#!/bin/bash

set -e

# Prompt for email
read -p "Enter email: " email

# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_${email}_ed25519

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to SSH agent and Apple keychain
ssh-add --apple-use-keychain ~/.ssh/id_${email}_ed25519

# Uploading keys needs the admin:public_key scope on the gh token
if ! gh auth status 2>&1 | grep -q "admin:public_key"; then
    gh auth refresh -h github.com -s admin:public_key
fi

# Upload public key to GitHub, titled with this Mac's name
gh ssh-key add ~/.ssh/id_${email}_ed25519.pub --title "$(scutil --get ComputerName)"

# Check if ~/.ssh/config exists
if [ ! -f ~/.ssh/config ]; then
    echo "Creating ~/.ssh/config file..."
    touch ~/.ssh/config
else
    echo "~/.ssh/config file already exists."
fi

# Add or update GitHub configuration in ~/.ssh/config
if grep -q "Host github.com" ~/.ssh/config; then
    echo "Updating existing GitHub configuration in ~/.ssh/config..."
    sed -i '' '/Host github.com/,/IdentityFile/c\
Host github.com\
  AddKeysToAgent yes\
  UseKeychain yes\
  IdentityFile ~/.ssh/id_'"${email}"'_ed25519
' ~/.ssh/config
else
    echo "Adding GitHub configuration to ~/.ssh/config..."
    echo "
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_${email}_ed25519
" >> ~/.ssh/config
fi

echo "SSH key setup complete. The public key has been added to your GitHub account."
