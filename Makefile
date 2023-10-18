MacAppLib := /Users/glyphack/Library/Application\ Support

link:
	echo "outdated"
	stow --target=${HOME}/.config/fish fish
	mkdir -p ${HOME}/.config/nvim && stow --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.local/share/nvim && stow --target=${HOME}/.local/share/nvim nvim-data
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.config/fd && stow --target=${HOME}/.config/fd fd
	stow --target=${HOME}/.config starship
	stow --target=${HOME} gitconf

link-mac:
	git submodule update --remote --recursive
	mkdir -p ${HOME}/.config/fish && stow --adopt --target=${HOME}/.config/fish fish
	mkdir -p ${HOME}/.config/starship && stow --adopt --target=${HOME}/.config starship
	stow --target=${HOME} gitconf
	mkdir -p ${HOME}/.config/nvim && stow --adopt --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.config/fd && stow --adopt --target=${HOME}/.config/fd fd
	mkdir -p ${HOME}/.config/karabiner && stow --adopt --target=${HOME}/.config/karabiner karabiner
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.hammerspoon && stow --adopt --target=${HOME}/.hammerspoon hammerspoon
	mkdir -p ${HOME}/Library/Application\ Support/espanso/ && stow --adopt --target=${HOME}/Library/Application\ Support/espanso/ espanso
	cd ./dotfiles-private/ && $(MAKE) link
	cd ./dotfiles-flexport/ && $(MAKE) link
	# to load new changes
	espanso restart

submodule:
	git submodule update --remote --recursive

# write a command to add and commit all the changes in the dotfiles-private and dotfiles-flexport folders. And update the submodule
commit-private:
	cd ./dotfiles-private/ && git stash && git checkout master && git stash pop && git add . && git commit -m "update dotfiles" && git push
	git submodule update --remote --recursive
	git add dotfiles-private dotfiles-flexport
	git commit -m "private update"
	git push

commit-work:
	cd ./dotfiles-flexport/ && git stash && git checkout master && git stash pop && git add . && git commit -m "update dotfiles" && git push
	git submodule update --remote --recursive
	git add dotfiles-flexport
	git commit -m "work update"
	git push

