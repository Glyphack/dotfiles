set -gx VIMCONFIG $HOME/.config/nvim/
set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx PROGRAMMING_DIR ~/Programming
set -gx DOTFILES_DIR ~/Programming/dotfiles
set -gx WORKTREES_DIR $PROGRAMMING_DIR/wk
set -gx FZF_DEFAULT_COMMAND "fd --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "\
fd -t d . $PROGRAMMING_DIR -d 1 -E wk; \
fd -t d . $HOME/Work -d 1 2>/dev/null; \
fd -t d . $WORKTREES_DIR -d 1 2>/dev/null; \
echo $HOME/Downloads\n
echo $HOME/Documents\n
echo $HOME/Movies\n
echo $HOME/Work
"
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
set -gx JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
set -gx NDK_HOME "$ANDROID_HOME/ndk/30.0.14904198"


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
    "/Applications/Obsidian.app/Contents/MacOS" \
    "$ANDROID_HOME/emulator" \
    "$ANDROID_HOME/platform-tools"


if test -f ~/Programming/dotfiles/local.fish
    source ~/Programming/dotfiles/local.fish
end

if status is-interactive
    fzf --fish | source

    if type -q direnv
        direnv hook fish | source
    end

    bind -M insert \cf accept-autosuggestion
    
    if type -q fish_hybrid_key_bindings
        fish_hybrid_key_bindings
    end

    on_pwd

    if test -f "$__fish_config_dir/aliases.fish"
        source "$__fish_config_dir/aliases.fish"
    end
    bind -M insert \cf accept-autosuggestion

end

function vm
    set gh_token (gh auth token)

    set vibe_args \
        --mount $HOME/Programming/dotfiles/gitconf/:/root/git_conf \
        --mount $HOME/Programming/dotfiles/agent/:$HOME/Programming/dotfiles/agent/ \
        --mount $HOME/.config/gh/:/root/.config/gh/

    set git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test -n "$git_common_dir" && test "$git_common_dir" != ".git"
        set -a vibe_args --mount $git_common_dir:$git_common_dir
    end

    command vibe \
        $vibe_args \
        --send "export GH_TOKEN='$gh_token';export CLAUDE_CONFIG_DIR='/root/.claude/';alias claude='claude --dangerously-skip-permissions';umount .git;echo vibe_send_done" \
        --expect "vibe_send_done" \
        --script ~/Programming/dotfiles/scripts/vibe-config.sh \
        --expect "vibe_setup_done"
end
