set -x VIMCONFIG $HOME/.config/nvim/
set -x VISUAL nvim
set -x PROGRAMMING_DIR ~/Programming
set --universal FZF_DEFAULT_COMMAND "fd --hidden"
set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -x FZF_ALT_C_COMMAND "fd -t d . $PROGRAMMING_DIR"
set -x NPM_PRE $HOME/.npm-global/bin
#
# # programming languages
set -x PYENV_ROOT $HOME/.pyenv
set -x POETRY $HOME/.poetry
set -x GOPATH $HOME/go
set -x RUST_HOME $HOME/.cargo/bin
#
# # place for software I install
set -x HOME_BIN $HOME/bin


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

set -gx PATH $PATH $HOME_BIN $PYENV_ROOT/bin $GOPATH/bin $RUST_HOME $JAVA_HOME $HOME/.local/bin $HOME/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE


set -gx GITHUB_USERNAME shooshyari


starship init fish | source
# status is-login; and pyenv init --path | source
# status is-interactive; and pyenv init - | source
#
# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

function __nvm_auto --on-variable PWD
  nvm use --silent 2>/dev/null
end
__nvm_auto

function __rvm_auto --on-variable PWD
  rvm default
end

# __rvm_auto
rvm default
