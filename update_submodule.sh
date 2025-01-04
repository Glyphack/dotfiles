#!/bin/bash

# Navigate to the submodule directory
cd dotfiles-private || exit

# Stage all changes
git add .

# Commit changes with the message "update"
git commit -m "update"

# Push changes to the remote repository
git push

# Return to the main repository directory
cd ..

# Update the submodule in the main repository
git submodule update --remote dotfiles-private

# Stage the submodule changes in the main repository
git add dotfiles-private

# Commit the submodule update in the main repository
git commit -m "update"

