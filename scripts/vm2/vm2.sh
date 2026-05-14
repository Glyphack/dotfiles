#!/bin/bash
set -e

DOTFILES="$HOME/Programming/dotfiles"
SCRIPT_DIR="$DOTFILES/scripts/vm2"

if [ "${1}" = "build" ]; then
    echo "Building vm2 image..."
    container build -f "$SCRIPT_DIR/Containerfile" -t vm2 "$SCRIPT_DIR/"
    echo "Build complete."
    exit 0
fi

if [ "${1}" = "prune" ]; then
    echo "Removing vm2 containers..."
    containers=$(container ls -a -q | grep '^vm2' || true)
    if [ -n "$containers" ]; then
        # shellcheck disable=SC2086
        container rm -f $containers
    fi
    echo "Removing vm2 volumes..."
    volumes=$(container volume ls -q | grep '^vm2' || true)
    if [ -n "$volumes" ]; then
        # shellcheck disable=SC2086
        container volume rm $volumes
    fi
    echo "Prune complete."
    exit 0
fi

GH_TOKEN=$(gh auth token)
# GH_TOKEN=""

WITH_GIT_PUSH=false
for arg in "$@"; do
    case "$arg" in
        --with-git-push) WITH_GIT_PUSH=true ;;
    esac
done

SIZE="small"
MEMORY="2g"
CPUS="2"
if [ "${1}" = "l" ]; then
    SIZE="large"
    MEMORY="6g"
    CPUS="4"
fi

CONTAINER_NAME="vm2-${SIZE}-$(basename "$PWD")"

container system start

# If container is already running, exec into it
if container ls --format json | grep -q "\"$CONTAINER_NAME\""; then
    echo "Attaching to running container $CONTAINER_NAME..."
    exec container exec -it -w /workspace "$CONTAINER_NAME" bash -c "claude; exec bash"

fi

container rm "$CONTAINER_NAME" 2>/dev/null || true

VOL_ARGS=(
    -v "$PWD:/workspace"
    -v "$DOTFILES/dotfiles-private/agent/:$DOTFILES/dotfiles-private/agent/"
    -v "$HOME/.config/gh/:/root/.config/gh/"
    -v "$HOME/.claude/:/root/.claude/"
    -v "$HOME/.databrickscfg:/root/.databrickscfg"
    -v "$HOME/.databricks/:/root/.databricks/"
)

if [ "$WITH_GIT_PUSH" = true ]; then
    VOL_ARGS+=(
        -v "$HOME/.gitconfig:/home/node/.gitconfig"
        -v "$HOME/.ssh/:/home/node/.ssh/"
    )
fi

# Shadow platform-specific build dirs with named volumes so host and container don't clash
PROJECT_ID=$(basename "$PWD")
[ -f "$PWD/package.json" ] && VOL_ARGS+=(-v "vm2-${PROJECT_ID}-node_modules:/workspace/node_modules")
[ -f "$PWD/Cargo.toml" ] && VOL_ARGS+=(-v "vm2-${PROJECT_ID}-target:/workspace/target")
[ -f "$PWD/go.mod" ] && VOL_ARGS+=(-v "vm2-${PROJECT_ID}-gobin:/workspace/bin")

# If this is a worktree also mount the .git folder of the actual git repo
GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null || true)
if [ -n "$GIT_COMMON_DIR" ]; then
    GIT_COMMON_DIR=$(realpath "$GIT_COMMON_DIR")
    LOCAL_GIT=$(realpath "$PWD/.git" 2>/dev/null || true)
    if [ "$GIT_COMMON_DIR" != "$LOCAL_GIT" ]; then
        VOL_ARGS+=(-v "$GIT_COMMON_DIR:$GIT_COMMON_DIR")
    fi
fi

INIT_SCRIPT=""
if [ "$WITH_GIT_PUSH" = true ]; then
    INIT_SCRIPT="claude --dangerously-skip-permissions; exec bash"
else
    INIT_SCRIPT="mkdir -p /home/node/git_hooks && printf '#!/bin/bash\necho \"git push is disabled in this VM\"\nexit 1\n' > /home/node/git_hooks/pre-push && chmod +x /home/node/git_hooks/pre-push && git config --global core.hooksPath /home/node/git_hooks; claude; exec bash"
fi

RUN_CMD=(
    container run
    --rm
    -it
    --name "$CONTAINER_NAME"
    -e "GH_TOKEN=$GH_TOKEN"
    -e "CLAUDE_CONFIG_DIR=/root/.claude/"
    -w /workspace
    --memory "$MEMORY"
    --cpus "$CPUS"
    "${VOL_ARGS[@]}"
    vm2
    bash -c "$INIT_SCRIPT"
)

# printf '%q ' "${RUN_CMD[@]}"
# printf '\n'

"${RUN_CMD[@]}"
