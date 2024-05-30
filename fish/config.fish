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

set -gx PATH $PATH $HOME_BIN $PYENV_ROOT/bin $GOBIN $RUST_HOME $FLUTTER_BIN $JAVA_HOME/bin $HOME/.local/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE $HOME_BIN/maelstrom


# setting the default kube config
set -gx KUBECONFIG $HOME/.kube/config


starship init fish | source
# status is-login; and pyenv init --path | source
# status is-interactive; and pyenv init - | source
#
# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
# complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# if test -f ~/miniconda3/bin/conda
#     eval ~/miniconda3/bin/conda "shell.fish" "hook" $argv | source
# else
#     if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
#         . "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
#     else
#         set -x PATH "$HOME/miniconda3/bin" $PATH
#     end
# end
# <<< conda initialize <<<
