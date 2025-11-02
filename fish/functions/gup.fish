function gup
    git fetch origin
    if git branch -r | grep -q "origin/main"
        git fetch origin main:main
    else
        git fetch origin master:master
    end
end