sudo softwareupdate --install-rosetta --agree-to-license

python -m pip install --user virtualfish
mkdir -p ~/.virtualenvs/

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
