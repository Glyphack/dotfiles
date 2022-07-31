link:
	stow --target=${HOME}/.config/fish fish
	stow --target=${HOME}/Programming/datachef datachef 
	mkdir -p ${HOME}/.config/obs-studio && stow --target=${HOME}/.config/obs-studio obs-studio
	mkdir -p ${HOME}/.config/obsidian && stow --target=${HOME}/.config/obsidian obsidian
	stow gitconf

