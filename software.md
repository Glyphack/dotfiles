## Manually Installed Software

- https://karabiner-elements.pqrs.org/
- https://brave.com/
- https://www.jetbrains.com/toolbox-app/
- https://getkap.co/
- https://go.dev/doc/install
- https://slack.com/downloads/instructions/mac
- https://aws.amazon.com/corretto
- https://github.com/ActivityWatch/activitywatch/releases
- https://sourceforge.net/p/gpgosx/docu/Download/
- https://www.docker.com/products/docker-desktop/
- https://obsidian.md/
- https://insomnia.rest/download
- https://iina.io/
- https://github.com/ActivityWatch/activitywatch/releases




## Homebrew

```
brew update
sh $(brew --prefix)/opt/fzf/install
brew install hammerspoon raycast wezterm gnupg pyenv neovim blackhole-16ch hugo fish bufbuild/buf/buf kotlin jq ripgrep fd gradle stow fzf sqlite openjdk graphviz gnuplot gh golangci-lint

brew tap homebrew/cask-fonts && brew install --cask font-Caskaydia-Cove-nerd-font font-Symbols-nerd-font
```


## Other

```
cd /tmp/
curl -sS https://starship.rs/install.sh | sh
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install jorgebucaran/nvm.fish
nvm install 16

curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg ./AWSCLIV2.pkg -target /

curl -LO https://corretto.aws/downloads/latest/amazon-corretto-17-aarch64-macos-jdk.pkg
curl -LO https://corretto.aws/downloads/latest/amazon-corretto-11-aarch64-macos-jdk.pkg

curl -sSL https://get.rvm.io | bash
rvm reinstall 2.7

echo /opt/homebrew/bin//fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin//fish

cargo install --locked zellij

```
