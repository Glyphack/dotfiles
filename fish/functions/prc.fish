function prc --description "Push, create pull request, and copy PR details to clipboard"
    git push
    gh pr create --fill-first && prr $argv
end
