set -U fish_greeting "fus ro dah"

set -x PYENV_ROOT $HOME/.pyenv
set -x POETRY $HOME/.poetry/bin
set -x GOPATH $HOME/go
set -gx NVM_DIR $HOME/.nvm
set --universal FZF_DEFAULT_COMMAND fd
set -x JAVA_HOME $HOME/Library/Caches/Coursier/arc/https/github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_x64_mac_hotspot_8u292b10.tar.gz/jdk8u292-b10/Contents/Home
set -x VISUAL nvim
set -x VIMCONFIG $HOME/.config/nvim/

set -x PATH $PATH $POETRY $PYENV_ROOT/bin $GOPATH/bin $NVM_DIR $JAVA_HOME /Users/glyphack/Library/Python/3.9/bin /Users/glyphack/.local/bin /Users/glyphack/opt/anaconda3/bin /Users/glyphack/opt/anaconda3/condabin /Users/glyphack/.pyenv/shims /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/go/bin /usr/local/Cellar/openvpn/2.5.5/sbin


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
        set -x PATH $PATH /Users/glyphack/Library/Application\ Support/Coursier/bin
end


# neovim
set -x PATH $PATH $VIMCONFIG/pack/bundle/start/fzf/bin

# fzf
set -x FZF_DEFAULT_COMMAND "rg --files"
