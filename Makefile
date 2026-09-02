.PHONY: link

-include local.mk

link::
	mkdir -p ${HOME}/.config/fish && stow --adopt --target=${HOME}/.config/fish fish
	stow --target=${HOME} gitconf
	stow --target=${HOME} ripgrep
	stow --target=${HOME} zsh
	mkdir -p ${HOME}/.config/nvim && stow --adopt --target=${HOME}/.config/nvim nvim
	mkdir -p ${HOME}/.config/mise && stow --adopt --target=${HOME}/.config/mise mise
	mkdir -p ${HOME}/.config/fd && stow --adopt --target=${HOME}/.config/fd fd
	python3 karabiner/karabiner_generate.py
	[ "$$(readlink ${HOME}/.config/karabiner)" = "${CURDIR}/karabiner" ] || { \
		mkdir -p ${HOME}/.config && rm -rf ${HOME}/.config/karabiner && ln -s ${CURDIR}/karabiner ${HOME}/.config/karabiner && \
		{ launchctl kickstart -k gui/$$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server || true; }; }
	mkdir -p ${HOME}/.config/wezterm && stow --adopt --target=${HOME}/.config/wezterm wezterm
	mkdir -p ${HOME}/.hammerspoon && stow --adopt --target=${HOME}/.hammerspoon hammerspoon
	mkdir -p ${HOME}/.qutebrowser/ && stow --adopt --target=${HOME}/.qutebrowser/ qutebrowser
	mkdir -p ${HOME}/Library/Application\ Support/harper-ls/ && stow --adopt --target=${HOME}/Library/Application\ Support/harper-ls harper-ls
	cd obsidian && VAULT="$$(/opt/homebrew/bin/fish -lc 'echo $$vault')" npm run install-vault
