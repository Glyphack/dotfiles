function on_pwd --on-variable PWD --description "Auto-activate virtualenvs and poetry environments"
    status is-interactive; or return

    # Set WezTerm tab title to current directory name
    printf "\e]1;%s\a" (basename $PWD)

    if test -d "$PWD/.venv"
        if test "$VIRTUAL_ENV" != "$PWD/.venv"
            source "$PWD/.venv/bin/activate.fish"
        end
        return
    end
end
