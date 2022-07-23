set -U fish_greeting "fus ro dah"

status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source

starship init fish | source

set -x PYENV_ROOT $HOME/.pyenv
set -x GOPATH $HOME/go
set -gx NVM_DIR $HOME/.nvm
set --universal FZF_DEFAULT_COMMAND fd

set -x PATH $PATH $PYENV_ROOT/bin $GOPATH/bin $NVM_DIR /Users/glyphack/Library/Python/3.9/bin /Users/glyphack/.local/bin /Users/glyphack/opt/anaconda3/bin /Users/glyphack/opt/anaconda3/condabin /Users/glyphack/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin /usr/local/Cellar/openvpn/2.5.5/sbin

# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'
