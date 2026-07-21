## Dotfiles

My personal dotfiles to install and configure software I use.
Anything I use is configured here.

## Installation

```bash
mkdir -p ~/Programming/ && cd ~/Programming
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone https://github.com/Glyphack/dotfiles.git
cd dotfiles/
sh setup.sh
gh auth login
git remote set-url origin git@github.com/glyphack/dotfiles
```

## Secrets

I store secrets in apple key chain.

```
security add-generic-password -a "myaccount" -s "myservice" -w "mysecret"
```
