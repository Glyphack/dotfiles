MacAppLib := /Users/glyphack/Library/Application\ Support

link:
	stow --target=${HOME}/.config/fish fish
	stow --target=${HOME}/Programming/datachef datachef
	mkdir -p ${HOME}/.config/nvim && stow --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.local/share/nvim && stow --target=${HOME}/.local/share/nvim nvim-data
	stow gitconf

link-mac:
	stow --target=${HOME}/.config/fish fish
	stow --target=${HOME}/Programming/datachef datachef
	mkdir -p ${HOME}/.config/nvim && stow --target=${HOME}/.config/nvim nvim
	stow gitconf

