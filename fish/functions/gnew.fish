function gnew
    git fetch origin
    if git branch -r | grep -q "origin/main"
        set base_branch main
        git fetch origin main:main
    else
        set base_branch master
        git fetch origin master:master
    end
    
    if test (count $argv) -gt 0
        git checkout $base_branch
        and git checkout -b $argv[1]
    end
end
