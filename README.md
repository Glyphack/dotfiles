## Dotfiles

My personal dotfiles to install and configure [software I use](./software.md).

## Installation

Install brew apps

```
mkdir -p ~/Programming/ && cd ~/Programming
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone https://github.com/Glyphack/dotfiles.git
cd dotfiles/
sh setup.sh
gh auth login
git remote set-url origin git@github.com/glyphack/dotfiles
```
