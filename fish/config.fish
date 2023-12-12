set -x VIMCONFIG $HOME/.config/nvim/
set -x VISUAL nvim
set -x PROGRAMMING_DIR ~/Programming
set -x DOTFILES_DIR ~/Programming/dotfiles
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



# setting the default kube config
set -gx KUBECONFIG $HOME/.kube/config


starship init fish | source
# status is-login; and pyenv init --path | source
# status is-interactive; and pyenv init - | source
#
# Enable AWS CLI autocompletion: github.com/aws/aws-cli/issues/1079
complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

nvm use 20 --silent

if test -e $DOTFILES_DIR/dotfiless-flexport/fish/env.fish
  source $DOTFILES_DIR/dotfiles-flexport/fish/env.fish
  setup_env
end

# pnpm
set -gx PNPM_HOME "/Users/glyphack/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
