link:
	echo "outdated"
	stow --target=${HOME}/.config/fish fish
	mkdir -p ${HOME}/.config/nvim && stow --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.local/share/nvim && stow --target=${HOME}/.local/share/nvim nvim-data
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.config/fd && stow --target=${HOME}/.config/fd fd
	stow --target=${HOME}/.config starship
	stow --target=${HOME} gitconf

link-personal:
	git submodule update --init dotfiles-private
	git submodule update --remote dotfiles-private
	mkdir -p ${HOME}/.config/fish && stow --adopt --target=${HOME}/.config/fish fish
	mkdir -p ${HOME}/.config/starship && stow --adopt --target=${HOME}/.config starship
	stow --target=${HOME} gitconf
	stow --target=${HOME} asdf
	stow --target=${HOME} ripgrep
	mkdir -p ${HOME}/.config/nvim && stow --adopt --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.config/fd && stow --adopt --target=${HOME}/.config/fd fd
	mkdir -p ${HOME}/.config/karabiner && stow --adopt --target=${HOME}/.config/karabiner karabiner
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.hammerspoon && stow --adopt --target=${HOME}/.hammerspoon hammerspoon
	mkdir -p ${HOME}/Library/Application\ Support/espanso/ && stow --adopt --target=${HOME}/Library/Application\ Support/espanso/ espanso
	cd ./dotfiles-private/ && $(MAKE) link
	# to load new changes
	espanso restart
