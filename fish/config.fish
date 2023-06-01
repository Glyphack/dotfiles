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

set -x PATH $PATH $PYENV_ROOT/bin $GOPATH/bin $JAVA_HOME /Users/glyphack/.local/bin $HOME/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin $POETRY/bin $NPM_PRE

status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source

starship init fish | source

# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'


#os dependant
switch (uname)
    case Linux
        set -x VIMDATA ~/.local/share/nvim
    case '*'
        set -x VIMDATA ~/.local/share/nvim
        set -x PATH $PATH /Users/glyphack/Library/Application\ Support/Coursier/bin /usr/local/opt/fzf/bin /Applications/WezTerm.app/Contents/MacOS
        set -x JAVA_HOME $HOME/Library/Caches/Coursier/arc/https/github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_x64_mac_hotspot_8u292b10.tar.gz/jdk8u292-b10/Contents/Home
end
