set -x VIMCONFIG $HOME/.config/nvim/
set -x VISUAL nvim
set -x PROGRAMMING_DIR ~/Programming
set --universal FZF_DEFAULT_COMMAND "fd --hidden"
set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -x FZF_ALT_C_COMMAND "fd -t d . $PROGRAMMING_DIR -d 3"
set -x NPM_PRE $HOME/.npm-global/bin
#
# # programming languages
set -x PYENV_ROOT $HOME/.pyenv
set -x POETRY $HOME/.poetry
set -x GOPATH $HOME/go
set -x GOBIN $GOPATH/bin
set -x RUST_HOME $HOME/.cargo/bin
#
# place for software I install
set -x HOME_BIN $HOME/bin

# kotlin language server

set -x KOTLIN_LANGUAGE_SERVER $HOME/Programming/kotlin-language-server/server/build/install/server/bin/


# Python
set -x VIRTUALFISH_ACTIVATION_FILE .venv

#os dependant
switch (uname)
    case Linux
        set -x VIMDATA ~/.local/share/nvim
    case '*'
        set -U fish_user_paths /opt/homebrew/bin/ $fish_user_paths
        set -x VIMDATA ~/.local/share/nvim
        set -x PATH $PATH  /usr/local/opt/fzf/bin /Applications/WezTerm.app/Contents/MacOS
        set -x JAVA_HOME /Library/Java/JavaVirtualMachines/amazon-corretto-19.jdk/Contents/Home
end

set -gx PATH $PATH $HOME_BIN $PYENV_ROOT/bin $GOBIN $RUST_HOME $JAVA_HOME/bin $HOME/.local/bin $HOME/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE $HOME_BIN/maelstrom $KOTLIN_LANGUAGE_SERVER


set -gx GITHUB_USERNAME shooshyari

# setting the default kube config
set -gx KUBECONFIG $HOME/.kube/config


starship init fish | source
# status is-login; and pyenv init --path | source
# status is-interactive; and pyenv init - | source
#
# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

function __check_rvm --on-variable PWD --description 'Do rvm stuff'
    if test "$PWD" != "$PROGRAMMING_DIR"
        return
    end
    rvm use 2.7
    nvm use 18.17.1 --silent
end

nvm use 20 --silent
__check_rvm

# function on_directory_change --on-event fish_prompt
#     # Check if the current directory is different from the previous one
#     if not set -q __prev_dir
#         set -g __prev_dir $PWD
#     else if test "$PWD" != "$__prev_dir"
#         echo "Directory changed: $__prev_dir -> $PWD"
#         set -g __prev_dir $PWD
#         # Add your custom actions here
#     end
# end
