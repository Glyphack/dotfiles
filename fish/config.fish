set -gx VIMCONFIG $HOME/.config/nvim/
set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx PROGRAMMING_DIR ~/Programming
set -gx DOTFILES_DIR ~/Programming/dotfiles
set -gx FZF_DEFAULT_COMMAND "fd --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd -t d . $PROGRAMMING_DIR -d 3"
set -gx NPM_PRE $HOME/.npm-global/bin
set -gx RIPGREP_CONFIG_PATH $HOME/.ripgreprc
set -gx POETRY $HOME/.poetry
set -gx GOPATH $HOME/go
set -gx GOBIN $GOPATH/bin
set -gx RUST_HOME $HOME/.cargo/bin
set -gx VIMDATA ~/.local/share/nvim
set -gx KUBECONFIG $HOME/.kube/config
set -gx VIRTUALFISH_ACTIVATION_FILE .venv
set -gx HOME_BIN $HOME/bin
set -gx scripts $HOME/Programming/dotfiles/scripts
set -gx tyty $HOME/Programming/ruff/target/debug/ty

if test -d "$HOME/flutter"
    set -gx FLUTTER_PATH $HOME/flutter/bin
else
    set -gx FLUTTER_PATH /Users/Shared/flutter/bin
end

fish_add_path -g "$HOME/.rd/bin" \
    "/opt/homebrew/bin" \
    "$HOME_BIN" \
    "$scripts" \
    "$PYENV_ROOT/bin" \
    "$GOBIN" \
    "$RUST_HOME" \
    "$FLUTTER_PATH" \
    "$JAVA_HOME/bin" \
    "$HOME/.local/bin" \
    "$POETRY/bin" \
    "$NPM_PRE" \
    "$HOME_BIN/maelstrom" \
    "/opt/homebrew/opt/llvm/bin" \
    "$HOME/flutter/flutter/bin" \
    "$HOME/.gem/bin" \
    "/usr/local/opt/fzf/bin" \
    "/Applications/WezTerm.app/Contents/MacOS" \
    "/usr/local/go/bin" \
    "/usr/local/bin" \
    "/usr/bin" \
    "/bin" \
    "/usr/sbin" \
    "/sbin" \
    "$HOME/.amp/bin"

if status is-interactive
    fzf --fish | source
    starship init fish | source

    # Key Bindings
    bind \ex "cd (fd -t d . $HOME -d 5 --hidden | fzf)"
    bind \ez "cd $HOME; commandline -f repaint"
    bind -M insert \cf accept-autosuggestion
    
    if type -q fish_hybrid_key_bindings
        fish_hybrid_key_bindings
    end

    some_setup

    if test -f "$__fish_config_dir/aliases.fish"
        source "$__fish_config_dir/aliases.fish"
    end

    if test -f ~/Programming/dotfiles/dotfiles-private/personal.fish
        source ~/Programming/dotfiles/dotfiles-private/personal.fish
    end
end
