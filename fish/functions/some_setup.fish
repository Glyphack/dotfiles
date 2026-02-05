function some_setup --on-variable PWD --description "Auto-activate virtualenvs and poetry environments"
    # Skip if we are in a non-interactive shell (though this function is called from interactive config)
    status is-interactive; or return

    # 1. Check for standard .venv directory (Fastest)
    if test -d "$PWD/.venv"
        if test "$VIRTUAL_ENV" != "$PWD/.venv"
            source "$PWD/.venv/bin/activate.fish"
        end
        return
    end

    # 2. Check for poetry.lock
    if test -e "$PWD/poetry.lock"
        if type -q poetry
            # If we are already in a virtualenv, check if it's the one for this project
            # Poetry envs usually have the project name in them.
            # This is a heuristic to avoid calling 'poetry env info' which is slow.
            set -l project_name (basename "$PWD")
            if not set -q VIRTUAL_ENV; or not string match -q "*$project_name*" "$VIRTUAL_ENV"
                eval (poetry env activate fish)
            end
        end
    end
end
