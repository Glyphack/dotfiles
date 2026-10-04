set -gx VIMCONFIG $HOME/.config/nvim/
set -gx VISUAL nvim
set -gx EDITOR nvim

# Personal
set -gx PROGRAMMING_DIR ~/Programming
set -gx DOTFILES_DIR ~/Programming/dotfiles
set -gx WORKTREES_DIR $PROGRAMMING_DIR/wk

# Tools
set -gx GOPATH $HOME/go
set -gx GOBIN $GOPATH/bin
set -gx RUST_HOME $HOME/.cargo/bin
set -gx VIMDATA ~/.local/share/nvim
set -gx KUBECONFIG $HOME/.kube/config
set -gx HOME_BIN $HOME/bin
set -gx DOTFILES_BIN $DOTFILES_DIR/bin
set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
set -gx NDK_HOME "$ANDROID_HOME/ndk/30.0.14904198"
if test -d "$HOME/flutter"
    set -gx FLUTTER_PATH $HOME/flutter/bin
else
    set -gx FLUTTER_PATH /Users/Shared/flutter/bin
end
set -gx BREWFILE_PATH "$HOME/Programming/dotfiles/Brewfile"

fish_add_path -g "$HOME/.rd/bin" \
    "/opt/homebrew/bin" \
    "$HOME_BIN" \
    "$DOTFILES_BIN" \
    "$PYENV_ROOT/bin" \
    "$GOBIN" \
    "$RUST_HOME" \
    "$FLUTTER_PATH" \
    "$HOME/.local/bin" \
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
    "/Applications/Obsidian.app/Contents/MacOS" \
    "$ANDROID_HOME/emulator" \
    "$ANDROID_HOME/platform-tools"

# Every executable in the dotfiles bin folder can be run by its name without
# the file extension, so bin/hue-on.sh runs as hue-on.
for script in $DOTFILES_BIN/*
    if not test -f $script; or not test -x $script
        continue
    end
    function (path change-extension '' (path basename $script)) --inherit-variable script
        $script $argv
    end
end

# I can quickly jump to my useful directories
set -gx FZF_DEFAULT_COMMAND "fd --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "\
fd -t d . $PROGRAMMING_DIR -d 1 -E wk; \
fd -t d . $HOME/Work -d 1 2>/dev/null; \
fd -t d . $WORKTREES_DIR -d 1 2>/dev/null; \
echo $HOME/Downloads\n$HOME/Documents\n$HOME/Movies\n$HOME/Work\n$HOME/Programming
"

if test -f ~/Programming/dotfiles/local.fish
    source ~/Programming/dotfiles/local.fish
end

source "$__fish_config_dir/aliases.fish"

if status is-interactive
    fzf --fish | source

    if type -q fish_hybrid_key_bindings
        fish_hybrid_key_bindings
    end
    bind -M insert \cf accept-autosuggestion
    bind -M insert \cf accept-autosuggestion

end

eval "$(/opt/homebrew/bin/brew shellenv fish)"
