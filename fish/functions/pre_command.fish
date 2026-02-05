function pre_command --on-event fish_preexec
    printf '\033]133;A\033'
end
