function gmerge --description "Merge latest main/master into current branch"
    if git show-ref --verify --quiet refs/heads/main
        set base_branch main
    else if git show-ref --verify --quiet refs/heads/master
        set base_branch master
    else
        echo "Error: Neither 'main' nor 'master' branch found"
        return 1
    end
    
    git fetch origin $base_branch
    and git merge origin/$base_branch
end
