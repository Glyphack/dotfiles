function gsync --description "Sync main branch from upstream to origin"
    if git remote get-url upstream >/dev/null 2>&1
        git fetch upstream
        git fetch origin
        git push origin main --force
    else
        echo "No upstream remote configured"
    end
end
