git config --global core.excludesFile /root/git_conf/.gitignore_global

mkdir -p /root/git_conf/hooks
cat > /root/git_conf/hooks/pre-push << 'HOOK'
#!/bin/bash
echo "git push is disabled in this VM"
exit 1
HOOK
chmod +x /root/git_conf/hooks/pre-push
git config --global core.hooksPath /root/git_conf/hooks

(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y


apt-get update -qq && apt-get install -y -qq tmux gh unzip
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

cat << 'TMUX_HELP'

=== tmux cheatsheet ===
prefix = Ctrl+b

sessions:  new: tmux new -s name   attach: tmux a -t name   list: tmux ls   detach: prefix d
windows:   create: prefix c   next: prefix n   prev: prefix p   pick: prefix <number>
panes:     split horizontal: prefix "   split vertical: prefix %   navigate: prefix <arrow>   close: prefix x
resize:    prefix Ctrl+<arrow>
TMUX_HELP
