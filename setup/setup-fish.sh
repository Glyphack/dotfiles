chsh -s /opt/homebrew/bin/fish
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
fisher update
