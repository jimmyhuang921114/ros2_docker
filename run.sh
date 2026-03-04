#!/usr/bin/env bash
set -euo pipefail

# Docker image and container name
IMAGE="arm_ws:latest"
NAME="my_container"

# Host username (avoid "unbound variable" when USER is not set)
USER_NAME="${USER:-$(id -un)}"

# Detect GPU flag for Docker
# Newer Docker supports: --gpus all
# Older NVIDIA runtime uses: --runtime nvidia
GPU_FLAG=()
if docker run --help 2>/dev/null | grep -q -- '--gpus'; then
  GPU_FLAG+=(--gpus all)
else
  GPU_FLAG+=(--runtime nvidia)
fi

# Host Xauthority file for X11 GUI apps (RViz, Terminator, etc.)
XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"

# Prompt config that will be injected into the container at runtime
# Red for user@host, yellow for path
PROMPT_RC=$'export TERM=xterm-256color\nPS1="\\[\\e[1;31m\\]\\u@\\h\\[\\e[0m\\]:\\[\\e[1;33m\\]\\w\\[\\e[0m\\]\\$ "\nalias ls="ls --color=auto"\nalias grep="grep --color=auto"\nalias ll="ls -alF"\n'

# Encode prompt config to base64 so quoting/escaping will not break in bash -c
PROMPT_RC_B64="$(printf '%s' "${PROMPT_RC}" | base64 | tr -d '\n')"

# Container-side bootstrap command
# Decode the base64 config into /tmp/rcfile, then start an interactive bash that uses it
RCFILE_BOOT='echo "$PROMPT_RC_B64" | base64 -d > /tmp/rcfile; exec bash --noprofile --rcfile /tmp/rcfile -i'

# If a container with the same name already exists, reuse it
# If it's running: exec into it
# If it's stopped: start and attach
if docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
  if docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "Container is running, exec into it: ${NAME}"
    docker exec -it \
      -e PROMPT_RC_B64="${PROMPT_RC_B64}" \
      "${NAME}" \
      bash -lc "${RCFILE_BOOT}"
  else
    echo "Container exists but is stopped, starting and attaching: ${NAME}"
    docker start -ai "${NAME}"
  fi
  exit 0
fi

# Create and run a new container (persistent: no --rm)
echo "Creating new container: ${NAME}"

docker run -it \
  --name "${NAME}" \
  --privileged \
  --network=host \
  --ipc=host \
  "${GPU_FLAG[@]}" \
  -e DISPLAY="${DISPLAY:-:0}" \
  -e QT_X11_NO_MITSHM=1 \
  -e XAUTHORITY="/home/${USER_NAME}/.Xauthority" \
  -e PROMPT_RC_B64="${PROMPT_RC_B64}" \
  -v "${XAUTH}:/home/${USER_NAME}/.Xauthority:rw" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v /dev:/dev \
  -v "$(realpath "$PWD/.."):/work" \
  -w /work \
  "${IMAGE}" \
  bash -lc "${RCFILE_BOOT}"