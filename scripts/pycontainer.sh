container run -it \
      -v $PWD:/workspace \
      ghcr.io/astral-sh/uv:debian \
      bash -c "
    apt update
    apt install vim
    cd /workspace
bash
"
