set -x VIMCONFIG $HOME/.config/nvim/
set -x VISUAL nvim
set -x PROGRAMMING_DIR ~/Programming
set -x DOTFILES_DIR ~/Programming/dotfiles
set --universal FZF_DEFAULT_COMMAND "fd --hidden"
set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -x FZF_ALT_C_COMMAND "fd -t d . $PROGRAMMING_DIR -d 3"
set -x NPM_PRE $HOME/.npm-global/bin
set -x RIPGREP_CONFIG_PATH $HOME/.ripgreprc

fzf --fish | source

bind \ex "cd (fd -t d . $HOME -d 5 --hidden | fzf)"
bind \ez "cd $HOME; commandline -f repaint"

# programming languages
set -x POETRY $HOME/.poetry
set -x GOPATH $HOME/go
set -x GOBIN $GOPATH/bin
set -x RUST_HOME $HOME/.cargo/bin
set -x FLUTTER_BIN $HOME/flutter/bin
set -x VIRTUALFISH_ACTIVATION_FILE .venv

# place for software I install
set -x HOME_BIN $HOME/bin
# setting the default kube config
set -gx KUBECONFIG $HOME/.kube/config


#os dependent
switch (uname)
    case Linux
        set -x VIMDATA ~/.local/share/nvim
    case '*'
        fish_add_path -U /opt/homebrew/bin
        set -x VIMDATA ~/.local/share/nvim
        set -x PATH $PATH /usr/local/opt/fzf/bin /Applications/WezTerm.app/Contents/MacOS
        set --export --prepend PATH "$HOME/.rd/bin"
end

set -gx PATH $PATH $HOME_BIN $PYENV_ROOT/bin $GOBIN $RUST_HOME $FLUTTER_BIN $JAVA_HOME/bin $HOME/.local/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE $HOME_BIN/maelstrom $HOME/.rd/bin /opt/homebrew/opt/llvm/bin

starship init fish | source

# Git 
alias prc="gh pr create --fill-first"
alias pro="gh pr view --web"
alias forks="git fetch upstream && git reset --hard upstream/main"

alias prr="bash $__fish_config_dir/functions/pr-review.sh $argv"
alias myprs="bash $__fish_config_dir/functions/myprs.sh $argv"
alias vim="nvim"

set -x fish_vi_key_bindings

if test -f ~/Programming/dotfiles/dotfiles-private/personal.fish
    source ~/Programming/dotfiles/dotfiles-private/personal.fish
end

function pre_command --on-event fish_preexec
    printf '\033]133;A\033\\'
end

function some_setup --on-variable PWD 
    if test -d "$PWD/.venv"
        source "$PWD/.venv/bin/activate.fish"
    end
end

if test -d "$PWD/.venv"
    source "$PWD/.venv/bin/activate.fish"
end
