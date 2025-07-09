eval "$(/opt/homebrew/bin/brew shellenv)"

FISH_ALIASES="$HOME/.config/fish/aliases.fish"

if [ -f $FISH_ALIASES ]; then
  source $FISH_ALIASES
fi
