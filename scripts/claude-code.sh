#!/bin/bash
if [ "$1" = "build" ]; then
    echo "Building claude-code image..."
    
    cat > /tmp/Containerfile.claude-code << 'EOF'
FROM node:24-alpine

# Install base development tools
RUN apk add --no-cache \
    curl \
    bash \
    git 

# Install claude-code
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /workspace
CMD ["/bin/bash"]
EOF
    
    podman build -f /tmp/Containerfile.claude-code -t claude-code .
    
    rm /tmp/Containerfile.claude-code
    
    echo "Build complete! Run './claude-code.sh' to start claude-code"
else
    container run -it \
        -v "$PWD":/workspace \
        -v ~/.claude-config-work/:/claude-config \
        -e CLAUDE_CONFIG_DIR=/claude-config \
        claude-code \
        bash -c "cd /workspace && bash"
fi
