MacAppLib := /Users/glyphack/Library/Application\ Support

link:
	stow --target=${HOME}/.config/fish fish
	mkdir -p ${HOME}/.config/nvim && stow --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.local/share/nvim && stow --target=${HOME}/.local/share/nvim nvim-data
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.config/fd && stow --target=${HOME}/.config/fd fd
	stow --target=${HOME}/.config starship
	stow --target=${HOME} gitconf

link-mac:
	stow --adopt --target=${HOME}/.config/fish fish
	stow --adopt --target=${HOME}/.config starship
	stow --target=${HOME} gitconf
	mkdir -p ${HOME}/.config/nvim && stow --adopt --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.config/fd && stow --adopt --target=${HOME}/.config/fd fd
	mkdir -p ${HOME}/.config/karabiner && stow --adopt --target=${HOME}/.config/karabiner karabiner
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.hammerspoon && stow --adopt --target=${HOME}/.hammerspoon hammerspoon

