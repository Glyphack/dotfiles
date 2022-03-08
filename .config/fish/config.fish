set -U fish_greeting "fus ro dah"

if status is-interactive
    # Base16 Shell
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
end
status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source

starship init fish | source

set -x PYENV_ROOT $HOME/.pyenv
set -x GOPATH $HOME/go
set -gx NVM_DIR $HOME/.nvm
set --universal FZF_DEFAULT_COMMAND fd

set -x PATH $PATH $PYENV_ROOT/bin $GOPATH/bin $NVM_DIR /Users/glyphack/Library/Python/3.9/bin /Users/glyphack/.local/bin /Users/glyphack/opt/anaconda3/bin /Users/glyphack/opt/anaconda3/condabin /Users/glyphack/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin /usr/local/Cellar/openvpn/2.5.5/sbin

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# eval /Users/glyphack/opt/anaconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

alias assume="source /usr/local/bin/assume.fish"
