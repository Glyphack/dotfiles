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

GH_TOKEN=$(gh auth token)
# GH_TOKEN=""

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
    exec container exec -it -w /workspace "$CONTAINER_NAME" bash -c "claude --dangerously-skip-permissions; exec bash"

fi

container rm "$CONTAINER_NAME" 2>/dev/null || true

VOL_ARGS=(
    -v "$PWD:/workspace"
    -v "$DOTFILES/agent/:$DOTFILES/agent/"
    -v "$HOME/.config/gh/:/home/node/.config/gh/"
    -v "$HOME/.claude/:/home/node/.claude/"
    -v "$HOME/.databrickscfg:/home/node/.databrickscfg"
    -v "$HOME/.databricks/:/home/node/.databricks/"
)

# Shadow platform-specific build dirs with named volumes so host and container don't clash
PROJECT_ID=$(basename "$PWD")
[ -f "$PWD/package.json" ] && VOL_ARGS+=(-v "vm2-${PROJECT_ID}-node_modules:/workspace/node_modules")
[ -f "$PWD/Cargo.toml" ] && VOL_ARGS+=(-v "vm2-${PROJECT_ID}-target:/workspace/target" -v "vm2-cargo-registry:/home/node/.cargo/registry" -v "vm2-cargo-git:/home/node/.cargo/git")
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

container run \
    --rm \
    -it \
    --name "$CONTAINER_NAME" \
    -e "GH_TOKEN=$GH_TOKEN" \
    -e "CLAUDE_CONFIG_DIR=/home/node/.claude/" \
    -w /workspace \
    --memory "$MEMORY" \
    --cpus "$CPUS" \
    "${VOL_ARGS[@]}" \
    vm2 \
    claude --dangerously-skip-permissions
