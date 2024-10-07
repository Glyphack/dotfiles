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
bind \ez "cd $HOME && echo $PWD"
#
# # programming languages
# set -x PYENV_ROOT $HOME/.pyenv
set -x POETRY $HOME/.poetry
set -x GOPATH $HOME/go
set -x GOBIN $GOPATH/bin
set -x RUST_HOME $HOME/.cargo/bin
set -x FLUTTER_BIN $HOME/flutter/bin
#
# place for software I install
set -x HOME_BIN $HOME/bin

# kotlin language server
set -x KOTLIN_LANGUAGE_SERVER $HOME/Programming/kotlin-language-server/server/build/install/server/bin/


# Python
set -x VIRTUALFISH_ACTIVATION_FILE .venv

#os dependent
switch (uname)
    case Linux
        set -x VIMDATA ~/.local/share/nvim
    case '*'
        set -U fish_user_paths /opt/homebrew/bin/ $fish_user_paths
        set -x VIMDATA ~/.local/share/nvim
        set -x PATH $PATH  /usr/local/opt/fzf/bin /Applications/WezTerm.app/Contents/MacOS
end

set -gx PATH $PATH $HOME_BIN $PYENV_ROOT/bin $GOBIN $RUST_HOME $FLUTTER_BIN $JAVA_HOME/bin $HOME/.local/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE $HOME_BIN/maelstrom $HOME/.rd/bin



# setting the default kube config
set -gx KUBECONFIG $HOME/.kube/config


starship init fish | source

alias prc="gh pr create --fill-first"
alias pro="gh pr view --web"
alias prr="bash $__fish_config_dir/functions/pr-review.sh $argv"
alias myprs="bash $__fish_config_dir/functions/myprs.sh $argv"
alias vim="nvim"
