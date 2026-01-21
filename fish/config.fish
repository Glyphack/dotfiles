set -x VIMCONFIG $HOME/.config/nvim/
set -x VISUAL nvim
set -x PROGRAMMING_DIR ~/Programming
set -x DOTFILES_DIR ~/Programming/dotfiles
set -x FZF_DEFAULT_COMMAND "fd --hidden"
set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -x FZF_ALT_C_COMMAND "fd -t d . $PROGRAMMING_DIR -d 3"
set -x NPM_PRE $HOME/.npm-global/bin
set -x RIPGREP_CONFIG_PATH $HOME/.ripgreprc

fzf --fish | source

bind \ex "cd (fd -t d . $HOME -d 5 --hidden | fzf)"
bind \ez "cd $HOME; commandline -f repaint"
# because of fish vi bindings. Emacs bindings are disabled.
bind -M insert \cf accept-autosuggestion

# programming languages
set -x POETRY $HOME/.poetry
set -x GOPATH $HOME/go
set -x GOBIN $GOPATH/bin
set -x RUST_HOME $HOME/.cargo/bin

if test -d "$HOME/flutter"
    set -x FLUTTER_PATH $HOME/flutter/bin
else
    set -x FLUTTER_PATH /Users/Shared/flutter/bin
end
set -x VIRTUALFISH_ACTIVATION_FILE .venv


# place for software I install
set -x HOME_BIN $HOME/bin
# setting the default kube config
set -gx KUBECONFIG $HOME/.kube/config

set -x VIMDATA ~/.local/share/nvim
fish_add_path "$HOME/.rd/bin" "/opt/homebrew/bin" "$HOME_BIN" "$scripts" "$PYENV_ROOT/bin" "$GOBIN" "$RUST_HOME" "$FLUTTER_PATH" "$JAVA_HOME/bin" "$HOME/.local/bin" "$POETRY/bin" "$NPM_PRE" "$HOME_BIN/maelstrom" "/opt/homebrew/opt/llvm/bin" "$HOME/flutter/flutter/bin" "$HOME/.gem/bin" "/usr/local/opt/fzf/bin" "/Applications/WezTerm.app/Contents/MacOS" "/usr/local/go/bin" "/usr/local/bin" "/usr/bin" "/bin" "/usr/sbin" "/sbin"

starship init fish | source

fish_hybrid_key_bindings


if test -e ~/Programming/dotfiles/dotfiles-private/personal.fish
    source ~/Programming/dotfiles/dotfiles-private/personal.fish
end

function pre_command --on-event fish_preexec
    printf '\033]133;A\033\\'
end

function some_setup --on-variable PWD
    if test -e "$PWD/poetry.lock"
	eval (poetry env activate)
    end

    if test -d "$PWD/.venv"
	source "$PWD/.venv/bin/activate.fish"
    end
end
some_setup

source "$__fish_config_dir/aliases.fish"

## Development
set -x tyty $HOME/Programming/ruff/target/debug/ty

set -x scripts $HOME/Programming/dotfiles/scripts

function __command_notification --on-event fish_postexec
    if not test $CMD_DURATION
      return
    end
    set duration (echo "$CMD_DURATION 1000" | awk '{printf "%.3fs", $1 / $2}')
    set exclude_cmd "bash|less|man|more|ssh|vim|f"
    if test $CMD_DURATION -lt 10000; or echo $argv[1] | grep -qE "^($exclude_cmd).*"
      return
    end
      set cmd_title (string replace -a '"' '\\"' -- $argv[1])
      fish -c "osascript -e 'display notification \"Finished in $duration\" with title \"$cmd_title\" sound name \"Glass\"'; sleep 10; osascript -e 'tell application \"System Events\" to tell process \"NotificationCenter\" to perform action \"AXCancel\" of last item of (windows whose subrole is \"AXNotificationCenterAlert\")' 2>/dev/null" &
end

function cpf --description "Copy file to clipboard (not content)"
    osascript -e "set the clipboard to (POSIX file \"$PWD/$argv\")"
end

function pf --description "Paste file from clipboard to current directory"
    osascript -e 'on run args' \
              -e 'tell application "Finder"' \
              -e 'set clipboardItems to (the clipboard as «class furl»)' \
              -e 'set destinationFolder to POSIX file (item 1 of args) as alias' \
              -e 'duplicate clipboardItems to destinationFolder' \
              -e 'end tell' \
              -e 'end run' \
              "$PWD"
end

# Amp CLI
export PATH="/Users/shayeganhooshyari/.amp/bin:$PATH"
