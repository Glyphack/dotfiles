set -a fish_function_path $__fish_config_dir/omacy

fish_add_path --path $HOME/.local/bin

if test -x /opt/homebrew/bin/brew
    eval "$(/opt/homebrew/bin/brew shellenv fish)"
end

if type -q mise
    mise activate fish | source
end

# Vi-style bindings that keep the emacs-style keys in every mode
# https://github.com/fish-shell/fish-shell/blob/master/share/functions/fish_hybrid_key_bindings.fish
if type -q fish_hybrid_key_bindings
    fish_hybrid_key_bindings
end

if type -q fzf
    fzf --fish | source

    if not functions -q fish_user_key_bindings
        function fish_user_key_bindings --description "Configure user key bindings with fzf integration"
            fzf_key_bindings
        end
    end
end
