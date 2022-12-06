MacAppLib := /Users/glyphack/Library/Application\ Support

link:
	stow --target=${HOME}/.config/fish fish
	stow --target=${HOME}/Programming/datachef datachef
	mkdir -p ${HOME}/.config/nvim && stow --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.local/share/nvim && stow --target=${HOME}/.local/share/nvim nvim-data
	mkdir -p ${HOME}/.config/fd && stow --target=${HOME}/.config/fd fd
	mkdir -p ${HOME}/.config/lvim && stow --target=${HOME}/.config/lvim lvim
	stow --target=${HOME}/.config starship
	stow gitconf

link-mac:
	stow --adopt --target=${HOME}/.config/fish fish
	stow --adopt --target=${HOME}/Programming/datachef datachef
	stow --adopt --target=${HOME}/.config starship
	stow --adopt --target=${HOME}/Programming/brenntag brenntag
	stow --target=${HOME} gitconf
	mkdir -p ${HOME}/.config/nvim && stow --adopt --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.config/fd && stow --adopt --target=${HOME}/.config/fd fd
	mkdir -p ${HOME}/.config/lvim && stow --target=${HOME}/.config/lvim lvim


