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

# Git
alias prc="gh pr create --fill-first && prr"
alias pro="gh pr view --web"
alias forks="git fetch upstream && git reset --hard upstream/main"

alias prr="bash $__fish_config_dir/functions/pr-review.sh $argv"
alias myprs="bash $__fish_config_dir/functions/myprs.sh $argv"
alias gcmp="bash $__fish_config_dir/functions/gcmp.sh $argv"
alias vim="nvim"

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

function fish_right_prompt
    if test $CMD_DURATION
        # Show duration of the last command
        set duration (echo "$CMD_DURATION 1000" | awk '{printf "%.3fs", $1 / $2}')
        # OS X notification when a command takes longer than notify_duration
        set notify_duration 10000
        set exclude_cmd "bash|less|man|more|ssh"
        if begin
                test $CMD_DURATION -gt $notify_duration
                and echo $history[1] | grep -vqE "^($exclude_cmd).*"
            end
            # Only show the notification if iTerm is not focused
            echo "
                tell application \"System Events\"
		    display notification \"Finished in $duration\" with title \"$history[1]\"
                end tell
                " | osascript
        end
    end
end
