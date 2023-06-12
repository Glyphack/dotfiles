set -U fish_greeting "fus ro dah"

set -x VISUAL nvim
set -x VIMCONFIG $HOME/.config/nvim/
set -x PROGRAMMING_DIR ~/Programming
set --universal FZF_DEFAULT_COMMAND "fd --hidden"
set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -x FZF_ALT_C_COMMAND "fd -t d . $PROGRAMMING_DIR"
set -x NPM_PRE $HOME/.npm-global/bin

# programming languages
set -x PYENV_ROOT $HOME/.pyenv
set -x POETRY $HOME/.poetry
set -x GOPATH $HOME/go

# place for software I install
set -x HOME_BIN $HOME/bin


# Python
set -x VIRTUALFISH_ACTIVATION_FILE .venv

#os dependant
switch (uname)
    case Linux
        set -x VIMDATA ~/.local/share/nvim
    case '*'
        set -x JAVA_HOME /opt/homebrew/Cellar/openjdk/20\x2e0\x2e1/libexec/openjdk\x2ejdk/Contents/Home
        set -U fish_user_paths /opt/homebrew/bin/ $fish_user_paths
        set -x VIMDATA ~/.local/share/nvim
        set -x PATH $PATH  /usr/local/opt/fzf/bin /Applications/WezTerm.app/Contents/MacOS
end

set -x PATH $PATH $HOME_BIN $PYENV_ROOT/bin $GOPATH/bin $JAVA_HOME $HOME/.local/bin $HOME/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE

starship init fish | source
status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source

# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

set -x GITHUB_USERNAME shooshyari

alias k="kubectl"
alias mpr="/Users/shooshyari/Programming/flexport/flexport/mpr"
alias dev="fx rdev"
